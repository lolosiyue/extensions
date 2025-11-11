extension = sgs.Package("scarletayuhuo", sgs.Package_GeneralPack)
extension_sl = sgs.Package("scarletyuhuoskillList", sgs.Package_GeneralPack)
extension_jx = sgs.Package("scarletbcuohuojixin", sgs.Package_GeneralPack)
extension_bf = sgs.Package("scarletchoujibofa", sgs.Package_GeneralPack)
extension_fg_jxyj = sgs.Package("extension_fg_jxyj", sgs.Package_GeneralPack)

extension_fakecard = sgs.Package("scarletbjixin_fakecard", sgs.Package_CardPack)  --卡牌包
extension_card = sgs.Package("scarletbcuohuojixin_card", sgs.Package_CardPack)  --卡牌包


s_HachisukaMasakatsu = sgs.General(extension,"s_HachisukaMasakatsu","magic","3", false)
local s_skillList = sgs.SkillList() 

--473338831
s_nixing = sgs.CreateTriggerSkill{
	name = "s_nixing" ,
	events = {sgs.DamageInflicted} ,
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if player:getArmor()  ~= nil then  return false end 
		if player:askForSkillInvoke(self:objectName(), data) then 
			local judge = sgs.JudgeStruct()
				judge.pattern = ".|black"
				judge.good = true
				judge.reason = self:objectName()
				judge.who = player
				player:getRoom():judge(judge)
				if judge:isGood() then 
				 local log= sgs.LogMessage()
					log.type = "#s_nixing"
					log.from = player
					log.arg = self:objectName()
					log.arg2  = damage.damage
					room:sendLog(log)
					damage.prevented = true
					data:setValue(damage)
				return true 
		end
		end
	end
}

s_anren = sgs.CreateViewAsSkill{
	name = "s_anren",
	n = 1,
	response_or_use = true,
		view_filter = function(self, selected, to_select)
		return to_select:isBlack()
	end, 
	view_as = function(self, cards)
	if #cards == 1 then 
		local card = s_anrencard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#s_anren")
	end,
}

s_anrencard = sgs.CreateSkillCard{
	name = "s_anren",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select) --必须
	local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
	card:deleteLater()
	card:setSkillName(self:objectName())
	local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
		if to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:canSlash(to_select, card,false) then
			return card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
		end
	end,
	on_use = function(self, room, source, targets) 
		if #targets > 0 then
			local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			card:setSkillName(self:objectName())
			card:deleteLater()
			card:addSubcard(self:getSubcards():first())
			local use = sgs.CardUseStruct()
			use.from = source
			for _,target in ipairs(targets) do
				use.to:append(target)
			end
			use.card = card
			room:useCard(use, false)
		end
	end,
}

s_anrenSlash = sgs.CreateTargetModSkill{
	name = "#s_anren-slash" ,
	pattern = "Slash" ,
	distance_limit_func = function(self, player, card)
		if player:hasSkill("s_anren") and (card:getSkillName() == "s_anren") then
			return 1000
		else
			return 0
		end
	end
}

s_HachisukaMasakatsu:addSkill(s_nixing)
s_HachisukaMasakatsu:addSkill(s_anren)
s_HachisukaMasakatsu:addSkill(s_anrenSlash)
extension:insertRelatedSkills("s_anren","#s_anren-slash")


s_MaedaToshitsune = sgs.General(extension,"s_MaedaToshitsune","magic","4", false)



s_wuqiang = sgs.CreateTargetModSkill{
	name = "s_wuqiang",
	pattern = "Slash",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) and ( player:getWeapon() ~= nil and player:getWeapon():getRealCard():toWeapon():getRange() > 2)then
			return 2
		else
			return 0
		end
	end,
}



s_MaedaToshitsune:addSkill(s_wuqiang)
--http://tieba.baidu.com/p/2139493222
sgs.LoadTranslationTable{
	["scarletayuhuo"] = "浴火重生",
	["scarletchoujibofa"] = "厚积薄发",
	["s_HachisukaMasakatsu"] = "蜂須賀五右衛門",
	["&s_HachisukaMasakatsu"] = "蜂須賀五右衛門",
	["#s_HachisukaMasakatsu"] = " 蜂須賀正勝",
	["designer:s_HachisukaMasakatsu"] = "御坂20623",
	["s_nixing"] = "匿形",
	[":s_nixing"] = "每当你受到一次伤害后，若你的装备区没有防具牌，你可以进行一次判定，若判定结果为黑色，防止該傷害。",
	["#s_nixing"] = " %from 的 %arg 發動成功，抵消 %arg2 點傷害",
	["s_anren"] = "暗刃",
	[":s_anren"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以將一張黑色牌当一张无视距离的【杀】使用。（該【杀】不计入出牌阶段内的使用次数限制）",
	
	["s_MaedaToshitsune"] = "前田犬千代",
	["&s_MaedaToshitsune"] = "前田犬千代",
	["#s_MaedaToshitsune"] = " 前田利家",
	["designer:s_MaedaToshitsune"] = "御坂20623",
	["s_wuqiang"] =  "舞槍",
	[":s_wuqiang"] = "<font color=\"blue\"><b>锁定技，</b></font>若你的装备区中有攻擊範圍大於2的武器牌時，你可以额外选择至多两名目标。",
	
  } 
  
  
  
 
 
 
 
 
  
  
  
 function s_addCards(card, proptable)
	local n = #proptable
	for i=1,n,2 do
		local tcard = card:clone()
		tcard:setSuit(proptable[i])
		tcard:setNumber(proptable[i+1])
		tcard:setParent(extension)
	end
end

 
 
--[[
 
 
 s_xiunufu = sgs.CreateArmor{
	name = "s_xiunufu",
	class_name = "s_XiuNuFu",
	suit = sgs.Card_Club,
	number = 12,	
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("s_xiunufu")
		room:getThread():addTriggerSkill(skill)
	end,
}

s_addCards(s_xiunufu, {sgs.Card_Club, 12})

s_xiunufuSkill = sgs.CreateTriggerSkill{
	name = "s_xiunufu",
	frequency = sgs.Skill_Compulsory, 
	can_trigger = function(self, target)
		if target then
				local armor = target:getArmor()
				return armor and armor:objectName() == self:objectName()
		end
	end,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Normal then 
				 local log= sgs.LogMessage()
					log.type = "#ArmorNullifyDamage"
					log.from = player
					log.arg = self:objectName()
					log.arg2  = damage.damage
					room:sendLog(log)
				return true 
				end
		return false
	end,
}
if not sgs.Sanguosha:getSkill("s_xiunufu") then
	s_skillList:append(s_xiunufuSkill)
end

 s_goggle = sgs.CreateArmor{
	name = "s_goggle",
	class_name = "s_Goggle",
	suit = sgs.Card_Spade,
	number = 7,	
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("s_goggle")
		room:getThread():addTriggerSkill(skill)
	end,
}

s_addCards(s_goggle, {sgs.Card_Spade, 7})

s_goggleSkill = sgs.CreateTriggerSkill{
	name = "s_goggle",
	frequency = sgs.Skill_Compulsory, 
	can_trigger = function(self, target)
		if target then
				local armor = target:getArmor()
				return armor and armor:objectName() == self:objectName()
		end
	end,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Thunder then 
			room:sendCompulsoryTriggerLog(player, "s_goggle", true)	
				damage.nature = sgs.DamageStruct_Thunder
				data:setValue(damage)
				end
		return false
	end,
}
if not sgs.Sanguosha:getSkill("s_goggle") then
	s_skillList:append(s_goggleSkill)
end





 s_shorthand_text = sgs.CreateWeapon{
	name = "s_shorthand_text",
	class_name = "s_shorthand_text",
	suit = sgs.Card_Club,
	number = 3,	
	range = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("s_shorthand_text")
		room:getThread():addTriggerSkill(skill)
	end,
}

s_addCards(s_shorthand_text, {sgs.Card_Club, 3})

s_shorthand_textSkill = sgs.CreateTriggerSkill{
	name = "s_shorthand_text",
	frequency = sgs.Skill_Frequent, 
	events = {sgs.CardResponded},
	on_trigger = function(self, event, player, data)
			local room = player:getRoom()
		local resp = data:toCardResponse()
						local card = resp.m_card
						if card and player:getPhase() == sgs.Player_NotActive then 
			if room:askForSkillInvoke(player, self:objectName(), data) then
				player:drawCards(1)
		end 
		end
	end,
		can_trigger = function(self, target)
		if target then
				local Weapon = target:getWeapon()
				return Weapon and Weapon:objectName() == self:objectName()
		end
	end,
}
if not sgs.Sanguosha:getSkill("s_shorthand_text") then
	s_skillList:append(s_shorthand_textSkill)
end

 s_lotus_stick = sgs.CreateWeapon{
	name = "s_lotus_stick",
	class_name = "s_lotus_stick",
	suit = sgs.Card_Club,
	number = 9,	
	range = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("s_lotus_stick")
		room:getThread():addTriggerSkill(skill)
	end,
}

s_addCards(s_lotus_stick, {sgs.Card_Club, 9})

s_lotus_stickSkill = sgs.CreateTriggerSkill{
	name = "s_lotus_stick",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
			local room = player:getRoom()
		local use = data:toCardUse()
			if use.from:objectName() == player:objectName() then
					if use.card:isKindOf("Duel") then
					room:sendCompulsoryTriggerLog(player,self:objectName(), true)
						player:drawCards(1)
					end
		end
	end,
		can_trigger = function(self, target)
		if target then
				local Weapon = target:getWeapon()
				return Weapon and Weapon:objectName() == self:objectName()
		end
	end,
}
if not sgs.Sanguosha:getSkill("s_lotus_stick") then
	s_skillList:append(s_lotus_stickSkill)
end


s_fire_sword = sgs.CreateWeapon{
	name = "s_fire_sword",
	class_name = "s_fire_sword",
	suit = sgs.Card_Heart,
	number = 12,	
	range = 3,
	on_install = function(self,player)
		local room = player:getRoom()
		room:attachSkillToPlayer(player, "s_fire_sword")
		local skill = sgs.Sanguosha:getTriggerSkill("#s_fire_sword")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "s_fire_sword")
	end,
}

s_addCards(s_fire_sword, {sgs.Card_Heart, 12})

s_fire_swordCard = sgs.CreateSkillCard{
	name = "s_fire_sword" ,
	will_throw = false,
	filter = function(self, targets, to_select)
	local card = sgs.Sanguosha:getCard(self:getSubcards():first())
	 if #targets <= 2 then 
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local slash = sgs.Sanguosha:cloneCard("fire_slash", card:getSuit(), card:getNumber())
		slash:setSkillName(self:objectName())
		slash:deleteLater()
		return  sgs.Self:canSlash(to_select, slash, true, 0)
			end
		end,
	on_use = function(self, room, source, targets)
		local targets_list = sgs.SPlayerList()
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		for _, target in ipairs(targets) do
			if source:canSlash(target, nil, false) then
				targets_list:append(target)
				room:setPlayerFlag(target, "s_fire_sword_target")
			end
		end
		if targets_list:length() > 0 then
			room:loseHp(source)
			local slash = sgs.Sanguosha:cloneCard("fire_slash", card:getSuit(), card:getNumber())
			slash:addSubcard(card)
			slash:setSkillName(self:objectName())
			room:useCard(sgs.CardUseStruct(slash, source, targets_list), true)
		end
	end
}

s_fire_swordskill = sgs.CreateViewAsSkill{
	name = "s_fire_sword",
	n = 1,
	view_filter = function(self, cards, to_select)
		return to_select:isKindOf("FireSlash")or to_select:isKindOf("ThunderSlash")
	end,
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = s_fire_swordCard:clone()
			card:addSubcard(cards[1])
			card:setSkillName("s_fire_sword")
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and player:getPhase() == sgs.Player_Play 
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}

s_fire_swordskill_tg = sgs.CreateTriggerSkill{
	name = "#s_fire_sword" ,
	events = {sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:getSkillName() == "s_fire_sword" and damage.to:hasFlag("s_fire_sword_target") then 
		local list = room:getOtherPlayers(damage.to)
		for _,q in sgs.qlist(list) do
				if q:hasFlag("s_fire_sword_target") then 
				room:sendCompulsoryTriggerLog(player, "s_fire_sword", true)
				room:damage(sgs.DamageStruct("s_fire_sword", damage.from, q, damage.damage, sgs.DamageStruct_Fire))
					
				end
				end
			end
	end,
		can_trigger = function(self, target)
		return target  and target:hasWeapon("s_fire_sword")
	end
}


if not sgs.Sanguosha:getSkill("s_fire_sword") then
	s_skillList:append(s_fire_swordskill)
end
if not sgs.Sanguosha:getSkill("#s_fire_sword") then
	s_skillList:append(s_fire_swordskill_tg)
end

s_seven_moment = sgs.CreateWeapon{
	name = "s_seven_moment",
	class_name = "s_seven_moment",
	suit = sgs.Card_Heart,
	number = 1,	
	range = 3,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("s_seven_moment")
		room:getThread():addTriggerSkill(skill)
	end,
}

s_addCards(s_seven_moment, {sgs.Card_Heart, 1})

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
s_seven_momentSkill = sgs.CreateTriggerSkill{
	name = "s_seven_moment" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			local can_invoke = false
			if use.card:isKindOf("Slash") and (player and player:isAlive()) and (use.from:objectName() == player:objectName()) then
				can_invoke = true
				room:sendCompulsoryTriggerLog(player, self:objectName(), true)
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				for i = 0, use.to:length() - 1, 1 do
					if jink_table[i + 1] == 1 then
						jink_table[i + 1] = 2 --只要设置出两张闪就可以了，不用两次askForCard
					end
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		if target then
				local Weapon = target:getWeapon()
				return Weapon and Weapon:objectName() == self:objectName() and target:isWounded()
		end
	end,
}
if not sgs.Sanguosha:getSkill("s_seven_moment") then
	s_skillList:append(s_seven_momentSkill)
end



s_coin = sgs.CreateWeapon{
	name = "s_coin",
	class_name = "s_coin",
	suit = sgs.Card_Spade,
	number = 1,	
	range = 5,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("s_coin")
		room:getThread():addTriggerSkill(skill)
	end,
}

s_addCards(s_coin, {sgs.Card_Spade, 1})


s_coinSkill = sgs.CreateTriggerSkill{
	name = "s_coin",
	frequency = sgs.Skill_Compulsory, 
	can_trigger = function(self, target)
		if target then
				local weapon = target:getWeapon()
				return weapon and weapon:objectName() == self:objectName()
		end
	end,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Thunder then 
			room:sendCompulsoryTriggerLog(player, "s_coin", true)	
				damage.nature = sgs.DamageStruct_Thunder
				data:setValue(damage)
				end
		return false
	end,
}


if not sgs.Sanguosha:getSkill("s_coin") then
	s_skillList:append(s_coinSkill)
end

s_rune = sgs.CreateWeapon{
	name = "s_rune",
	class_name = "s_rune",
	suit = sgs.Card_Diamond,
	number = 1,	
	range = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("s_rune")
		room:getThread():addTriggerSkill(skill)
	end,
}

s_addCards(s_rune, {sgs.Card_Diamond, 1})


s_runeSkill = sgs.CreateTriggerSkill{
	name = "s_rune",
	frequency = sgs.Skill_Compulsory, 
	can_trigger = function(self, target)
		if target then
				local weapon = target:getWeapon()
				return weapon and weapon:objectName() == self:objectName() and target:isWounded()
		end
	end,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.nature == sgs.DamageStruct_Fire and player:inMyAttackRange(damage.to)  then 
			room:sendCompulsoryTriggerLog(player, "s_rune", true)	
				local re = sgs.RecoverStruct()
						re.who = player		
						room:recover(player,re,true)
				end
		return false
	end,
}


if not sgs.Sanguosha:getSkill("s_rune") then
	s_skillList:append(s_runeSkill)
end


 
  sgs.LoadTranslationTable{
	["s_xiunufu"] = "修女服",
	[":s_xiunufu"] = "装备牌·防具<br /><b>防具技能</b>：<font color=\"blue\"><b>锁定技，</b></font>对你造成的属性伤害无效。",

	["s_goggle"] = "护目镜",
	[":s_goggle"] = "装备牌·防具<br /><b>防具技能</b>：<font color=\"blue\"><b>锁定技，</b></font>你受到的伤害始终视为雷电伤害。",
	
	["s_shorthand_text"] = "速记原典",
	[":s_shorthand_text"] = "装备牌·武器<br /><b>攻击范围</b>：２<br /><b>武器技能</b>：你的回合外，你每打出一张手牌可摸一张牌。",
	
	["s_lotus_stick"] = "莲花杖",
	[":s_lotus_stick"] = "装备牌·武器<br /><b>攻击范围</b>：２<br /><b>武器技能</b>：<font color=\"blue\"><b>锁定技，</b></font>你每使用一张【决斗】时，你摸一张牌。",
	
	["s_fire_sword"] = "焰形剑",
	[":s_fire_sword"] = "装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>：出牌阶段，你可以失去一点体力使你使用的属性杀视为火杀对三名角色使用，若其中有一名角色无法打出【闪】而受到伤害，其他目标角色也同时受到伤害。",
	
	["s_seven_moment"] = "七天七刀",
	[":s_seven_moment"] = "装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>：<font color=\"blue\"><b>锁定技，</b></font>若你已受伤，你使用的的【杀】需要两张【闪】才能抵消。",
	
	["s_coin"] = "硬币",
	[":s_coin"] = "装备牌·武器<br /><b>攻击范围</b>：５<br /><b>武器技能</b>：<font color=\"blue\"><b>锁定技，</b></font>你造成的伤害均视为雷电伤害。",
	
	[":s_rune"] = "装备牌·武器<br /><b>攻击范围</b>：２<br /><b>武器技能</b>：<font color=\"blue\"><b>锁定技，</b></font>当你对攻击范围内的角色造成火焰伤害时，你回复一点体力。",
	["s_rune"] = "符文卡",
	
	["s_arche"] = "箭矢",
	[":s_arche"] = "装备牌·武器<br /><b>攻击范围</b>：５<br /><b>武器技能</b>：<font color=\"blue\"><b>锁定技，</b></font>你的方块花色的判定牌生效后，均视为梅花。",
 } 
  
 
 
 
 
 ]]
 


LuaHuashen = sgs.CreateTriggerSkill{
	name = "LuaHuashen",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damaged, sgs.GameStart, sgs.TurnStart, sgs.DamageCaused}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.Damaged  or event == sgs.DamageCaused  then
			local damage = data:toDamage()
			if damage.to:hasSkill(self:objectName()) or damage.from:hasSkill(self:objectName()) then
                
				for i = 1, damage.damage, 1 do
					local players = room:getAlivePlayers()
					local skill_name = ""
					local sks = {}
					local all_generals = sgs.Sanguosha:getLimitedGeneralNames()
					
					for _,general_name in ipairs(all_generals) do
						local general = sgs.Sanguosha:getGeneral(general_name)
						for _,sk in sgs.qlist(general:getVisibleSkillList()) do
							--if not sk:isLordSkill() then
									table.insert(sks, sk:objectName())
							--end
						end
					end

					for _,pl in sgs.qlist(players) do
						for _,ske in sgs.qlist(pl:getVisibleSkillList()) do
							if table.contains(sks, ske:objectName()) then table.removeOne(sks, ske:objectName()) end
						end
					end

					if #sks == 0 then return end
					local ran = math.random(1, #sks)
					skill_name = sks[ran]
					if event ==  sgs.Damaged and damage.to:hasSkill(self:objectName()) and player:objectName() == damage.to:objectName() then
                    player:drawCards(1)
					room:handleAcquireDetachSkills(damage.to, skill_name)
                    elseif event  ==  sgs.DamageCaused and damage.from:hasSkill(self:objectName()) and player:objectName() == damage.from:objectName() then
                    player:drawCards(1)
					room:handleAcquireDetachSkills(damage.from, skill_name)
					end
				end
			end
		elseif event == sgs.GameStart or event == sgs.TurnStart then
			if not player:faceUp() then
			player:turnOver()
			end
            player:drawCards(1)
            if player:getMaxHp() < 4 then
                room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 3) )
            end
					local players = room:getAlivePlayers()
					local skill_name = ""
					local sks = {}
					local all_generals = sgs.Sanguosha:getLimitedGeneralNames()
					for i=1, #all_generals do
						if all_generals[i]=="Tukasa" or all_generals[i]=="mianma" or all_generals[i]=="Sakura" or all_generals[i]=="Riko" or all_generals[i]=="Nanami" or all_generals[i]=="Koishi" or all_generals[i]=="Mikoto" or all_generals[i]=="Natsume_Rin" or all_generals[i]=="Kazehaya" or all_generals[i]=="AiAstin" or all_generals[i]=="Reimu" or all_generals[i]=="Louise" then
							table.remove(all_generals, i)
							i = i - 1 
						end
					end

					for _,general_name in ipairs(all_generals) do
						local general = sgs.Sanguosha:getGeneral(general_name)
						for _,sk in sgs.qlist(general:getVisibleSkillList()) do
							if not sk:isLordSkill() then
									table.insert(sks, sk:objectName())
							end
						end
					end

					for _,pl in sgs.qlist(players) do
						for _,ske in sgs.qlist(pl:getVisibleSkillList()) do
							if table.contains(sks, ske:objectName()) then table.removeOne(sks, ske:objectName()) end
						end
					end

					if #sks == 0 then return end
					local ran = math.random(1, #sks)
					skill_name = sks[ran]
					room:handleAcquireDetachSkills(player, skill_name)
		end
		return false
	end
}


sgs.LoadTranslationTable{
["#test"]="%arg",}

s_Godking = sgs.General(extension,"s_Godking","god","4", false)
 
s_Godking:addSkill(LuaHuashen)
s_Godking:addSkill("biyue")
 
 
 sgs.LoadTranslationTable{
	["s_Godking"] = "娜路",
	["&s_Godking"] = "娜路",
	["#s_Godking"] = " 神皇",
	["designer:s_Godking"] = "SCARLET",
	
	["LuaHuashen"] = "幻化",
	[":LuaHuashen"] = "所有人都展示武将牌后，你随机获得五张未加入游戏的武将牌，称为“幻化牌”，选一张置于你面前并声明该武将的所有技能，你获得该技能且同时将势力属性变成与该武将相同直到“幻化牌”被替换。在你的每个回合开始时和结束后，你可以替换“幻化牌”。每当你造成1点伤害后，你可以获得一张“幻化牌”，你可以替换“幻化牌”。若你的“幻化牌”等於或多於十張，你須棄置所有“幻化牌”。",
} 



s_yeyun = sgs.General(extension,"s_yeyun","god","4", false)
s_yeyun:addSkill("biyue")
s_yeyun:addSkill("qiangwu")
s_yeyun:addSkill("hongyan")
sgs.LoadTranslationTable{
	["s_yeyun"] = "夜云",
	["&s_yeyun"] = "夜云",
	["#s_yeyun"] = " 国色天香",
	["designer:s_yeyun"] = "SCARLET",
	
} 

  

 
s_w_machao = sgs.General(extension,"s_w_machao","qun","4")




s_biaoqi = sgs.CreateTriggerSkill{
	name = "s_biaoqi" ,
	events = {sgs.Damage, sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	if event == sgs.Damage then 
		local damage = data:toDamage()
		if  damage.card and damage.card:isKindOf("Slash")
				and damage.by_user and (not damage.chain) and (not damage.transfer)  and damage.to:isAlive() then
			if player:askForSkillInvoke(self:objectName(), data) then
					room:drawCards(player, 1, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
				if not player:isKongcheng() then
				local card_id
					if player:getHandcardNum() == 1 then
						card_id = player:handCards():first()
					else
						card_id = room:askForExchange(player, self:objectName(), 1,1, false, "s_biaoqiPush"):getSubcards():first()
					end
					damage.to:addToPile("s_yong", card_id)
				end
			end
			end
		else 
		local change = data:toPhaseChange()
			if change.to == sgs.Player_Start then
			for _,p in sgs.qlist(room:getOtherPlayers(player))do
			if p:getPile("s_yong"):length() > 0 then 
			  local dummy = sgs.Sanguosha:cloneCard("slash")
			 	for i=0, (p:getPile("s_yong"):length()-1), 1 do
				dummy:addSubcard(p:getPile("s_yong"):at(i))
				end
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, p:objectName(), "s_biaoqi", "");
						room:obtainCard(player, dummy, reason, false)
				end	
				end
			end
		end
		return false
	end
}

s_biaoqiAttach = sgs.CreateTriggerSkill{
	name = "#s_biaoqi", 
	events = {sgs.TurnStart,sgs.EventAcquireSkill,sgs.EventLoseSkill}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local source = room:findPlayerBySkillName("s_biaoqi")
		if event == sgs.TurnStart then
			if (event == sgs.TurnStart and source and source:isAlive()) or (event == sgs.EventAcquireSkill and data:toString() == "s_biaoqi") then
				for _,p in sgs.qlist(room:getOtherPlayers(source))do
					if not p:hasSkill("s_biaoqiSlash&") then
						room:attachSkillToPlayer(p,"s_biaoqiSlash&")
					end
				end
			end
		elseif event == sgs.EventLoseSkill and data:toString() == "s_biaoqi"then
			for _,p in sgs.qlist(room:getOtherPlayers(player))do
				if p:hasSkill("s_biaoqiSlash&") then
					room:detachSkillFromPlayer(p, "s_biaoqiSlash&", true)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

s_biaoqiSlashCard = sgs.CreateSkillCard{
	name = "s_biaoqiSlash", 
	target_fixed = false,
	will_throw = false, 
	filter = function(self, targets, to_select) 
	if to_select:getPile("s_yong"):length() >0 and sgs.Self:canSlash(to_select,nil)then 
		for _, card_id in sgs.qlist(to_select:getPile("s_yong")) do
				local card = sgs.Sanguosha:getCard(card_id)
				if card:getId() == sgs.Sanguosha:getCard(self:getSubcards():first()):getId() then 
				return true 
				end
			end
		end
	end,
	on_validate = function(self,carduse)
		local source = carduse.from
		local target = carduse.to:first()
		local room = source:getRoom()
		local dummy = sgs.Sanguosha:cloneCard("jink")
		dummy:addSubcard(self:getSubcards():first())
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "s_biaoqiSlash", "");
		room:throwCard(dummy, reason, nil);
		if source:canSlash(target, nil, false) then
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:setSkillName("s_biaoqi")
			return slash
		end
	end,
}
function canSlashLiufeng (player)
	local liufeng = nil;
	for _,p in sgs.qlist(player:getAliveSiblings()) do
		if (p:getPile("s_yong"):length() > 0) then
			liufeng = p;
			local slash = sgs.Sanguosha:cloneCard("slash")
			if slash:targetFilter(sgs.PlayerList(), liufeng, player) then 
			return true 
			end
		end
	end
end

s_biaoqiSlash = sgs.CreateOneCardViewAsSkill{
	name = "s_biaoqiSlash",
	expand_pile = "%s_yong",
	view_as = function(self, originalCard) 
	local card =  s_biaoqiSlashCard:clone()
	card:addSubcard(originalCard:getId())
	card:setSkillName(self:objectName())
		return card
	end, 
	view_filter=function(self,selected,to_select)
		for _,p in sgs.qlist(sgs.Self:getAliveSiblings()) do 
			if  p:getPile("s_yong"):length() > 0 then 
				return p:getPile("s_yong")--:contains(to_select:getId())
		end
		end
		return false 
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and canSlashLiufeng(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return  pattern == "slash"and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
			   and canSlashLiufeng(player)
	end,
}



s_w_machao:addSkill("mashu")
s_w_machao:addSkill(s_biaoqi)
s_w_machao:addSkill(s_biaoqiAttach)
extension:insertRelatedSkills("s_biaoqi","#s_biaoqi")
if not sgs.Sanguosha:getSkill("s_biaoqiSlash") then
	s_skillList:append(s_biaoqiSlash)
end

--http://tieba.baidu.com/p/3798932117
 sgs.LoadTranslationTable{
	["s_w_machao"] = "马超",
	["&s_w_machao"] = "马超",
	["#s_w_machao"] = " 西涼之柱",
	["designer:s_w_machao"] = "你别吐",
	
	["s_biaoqiPush"] = "请将一张手牌置于目标角色的武将牌上",
	["s_yong"] = "勇",
	["s_biaoqi"] = "驃騎",
	[":s_biaoqi"] = "当你使用【杀】对目标角色造成伤害后，你可以摸一张牌，然后将一张手牌置于目标角色的武将牌上，称为“勇”。其他角色可以将一张“勇”置入弃牌堆，视为对该角色使用一张【杀】。准备阶段开始时，你获得場上所有“勇”。",
	["s_biaoqiSlash"] = "驃騎(杀)",
	[":s_biaoqiSlash"] = "你可以将一张“勇”置入弃牌堆，视为对该角色使用一张【杀】。",
	["s_biaoqislash"] = "驃騎",
	["$s_biaoqi"] = "目标敌阵，全军突击！",
	["$s_biaoqiSlash1"] = "全军突击！",
	["$s_biaoqiSlash2"] = "（枪声，马叫声）",
	} 
  

s_w_godzhaoyun = sgs.General(extension,"s_w_godzhaoyun","god","1")

s_w_longhou = sgs.CreateMaxCardsSkill{
	name = "s_w_longhou" ,
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return 3
		end
	end
}


s_w_yongjin = sgs.CreateViewAsSkill{
	name = "s_w_yongjin",
	n = 0,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit,0)
			slash:setSkillName(self:objectName())
			return slash
	end,
	enabled_at_play = function(self, player)
		if sgs.Slash_IsAvailable(player) and player:getMark("&s_w_yongjin") > 0 then
			return true
		end
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if (pattern == "slash" and player:getMark("&s_w_yongjin") > 0) then
			return true
		end
		return false
	end,
}

s_w_yongjinWork = sgs.CreateTriggerSkill{
	name = "#s_w_yongjinWork",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardResponded, sgs.TargetConfirmed, sgs.GameStart, sgs.EventAcquireSkill},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardResponded then
			local resp = data:toCardResponse()
			local card = resp.m_card
			if card:getSkillName() == "s_w_yongjin" then
				if card:isKindOf("Slash") then
					player:loseMark("&s_w_yongjin", 1)
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.from:objectName() == player:objectName() then
				if use.card:getSkillName() == "s_w_yongjin" then
					if use.card:isKindOf("Slash") then
						player:loseMark("&s_w_yongjin", 1)
						room:broadcastSkillInvoke("s_w_yongjin")
					end
				end
			end
		elseif (event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == "s_w_yongjin") and player:getMark("s_w_yongjinDone") == 0) then 
		player:gainMark("&s_w_yongjin", 7) 
		room:setPlayerMark(player,"s_w_yongjinDone",1)
		end
	end
}
 

s_w_zhituiWork = sgs.CreateTriggerSkill{
	name = "#s_w_zhituiWork",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardResponded, sgs.GameStart, sgs.TargetConfirmed, sgs.EventAcquireSkill},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardResponded then
			local resp = data:toCardResponse()
			local card = resp.m_card
			if card:getSkillName() == "s_w_zhitui" then
				if card:isKindOf("Jink") then
					player:loseMark("&s_w_zhitui", 1)
				elseif card:isKindOf("Peach") then
				player:loseMark("&s_w_zhitui", 1)
				end
			end
		elseif (event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == "s_w_zhitui") and player:getMark("s_w_zhituiDone") == 0) then 
		player:gainMark("&s_w_zhitui", 7) 
		room:setPlayerMark(player,"s_w_zhituiDone",1)
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.from:objectName() == player:objectName() then
				if use.card:getSkillName() == "s_w_zhitui" then
					if use.card:isKindOf("Peach") then
						player:loseMark("&s_w_zhitui", 1)
						room:broadcastSkillInvoke("s_w_zhitui", math.random(2))
					end
				end
		end
		end
	end
}
s_w_zhitui = sgs.CreateViewAsSkill{
	name = "s_w_zhitui" ,
	n = 0 ,
	view_as = function(self, cards)
		if #cards ~= 0 then return nil end
		local new_card = nil
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY  then
			new_card = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
		elseif (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
				or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "jink" then
			new_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
			elseif string.find(pattern, "peach") then
				new_card = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
			end
		end
		new_card:setSkillName(self:objectName())
		return new_card
	end ,
	enabled_at_play = function(self, player)
		return player:isWounded() and player:getMark("&s_w_zhitui") > 0
	end ,
	enabled_at_response = function(self, player, pattern)
		return  (pattern == "jink" and player:getMark("&s_w_zhitui") > 0)
				or (string.find(pattern, "peach") and (not player:hasFlag("Global_PreventPeach")) and player:getMark("&s_w_zhitui") > 0)
	end ,
}



s_w_godzhaoyun:addSkill(s_w_longhou)
s_w_godzhaoyun:addSkill(s_w_yongjin)
s_w_godzhaoyun:addSkill(s_w_yongjinWork)
s_w_godzhaoyun:addSkill(s_w_zhitui)
s_w_godzhaoyun:addSkill(s_w_zhituiWork)
extension:insertRelatedSkills("s_w_yongjin","#s_w_yongjinWork")
extension:insertRelatedSkills("s_w_zhitui","#s_w_zhituiWork")
--http://tieba.baidu.com/p/1293651054

 sgs.LoadTranslationTable{
	["s_w_godzhaoyun"] = "神赵云",
	["&s_w_godzhaoyun"] = "神赵云",
	["#s_w_godzhaoyun"] = " 單騎救主",
	["designer:s_w_godzhaoyun"] = "wjlhr0",
	
	["s_w_longhou"] = "龍吼",
	["$s_w_longhou"] = "龙战于野，其血玄黄。",
	[":s_w_longhou"] = "<font color=\"blue\"><b>锁定技，</b></font>你的手牌上限+3。",
	
	["s_w_yongjin"] = "勇進",
	[":s_w_yongjin"] = "游戏开始时，你获得7枚“進”标记；你可以弃置1枚“進”标记，视为你使用或打出一张【杀】。",
	["&s_w_yongjin"] = "進",
	["$s_w_yongjin"] = "千里一怒，红莲灿世。",
	
	["s_w_zhitui"] = "智退",
	[":s_w_zhitui"] = "游戏开始时，你获得7枚“退”标记；你可以弃置1枚“進”标记，视为你使用或打出一张【桃】或【閃】。",
	["&s_w_zhitui"] = "退",
	["$s_w_zhitui1"] = "进退自如，游刃有余！",
	["$s_w_zhitui2"] = "遍寻天下，但求一败！",
  } 


s_w_caocao = sgs.General(extension,"s_w_caocao","wei","4")

s_w_jianxiong = sgs.CreateMasochismSkill{
	name = "s_w_jianxiong" ,
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		local data = sgs.QVariant()
		data:setValue(damage)
		local choices = {"draw+cancel"}
		local card = damage.card
		if card then
			local ids = sgs.IntList()
			if card:isVirtualCard() then
				ids = card:getSubcards()
			else
				ids:append(card:getEffectiveId())
			end
			if ids:length() > 0 then
				local all_place_table = true
				for _, id in sgs.qlist(ids) do
					if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
						all_place_table = false
						break
					end
				end
				if all_place_table then
					table.insert(choices, "obtain")
				end
			end
		end
		player:setTag("s_w_jianxiong", data)
		local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), data)
		if choice ~= "cancel" then
			room:notifySkillInvoked(player, self:objectName())
			if choice == "obtain" then
				player:obtainCard(card)
			else
				player:drawCards(1, self:objectName())
			end
		end
	end
}


s_w_luopo = sgs.CreateTriggerSkill{
	name = "s_w_luopo" ,
	frequency = sgs.Skill_Wake,
	events = {sgs.ChoiceMade} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local str = data:toString()
		local data_list = str:split(":")
		if (data_list[2] == "s_w_jianxiong") then 
			if data_list[3] == "cancel" then return false end
			if (player:getHp() <=2 or player:canWake(self:objectName())) and room:changeMaxHpForAwakenSkill(player) then
				room:addPlayerMark(player, "s_w_luopo")
				local hp = player:getHp()
				if hp < 3 then
					local recover = sgs.RecoverStruct()
					recover.who = player
					recover.recover = 3 - hp 
					room:recover(player, recover)
				end
				room:handleAcquireDetachSkills(player, "s_w_geran")
				room:handleAcquireDetachSkills(player, "s_w_qipao")
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
		   and (target:getMark("s_w_luopo") == 0) 
	end
}

s_w_geran = sgs.CreateTriggerSkill{
	name = "s_w_geran" ,
	frequency = sgs.Skill_NotFrequent ,
	events = {sgs.ChoiceMade} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local str = data:toString()
		local data_list = str:split(":")
		 if ( data_list[2] == "s_w_jianxiong" and data_list[3] == "draw") then 
				local damage = player:getTag("s_w_jianxiong"):toDamage()
				if room:askForSkillInvoke(player, "s_w_geran", player:getTag("s_w_jianxiong")) then
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|black"
				judge.good = true
				judge.reason = self:objectName()
				judge.who = player
				judge.time_consuming = true
				room:judge(judge)
				if judge:isGood() then 
				if damage.from then
					if  player:canDiscard(damage.from, "he") then
					local to_throw = room:askForCardChosen(player, damage.from, "he", self:objectName())
					local card = sgs.Sanguosha:getCard(to_throw)
					room:throwCard(card, damage.from, player);
						end
					end
				end
				end
		end
		return false
	end ,
}

s_w_qipaocard = sgs.CreateSkillCard{
	name = "s_w_qipao",
	target_fixed = true,
	will_throw = true
}

s_w_qipaoVS = sgs.CreateViewAsSkill{
	name = "s_w_qipao",
	n = 2,
	view_filter = function(self, selected, to_select)
		return #selected<2 and to_select:isRed()
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local card = s_w_qipaocard:clone()
			card:addSubcard(cards[1])
			card:addSubcard(cards[2])
			card:setSkillName("s_w_qipao")
			return card 
		end
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@s_w_qipao" 
	end
}


s_w_qipao = sgs.CreateTriggerSkill{
	name = "s_w_qipao" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.ChoiceMade} ,
	view_as_skill = s_w_qipaoVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local str = data:toString()
		local data_list = str:split(":")
		 if (data_list[2] == "s_w_jianxiong" and data_list[3] == "obtain") then 
		 local damage = player:getTag("s_w_jianxiong"):toDamage()
				if room:askForSkillInvoke(player, "s_w_qipao", player:getTag("s_w_jianxiong")) then
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|red"
				judge.good = true
				judge.reason = self:objectName()
				judge.who = player
				judge.time_consuming = true
				room:judge(judge)
				if judge:isGood() then 
						if  player:canDiscard(player, "he") then
						local pattern = "@@s_w_qipao"
					local prompt = string.format("#s_w_qipao:%s",player:objectName())
					local card = room:askForCard(player, pattern, prompt, data, sgs.Card_MethodDiscard, player, true, self:objectName())
							if card then 
								room:throwCard(card, player)
								local recover = sgs.RecoverStruct()
						recover.who = player
						room:recover(player, recover)
							end
						end
					end
				end
		end
		return false
	end ,
}




if not sgs.Sanguosha:getSkill("s_w_qipao") then
	s_skillList:append(s_w_qipao)
end
if not sgs.Sanguosha:getSkill("s_w_geran") then
	s_skillList:append(s_w_geran)
end


s_w_caocao:addSkill(s_w_jianxiong)
s_w_caocao:addSkill(s_w_luopo)
s_w_caocao:addSkill(s_w_qipao)
s_w_caocao:addSkill("hujia")
s_w_caocao:addRelateSkill("s_w_geran")
s_w_caocao:addRelateSkill("s_w_qipao")
--http://tieba.baidu.com/p/3826540104
 sgs.LoadTranslationTable{
	["s_w_caocao"] = "曹操",
	["&s_w_caocao"] = "曹操",
	["#s_w_caocao"] = " 割髯弃袍",
	["designer:s_w_caocao"] = "Mercer_x",
	
	["s_w_jianxiong"] = "奸雄",
	[":s_w_jianxiong"] = "每当你受到伤害后，你可以选择一项；摸一张牌，或获得对你造成伤害的牌。",
	
	["s_w_geran"] = "割髯",
	[":s_w_geran"] = "当你发动“奸雄”时，若你选择摸一张牌，你可以进行一次判定，若结果为黑色，你弃置其1张牌。",
	
	["s_w_luopo"] = "落魄",
	[":s_w_luopo"] = "<font color=\"purple\"><b>觉醒技，</b></font>当你发动“奸雄”且体力值小于等于2时，你必须减一点体力上限，将体力值恢复至3，并获得技能“割髯”和“弃袍”。",
	
	["s_w_qipao"] = "弃袍",
	["~s_w_qipao"] = "选择两张手牌→点击确定",
	[":s_w_qipao"] = "当你发动“奸雄”时，若你选择获得对你造成伤害的牌，你可以进行一次判定，若为红色，你可弃置两张红色牌并回复一点体力。",
	["#s_w_qipao"] = "你可以弃置两张红色牌并回复一点体力。",
 } 



s_w_lubu = sgs.General(extension,"s_w_lubu","qun","4")

s_w_wushuangVS = sgs.CreateOneCardViewAsSkill{
	name = "s_w_wushuang",
	response_or_use = true,
	view_filter = function(self, card)
		if card:isEquipped() then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(card:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self, originalCard)
	if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
		local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
		slash:addSubcard(originalCard:getId())
		slash:setSkillName(self:objectName())
		return slash
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and player:getMark("s_w_wushuang-PlayClear") == 0
	end, 
}


s_w_wushuang = sgs.CreateTriggerSkill{
	name = "s_w_wushuang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed},
	view_as_skill = s_w_wushuangVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Jink") and use.whocard and use.whocard:getSkillName() == "s_w_wushuang" and use.card:getSuit() ~= use.whocard:getSuit() then
				if use.who and use.who:hasSkill(self:objectName()) then
					local log = sgs.LogMessage()
					log.from = use.who
					log.to:append(player)
					log.type = "#DaheEffect"
					log.arg = use.card:getSuitString()
					log.arg2 = self:objectName()
					room:sendLog(log)
					local nullified_list = use.nullified_list
					table.insert(nullified_list, "_ALL_TARGETS")
					use.nullified_list = nullified_list
					data:setValue(use)
				end
			end
			if use.card and use.card:isKindOf("Slash") and use.card:getSkillName() == "s_w_wushuang" then
				room:setPlayerMark(use.from, self:objectName().."-PlayClear", 1)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}



s_w_lubu:addSkill(s_w_wushuang)


--https://tieba.baidu.com/p/3821198134?red_tag=2791716333

 sgs.LoadTranslationTable{
	["s_w_lubu"] = "吕布",
	["&s_w_lubu"] = "吕布",
	["#s_w_lubu"] = " 武的化身",
	["designer:s_w_lubu"] = "hanmozhao",
	
	["s_w_wushuang"] = "無雙",
	[":s_w_wushuang"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张手牌当【杀】使用。你以此法使用【杀】目標角色僅能將一張與之花色相同的手牌當【閃】使用才能抵消。",
	
  } 



s_w_ganning = sgs.General(extension,"s_w_ganning","qun","4")

s_w_tongling = sgs.CreateTriggerSkill{
	name = "s_w_tongling" ,
	events = {sgs.EventPhaseEnd} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw and  not player:isKongcheng() and not (player:getPile("s_ling"):length() > 0)  then
		local 	card_id = room:askForExchange(player, self:objectName(), 1,1, false, "s_w_tonglingPush", true, "BasicCard"):getSubcards():first()
			if card_id then
					player:addToPile("s_ling", card_id)
					room:broadcastSkillInvoke(self:objectName(), math.random(2))
			end
		end
		return false
	end
}

s_w_jiejiangcard = sgs.CreateSkillCard{
	name = "s_w_jiejiang", 
	target_fixed = true, 
	will_throw = false,
	 handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
	local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "s_w_jiejiang", "");
	room:throwCard(self, reason, nil);
	end
}

s_w_jiejiangVS = sgs.CreateOneCardViewAsSkill{
	name = "s_w_jiejiang", 
	filter_pattern = ".|.|.|s_ling",
	expand_pile = "s_ling",
	response_pattern = "@@s_ling",
	view_as = function(self, originalCard) 
		local snatch = s_w_jiejiangcard:clone()
		snatch:addSubcard(originalCard:getId())
		snatch:setSkillName(self:objectName())
		return snatch
	end, 
	enabled_at_play = function(self, player)
		return false 
	end
}


s_w_jiejiang = sgs.CreateTriggerSkill{
	name = "s_w_jiejiang",  
	view_as_skill = s_w_jiejiangVS, 
	events = {sgs.EventPhaseEnd},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Draw then
      		for _,ganning in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if (ganning and ganning:objectName()~=player:objectName() and  ganning:getPile("s_ling"):length() > 0 and room:askForUseCard(ganning, "@@s_ling", "s_ling_remove:remove", -1, sgs.Card_MethodNone)) then
					room:broadcastSkillInvoke("s_w_jiejiang", math.random(2))
					if player:getEquips():length() > 0 and player:getHandcardNum() >= 2  then 
						if not room:askForDiscard(player, "s_w_jiejiang", 2, 2, true, false, "s_w_jiejiang_dis") then
						room:setPlayerFlag(ganning, "s_w_jiejiang")
						local 	card_id = sgs.Sanguosha:getCard(room:askForExchange(player, "s_w_jiejiang_q", 1,1, true, "s_w_jiejiang_give", false, "EquipCard|.|.|equipped|."):getSubcards():first())
						room:setPlayerFlag(ganning, "-s_w_jiejiang")
						ganning:obtainCard(card_id)
						end
					elseif player:getEquips():length() == 0 and player:getHandcardNum() >= 2  then 
						room:askForDiscard(player, self:objectName(), 2, 2)
					elseif player:getEquips():length() > 0 and player:getHandcardNum() < 2  then 
						room:setPlayerFlag(ganning, "s_w_jiejiang")
						local 	card_id =  sgs.Sanguosha:getCard(room:askForExchange(player, "s_w_jiejiang_q", 1,1, true, "s_w_jiejiang_give", false, "EquipCard|.|.|equipped|."):getSubcards():first())
						room:setPlayerFlag(ganning, "-s_w_jiejiang")
						ganning:obtainCard(card_id)
					end
				end
			end
			return
		end
	end,
	can_trigger=function(self,player)
		return true 
	end,
}







s_w_ganning:addSkill(s_w_tongling)
s_w_ganning:addSkill(s_w_jiejiang)
--http://tieba.baidu.com/p/1697110286?fr=frs
sgs.LoadTranslationTable{
	["s_w_ganning"] = "☆SP甘宁",
	["&s_w_ganning"] = "甘宁",
	["designer:s_w_ganning"] = "鬼神EX",
	
	["s_w_tongling"] = "銅鈴",
	--[":s_w_tongling"] = "若你的武将牌上没有牌，你可以跳过你的摸牌阶段并将一张基本牌置于你的武将牌上，称为“鈴”。",
	[":s_w_tongling"] = "若你的武将牌上没有牌，你可以在摸牌阶段結束時将一张基本牌置于你的武将牌上，称为“鈴”。",
	["s_ling"] = "鈴",
	["s_w_tonglingPush"] = "你可以发动“銅鈴”",
	["$s_w_tongling1"] = "银铃响，锦帆扬！",
	["$s_w_tongling2"] = "老子就是银铃锦帆甘兴霸！",
	
	["s_w_jiejiang"] = "截江",
	["s_w_jiejiang_q"] = "截江",
	[":s_w_jiejiang"] = "一名其他角色的摸牌阶段结束时，你可以将一张“鈴”置入弃牌堆，然后其选择一项：弃置两张手牌，或交給你裝備區的一張牌。",
	["s_w_jiejiang_give"] = "交給甘宁裝備區的一張牌",
	["s_ling_remove"] = "你可以发动“截江”",
	["s_w_jiejiang_dis"] = "你弃置两张手牌，或交給甘宁裝備區的一張牌。",
	["$s_w_jiejiang1"] = "弟兄们，准备动手！",
	["$s_w_jiejiang2"] = "接招吧！",
	
} 



s_w_2_lubu = sgs.General(extension,"s_w_2_lubu","qun","7")

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
s_w_shenyong = sgs.CreateTriggerSkill{
	name = "s_w_shenyong" ,
	events = {sgs.TargetSpecified, sgs.EventPhaseEnd} ,
	frequency = sgs.Skill_Compulsory, 
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	if event == sgs.TargetSpecified then 
		local use = data:toCardUse()
		if player:objectName() ~= use.from:objectName() or not use.card:isKindOf("Slash") then return false end
		room:addPlayerMark(player, "&s_w_shenyong-Clear")
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			local _data = sgs.QVariant()
				_data:setValue(p)
				jink_table[index] = 0
			index = index + 1
		end
		room:sendCompulsoryTriggerLog(player, self:objectName(), true)
		room:broadcastSkillInvoke(self:objectName(), math.random(2))
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		elseif event == sgs.EventPhaseEnd then 
		if player:getPhase() == sgs.Player_Finish then 
		if player:getMark("&s_w_shenyong-Clear") > 0 then return false end 
		room:sendCompulsoryTriggerLog(player, self:objectName(), true )
		room:loseMaxHp(player)
		end
		end
	end
}
s_w_2_lubu:addSkill(s_w_shenyong)

--http://tieba.baidu.com/p/1718537526?fr=frs
sgs.LoadTranslationTable{
	["s_w_2_lubu"] = "呂布",
	["&s_w_2_lubu"] = "呂布",
	["#s_w_2_lubu"] = " 无双",
	["designer:s_w_2_lubu"] = "旋风ZERO",
	
	["s_w_shenyong"] = "神勇",
	[":s_w_shenyong"] = "<font color=\"blue\"><b>锁定技，</b></font>你使用的【杀】不能使用【闪】进行响应；若你未于你的回合內使用【杀】，你減一點体力上限。 ",
	["$s_w_shenyong1"] = "战神降世，神威再临！",
	["$s_w_shenyong2"] = "战神既出，谁与争锋！",
	
} 



s_w_2_godzhaoyun = sgs.General(extension,"s_w_2_godzhaoyun","god","2")


s_w_nilin = sgs.CreateTriggerSkill{
	name = "s_w_nilin",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged, sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.Damaged then 
		local x = damage.damage
		if damage.from and damage.from:isAlive() and damage.damage > 0  then 
		damage.from:gainMark("&s_w_nilin+to+#"..player:objectName(), x)
		end
		elseif event == sgs.DamageCaused then 
		if damage.to:getMark("&s_w_nilin+to+#"..player:objectName()) > 0  and  player:getPhase() ~= sgs.Player_NotActive and damage.card and damage.card:isKindOf("Slash") then 
		damage.damage = damage.damage + damage.to:getMark("&s_w_nilin+to+#"..player:objectName())
			local log= sgs.LogMessage()
	log.type = "#skill_add_damage"
		log.from = damage.from
		log.to:append(damage.to)
		log.arg = self:objectName()
		log.arg2  = damage.damage
		room:sendLog(log)
		damage.to:loseAllMarks("&s_w_nilin+to+#"..player:objectName())
		data:setValue(damage)
		end
		end
		return false
	end
}


s_w_juling = sgs.CreateTriggerSkill{
	name = "s_w_juling",
	events = {sgs.DamageForseen},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Normal then
		player:getRoom():sendCompulsoryTriggerLog(player, self:objectName(), true)
		damage.prevented = true
		data:setValue(damage)
			return true
		else
			return false
		end
	end,
}
s_w_juling_tg = sgs.CreateProhibitSkill{
	name = "#s_w_juling_tg",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill("s_w_juling") and (card:isKindOf("TrickCard") and not card:isNDTrick())
	end
}
s_w_longnu = sgs.CreateTriggerSkill{
	name = "s_w_longnu" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	waked_skills = "longdan,chongzhen,mashu,feiying",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "s_w_longnu")
		if room:changeMaxHpForAwakenSkill(player) then
			room:handleAcquireDetachSkills(player, "longdan|chongzhen|mashu|feiying")
		end
		return false
	end ,
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		return player:isKongcheng()
	end,
}


s_w_2_godzhaoyun:addSkill(s_w_nilin)
s_w_2_godzhaoyun:addSkill("shenwei")
s_w_2_godzhaoyun:addSkill(s_w_juling)
s_w_2_godzhaoyun:addSkill(s_w_juling_tg)
extension:insertRelatedSkills("s_w_juling","#s_w_juling_tg")
s_w_2_godzhaoyun:addSkill(s_w_longnu)

--http://tieba.baidu.com/p/1587196553?fr=frs
sgs.LoadTranslationTable{
	["s_w_2_godzhaoyun"] = "神赵云",
	["&s_w_2_godzhaoyun"] = "神赵云",
	["#s_w_2_godzhaoyun"] = " 常勝將軍",
	["designer:s_w_2_godzhaoyun"] = "卡嘎猴",
	
	["s_w_nilin"] = "逆鱗",
	[":s_w_nilin"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你受到伤害后，伤害来源获得与伤害点数等量的鱗标记；你的回合內，你使用的【杀】对擁有鱗标记的角色造成的伤害+X（X为该角色擁有鱗标记数量），然后棄置该角色所有鳞标记。",
	["s_w_juling"] = "聚靈",
	[":s_w_juling"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你受到的非屬性伤害结算开始时，防止此伤害；你不能被选择为延时类锦囊的目标。",
	["s_w_longnu"] = "龍怒",
	[":s_w_longnu"] = "<font color=\"purple\"><b>觉醒技，</b></font>回合开始阶段开始时，若你没有手牌，你减1点体力上限，并获得技能“龙胆”“马术”“飞影”“冲阵”。",
	
} 

s_w_weiyan = sgs.General(extension,"s_w_weiyan","shu","4")

s_w_jianshou = sgs.CreateTriggerSkill{
	name = "s_w_jianshou", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseEnd}, 
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseEnd then
			if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish and player:getMark("damage_point_play_phase") == 0  and player:askForSkillInvoke(self:objectName()) then
				player:drawCards(2, self:objectName())
				player:getRoom():broadcastSkillInvoke(self:objectName(),math.random(1,2))
			end
		end
		return false
	end
}


s_w_qimouCard = sgs.CreateSkillCard{
	name = "s_w_qimouCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng() 
	end,
	on_use = function(self, room, player, targets)
		room:removePlayerMark(player,"@s_mou")
		local dest = sgs.QVariant()
		dest:setValue(player)
		if room:askForSkillInvoke(targets[1], "s_w_qimou_give", dest) then 
		local cards = targets[1]:getCards("h")
						if cards:length() > 0 then
							local allcard = sgs.Sanguosha:cloneCard("slash")
							for _,cardq in sgs.qlist(cards) do
								allcard:addSubcard(cardq)
							end
							room:obtainCard(player, allcard)
						end
					local victims = sgs.SPlayerList()
					local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:canSlash(p, card, false) then
				victims:append(p)
			end
		end
		if not victims:isEmpty() then		
		local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		card:deleteLater()
			card:setSkillName("s_w_qimou")
			local use = sgs.CardUseStruct()
			use.from = player
			local dest = room:askForPlayerChosen(player, victims, self:objectName())
			use.to:append(dest)
			use.card = card
			room:useCard(use, false)
			end
			else
			room:setPlayerCardLimitation(player, "use", "Slash", true);
		end
	end
}
s_w_qimouVS = sgs.CreateZeroCardViewAsSkill{
	name = "s_w_qimou",
	view_as = function(self, cards)
		return s_w_qimouCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@s_mou") >= 1 
	end
}
s_w_qimou = sgs.CreateTriggerSkill{
	name = "s_w_qimou",
	frequency = sgs.Skill_Limited,
	limit_mark = "@s_mou",
	events = {sgs.TargetSpecified, sgs.Damage, sgs.CardFinished},
	view_as_skill = s_w_qimouVS,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local  use = data:toCardUse()
		if use.card:isKindOf("Slash")  and use.card:getSkillName() == self:objectName() then 
			local  do_anim = false
		   for _,p in sgs.qlist(use.to) do 
				if (p:getMark("Equips_of_Others_Nullified_to_You") == 0) then 
					do_anim = (p:getArmor() and  p:hasArmorEffect(p:getArmor():objectName())) or p:hasSkills("bazhen|bossmanjia")
					p:addQinggangTag(use.card)
				end
			end 
				room:setEmotion(use.from, "weapon/qinggang_sword")
				end
			elseif event == sgs.Damage then 
				local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and (not damage.chain) and (not damage.transfer)
				and damage.to:isAlive() and damage.card:getSkillName() == self:objectName() then
				room:setPlayerFlag(player, "s_w_qimou_damaged")
			if player:getRoom():askForSkillInvoke(player, self:objectName(), data) then
				damage.to:turnOver()
			end
		end
		elseif event == sgs.CardFinished then 
		local use = data:toCardUse() 
		if use.card and use.card:isKindOf("Slash") and use.card:getSkillName() == self:objectName() then 
		if not player:hasFlag("s_w_qimou_damaged") then 
		player:turnOver() 
		end
		end
		end
	end
}

s_w_weiyan:addSkill(s_w_jianshou)
s_w_weiyan:addSkill(s_w_qimou)

--http://tieba.baidu.com/p/1753372156?fr=frs#22389008242l
sgs.LoadTranslationTable{
	["s_w_weiyan"] = "SP魏延",
	["&s_w_weiyan"] = "魏延",
	["#s_w_weiyan"] = " 诡道之兵",
	["designer:s_w_weiyan"] = "路人阿明",
	
	["s_w_jianshou"] = "堅守",
	[":s_w_jianshou"] = "若你于你的出牌阶段未造成伤害，结束阶段开始时，你可以摸两张牌。",
	["$s_w_jianshou1"] = "尔等还有何招？哈哈哈",
	["$s_w_jianshou2"] = "胆小鼠辈，谁还敢来？",
	
	["@s_mou"] = "謀",
	["s_w_qimou"] = "奇謀",
	["s_w_qimouCard"] = "奇謀",
	["s_w_qimou_give"] = "奇謀",
	[":s_w_qimou"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以令一名其他角色选择是否交给你所有手牌。若如此做，视为你对一名其他角色使用一张【杀】，你以此法使用的【杀】无视防具且对目标角色造成一次伤害后，你可以令该角色将其武将牌翻面。若此【杀】没有造成伤害，你須將武将牌翻面。若該角色选择不交给你手牌，你不能使用【杀】，直到回合结束。",
	
} 

s_w_guanyu = sgs.General(extension,"s_w_guanyu","shu","4")

s_w_shenghunCard = sgs.CreateSkillCard{
	name = "s_w_shenghun",

	filter = function(self, targets, to_select, player)
		return #targets == 0 and player:canPindian(to_select) and to_select:objectName() ~= player:objectName()
	end,

	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("yijue1")
		local success = source:pindian(targets[1], "s_w_shenghun", nil)
		if success then
			room:addPlayerMark(source, "s_w_shenghun_use")
			room:handleAcquireDetachSkills(source,"wusheng")
			room:broadcastSkillInvoke("wusheng1")
			room:addPlayerMark(targets[1], "Armor_Nullified")
			room:addPlayerMark(targets[1], "s_w_shenghun_target");
		else
			room:setPlayerCardLimitation(source, "use", "Slash", true)
		end
	end
}
s_w_shenghunVS = sgs.CreateZeroCardViewAsSkill{
	name = "s_w_shenghun",
	view_as = function(self) 
		return s_w_shenghunCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#s_w_shenghun") and not player:isKongcheng()
	end, 
}
s_w_shenghun = sgs.CreateTriggerSkill{
	name = "s_w_shenghun",
	events = {sgs.EventPhaseChanging,sgs.Death},
	view_as_skill = s_w_shenghunVS,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Start  then 
			if  player:getMark("s_w_shenghun_use") > 0 then
				room:handleAcquireDetachSkills(player, "-wusheng")
				end
			elseif change.to == sgs.Player_Finish then 
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("s_w_shenghun_target") > 0 then 
				room:removePlayerMark(p, "Armor_Nullified")
				room:removePlayerMark(p, "s_w_shenghun_target")
				end
			end
			end
	elseif event == sgs.Death then 
				local death = data:toDeath()
				if death.who:objectName() == player:objectName() then
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("s_w_shenghun_target") > 0 then 
				room:removePlayerMark(p, "Armor_Nullified")
				room:removePlayerMark(p, "s_w_shenghun_target")
				end
			end
		end	
			end
		return false
	end,
}

s_w_wenjiu = sgs.CreateTriggerSkill{
	name = "s_w_wenjiu" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.ConfirmDamage, sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	if event == sgs.ConfirmDamage then 
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.card:isRed() and (player:getPhase() == sgs.Player_Play) and  player:getMark("s_w_wenjiu-PlayClear") == 0 then
				room:addPlayerMark(player, "s_w_wenjiu-PlayClear")
				damage.damage = damage.damage + 1
				data:setValue(damage)
					local log= sgs.LogMessage()
	log.type = "#skill_add_damage"
		log.from = damage.from
		log.to:append(damage.to)
		log.arg = self:objectName()
		log.arg2  = damage.damage
		room:sendLog(log)
		end
		elseif event == sgs.EventPhaseChanging then 
		local change = data:toPhaseChange()
			if change.to == sgs.Player_Start  then 
		room:setPlayerCardLimitation(player, "use", "Analeptic", true)
		end
		end
		return false
	end
}




s_w_guanyu:addSkill("mashu")
s_w_guanyu:addSkill(s_w_shenghun)
s_w_guanyu:addSkill(s_w_wenjiu)
s_w_guanyu:addRelateSkill("wusheng")

--http://tieba.baidu.com/p/1742886013?fr=frs
sgs.LoadTranslationTable{
	["s_w_guanyu"] = "☆SP·关羽",
	["&s_w_guanyu"] = "关羽",
	["#s_w_guanyu"] = " 汉寿亭侯",
	["designer:s_w_guanyu"] = "风欲哭无泪",
	
	
	["s_w_wenjiu"] = "温酒",
	[":s_w_wenjiu"] = "<font color=\"blue\"><b>锁定技，</b></font>出牌阶段，你使用红色【杀】造成的第一次伤害+1。你不能在自己的回合內使用【酒】。",
	["s_w_shenghun"] = "聖魂",
	[":s_w_shenghun"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以与一名其他角色拼点。若你赢，你获得“武圣”直到你下回合的准备阶段和以下技能：本回合，该角色的防具无效；若你没赢，你不能使用【杀】，直到回合结束。",
	["$s_w_shenghun1"] = "为国尽忠，天经地义！",
	["$s_w_shenghun2"] = "忠义是为将之本！",
	
} 

s_w_3_lubu =  sgs.General(extension,"s_w_3_lubu","qun","4")


s_w_zhan = sgs.CreateTriggerSkill{
	name = "s_w_zhan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from and (move.from:objectName() == player:objectName()) 
			and (move.from_places:contains(sgs.Player_PlaceHand) or  move.from_places:contains(sgs.Player_PlaceEquip))) 
			and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) 
			and player:getPhase() == sgs.Player_NotActive then
					player:gainMark("&s_w_yong")
			end
		elseif event == sgs.Damaged then 
		local damage = data:toDamage()
		if damage.damage > 0 then 
		player:gainMark("&s_w_yong", damage.damage)
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) 
	end
}

s_w_fanji = sgs.CreateTriggerSkill{
	name = "s_w_fanji" ,
	frequency = sgs.Skill_Wake ,
	waked_skills = "s_w_juezhan",
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "s_w_fanji")
		if room:changeMaxHpForAwakenSkill(player) then
			room:handleAcquireDetachSkills(player, "s_w_juezhan")
		end
		return false
	end ,
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then
			return false
		end
		if player:canWake(self:objectName()) then
			return true
		end
		if player:getMark("&s_w_yong") >= 3 then
			return true
		end
		return false
	end
}


Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

s_w_juezhan = sgs.CreateTriggerSkill{
	name = "s_w_juezhan",
	events = {sgs.TargetSpecified,sgs.AskForPeaches,sgs.DrawNCards, sgs.AfterDrawNCards, sgs.CardEffected},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		player:setMark("s_w_juezhanEvent",tonumber(event))
		if event == sgs.TargetSpecified then
			local wushuang = sgs.Sanguosha:getTriggerSkill("wushuang")
			local use = data:toCardUse()
			if wushuang and use.card and (use.card:isKindOf("Slash")) and player:askForSkillInvoke("s_w_juezhan_wushuang1",data) then
				room:notifySkillInvoked(player,self:objectName())
				player:loseMark("&s_w_yong")
				--[[local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				room:sendCompulsoryTriggerLog(player, "wushuang", true )
				for i = 0, use.to:length() - 1, 1 do
					if jink_table[i + 1] == 1 then
						jink_table[i + 1] = 2 --只要设置出两张闪就可以了，不用两次askForCard
					end
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end]]
			 	room:setPlayerProperty(player, "pingjian_triggerskill", sgs.QVariant("wushuang"))
				wushuang:trigger(event,room,player,data)	
				room:setPlayerProperty(player, "pingjian_triggerskill", sgs.QVariant(""))
			end
		elseif event == sgs.AskForPeaches then
			local buqu = sgs.Sanguosha:getTriggerSkill("buqu")
			local dying = data:toDying()
			if dying.who:objectName() == player:objectName() then
			if buqu and player:askForSkillInvoke("s_w_juezhan_buqu",data) then
				room:notifySkillInvoked(player,self:objectName())
				player:loseMark("&s_w_yong")
				buqu:trigger(event,room,player,data)
				end
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
			local tuxi = sgs.Sanguosha:getTriggerSkill("tenyeartuxi")
				local can_invoke = false
			local other_players = room:getOtherPlayers(player)
			for _, q in sgs.qlist(other_players) do
				if q:getHandcardNum() >= player:getHandcardNum() then
					can_invoke = true
					break
				end
			end
			if tuxi and can_invoke then
				room:setPlayerMark(player, "tenyeartuxi", draw.num)
				if  player:askForSkillInvoke("s_w_juezhan_tuxi",data)  then
			
				room:notifySkillInvoked(player,self:objectName())
				player:loseMark("&s_w_yong")
				tuxi:trigger(event,room,player,data)
				end
				room:setPlayerMark(player, "tuxi", 0)
			end
		elseif event == sgs.AfterDrawNCards then
			local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
			local tuxiAct = sgs.Sanguosha:getTriggerSkill("#tenyeartuxi")
				if tuxiAct  then
				tuxiAct:trigger(event,room,player,data)
				end
		elseif event == sgs.CardEffected then 
		local effect = data:toCardEffect()
			if effect.card:isKindOf("Duel") then				
				if effect.from and effect.from:isAlive() and effect.from:hasSkill(self:objectName()) then
					can_invoke = true
				end
				if effect.to and effect.to:isAlive() and effect.to:hasSkill(self:objectName()) then
					can_invoke = true
				end
			end
			if not can_invoke then return false end
			
			if effect.card:isKindOf("Duel") and  player:askForSkillInvoke("s_w_juezhan_wushuang2",data)then
				if room:isCanceled(effect) then
					effect.to:setFlags("Global_NonSkillNullify")
					return true;
				end
				if effect.to:isAlive() then
					local second = effect.from
					local first = effect.to
					room:setEmotion(first, "duel");
					room:setEmotion(second, "duel")
					room:sendCompulsoryTriggerLog(player, "wushuang", true )
					while true do
						if not first:isAlive() then
							break
						end
						local slash
						if second:hasSkill(self:objectName()) then
							slash = room:askForCard(first,"slash","@wushuang-slash-1:" .. second:objectName(),data,sgs.Card_MethodResponse, second);
							if slash == nil then
								break
							end

							slash = room:askForCard(first, "slash", "duel-slash:" .. second:objectName(),data,sgs.Card_MethodResponse,second);
							if slash == nil then
								break
							end
						else
							slash = room:askForCard(first,"slash","duel-slash:" .. second:objectName(),data,sgs.Card_MethodResponse,second)
							if slash == nil then
								break
							end
						end
						local temp = first
						first = second
						second = temp
					end
					local daamgeSource = function() if second:isAlive() then return second else return nil end end
					local damage = sgs.DamageStruct(effect.card, daamgeSource() , first)
					if second:objectName() ~= effect.from:objectName() then
						damage.by_user = false;
					end
					room:damage(damage)
				end
				room:setTag("SkipGameRule",sgs.QVariant(tonumber(event)))
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and target:getMark("&s_w_yong") > 0
	end
}

s_w_3_lubu:addSkill(s_w_zhan)
s_w_3_lubu:addSkill(s_w_fanji)
if not sgs.Sanguosha:getSkill("s_w_juezhan") then
	s_skillList:append(s_w_juezhan)
end
s_w_3_lubu:addRelateSkill("tenyeartuxi")
s_w_3_lubu:addRelateSkill("wushuang")
s_w_3_lubu:addRelateSkill("buqu")
--http://tieba.baidu.com/p/1715633502?fr=frs
sgs.LoadTranslationTable{
	["s_w_3_lubu"] = "呂布",
	["&s_w_3_lubu"] = "呂布",
	["#s_w_3_lubu"] = " 武的化身",
	["designer:s_w_3_lubu"] = "Ben779608658",
	
	["s_w_yong"] = "勇",
	["s_w_zhan"] = "戰",
	[":s_w_zhan"] = "<font color=\"blue\"><b>锁定技，</b></font>当你每受到一点伤害或于你的回合外失去牌时，你获得1枚“勇”标记。",
	["s_w_fanji"] = "反撃",
	[":s_w_fanji"] = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段开始时，若“勇”标记大于或等于三，你减1点体力上限，然后获得技能“決戰”。",
	["s_w_juezhan"] = "決戰",
	["s_w_juezhan_buqu"] = "決戰",
	["s_w_juezhan_wushuang"] = "決戰",
	["s_w_juezhan_tuxi"] = "決戰",
	[":s_w_juezhan"] = "你可以弃一枚“勇”标记发动下列一项技能——“无双”、“不屈”、“突袭”。",
	
} 
s_w_sunshangxiang =  sgs.General(extension,"s_w_sunshangxiang","shu","3", false)


s_w_diaohua = sgs.CreateTriggerSkill{
	name = "s_w_diaohua" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	if event == sgs.CardsMoveOneTime then
		local move = data:toMoveOneTime()
		if move.from and (move.from:objectName() ~= player:objectName() and player:hasSkill(self:objectName())) and (move.to_place == sgs.Player_DiscardPile)
				and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))  then
			local can_draw = 0
			for _, id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
					can_draw = can_draw + 1
				end
			end
			if can_draw > 0 then
			for n = 1, can_draw , 1 do
				if player:getMark("s_w_diaohua-Clear") < 2 then
						if player:askForSkillInvoke(self:objectName()) then
						room:broadcastSkillInvoke(self:objectName(), math.random(2))
							player:drawCards(1, self:objectName())
							room:addPlayerMark(player,"s_w_diaohua-Clear",1)
						else
							break
						end
						end
					end
			end
		end
		end
		return false
	end ,
	can_trigger=function(self,player)
		return true
	end,
}

s_w_changshuCard = sgs.CreateSkillCard{
	name = "s_w_changshu",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return to_select:objectName() ~= sgs.Self:objectName() and #targets == 0 
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local ids = self:getSubcards()
		local obtain = sgs.Sanguosha:cloneCard("slash")
		for _,id in sgs.qlist(ids) do
			if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Heart then 
				local recover = sgs.RecoverStruct()
					recover.who = source
					room:recover(source,recover)
					room:recover(target,recover)
			else 
					obtain:addSubcard(id)
			end
		end 
		target:obtainCard(obtain, false)
	end
}
s_w_changshuVS = sgs.CreateViewAsSkill{
	name = "s_w_changshu",
	n = 5,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = s_w_changshuCard:clone()
			for _,cd in pairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@s_w_changshu" 
		end
}
s_w_changshu = sgs.CreateTriggerSkill{
	name = "s_w_changshu" ,
	events = {sgs.EventPhaseEnd} ,
	view_as_skill = s_w_changshuVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Play then return false end
		if player:isNude() then return false end
		if room:askForUseCard(player, "@@s_w_changshu", "@s_w_changshu-card") then
		end
		return false
	end
}
s_w_sunshangxiang:addSkill(s_w_diaohua)
s_w_sunshangxiang:addSkill(s_w_changshu)

--http://tieba.baidu.com/p/1735734609?fr=frs
sgs.LoadTranslationTable{
	["s_w_sunshangxiang"] = "SP孙尚香",
	["&s_w_sunshangxiang"] = "孙尚香",
	["#s_w_sunshangxiang"] = " 粉黛凋香",
	["designer:s_w_sunshangxiang"] = "_A_N_C_O_",
	
	["$s_w_diaohua1"] = "双剑夸俏，不让须眉！",
	["$s_w_diaohua2"] = "弓马何须系红妆？",
	["s_w_diaohua"] = "凋花",
	[":s_w_diaohua"] = "每名角色的回合限两次，每当其他角色的一张装备牌进入弃牌堆后，你可以摸一张牌。",
	["s_w_changshu"] = "怅蜀",
	["@s_w_changshu-card"] = "你可以发动“怅蜀”",
	["~s_w_changshu"] = "选择一名其他角色→选择至多5张牌→点击确定",
	[":s_w_changshu"] = "出牌阶段结束时，你可以指定一名其他角色并弃置至多5张牌。其中每有一张<font color=\"red\">♥</font>牌，你与该角色回复1点体力，然后弃置其中的<font color=\"red\">♥</font>牌，该角色将其余的牌收入手牌。",
	["$s_w_changshu1"] = "夫君，身体要紧。",
	["$s_w_changshu2"] = "他好，我也好。",
} 

s_w_gongshunzan =  sgs.General(extension,"s_w_gongshunzan","qun","4")


s_w_yuma = sgs.CreateTriggerSkill{
	name = "s_w_yuma",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DrawNCards, sgs.EventPhaseStart, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then 
			local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
		if player:getOffensiveHorse() and room:askForSkillInvoke(player, "s_w_yuma", data) then
			draw.num = draw.num + 1
			data:setValue(draw)
			end
		elseif event == sgs.EventPhaseStart then 
		 if player:getPhase() == sgs.Player_Finish then
			if player:getDefensiveHorse() and player:askForSkillInvoke(self:objectName()) then
				player:drawCards(1, self:objectName())
				end
			end
		elseif event == sgs.CardsMoveOneTime then
		local move = data:toMoveOneTime()
		if move.from and (move.from:objectName() == player:objectName() and player:hasSkill(self:objectName())) and ((move.to_place == sgs.Player_PlaceEquip) or move.from_places:contains(sgs.Player_PlaceEquip))  then
			local can_draw = 0
			local x = 0
			for _, id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isKindOf("OffensiveHorse") or sgs.Sanguosha:getCard(id):isKindOf("DefensiveHorse") then
					if sgs.Sanguosha:getCard(id):isKindOf("OffensiveHorse") then
					x = 1
					elseif  sgs.Sanguosha:getCard(id):isKindOf("DefensiveHorse") then
					x = 2
					end
					can_draw = can_draw + 1
				end
			end
			if can_draw > 0 then
			for n = 1, can_draw , 1 do
						if player:askForSkillInvoke(self:objectName()) then
						room:broadcastSkillInvoke(self:objectName(), x)
							player:drawCards(1, self:objectName())
						else 
						break
						end
					end
			end
		end
		end
		return false
	end ,
}
s_w_gongshunzan:addSkill(s_w_yuma)

--http://tieba.baidu.com/p/1766586406?fr=frs
sgs.LoadTranslationTable{
	["s_w_gongshunzan"] = "公孙瓒",
	["&s_w_gongshunzan"] = "公孙瓒",
	["#s_w_gongshunzan"] = " 白馬義從",
	["designer:s_w_gongshunzan"] = "bzllll1234",
	["s_w_yuma"] = "馭馬",
	[":s_w_yuma"] = "當你装备区有-1坐骑时，摸牌阶段，-1坐骑你可以额外摸一张牌；當你装备区有+1坐骑时，结束阶段开始时，你可以摸一张牌。当你失去或获得装备区里的坐骑牌时，你可以摸一张牌。",
	
	
} 

s_w_3_guanyu =  sgs.General(extension,"s_w_3_guanyu","shu","4")


s_w_2_wenjiu = sgs.CreateViewAsSkill{
	name = "s_w_2_wenjiu",
	n = 2,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return not to_select:isEquipped()
		elseif #selected == 1 then
			local card = selected[1]
			if to_select:getSuit() == card:getSuit() then
				return not to_select:isEquipped()
			end
		else
			return false
		end
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local cardA = cards[1]
			local cardB = cards[2]
			local suit = cardA:getSuit()
			local aa = sgs.Sanguosha:cloneCard("analeptic", suit, 0);
			aa:addSubcard(cardA)
			aa:addSubcard(cardB)
			aa:setSkillName(self:objectName())
			return aa
		end
	end,
	enabled_at_play = function(self, player)
		local newanal = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		if player:isCardLimited(newanal, sgs.Card_MethodUse) or player:isProhibited(player, newanal) then return false end
		return player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player , newanal)
	end, 
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "analeptic")
	end
}
s_w_3_guanyu:addSkill(s_w_2_wenjiu)
s_w_3_guanyu:addSkill("mashu")

--http://tieba.baidu.com/p/1692877138?fr=frs
sgs.LoadTranslationTable{
	["s_w_3_guanyu"] = "关羽",
	["&s_w_3_guanyu"] = "关羽",
	["#s_w_3_guanyu"] = " 赤须猛将",
	["designer:s_w_3_guanyu"] = "颜之妍",
	["s_w_2_wenjiu"] = "温酒",
	[":s_w_2_wenjiu"] = "你可以将两张花色相同的手牌当【酒】使用。",
} 






s_w_godlubu =  sgs.General(extension,"s_w_godlubu","god","5")


Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
s_w_huaji = sgs.CreateTriggerSkill{
	name = "s_w_huaji" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.TargetSpecified, sgs.GameStart, sgs.EventPhaseStart, sgs.EventAcquireSkill} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			local can_invoke = false
			if use.card:isKindOf("Slash") and (player and player:isAlive() and player:hasSkill(self:objectName())) and (use.from:objectName() == player:objectName()) then
				can_invoke = true
				room:sendCompulsoryTriggerLog(player, self:objectName(), true)
				room:broadcastSkillInvoke("wushuang")
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				for i = 0, use.to:length() - 1, 1 do
					if jink_table[i + 1] == 1 then
						jink_table[i + 1] = 2 --只要设置出两张闪就可以了，不用两次askForCard
					end
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		else
		if player:hasSkill(self:objectName()) and player:hasEquipArea(0) then
			player:throwEquipArea(0)
		end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end,
	priority = 1,
}








s_w_huajiTargetMod = sgs.CreateAttackRangeSkill{
	name = "#s_w_huaji-target",
	extra_func = function(self, player, include_weapon)
		if player:hasSkill("s_w_huaji") then
			return player:getHp()
		end
	end,
}

s_w_shenzi = sgs.CreateTriggerSkill{
	name = "s_w_shenzi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase()  == sgs.Player_Start  then
		local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "s_w_shenzi-invoke", true, true)
			if not target then return false end
			target:drawCards(player:getLostHp() + 2, self:objectName())
			player:skip(sgs.Player_Draw)
			player:skip(sgs.Player_Judge)
			target:setFlags("s_w_shenzi")
		elseif player:getPhase()  == sgs.Player_Play then
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasFlag("s_w_shenzi") then
				local to_exchange = room:askForExchange(p, "s_w_shenzi", player:getLostHp() + 2, player:getLostHp() + 2, false)
				room:moveCardTo(to_exchange, player, sgs.Player_PlaceHand, false)
			end
		end
			end
		return false
	end,
}

s_w_shouyou = sgs.CreateTriggerSkill{
	name = "s_w_shouyou" ,
	events = {sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if string.find(damage.to:getGeneralName(), "diaochan") or string.find(damage.to:getGeneral2Name(), "diaochan") then
			if player:askForSkillInvoke(self:objectName(), data) then
				player:drawCards(1, self:objectName())
				damage.damage = damage.damage - 1
				if damage.damage <= 0 then return true end
				data:setValue(damage)
			end
		end
		return false
	end
}


s_w_godlubu:addSkill(s_w_huaji)
s_w_godlubu:addSkill(s_w_huajiTargetMod)
extension:insertRelatedSkills("s_w_huaji","#s_w_huaji-target")
s_w_godlubu:addSkill(s_w_shenzi)
s_w_godlubu:addSkill(s_w_shouyou)

sgs.LoadTranslationTable{
	["s_w_godlubu"] = "吕布",
	["&s_w_godlubu"] = "吕布",
	["#s_w_godlubu"] = " 戰鬼",
	["designer:s_w_godlubu"] = "令人恐怖的男子",
	["s_w_huaji"] = "畫戟",
	[":s_w_huaji"] = "<font color=\"blue\"><b>锁定技，</b></font>你废除武器栏；你的攻擊距離額外加X（X为你的体力值）；当你使用【杀】指定一名角色为目标后，该角色需连续使用两张【闪】才能抵消。",
	["s_w_shenzi"] = "神姿",
	["s_w_shenzi-invoke"] =  "你可以发动“神姿”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	[":s_w_shenzi"] = "准备阶段开始时，你可以选择一名其他角色摸X+2张牌，然后跳过你的判定阶段和摸牌阶段，出牌阶段开始时，该角色须给你X+2张手牌（X为你已损失的体力值）。",
	["s_w_shouyou"] = "受誘",
	[":s_w_shouyou"] = "<font color=\"orange\"><b>联动技，</b></font>当你对貂蝉造成伤害时，可摸一張牌并令该伤害-1。",
	
} 


s_w_goddiaochan =  sgs.General(extension,"s_w_goddiaochan","god","4", false)

s_w_juese = sgs.CreateTriggerSkill{
	name = "s_w_juese" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.GameStart, sgs.EventPhaseStart, sgs.EventAcquireSkill, sgs.Death } ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == self:objectName()) or event == sgs.Death then 
			local can_invoke = true
			for  _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("s_w_juese_target"..player:objectName()) > 0  then
				can_invoke = false 
					break
				end
			end
			if event == sgs.Death then
				local death = data:toDeath()
				if not (death.who:objectName() == player:objectName()) then 
					local can_invoke2 = false
					for _, mark in sgs.list(death.who:getMarkNames()) do
						if string.find(mark, "s_w_juese_target"..player:objectName()) and death.who:getMark(mark) > 0 then
							can_invoke2 = true
						end
					end
					if not can_invoke2 then return false end
				end
			end
			if player:hasSkill(self:objectName()) and can_invoke then
				local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:isMale() then
						targets:append(p)
					end
				end
				local target = room:askForPlayerChosen(player, targets, self:objectName(), self:objectName(), true, true)
				target:gainMark("&s_w_juese")
				room:addPlayerMark(target, "s_w_juese_target"..player:objectName())
				room:addPlayerMark(target, "&s_w_juese+to+#"..player:objectName())
			end
		else 
			if player:getPhase() == sgs.Player_Start then
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, "s_w_juese_target") and player:getMark(mark) > 0 then
						room:addPlayerMark(player, "&s_w_juese")
					end
				end
				if player:getMark("s_w_juese_target") > 0 then 
					player:gainMark("&s_w_juese")
				end
			end
		end
		return false
	end,
		can_trigger = function(self, target)
		return target 
	end
}

s_w_yanzi = sgs.CreateTriggerSkill{
	name = "s_w_yanzi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
		local dest = sgs.QVariant()
				dest:setValue(player)
				for _, diaochan in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
		if player:getMark("s_w_juese_target"..diaochan:objectName()) and room:askForSkillInvoke(diaochan, "s_w_yanzi", dest) then
			local draw_num = {}
			for i = 1, player:getMark("&s_w_juese"), 1 do
					table.insert(draw_num, tostring(i))
					if i > 2 then 
						break 
						end
				end
				local num = tonumber(room:askForChoice(diaochan, "s_w_yanzi_disMark", table.concat(draw_num, "+"), dest))
				player:loseMark("&s_w_juese", num)
			local choice =  room:askForChoice(diaochan, "s_w_yanzi_in_de", "s_w_yanzi_in+s_w_yanzi_de",dest)
			if choice == "s_w_yanzi_in" then 
			draw.num = draw.num + num
			data:setValue(draw)
			else 
			draw.num = draw.num - num
			if draw.num < 0 then 
			draw.num = 0 
			end
			data:setValue(draw)
			diaochan:drawCards(num, self:objectName())
			end
		end
		end
	end,
			can_trigger = function(self, target)
		return target:getMark("&s_w_juese") > 0 
	end
}


s_w_youhuo = sgs.CreateTriggerSkill{
	name = "s_w_youhuo" ,
	events = {sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if string.find(damage.to:getGeneralName(), "lubu") or string.find(damage.to:getGeneral2Name(), "lubu") then
			if player:askForSkillInvoke(self:objectName(), data) then
			local choicelist = "s_w_youhuo_draw"
			if damage.to:isWounded() then
			choicelist = string.format("%s+%s", choicelist, "s_w_youhuo_recover")
			end
			local choice =room:askForChoice(player, "s_w_youhuo",choicelist,data)
			if choice == "s_w_youhuo_draw" then
				player:drawCards(2, self:objectName())
				else
				player:damageRevises(data,-1)
				end
			end
		end
		return false
	end
}

s_w_goddiaochan:addSkill(s_w_juese)
s_w_goddiaochan:addSkill(s_w_yanzi)
s_w_goddiaochan:addSkill(s_w_youhuo)

--http://tieba.baidu.com/p/1690733419?fr=frs
sgs.LoadTranslationTable{
	["s_w_goddiaochan"] = "貂蝉",
	["&s_w_goddiaochan"] = "貂蝉",
	["#s_w_goddiaochan"] = " 絕色神姬",
	["designer:s_w_goddiaochan"] = "令人恐怖的男子",
	
	["s_w_youhuo"] = "誘惑",
	["s_w_youhuo_draw"] = "摸兩張牌",
	["s_w_youhuo_recover"] = "令该伤害-1",
	[":s_w_youhuo"] = "<font color=\"orange\"><b>联动技，</b></font>当你对吕布造成伤害时，可摸兩張牌或令该伤害-1。",
	["s_w_juese"] = "絕色",
	["&s_w_juese"] = "色",
	[":s_w_juese"] = "遊戲開始時，你可以指定一名其他男性角色，该角色獲得一個色標記；每當該角色的准备阶段开始时，该角色獲得一個色標記；當該角色死亡時，你可以指定另外一名男性角色。",
	["s_w_yanzi"] = "艷姿",
	[":s_w_yanzi"] = "當一名擁有色標記的角色的摸牌阶段摸牌时，你可以棄置其最多3枚色標記，然后該角色少摸X張牌或多摸X張牌，若你選擇少摸牌則你摸X張牌。（X为棄置的色標記量）",
	["s_w_yanzi_disMark"] = "艷姿棄置標記数",
	["s_w_yanzi_in_de"] = "艷姿少摸X張牌或多摸X張牌",
	["s_w_yanzi_in"] = "艷姿多摸X張牌",
	["s_w_yanzi_de"] = "艷姿少摸X張牌",
} 






s_w_2_godlubu =  sgs.General(extension,"s_w_2_godlubu","god","6")



s_w_biaonu = sgs.CreateTriggerSkill{
	name = "s_w_biaonu" ,
	events = {sgs.Damage, sgs.Damaged, sgs.GameStart, sgs.Death} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	if event == sgs.GameStart then 
		local kingdom_set = {}
		table.insert(kingdom_set, player:getKingdom())
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			local flag = true
			for _, k in ipairs(kingdom_set) do
				if p:getKingdom() == k then
					flag = false
					break
				end
			end
			if flag then table.insert(kingdom_set, p:getKingdom()) end
		end
		room:addPlayerMark(player,"&wrath",#kingdom_set)
	elseif event == sgs.Death then
			local death = data:toDeath()
			local damage = death.damage
			if death.who:objectName() == player:objectName() then return false end
			if player:hasSkill(self:objectName()) then 
			local killer 
			if death.damage then
				killer = death.damage.from
			else
				killer = nil
			end
			if killer then
				if killer:hasSkill(self:objectName()) then
					killer:gainMark("&wrath", 3)
						end
				end
			end
	elseif  event == sgs.Damaged or event == sgs.Damage then
	local damage = data:toDamage()
	if damage.damage > 0 then 
		player:getRoom():addPlayerMark(player,"&wrath",damage.damage)
			end
		end
	end
}

s_w_wuqianCard = sgs.CreateSkillCard{
	name = "s_w_wuqian" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName()) and (sgs.Self:getMark("&wrath") >= to_select:getHp())
	end ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		effect.from:loseMark("&wrath", effect.to:getHp())
		room:handleAcquireDetachSkills(effect.from, "wushuang")
		room:setFixedDistance(effect.from, effect.to, 1);
		effect.from:setFlags("s_w_wuqianSource")
		effect.to:setFlags("s_w_wuqianTarget")
		room:addPlayerMark(effect.to, "Armor_Nullified")
		room:addPlayerMark(effect.to, "&s_w_wuqian+to+#"..effect.from:objectName().."-Clear")
	end
}
s_w_wuqianVS = sgs.CreateViewAsSkill{
	name = "s_w_wuqian" ,
	view_as = function()
		return s_w_wuqianCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return player:getMark("&wrath") > 0 
	end
}
s_w_wuqian = sgs.CreateTriggerSkill{
	name = "s_w_wuqian" ,
	events = {sgs.EventPhaseChanging, sgs.Death} ,
	view_as_skill = s_w_wuqianVS ,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
				return false
			end
		end
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then
				return false
			end
		end
		for _, p in sgs.qlist(player:getRoom():getAllPlayers()) do
			if p:hasFlag("s_w_wuqianTarget") then
				p:setFlags("-s_w_wuqianTarget")
				room:removeFixedDistance(player, p, 1)
				if p:getMark("Armor_Nullified") then
					room:removePlayerMark(p, "Armor_Nullified")
				end
			end
		end
		room:detachSkillFromPlayer(player, "wushuang")
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasFlag("s_w_wuqianSource")
	end
}
s_w_wumou = sgs.CreateTriggerSkill{
	name = "s_w_wumou" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.CardUsed, sgs.CardResponded, sgs.TurnedOver} ,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	if event == sgs.TurnedOver then 
	if player:faceUp() then 
	room:removePlayerCardLimitation(player, "use,response", "TrickCard")
	else 
	room:setPlayerCardLimitation(player, "use,response", "TrickCard", false)
	end
	return false 
	end
		local card
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponded then
			card = data:toCardResponse().m_card
		end
		if card:isNDTrick() then	
			local result = room:askForChoice(player, self:objectName(), "hp+maxhp")
				if result == "hp" then
					room:loseHp(player)
				else
					room:loseMaxHp(player)
				end
		end
	end
}

s_w_tuyong = sgs.CreateFilterSkill{
	name = "s_w_tuyong", 
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return (to_select:getSuit() == sgs.Card_Heart and to_select:isKindOf("Peach")) and (place == sgs.Player_PlaceHand)
	end,
	view_as = function(self, originalCard)
		local analeptic = sgs.Sanguosha:cloneCard("Analeptic", originalCard:getSuit(), originalCard:getNumber())
		analeptic:setSkillName(self:objectName())
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(analeptic)
		return card
	end
}
s_w_guishen = sgs.CreateTriggerSkill{
	name = "s_w_guishen" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.TurnedOver} ,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	if event == sgs.TurnedOver then 
	if not player:hasFlag("s_w_guishen_ing") then 
	if room:askForSkillInvoke(player, self:objectName()) then 
	player:setFlags("s_w_guishen_ing")
	if (player:getCardCount(true, true) >= player:getHp()) and not player:faceUp()  then 
	if room:askForDiscard(player, self:objectName(), player:getHp(), player:getHp(), true, true) then 
	player:turnOver()
	else 
	player:drawCards(player:getHp(), self:objectName())
	end
	else 
	player:drawCards(player:getHp(), self:objectName())
	end
	player:setFlags("-s_w_guishen_ing")
	end
	end
	end
	end
}

s_w_2_godlubu:addSkill(s_w_biaonu)
s_w_2_godlubu:addSkill(s_w_wuqian)
s_w_2_godlubu:addSkill(s_w_wumou)
s_w_2_godlubu:addSkill("shenfen")
s_w_2_godlubu:addSkill("xiuluo")
s_w_2_godlubu:addSkill(s_w_guishen)
s_w_2_godlubu:addSkill(s_w_tuyong)
--http://tieba.baidu.com/p/1690733419?fr=frs
sgs.LoadTranslationTable{
	["s_w_2_godlubu"] = "神吕布",
	["&s_w_2_godlubu"] = "神吕布",
	["#s_w_2_godlubu"] = " 修羅鬼神",
	["designer:s_w_2_godlubu"] = "花栗鼠的春天",
	["s_w_biaonu"] = "暴怒",
	[":s_w_biaonu"] = "<font color=\"blue\"><b>锁定技，</b></font>游戏开始时，你获得X枚“暴怒”标记（X为现存势力数）；每当你造成或受到1点伤害后，你获得1枚“暴怒”标记；若你杀死一名角色，则你获得3枚“暴怒”标记",
	["s_w_wuqian"] = "无前",
	[":s_w_wuqian"] = "出牌阶段，你可以弃X枚“暴怒”标记并选择一名其他角色（X为该角色的体力值），该角色的防具无效且你无视与该角色的距离，然后你获得技能“无双”，直到回合结束。",
	["s_w_wumou"] = "无谋",
	[":s_w_wumou"] = "<font color=\"blue\"><b>锁定技，</b></font>当你使用一张非延时类锦囊牌选择目标后，你须选择失去1点体力或失去1点体力上限；當你武將牌背面朝上時，你不能使用非延时类锦囊牌。",
	["s_w_guishen"] = "鬼神",
	[":s_w_guishen"] = "每当你的武将牌翻面时，你可以摸X張牌或棄置X張牌令武將牌翻回正面（X为你的体力值）。",
	["s_w_tuyong"] = "圖勇",
	[":s_w_tuyong"] = "<font color=\"blue\"><b>锁定技，</b></font>你的红桃【桃】视为【酒】。",
} 

s2_godzhaoyun = sgs.General(extension_jx,"s2_godzhaoyun","god","2")
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

function chadian(sponsor, first,second, skill_name)	
	local room = sponsor:getRoom()
	if sponsor:isKongcheng() or first:isKongcheng() or second:isKongcheng() then 
	return "false"
	end
	local msg = sgs.LogMessage()
				msg.type = "#chadian"
				msg.from = sponsor
				msg.to:append(first)
				msg.to:append(second)
				room:sendLog(msg)
			local card_s = room:askForCard(sponsor, ".!", skill_name, sgs.QVariant(), sgs.Card_MethodNone,sponsor,false,skill_name,true)
			local msg1 = sgs.LogMessage()
				msg1.type = "#chadianResult"
				msg1.from = sponsor
				msg1.arg = card_s:toString()
			local card_d = room:askForCard(first, ".!", skill_name, sgs.QVariant(), sgs.Card_MethodNone,sponsor,false,skill_name,true)
			local msg2 = sgs.LogMessage()
				msg2.type = "#chadianResult"
				msg2.from = first
				msg2.arg = card_d:toString()
			local card_se = room:askForCard(second, ".!", skill_name, sgs.QVariant(), sgs.Card_MethodNone,sponsor,false,skill_name,true)
			local msg3 = sgs.LogMessage()
				msg3.type = "#chadianResult"
				msg3.from = second
				msg3.arg = card_se:toString()
				room:sendLog(msg1)
				room:sendLog(msg2)
				room:sendLog(msg3)
	room:moveCardTo(card_s, sponsor, nil, sgs.Player_DiscardPile,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RULEDISCARD, sponsor:objectName(), skill_name, ""))
	room:moveCardTo(card_d, first, nil, sgs.Player_DiscardPile,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RULEDISCARD, first:objectName(), skill_name, ""))
	room:moveCardTo(card_se, second, nil, sgs.Player_DiscardPile,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RULEDISCARD, second:objectName(), skill_name, ""))
	if ((card_s:getNumber() < card_d:getNumber()) and (card_s:getNumber() > card_se:getNumber())) or  ((card_s:getNumber() > card_d:getNumber()) and (card_s:getNumber() < card_se:getNumber())) then
	room:setEmotion(sponsor, "success")
	local msg = sgs.LogMessage()
				msg.type = "#chadianSuccess"
				msg.from = sponsor
				msg.to:append(first)
				msg.to:append(second)
				room:sendLog(msg)
	return "success"
else
room:setEmotion(sponsor, "no-success")
local msg = sgs.LogMessage()
				msg.type = "#chadianFailure"
				msg.from = sponsor
				msg.to:append(first)
				msg.to:append(second)
				room:sendLog(msg)
return "false"
end	
end

listIndexOf = function(theqlist, theitem)
	local index = 0
	for _, item in sgs.qlist(theqlist) do
		if item == theitem then return index end
		index = index + 1
	end
end
player2serverplayer = function(room, player) --啦啦SLG (OTZ--ORZ--Orz) --作用：将currentplayer转换成serverplayer
	local players = room:getPlayers()
	for _,p in sgs.qlist(players) do
		if p:objectName() == player:objectName() then
			return p
		end
	end
end
qstring2serverplayer = function(room, qstring) --改编版本 --作用：将qstring类型转换成serverplayer
	local players = room:getPlayers()
	for _,p in sgs.qlist(players) do
		if p:objectName() == qstring then
			return p
		end
	end
end


--思路: COS C= ture S= false
function equipEXtra(owner, original_equip, added_equip, skill_name)
	local room = owner:getRoom()

end
function canExtraEquip(owner, which_equip)
	local room = owner:getRoom()
	if owner:getMark("ExtraEquip") > 0 then
	if owner:getMark("ExtraEquip"..which_equip) > 0  then
	return true 
	end
else 
return false 	
	end
end
--[[
s2_equipEXtra = sgs.CreateTriggerSkill{
	name = "s2_equipEXtra",
	events = {sgs.BeforeCardsMove},
	global = true,
	can_trigger = function(self, player)
	    return true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		math.random()
	if event == sgs.BeforeCardsMove then
	local move = data:toMoveOneTime()
		if move.from and (move.from:objectName() == player:objectName()) then 
			if (move.to_place == sgs.Player_PlaceEquip) and move.card_ids:length()==1  then
			for _, id in sgs.qlist(move.card_ids) do
			local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf("EquipCard") then
				local cardtype = ""
					if card:isKindOf("Weapon") and player:getWeapon() and canExtraEquip(player2serverplayer(room,move.from), "weapon") then
					cardtype = "Weapon"
					elseif  card:isKindOf("Armor") and player:getArmor() and canExtraEquip(player2serverplayer(room,move.from), "armor") then
					cardtype = "Armor"
					elseif card:isKindOf("OffensiveHorse") and player:getOffensiveHorse() and canExtraEquip(player2serverplayer(room,move.from), "offensive_horse") then
					cardtype = "OffensiveHorse"
					elseif card:isKindOf("DefensiveHorse") and player:getDefensiveHorse() and canExtraEquip(player2serverplayer(room,move.from), "defensive_horse") then
					cardtype = "DefensiveHorse"
					end
					if cardtype ~= "" and (player:getTag("equipEXtra_COS"):toBool() or  room:askForSkillInvoke(player,player:getTag("equipEXtra"):toString()) )then
						player:addToPile("extra_"..cardtype, card, true)
						move.card_ids:removeOne(id)
							data:setValue(move)
							room:setTag("s2_equipEXtraCard"..move.from:objectName(), sgs.QVariant(move.card_ids:first()))
					end
					end
					end
					end
					end
	if move.from and (move.from:objectName() == player:objectName()) and (move.to_place ~= sgs.Player_PlaceEquip)  then
	for _, id in sgs.qlist(move.card_ids) do
	local extra_card = room:getTag("s2_equipEXtraCard"..move.from:objectName()):toInt()
				if sgs.Sanguosha:getCard(id) == sgs.Sanguosha:getCard(extra_card) then
				player:gainMark("@2")
						move.card_ids:removeOne(id)
						data:setValue(move)
						room:setTag("s2_equipEXtraCard"..move.from:objectName(), sgs.QVariant())
						end
				end
	end
	end
	end,
}
if not sgs.Sanguosha:getSkill("s2_equipEXtra") then
	s_skillList:append(s2_equipEXtra)
end
]]
xiangle_anim = sgs.CreateTriggerSkill{
	name = "xiangle_anim",
	events = {sgs.TargetConfirming},
	global = true,
	can_trigger = function(self, player)
	    return true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		math.random()
	if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
			  for _,p in sgs.qlist(use.to) do
			if p:hasSkill("xiangle") then
			 room:setEmotion(p, "xiangle/xiangle")
					end
				end
			end
	end
	end,
	priority = 5
}

if not sgs.Sanguosha:getSkill("xiangle_anim") then
	s_skillList:append(xiangle_anim)
end









s2_juejing = sgs.CreateTriggerSkill{
	name = "s2_juejing" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, luxun, data)
		local room = luxun:getRoom()
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == luxun:objectName() and move.from_places:contains(sgs.Player_PlaceHand) and move.is_last_handcard then
		local targets = sgs.SPlayerList()
		local other_players = room:getOtherPlayers(player)
			for _, player in sgs.qlist(other_players) do
				if not player:isAllNude() then
					targets:append(player)
				end
			end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(luxun, targets, self:objectName(), "s2_juejing-invoke", true, true)
			if not target then return false end
			local card = room:askForCardChosen(luxun, target, "hej", self:objectName())
												room:obtainCard(luxun, card)
			end
		end
		return false
	end
}



s2_longhunCard = sgs.CreateSkillCard{
	name = "s2_longhun",
	will_throw = false,
	filter = function(self, targets, to_select)
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local rangefix = 0
		if not self:getSubcards():isEmpty() and sgs.Self:getWeapon() and sgs.Self:getWeapon():getId() == self:getSubcards():first() then
			local card = sgs.Self:getWeapon():getRealCard():toWeapon()
			rangefix = rangefix + card:getRange() - sgs.Self:getAttackRange(false)
		end
		if not self:getSubcards():isEmpty() and sgs.Self:getOffensiveHorse() and sgs.Self:getOffensiveHorse():getId() == self:getSubcards():first() then
			rangefix = rangefix + 1
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetFilter(plist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, plist)
				and (card:isKindOf("Slash") and sgs.Self:canSlash(to_select, true, rangefix))
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end
		local card = sgs.Self:getTag("s2_longhun"):toCard()
		return card and card:targetFilter(plist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, plist)
			and (card:isKindOf("Slash") and sgs.Self:canSlash(to_select, true, rangefix))
	end,
	target_fixed = function(self)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetFixed()
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local card = sgs.Self:getTag("s2_longhun"):toCard()
		return card and card:targetFixed()
	end,
	feasible = function(self, targets)
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetsFeasible(plist, sgs.Self)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local card = sgs.Self:getTag("s2_longhun"):toCard()
		return card and card:targetsFeasible(plist, sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
		local room, to_xin_zhayi_jiben = player:getRoom(), self:getUserString()
		if self:getUserString() == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local xin_zhayi_jiben_list = {}
			table.insert(xin_zhayi_jiben_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(xin_zhayi_jiben_list, "normal_slash")
				table.insert(xin_zhayi_jiben_list, "thunder_slash")
				table.insert(xin_zhayi_jiben_list, "fire_slash")
			end
			to_xin_zhayi_jiben = room:askForChoice(player, "s2_longhun_slash", table.concat(xin_zhayi_jiben_list, "+"))
		end
		local card = nil
		if self:subcardsLength() == 1 then card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self:getSubcards():first())) end
		local user_str
		if to_xin_zhayi_jiben == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_xin_zhayi_jiben == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_xin_zhayi_jiben
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str, card and card:getSuit() or sgs.Card_SuitToBeDecided, card and card:getNumber() or -1)
		use_card:setSkillName("s2_longhun")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		return use_card
	end,
	on_validate_in_response = function(self, user)
		local room, user_str = user:getRoom(), self:getUserString()
		local to_xin_zhayi_jiben
		if user_str == "peach+analeptic" then
			local xin_zhayi_jiben_list = {}
			table.insert(xin_zhayi_jiben_list, "peach")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(xin_zhayi_jiben_list, "analeptic")
			end
			to_xin_zhayi_jiben = room:askForChoice(user, "s2_longhun_saveself", table.concat(xin_zhayi_jiben_list, "+"))
		elseif user_str == "slash" then
			local xin_zhayi_jiben_list = {}
			table.insert(xin_zhayi_jiben_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(xin_zhayi_jiben_list, "normal_slash")
				table.insert(xin_zhayi_jiben_list, "thunder_slash")
				table.insert(xin_zhayi_jiben_list, "fire_slash")
			end
			to_xin_zhayi_jiben = room:askForChoice(user, "s2_longhun_slash", table.concat(xin_zhayi_jiben_list, "+"))
		else
			to_xin_zhayi_jiben = user_str
		end
		local card = nil
		if self:subcardsLength() == 1 then card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self:getSubcards():first())) end
		local user_str
		if to_xin_zhayi_jiben == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_xin_zhayi_jiben == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_xin_zhayi_jiben
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str, card and card:getSuit() or sgs.Card_SuitToBeDecided, card and card:getNumber() or -1)
		use_card:setSkillName("s2_longhun")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		return use_card
	end
}
s2_longhun = sgs.CreateViewAsSkill{
	name = "s2_longhun",
	n=1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
				return to_select:isKindOf("BasicCard")
	end
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local skillcard = s2_longhunCard:clone()
		skillcard:setSkillName(self:objectName())
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			skillcard:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
			for _, card in ipairs(cards) do
				skillcard:addSubcard(card)
			end
			return skillcard
		end
		local c = sgs.Self:getTag("s2_longhun"):toCard()
		if c then
			skillcard:setUserString(c:objectName())
			for _, card in ipairs(cards) do
				skillcard:addSubcard(card)
			end
			return skillcard
		else
			return nil
		end
	end,
	enabled_at_play = function(self, player)
		if not player:isWounded() then return false end
		local basic = {"slash", "peach"}
		if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
			table.insert(basic, "thunder_slash")
			table.insert(basic, "fire_slash")
			table.insert(basic, "analeptic")
		end
		for _, patt in ipairs(basic) do
			local poi = sgs.Sanguosha:cloneCard(patt, sgs.Card_NoSuit, -1)
			if poi and poi:isAvailable(player) and not(patt == "peach" and not player:isWounded()) then
				return true
			end
		end
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if not player:isWounded() then return false end
		if string.startsWith(pattern, ".") or string.startsWith(pattern, "@") then return false end
		if pattern == "peach" and player:getMark("Global_PreventPeach") > 0 then return false end
		return pattern ~= "nullification"
	end
}
s2_longhun:setGuhuoDialog("l")

s2_godzhaoyun:addSkill(s2_juejing)
s2_godzhaoyun:addSkill(s2_longhun)

--http://tieba.baidu.com/p/1217356623?pn=1
sgs.LoadTranslationTable{
	["scarletbcuohuojixin"] = "厝火積薪",
	["scarletbcuohuojixin_card"] = "厝火積薪",
	
	["s2_godzhaoyun"] = "趙雲",
	["&s2_godzhaoyun"] = "趙雲",
	["#s2_godzhaoyun"] = " 神威如龙",
	["designer:s2_godzhaoyun"] = "曉ャ絕對",
	
	["s2_juejing"] = "绝境",
	[":s2_juejing"] = "每当你失去最后的手牌后，你可以獲得一名其他角色区域内的一张牌。",
	["s2_juejing-invoke"] =  "你可以发动“绝境”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
  
	["s2_longhun"] = "龙魂",
	[":s2_longhun"] = "若你已受伤，你可以将一张基本牌当【闪】，【杀】，【桃】，【酒】使用或打出。",
	["s2_longhun-new"] = "龙魂",
	["s2_longhun_select"]  ="龙魂",
	["@@s2_longhun"]= "你可以将一张基本牌当 %src 使用或打出。",
	["~s2_longhun"] = "选择一张基本牌→点击确定",
	["s2_longhun_slash"] = "龙魂【杀】",
	}  

s2_guanyu = sgs.General(extension_jx,"s2_guanyu","shu","4")

s2_wusheng = sgs.CreateTargetModSkill{
	name = "s2_wusheng",
	pattern = "Slash",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("wusheng") and (card:getSuit() == sgs.Card_Heart) and from:hasSkill(self:objectName()) then
			return 1000
		else
			return 0
		end
	end
}

s2_guanyu:addSkill("wusheng")
s2_guanyu:addSkill(s2_wusheng)
s2_guanyu:addSkill("wuhun")

--http://tieba.baidu.com/p/1273768030
sgs.LoadTranslationTable{
	["#s2_equipEXtra"] = "%arg",
	["s2_guanyu"] = "关羽",
	["&s2_guanyu"] = "关羽",
	["designer:s2_guanyu"] = "林森鸣",
	
	["s2_wusheng"] = "武圣-效果",
	[":s2_wusheng"] = "你使用红桃【杀】无距离限制。 ",
}  
s2_shana = sgs.General(extension_jx,"s2_shana","magic","3", false)


s2_feiyan = sgs.CreateFilterSkill{
	name = "s2_feiyan", 
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return (to_select:isKindOf("Slash")) and (place == sgs.Player_PlaceHand)
	end,
	view_as = function(self, originalCard)
		local slash = sgs.Sanguosha:cloneCard("fire_slash", originalCard:getSuit(), originalCard:getNumber())
		slash:setSkillName(self:objectName())
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(slash)
		return card
	end
}

s2_shenpanCard = sgs.CreateSkillCard{
	name = "s2_shenpan" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName()) and not (to_select:getHandcardNum() < 2 )
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local player = effect.from 
		local target = effect.to
		local original_places = sgs.PlaceList()
		local y = 0
		local discards = sgs.IntList()
		for i = 1, 2 do--进行多次执行
			local id = room:askForCardChosen(player, target, "h", self:objectName(),
				false,--选择卡牌时手牌不可见
				sgs.Card_MethodNone,--设置为弃置类型
				discards,--将子卡表设置为不可选卡牌id表（保证每张卡只能被选择一次）
				false)--只有执行过一次选择才可取消
			if id < 0 then break end--如果卡牌id无效就结束多次执行
			discards:append(id)--将选择的id添加到虚拟卡的子卡表
		end

		for _, card in sgs.qlist(discards) do
					room:showCard(effect.to, sgs.Sanguosha:getCard(card):getEffectiveId(),effect.from)
					if sgs.Sanguosha:getCard(card):getSuit() == sgs.Card_Heart then 
					y = y + 1 
					end
			end
			if y > 0 then 
			room:damage(sgs.DamageStruct("s2_shenpan", effect.from, effect.to, y, sgs.DamageStruct_Fire))
			end
	end
}
s2_shenpan = sgs.CreateViewAsSkill{
	name = "s2_shenpan" ,
	n = 0 ,
	view_as = function()
		return s2_shenpanCard:clone()
	end ,
	enabled_at_play = function(self, target)
		return not target:hasUsed("#s2_shenpan")
	end
}

s2_duanzuiCard = sgs.CreateSkillCard{
	name = "s2_duanzui" ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@s2_duanzui")
		local players = room:getOtherPlayers(source)
		source:setFlags("s2_duanzuiUsing")
		for _, player in sgs.qlist(players) do
			if player:isAlive() then
				room:cardEffect(self, source, player)
			end
		end
		source:setFlags("-s2_duanzuiUsing")
	end ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
			room:damage(sgs.DamageStruct("s2_duanzui", effect.from, effect.to, 1, sgs.DamageStruct_Fire))
	end
}
s2_duanzuiVS = sgs.CreateViewAsSkill{
	name = "s2_duanzui" ,
	n = 0,
	view_as = function()
		return s2_duanzuiCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return player:getMark("@s2_duanzui") >= 1
	end
}
s2_duanzui = sgs.CreateTriggerSkill{
	name = "s2_duanzui" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@s2_duanzui",
	events = {},
	view_as_skill = s2_duanzuiVS,
	
	on_trigger = function()
	end
}



s2_shana:addSkill(s2_feiyan)
s2_shana:addSkill(s2_shenpan)
s2_shana:addSkill(s2_duanzui)
--http://tieba.baidu.com/p/1213960230
sgs.LoadTranslationTable{
	["s2_shana"] = "夏娜",
	["&s2_shana"] = "夏娜",
	["#s2_shana"] = " 炎髮灼眼的討伐者",
	["designer:s2_shana"] = "輕音de蔥頭",
	
	["s2_feiyan"] = "飛炎",
	[":s2_feiyan"] = "<font color=\"blue\"><b>锁定技，</b></font>你的【杀】视为火【杀】。 ",
	
	["s2_duanzui"] = "断罪",
	[":s2_duanzui"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以对所有其他角色造成的1点火焰伤害。",
	
	["@s2_duanzui"] = "断罪",
	["s2_shenpan"] = "審判",
	[":s2_shenpan"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以观看一名其他角色的两张手牌，若當中有红桃牌，你对其造成的X点火焰伤害。（X为當中红桃牌的數量）",
}  




s2_guanxingzhangbao = sgs.General(extension_jx,"s2_guanxingzhangbao","shu","4")

s2_chengwu = sgs.CreateTriggerSkill{
	name = "s2_chengwu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local card = damage.card
		if card then
			if card:isKindOf("Slash") and card:isRed() then
				local hurt = damage.damage
				damage.damage = hurt + 1
				data:setValue(damage)
				local log= sgs.LogMessage()
				log.type = "#skill_add_damage"
				log.from = damage.from
				log.to:append(damage.to)
				log.arg = self:objectName()
				log.arg2  = damage.damage
				player:getRoom():sendLog(log)
			end
		end
		return false
	end
}
s2_huzi = sgs.CreateTriggerSkill{
	name = "s2_huzi", 
	frequency = sgs.Skill_Wake, 
	events = {sgs.EventPhaseStart}, 
	waked_skills = "wushen,paoxiao",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:canWake(self:objectName()) or player:getHp() <= 2 then
	if 	room:changeMaxHpForAwakenSkill(player, -2) then 
		room:addPlayerMark(player, self:objectName())
		room:handleAcquireDetachSkills(player, "wushen")
		room:handleAcquireDetachSkills(player, "paoxiao")
		
		end
	end
	return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:getPhase() == sgs.Player_Start and not (target:getMark(self:objectName()) > 0 )then
						return true
				end
			end
		end
		return false
	end
}
s2_guanxingzhangbao:addSkill(s2_chengwu)
s2_guanxingzhangbao:addSkill(s2_huzi)
--http://tieba.baidu.com/p/1390728045
sgs.LoadTranslationTable{
	["s2_guanxingzhangbao"] = "关兴张苞",
	["&s2_guanxingzhangbao"] = "关兴张苞",
	["#s2_guanxingzhangbao"] = " 龙骧虎翼",
	["designer:s2_guanxingzhangbao"] = "郁闷的油茶",
	
	["s2_chengwu"] = "承武",
	[":s2_chengwu"] = "<font color=\"blue\"><b>锁定技，</b></font>你使用红色【杀】对目标角色造成伤害时，此伤害+1。",
	
	["s2_huzi"] = "虎子",
	[":s2_huzi"] = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段开始时，若你的体力值不大于2，你失去2点体力上限，然后获得“咆哮”和“武神”。",
	
}  

s2_wenyang = sgs.General(extension_jx,"s2_wenyang","wei","4")
s2_wenyang_ch = sgs.General(extension_jx,"s2_wenyang_ch","wu","4", true, true, true)

s2_benxi = sgs.CreateFilterSkill{
	name = "s2_benxi", 
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return (to_select:isKindOf("Slash")) and (place == sgs.Player_PlaceHand)
	end,
	view_as = function(self, originalCard)
		local slash = sgs.Sanguosha:cloneCard(originalCard:objectName(), sgs.Card_NoSuit, originalCard:getNumber())
		slash:setSkillName(self:objectName())
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(slash)
		return card
	end
}
s2_benxi_d = sgs.CreateDistanceSkill{
	name = "#s2_benxi_d",
	correct_func = function(self, from, to)
		if from:hasSkill("s2_benxi") then
			return -1
		end
	end,
}

s2_touben_wei = sgs.CreatePhaseChangeSkill{
	name = "s2_touben_wei",
	frequency = sgs.Skill_NotFrequent,
	on_phasechange = function(self, player)
	local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish   then
		if (player:getMark("s2_touben")  < 1  ) then 
			if player:askForSkillInvoke(self:objectName()) then
				player:getRoom():broadcastSkillInvoke(self:objectName())
				player:getRoom():loseHp(player)
				player:drawCards(2, self:objectName())
				room:setPlayerMark(player, "s2_touben", 1)
					if player:getGeneralName() == "s2_wenyang" then
				room:changeHero(player,"s2_wenyang_ch",false, false, false, false)
			elseif player:getGeneral2Name() == "s2_wenyang" then
				room:changeHero(player,"s2_wenyang_ch",false, false, true, false)
				else
				player:getRoom():setPlayerProperty(player, "kingdom", sgs.QVariant("wu"))
				player:getRoom():handleAcquireDetachSkills(player, "-s2_benxi")
				player:getRoom():handleAcquireDetachSkills(player, "s2_nixi")
				player:getRoom():handleAcquireDetachSkills(player, "s2_touben_wu")
				player:getRoom():handleAcquireDetachSkills(player, "-s2_touben_wei")
				end
				end
			end
				elseif player:getPhase() == sgs.Player_NotActive then
		room:setPlayerMark(player, "s2_touben", 0)
		end
	end
}

s2_nixi = sgs.CreateTriggerSkill{
	name = "s2_nixi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local from = damage.from
		local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:inMyAttackRange(p) then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then 
		local target = room:askForPlayerChosen(player, targets, self:objectName(), "s2_nixi-invoke", true, true)
			if not target then return false end
				room:damage(sgs.DamageStruct(self:objectName(), player, target))
		end
	end
}
s2_touben_wu = sgs.CreatePhaseChangeSkill{
	name = "s2_touben_wu",
	frequency = sgs.Skill_NotFrequent,
	on_phasechange = function(self, player)
	local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
		if (player:getMark("s2_touben")  < 1  ) then
			if player:askForSkillInvoke(self:objectName()) then
				player:getRoom():broadcastSkillInvoke(self:objectName())
				player:getRoom():loseHp(player)
				room:setPlayerMark(player, "s2_touben", 1)
				player:drawCards(2, self:objectName())
				if player:getGeneralName() == "s2_wenyang_ch" then
				room:changeHero(player,"s2_wenyang",false, false, false, false)
			elseif player:getGeneral2Name() == "s2_wenyang_ch" then
				room:changeHero(player,"s2_wenyang",false, false, true, false)
				else
				player:getRoom():setPlayerProperty(player, "kingdom", sgs.QVariant("wei"))
				player:getRoom():handleAcquireDetachSkills(player, "s2_benxi")
				player:getRoom():handleAcquireDetachSkills(player, "-s2_nixi")
				player:getRoom():handleAcquireDetachSkills(player, "-s2_touben_wu")
				player:getRoom():handleAcquireDetachSkills(player, "s2_touben_wei")
				end
			end
			end
		elseif player:getPhase() == sgs.Player_NotActive then
		room:setPlayerMark(player, "s2_touben", 0)
		end
	end
}

extension_jx:insertRelatedSkills("s2_benxi","#s2_benxi_d")
s2_wenyang:addSkill(s2_benxi)
s2_wenyang:addSkill(s2_benxi_d)
s2_wenyang:addSkill(s2_touben_wei)
s2_wenyang_ch:addSkill(s2_nixi)
s2_wenyang_ch:addSkill(s2_touben_wu)
s2_wenyang:addRelateSkill("s2_nixi")
--http://tieba.baidu.com/p/1300921974
sgs.LoadTranslationTable{
	["s2_wenyang"] = "文鸯",
	["&s2_wenyang"] = "文鸯",
	["#s2_wenyang"] = " 万人之雄",
	["designer:s2_wenyang"] = "NotAsked",
	
	["s2_benxi"] = "奔袭",
	[":s2_benxi"] = "<font color=\"blue\"><b>锁定技，</b></font>你计算的与其他角色的距离-1；你的【杀】均视为无花色。",
	["#s2_benxi_d"] = "奔袭",
	
	["s2_touben_wei"] = "投奔",
	[":s2_touben_wei"] = "结束阶段开始时，你可以失去1点体力并摸两张牌，改变势力为吴并失去技能“奔袭”获得技能“逆袭”。",
	
	["s2_nixi"] = "逆袭",
	[":s2_nixi"] = "每当你受到一次伤害后，你可以对攻击范围内的一名其他角色造成1点伤害。",
	["s2_nixi-invoke"] =  "你可以发动“逆袭”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	
	["s2_touben_wu"] = "投奔",
	[":s2_touben_wu"] = "结束阶段开始时，你可以失去1点体力并摸两张牌，改变势力为魏并失去技能“逆袭”获得技能“奔袭”。",
	
	["s2_wenyang_ch"] = "文鸯",
	["&s2_wenyang_ch"] = "文鸯",
	["#s2_wenyang_ch"] = " 万人之雄",
	["designer:s2_wenyang_ch"] = "NotAsked",
}  


s2_jiangwei = sgs.General(extension_jx,"s2_jiangwei","shu","4")



s2_jiangeCard = sgs.CreateSkillCard{
	name = "s2_jiange" ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		local x = math.min(room:getAlivePlayers():length(),source:getHp())
		if x > 4 then 
		x = 4 
		end
		local cards = room:getNCards(x)
		local left = cards
		room:fillAG(left, source)
		if room:askForSkillInvoke(source, "s2_jiange_obtain") then 
		room:clearAG(source)
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		if not cards:isEmpty() then
		room:fillAG(left, source)
				local card_id = room:askForAG(source, left, false, "s2_jiange")
				left:removeOne(card_id)
				dummy:addSubcard(card_id)
				room:clearAG(source)
			if dummy:subcardsLength() > 0 then
				room:doBroadcastNotify(56, tostring(room:getDrawPile():length() + dummy:subcardsLength()))
				source:obtainCard(dummy)
				end
		end
		end
		room:clearAG(source)
		if not source:isNude() then 
		local card_ex = room:askForCard(source, "..", "@s2_jiange_add", sgs.QVariant(), sgs.Card_MethodNone)
		if card_ex then 
		room:moveCardTo(card_ex, source, nil,sgs.Player_DrawPile,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "s2_jiange", ""), true)
		left:append(card_ex:getId())
		end
		end
		if not left:isEmpty() then
			room:askForGuanxing(source, left, sgs.Room_GuanxingUpOnly)
	end
	end ,
}
s2_jiange = sgs.CreateViewAsSkill{
	name = "s2_jiange" ,
	n = 0,
	view_as = function(self, cards)
		return s2_jiangeCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#s2_jiange")) and not player:isKongcheng()
	end,
}
s2_jiangwei:addSkill(s2_jiange)
--http://tieba.baidu.com/p/1288077139
sgs.LoadTranslationTable{
	["s2_jiangwei"] = "姜维",
	["&s2_jiangwei"] = "姜维",
	["#s2_jiangwei"] = " 麒麟儿",
	["designer:s2_jiangwei"] = "NotAsked",
	
	["s2_jiange"] = "劍閣",
	[":s2_jiange"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>若你有手牌，你可以观看牌堆顶的X张牌，你可以获得其中一张牌或添加一张牌，然后将任意数量的牌以任意顺序置于牌堆顶。（X为你当前体力或为场上存活角色数，两者取最少且最大为4。）",
	["@s2_jiange_add"] = "你可以添加一张牌",
	["s2_jiange_obtain"] = "你可以获得其中一张牌",
	["$s2_jiange1"] = "放手一搏，或未可知。",
	["$s2_jiange2"] = "璀璨星河，伴我同行。",
}  

s2_shenguanyu = sgs.General(extension_jx,"s2_shenguanyu","god","5")

s2_wushenCard = sgs.CreateSkillCard{
	name = "s2_wushen" ,
	will_throw = true ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
	end
}
s2_wushen = sgs.CreateViewAsSkill{
	name = "s2_wushen",
	n = 999,
	view_filter = function(self, cards, to_select)
			return to_select:isKindOf("Slash")
	end ,
	view_as = function(self, cards)
			if #cards == 0 then return nil end
			local acard = s2_wushenCard:clone()
			for _, c in ipairs(cards) do
				acard:addSubcard(c)
			end
			acard:setSkillName(self:objectName())
			return acard
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@s2_wushen"
	end
}
s2_wushen_T = sgs.CreateTriggerSkill{
	name = "#s2_wushen",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DrawNCards},
	view_as_skill = s2_wushenVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
		local card = room:askForUseCard(player, "@@s2_wushen", "@s2_wushen")
		 if card then 
			draw.num = draw.num + card:subcardsLength()
			data:setValue(draw)
			end
	end
}

s2_wuhun = sgs.CreateOneCardViewAsSkill{
	name = "s2_wuhun",
	response_or_use = true,
	view_filter = function(self, card)
		if  card:isEquipped() then return false end 
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(card:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self) and card:getSuit() == sgs.Card_Heart
		end
		return card:getSuit() == sgs.Card_Heart
	end,
	view_as = function(self, originalCard)
		local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
		slash:addSubcard(originalCard:getId())
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}
s2_wuhun_T = sgs.CreateTriggerSkill{
	name = "#s2_wuhun",
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardsMoveOneTime} ,
	view_as_skill = s2_wuhunVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip) then
			for i = 0, move.card_ids:length() - 1, 1 do
				if not player:isAlive() then return false end
				if move.from_places:at(i) == sgs.Player_PlaceEquip then
					if player:isWounded() then 
					if room:askForSkillInvoke(player, "s2_wuhun") then
							local recover = sgs.RecoverStruct()
			recover.who = player;
			room:recover(player, recover);
					else
						break
					end
					else 
					break
					end
				end
			end
		end
		return false
	end
}


s2_shenguanyu:addSkill(s2_wushen)
s2_shenguanyu:addSkill(s2_wushen_T)
s2_shenguanyu:addSkill(s2_wuhun_T)
s2_shenguanyu:addSkill(s2_wuhun)
extension_jx:insertRelatedSkills("s2_wuhun","#s2_wuhun")
extension_jx:insertRelatedSkills("s2_wushen","#s2_wushen")

--http://tieba.baidu.com/p/1449148997
sgs.LoadTranslationTable{
	["s2_shenguanyu"] = "关羽",
	["&s2_shenguanyu"] = "关羽",
	["#s2_shenguanyu"] = " 鬼神降临",
	["designer:s2_shenguanyu"] = "青苹果1021",
	
	["s2_wushen"] = "武神",
	[":s2_wushen"] = "摸牌阶段，你可以弃置任意数量的【杀】，你额外摸X张牌。（X为弃置【杀】的数量。）",
	["@s2_wushen"] = "你可以发动“武神”",
	["~s2_wushen"] = "选择任意数量的【杀】→点击确定",
	
	["s2_wuhun"] = "武魂",
	[":s2_wuhun"] = "你可以将一张红桃手牌当【杀】使用或打出；每当你失去一张装备区的装备牌后，你可以回复1点体力。 ",
	
}  


s2_SPgangning = sgs.General(extension_jx,"s2_SPgangning","qun","4")

s2_jiechuan = sgs.CreateTriggerSkill{
	name = "s2_jiechuan" ,
	events = {sgs.Damage, sgs.Damaged} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		player:getRoom():sendCompulsoryTriggerLog(player, self:objectName(), true)
		player:getRoom():addPlayerMark(player,"&s2_jie",damage.damage)
	end
}

s2_jiechuanTargetMod = sgs.CreateAttackRangeSkill{
	name = "#s2_jiechuan",
	extra_func = function(self, player, include_weapon)
		if player:hasSkill("s2_jiechuan") then
			return player:getMark("&s2_jie")
		end
	end,
}

s2_jiangwu = sgs.CreateTriggerSkill{
	name = "s2_jiangwu" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:canWake(self:objectName()) or player:getMark("&s2_jie") >= 4 then
		room:addPlayerMark(player, "s2_jiangwu")
		if room:changeMaxHpForAwakenSkill(player) then
				player:getRoom():setPlayerProperty(player, "kingdom", sgs.QVariant("wu"))
				room:handleAcquireDetachSkills(player, "s2_gn_nixi")
		end
	end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
		   and (target:getPhase() == sgs.Player_Start)
		   and (target:getMark("s2_jiangwu") == 0)
	end
}



s2_gn_nixiVS = sgs.CreateOneCardViewAsSkill{
	name = "s2_gn_nixi", 
	filter_pattern = ".|black",
	view_as = function(self, card) 
		local acard = sgs.Sanguosha:cloneCard("dismantlement", card:getSuit(), card:getNumber())
		acard:addSubcard(card:getId())
		acard:setSkillName("s2_gn_nixi")
		return acard
	end, 
		enabled_at_play = function(self, player)
		return (player:getMark("&s2_jie") > 0 )
	end, 
}
s2_gn_nixi = sgs.CreateTriggerSkill{
	name = "s2_gn_nixi",
	events = {sgs.DrawNCards, sgs.AfterDrawNCards, sgs.TargetSpecified},
	view_as_skill = s2_gn_nixiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		player:setMark("s_w_juezhanEvent",tonumber(event))
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
			local tuxi = sgs.Sanguosha:getTriggerSkill("tenyeartuxi")
			room:setPlayerMark(player, "tenyeartuxi", draw.num)
			if tuxi and player:askForSkillInvoke(self:objectName(),data)  then
			
				room:notifySkillInvoked(player,self:objectName())
				tuxi:trigger(event,room,player,data)
				room:setPlayerFlag(player, "s2_gn_nixi_tuxied")
			end
		elseif event == sgs.AfterDrawNCards then
			local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
		if player:hasFlag("s2_gn_nixi_tuxied") then 
			local tuxiAct = sgs.Sanguosha:getTriggerSkill("#tenyeartuxi")
				if tuxiAct  then
				tuxiAct:trigger(event,room,player,data)
				player:loseMark("&s2_jie")
				room:setPlayerFlag(player, "-s2_gn_nixi_tuxied")
				end
				end
		elseif event == sgs.TargetSpecified then 
		local use = data:toCardUse()
		if use.card:getSkillName() == "s2_gn_nixi" then 
		player:loseMark("&s2_jie")
		end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and target:getMark("&s2_jie") > 0 
	end
}


extension_jx:insertRelatedSkills("s2_jiechuan","#s2_jiechuan")
s2_SPgangning:addSkill(s2_jiechuan)
s2_SPgangning:addSkill(s2_jiechuanTargetMod)
if not sgs.Sanguosha:getSkill("s2_gn_nixi") then
	s_skillList:append(s2_gn_nixi)
end
s2_SPgangning:addSkill(s2_jiangwu)
s2_SPgangning:addRelateSkill("s2_gn_nixi")
s2_SPgangning:addRelateSkill("qixi")
s2_SPgangning:addRelateSkill("tenyeartuxi")
--http://tieba.baidu.com/p/1473754971
sgs.LoadTranslationTable{
	["s2_SPgangning"] = "甘宁",
	["&s2_SPgangning"] = "SP甘宁",
	["#s2_SPgangning"] = " 江东水贼",
	["designer:s2_SPgangning"] = "苝偑′飘雪",
	
	["s2_jie"] = "劫",
	["s2_jiechuan"] = "劫船",
	[":s2_jiechuan"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你造成或受到1点伤害后，你获得1枚“劫”标记；每有一个“劫”，你的攻击范围便+1。",
	
	["s2_jiangwu"] = "降吴",
	[":s2_jiangwu"] = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段开始时，若“劫”大于或等于四个，你获得技能“逆袭”。",
	
	["s2_gn_nixi"] = "逆袭",
	[":s2_gn_nixi"] = "你可以弃一枚“劫”标记发动下列一项技能——“奇袭”、“突袭”。",
	
} 


s2_caocao = sgs.General(extension_jx,"s2_caocao","wei","4")


s2_huibian = sgs.CreateAttackRangeSkill{
	name = "s2_huibian",
	fixed_func = function(self, player, include_weapon)
		if player:hasSkill(self:objectName()) and player:getWeapon() == nil  then
			local x = math.min(5, player:getSiblings():length()+ 1)
			return x
		end
	end,
}

s2_guanhui = sgs.CreateTriggerSkill{
	name = "s2_guanhui" ,
	events = {sgs.AskForRetrial} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isNude() then return false end
		local judge = data:toJudge()
		local prompt_list = {
			"@s2_guanhui-card" ,
			judge.who:objectName() ,
			self:objectName() ,
			judge.reason ,
			string.format("%d", judge.card:getEffectiveId())
		}
		local prompt = table.concat(prompt_list, ":")
		local card = room:askForCard(player, "..", prompt, data, sgs.Card_MethodDiscard, judge.who, true)
		if card then
		local x =player:getAttackRange()
		local cards = room:getNCards(x)
		room:fillAG(cards, player)
		room:setTag("s2_guanhui", data)
		local card_id = room:askForAG(player, cards, false, self:objectName())
		room:removeTag("s2_guanhui")
		if card_id then
			cards:removeOne(card_id)
			local move = sgs.CardsMoveStruct()
		move.card_ids = cards
		move.to_place = sgs.Player_DiscardPile
		 local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), "s2_guanhui", "");
		 move.reason = reason
		room:moveCardsAtomic(move,false)		
			room:retrial(sgs.Sanguosha:getCard(card_id), player, judge, self:objectName())
		end
		room:clearAG()
		end
		return false
	end
}
s2_caocao:addSkill(s2_huibian)
s2_caocao:addSkill(s2_guanhui)

--http://tieba.baidu.com/p/1574380549
sgs.LoadTranslationTable{
	["s2_caocao"] = "曹操",
	["&s2_caocao"] = "曹操",
	["#s2_caocao"] = " 东临碣石",
	["designer:s2_caocao"] = "唯我独若遗",
	
	["s2_huibian"] = "挥鞭",
	[":s2_huibian"] = "<font color=\"blue\"><b>锁定技，</b></font>若你的装备区没有武器牌，你的攻击范围为X。（X为存活角色数且至多为5）",
	
	["s2_guanhui"] = "觀海",
	[":s2_guanhui"] = "在一名角色的判定牌生效前，你可以弃置一张牌，然后展示牌堆顶的X张牌并选择其中一张代替之，将其余的牌置入弃牌堆。（X为你的攻击范围）",

} 

s2_huaxiong = sgs.General(extension_jx,"s2_huaxiong","qun","4")


s2_hengchong = sgs.CreateFilterSkill{
	name = "s2_hengchong", 
	view_filter = function(self,to_select)
		return (to_select:isKindOf("Jink") and to_select:getSuit() == sgs.Card_Diamond)
	end,
	view_as = function(self, originalCard)
		local slash = sgs.Sanguosha:cloneCard("duel", originalCard:getSuit(), originalCard:getNumber())
		slash:setSkillName(self:objectName())
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(slash)
		return card
	end
}

s2_mengzhuang = sgs.CreateTriggerSkill{
	name = "s2_mengzhuang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local from = damage.from
		if damage.card and damage.card:isKindOf("Slash") then
		room:askForUseCard(player, "Duel", "@s2_mengzhuang")
			end
	end
}

s2_huaxiong:addSkill(s2_hengchong)
s2_huaxiong:addSkill(s2_mengzhuang)

--http://tieba.baidu.com/p/1412051384
sgs.LoadTranslationTable{
	["s2_huaxiong"] = "华雄",
	["&s2_huaxiong"] = "华雄",
	["#s2_huaxiong"] = " 虎将",
	["designer:s2_huaxiong"] = "绝版刁民",
	
	["s2_hengchong"] = "横冲",
	[":s2_hengchong"] = "<font color=\"blue\"><b>锁定技，</b></font>你方块花色的【闪】始终视为【决斗】。 ",
	
	["s2_mengzhuang"] = "莽撞",
	[":s2_mengzhuang"] = "每当你受到【杀】造成的一次伤害后可以使用一次【决斗】。",
	["@s2_mengzhuang"] =  "你可以发动“莽撞”，使用一次【决斗】。",

} 


s2_2_guanxingzhangbao = sgs.General(extension_jx,"s2_2_guanxingzhangbao","shu","4")

s2_jiangmen = sgs.CreateTriggerSkill{
	name = "s2_jiangmen" ,
	events = {sgs.PreCardUsed},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.card:isBlack() then
				if (use.m_addHistory) then
					room:addPlayerHistory(player, use.card:getClassName(), -1)
					room:sendCompulsoryTriggerLog(player, self:objectName(), true)
					use.m_addHistory = false
					data:setValue(use)
				end
			end
		end
		return false
	end ,
}
s2_jiangmenTargetMod = sgs.CreateTargetModSkill{
	name = "#s2_jiangmen" ,
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if (player:hasSkill(self:objectName())) and (card:isRed()) then
			return 998
		end
		return 0
	end,
	residue_func = function(self, player, card)
		if player:hasSkill(self:objectName()) and card:isBlack()  then
			return 999
		end
	end,
}

s2_duanya = sgs.CreateTriggerSkill{
	name = "s2_duanya" ,
	events = {sgs.DamageDone, sgs.EventPhaseChanging} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageDone then
			local damage = data:toDamage()
			if damage.from and damage.from:isAlive() and (damage.from:hasSkill(self:objectName())) then
				room:addPlayerMark(damage.from, "s2_duanya", damage.damage)
				room:addPlayerMark(damage.from, "&s2_duanya-Clear", damage.damage)
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _,guanxingzhangbao in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if guanxingzhangbao:getMark("s2_duanya") >= 3 then
						local x = math.ceil(guanxingzhangbao:getMark("s2_duanya")/ 3)
						if (x > 0) then 
							room:sendCompulsoryTriggerLog(guanxingzhangbao, self:objectName(), true)
							for i = 1, x, 1 do 
								if not room:askForDiscard(guanxingzhangbao, self:objectName(), 2, 2, true) then
									room:loseHp(guanxingzhangbao)
									if guanxingzhangbao:isDead() then break end 
								end
							end
						end
					end
					room:setPlayerMark(guanxingzhangbao, "s2_duanya", 0)
				end
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}

s2_2_guanxingzhangbao:addSkill(s2_jiangmen)
s2_2_guanxingzhangbao:addSkill(s2_jiangmenTargetMod)
s2_2_guanxingzhangbao:addSkill(s2_duanya)
extension_jx:insertRelatedSkills("s2_jiangmen","#s2_jiangmen")

sgs.LoadTranslationTable{
	["s2_2_guanxingzhangbao"] = "关兴张苞",
	["&s2_2_guanxingzhangbao"] = "关兴张苞",
	["#s2_2_guanxingzhangbao"] = " 將門虎子",
	["designer:s2_2_guanxingzhangbao"] = "绝版刁民",
	
	["s2_jiangmen"] = "将门",
	[":s2_jiangmen"] = "<font color=\"blue\"><b>锁定技，</b></font>你在出牌阶段内使用黑【杀】时无次数限制；你的红【杀】无视距离限制。 ",
	["s2_duanya"] = "断崖",
	[":s2_duanya"] = "<font color=\"blue\"><b>锁定技，</b></font>一名角色的结束阶段开始时，若你于此回合内已造成3点或更多伤害，你每造成3点伤害，你需要失去一点体力或弃两张牌。",

} 
s2_liaohua = sgs.General(extension_jx,"s2_liaohua","shu","4")

s2_chifa = sgs.CreateTriggerSkill{
	name = "s2_chifa", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseEnd}, 
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish and not room:getTag("ExtraTurn"):toBool() and (player:getMark(self:objectName().."_lun") == 0) then
			room:addPlayerMark(player, self:objectName().."_lun")
				--if player:getMark("damage_point_play_phase") == 0 then
				--if player:getMark("damage_point_play_phase") == 0 then
					local room = player:getRoom()
					local judge = sgs.JudgeStruct()
			judge.pattern = ".|spade"
			judge.good = false
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if judge:isGood() then 
					player:addToPile("s2_fa", judge.card:getEffectiveId())
				end
				end
		--	end
		end
		return false
	end
}



s2_houqiCard = sgs.CreateSkillCard{
	name = "s2_houqi" ,
	will_throw = false ,
	target_fixed = true ,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		 room:throwCard(self, nil);
		 	local playerdata = sgs.QVariant()
				playerdata:setValue(source)
				room:setTag("s2_houqi", playerdata)
	end
}


s2_houqi = sgs.CreateViewAsSkill{
	name = "s2_houqi" ,
	n = 999,
	expand_pile = "s2_fa",
	view_filter = function(self, selected, to_select)
	if #selected > 0 then 
		if sgs.Self:getPile("s2_fa"):contains(selected[1]:getId()) then 
			if selected[1]:getSuit() == sgs.Card_Heart then 
		return false
		else 
		if #selected > 1 then 
		return false 
		else 
		 return sgs.Self:getPile("s2_fa"):contains(to_select:getId())
		 end
		end
		end
		else 
		return sgs.Self:getPile("s2_fa"):contains(to_select:getId())
		end
	end,
	view_as = function(self, cards)
			if #cards > 0 then 
			local acard = s2_houqiCard:clone()
			for _, c in ipairs(cards) do
				acard:addSubcard(c)
			end
			acard:setSkillName(self:objectName())
			if sgs.Sanguosha:getCard(cards[1]:getId()):getSuit() == sgs.Card_Heart and #cards == 1 then
			return acard
			else
			if #cards == 2 then
			return acard
			end
			end
			end
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		if  pattern == "@@s2_houqi"  then
			return (player:getPile("s2_fa"):length() > 0)
		end
	end,
}
s2_houqi_TM = sgs.CreateTriggerSkill{
	name = "#s2_houqi" ,
	events = {sgs.EventPhaseStart} ,
	view_as_skill = s2_houqiVS,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Finish then return false end
		local yuejin = room:findPlayerBySkillName(self:objectName())
		if not yuejin  then return false end
		if yuejin:getPile("s2_fa"):length() > 0  then
			room:askForUseCard(yuejin, "@@s2_houqi", "@s2_houqi")
		end
		return false
	end
}
s2_houqiGive = sgs.CreateTriggerSkill{
	name = "#s2_houqi-give" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("s2_houqi") then
			local target = room:getTag("s2_houqi"):toPlayer()
			room:removeTag("s2_houqi")
			if target and target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end ,
	priority = 1
}

s2_liaohua:addSkill(s2_chifa)
s2_liaohua:addSkill(s2_houqi)
s2_liaohua:addSkill(s2_houqiGive)
s2_liaohua:addSkill(s2_houqi_TM)
extension_jx:insertRelatedSkills("s2_houqi","#s2_houqi-give")
extension_jx:insertRelatedSkills("s2_houqi","#s2_houqi")


sgs.LoadTranslationTable{
	["s2_liaohua"] = "廖化",
	["&s2_liaohua"] = "廖化",
	["#s2_liaohua"] = " 末蜀的先鋒",
	["designer:s2_liaohua"] = "绝版刁民",
	
	["s2_chifa"] = "迟发",
	--[":s2_chifa"] = "出牌阶段，若你未使用以其他角色为目标的牌，回合结束后可进行一次判定：若结果不为黑桃，则将判定牌置于你将牌上作为你的“发”。你“发”的数量最多不能超过场上存活角色的数量。 ",
	--[":s2_chifa"] = "若你于你的出牌阶段未造成伤害，结束阶段开始时，你可进行一次判定：若结果不为黑桃，则将判定牌置于你将牌上作为你的“发”。 ",
	[":s2_chifa"] = "当你不因“后起”的结束阶段开始时，你可进行一次判定：若结果不为黑桃，则将判定牌置于你将牌上作为你的“发”。 ",
	["s2_fa"] = "发",
	
	["s2_houqi"] = "后起",
	[":s2_houqi"] = "一名角色回合结束后，你可以弃两张“发”或弃一张红色“发”，获得一个额外的回合。",
	["@s2_houqi"] = "你可以发动“后起”",
	["~s2_houqi"] = "选择两张“发”或选择一张红色“发”→点击确定",
} 



s2_liubiao = sgs.General(extension_jx,"s2_liubiao","qun","4", true)

s2_yongbing = sgs.CreateTriggerSkill{
	name = "s2_yongbing" ,
	events = {sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		local can_invoke = false 
		if change.to == sgs.Player_Draw  then
			if not player:isSkipped(sgs.Player_Draw) then 
			if  player:askForSkillInvoke(self:objectName()) then
				player:skip(sgs.Player_Draw)
				can_invoke = true
				end
			else 
			if  player:askForSkillInvoke(self:objectName()) then
			can_invoke = true
			end
			end
			if can_invoke then 
			room:loseHp(player)
			if player:isDead() then return false end 
			local card = sgs.Sanguosha:cloneCard("amazing_grace", sgs.Card_NoSuit, 0)
			card:setSkillName("s2_yongbing")
			card:deleteLater()
			local use = sgs.CardUseStruct()
			use.from = player
			use.card = card
			room:useCard(use, false)
			end
		end
		return false
	end
}

s2_lixian = sgs.CreateTriggerSkill{
	name = "s2_lixian" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.CardEffected} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("AmazingGrace") then				
				if effect.from and effect.from:isAlive() and effect.from:hasSkill(self:objectName()) then
					can_invoke = true
				end
			end
			if not can_invoke then return false end 
			if effect.card:isKindOf("AmazingGrace") then
				if room:isCanceled(effect) then
					effect.to:setFlags("Global_NonSkillNullify")
					return true;
				end
				if  effect.from:isAlive() then 
				if effect.to:objectName() == effect.from:objectName() then
				room:setPlayerMark(effect.from, self:objectName(), 1)
					local aglist = room:getTag("AmazingGrace"):toIntList()
					room:fillAG(aglist)
					local basic = 0 
					local equip = 0 
					local trick = 0 
					for _, card_id in sgs.qlist(aglist) do
					local card = sgs.Sanguosha:getCard(card_id)
					if card:isKindOf("BasicCard") then 
					basic = basic + 1 
					elseif card:isKindOf("EquipCard") then 
					equip = equip + 1 
					elseif card:isKindOf("TrickCard") then 
					trick = trick + 1 
					end
					end 
					local choicelist = "cancel"
					if basic > 0 then 
					choicelist = string.format("%s+%s", choicelist, "s2_lixian_basic")
					end
					if equip > 0 then 
					choicelist = string.format("%s+%s", choicelist, "s2_lixian_equip")
					end 
					if trick > 0 then 
					choicelist = string.format("%s+%s", choicelist, "s2_lixian_trick") 
					end 
					local choice = room:askForChoice(effect.from, self:objectName(), choicelist)
					for i = 0, aglist:length(), 1 do 
					for _, card_id in sgs.qlist(aglist) do
							local card = sgs.Sanguosha:getCard(card_id)
							if choice == "s2_lixian_basic" then
							if card:isKindOf("BasicCard") then 
							aglist:removeOne(card_id)
							room:obtainCard(effect.from,sgs.Sanguosha:getCard(card_id))
							end 
							elseif choice == "s2_lixian_equip" then 
							if card:isKindOf("EquipCard") then 
							aglist:removeOne(card_id)
							room:obtainCard(effect.from,sgs.Sanguosha:getCard(card_id))
							end 
							elseif choice == "s2_lixian_trick" then 
							if card:isKindOf("TrickCard") then 
							aglist:removeOne(card_id)
							room:obtainCard(effect.from,sgs.Sanguosha:getCard(card_id))
							end 
							end
							end
							end 
								local tos = sgs.SPlayerList()
								for _,p in sgs.qlist(room:getOtherPlayers(effect.from)) do
							if not effect.from:isProhibited(p, effect.card)  then
								tos:append(p)
							end
						end
								if aglist:length() > 0 then 
								while true do 
								local target = room:askForPlayerChosen(effect.from, tos, self:objectName())
								local  card_id = room:askForAG(target, aglist, false, self:objectName())
								aglist:removeOne(card_id)
								room:obtainCard(target,sgs.Sanguosha:getCard(card_id))
								-- room:takeAG(target, card_id)
								tos:removeOne(target)	
								if aglist:length() < 1  then
								break end 								
								end 
								end 
								room:clearAG()
								local jink_data = sgs.QVariant()
		jink_data:setValue(aglist)
								 room:setTag("AmazingGrace", jink_data)
								return true 
					elseif effect.to:objectName() ~= effect.from:objectName() then 
						
						return true 
						end 
				end
				end
				end
			
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end,
	priority = 1,
}
s2_liubiao:addSkill(s2_yongbing)
s2_liubiao:addSkill(s2_lixian)
--http://tieba.baidu.com/p/1412051384
sgs.LoadTranslationTable{
	["s2_liubiao"] = "刘表",
	["&s2_liubiao"] = "刘表",
	["#s2_liubiao"] = " 八俊儒士",
	["designer:s2_liubiao"] = "绝版刁民",
	
	["s2_yongbing"] = "拥兵",
	[":s2_yongbing"] = "你若失去或跳过你的摸牌阶段，可失去一点体力。如若此做，视为你使用了一张【五谷丰登】。",
	
	["s2_lixian"]  = "礼贤",
	[":s2_lixian"] = "每当你使用【五谷丰登】后，立即获得亮出牌（基本牌、装备牌、锦囊牌）的一类，剩余的牌按照你指定的顺序由其他角色继续选择。",
	["s2_lixian_basic"] = "获得基本牌",
	["s2_lixian_equip"] = "获得装备牌",
	["s2_lixian_trick"] = "获得锦囊牌",
	
} 


s2_quyi = sgs.General(extension_jx,"s2_quyi","qun","4")

s2_jianzu = sgs.CreateTriggerSkill{
	name = "s2_jianzu", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventAcquireSkill, sgs.EventLoseSkill,sgs.GameStart, sgs.CardsMoveOneTime},  
		on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventLoseSkill then
			if data:toString()=="s2_jianzu" then
				 room:handleAcquireDetachSkills(player, "-luanji", true)
			player:setMark("s2_jianzu_luanji", 0)
			end
		elseif ((event == sgs.EventAcquireSkill and data:toString()=="s2_jianzu") or event == sgs.GameStart ) then
			if player:hasWeapon("crossbow") or 
			player:hasWeapon("kylin_bow") then 			
				 room:handleAcquireDetachSkills(player, "luanji", true)
			player:setMark("s2_jianzu_luanji", 1)
			 room:notifySkillInvoked(player, self:objectName())
			end
		elseif event == sgs.CardsMoveOneTime and player:isAlive()  then 
		local move = data:toMoveOneTime()
		if move.from and  move.from_places:contains(sgs.Player_PlaceEquip) then 
		if  not (player:hasWeapon("crossbow") or 
			player:hasWeapon("kylin_bow")) and player:getMark("s2_jianzu_luanji") == 1  then 	
			room:handleAcquireDetachSkills(player, "-luanji", true)
			player:setMark("s2_jianzu_luanji", 0)
			end
			elseif move.to and move.to_place == sgs.Player_PlaceEquip then 
			   if ((player:hasWeapon("crossbow") or 
			player:hasWeapon("kylin_bow")) and player:getMark("s2_jianzu_luanji") == 0) then 
					room:handleAcquireDetachSkills(player, "luanji", true);
					player:setMark("s2_jianzu_luanji", 1)
			end 
		end
		end 
	end,
}

s2_kema = sgs.CreateDistanceSkill{
	name = "s2_kema" ,
	correct_func = function(self, from, to)
		local correct = 0
		if from:hasSkill(self:objectName()) and (from:getHp() <= 2) then
			correct = correct - 1
		end
		return correct
	end
}
s2_quyi:addSkill(s2_jianzu)
s2_quyi:addSkill(s2_kema)
s2_quyi:addRelateSkill("luanji")

--http://tieba.baidu.com/p/1534078895
sgs.LoadTranslationTable{
	["s2_quyi"] = "麴义",
	["&s2_quyi"] = "麴义",
	["#s2_quyi"] = " 骑兵克星",
	["designer:s2_quyi"] = "占士邦大家长",
	
	["s2_jianzu"] = "箭祖",
	[":s2_jianzu"] = "<font color=\"blue\"><b>锁定技，</b></font>若你的装备区有诸葛连弩或麒麟弓，视为你拥有技能“乱击”。",
	
	["s2_kema"] = "克馬",
	[":s2_kema"] = "<font color=\"blue\"><b>锁定技，</b></font>若你当前的体力值小于或等于2，你计算的与其他角色的距离-1。",
	
	
} 

s2_tairuier = sgs.General(extension_jx,"s2_tairuier","god","4")

s2_shengjian = sgs.CreateTriggerSkill{
	name = "s2_shengjian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
		local damage = data:toDamage()
		local reason = damage.card
		if reason then
			if reason:isKindOf("Slash") and damage.from and damage.from:getWeapon() ~= nil  then
				damage.damage = damage.damage + 1
				data:setValue(damage)
				local log= sgs.LogMessage()
	log.type = "#skill_add_damage"
		log.from = damage.from
		log.to:append(damage.to)
		log.arg = self:objectName()
		log.arg2  = damage.damage
		room:sendLog(log)
			end
		end
		return false
	end,
}

s2_zhengyi = sgs.CreateTriggerSkill{
	name = "s2_zhengyi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.to:isDead() then
			return false
		end
		for _, caiwenji in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
		local dest = sgs.QVariant()
dest:setValue(damage)		
			if room:askForSkillInvoke(caiwenji, self:objectName(), dest) then
				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.good = true
				judge.play_animation = false
				judge.who = player
				judge.reason = self:objectName()
				room:judge(judge)
				if judge.card:isRed() then
					room:recover(player, sgs.RecoverStruct(caiwenji))
					player:drawCards(1, self:objectName())
				elseif judge.card:isBlack() then
					if damage.from and damage.from:isAlive() then
						room:askForDiscard(damage.from, self:objectName(), 1, 1, false, true)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
--http://tieba.baidu.com/p/1592584320
s2_tairuier:addSkill(s2_shengjian)
s2_tairuier:addSkill(s2_zhengyi)
sgs.LoadTranslationTable{
	["s2_tairuier"] = "泰瑞尔",
	["&s2_tairuier"] = "泰瑞尔",
	["#s2_tairuier"] = " 天使长",
	["designer:s2_tairuier"] = "殺龍戰士",
	
	["s2_shengjian"] = "圣剑",
	[":s2_shengjian"] = "<font color=\"blue\"><b>锁定技，</b></font>若你的装备区有武器牌，你使用的【杀】造成的伤害+1。",
	["s2_zhengyi"] = "正义",
	[":s2_zhengyi"] = "每当一名角色受到一次伤害后，你可以令其进行一次判定，判定结果为：红色 该角色回复1点体力并摸一张牌；黑色 伤害来源弃置一张牌。",
	
} 

s2_god_zhugeliang = sgs.General(extension_jx,"s2_god_zhugeliang","god","7")

s2_shensuan = sgs.CreateTriggerSkill{
	name = "s2_shensuan" ,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed, sgs.CardEffected} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if (not use.to:contains(player)) or (not use.card:isKindOf("TrickCard")) or not use.card:isNDTrick() then
				return false
			end
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|heart"
			judge.good = false
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
			if judge:isGood() and player:isAlive() then
			player:setTag("s2_shensuan", sgs.QVariant(use.card:toString()))
			end
		else
			if (not player:isAlive()) or (not player:hasSkill(self:objectName())) then return false end
			local effect = data:toCardEffect()
			if player:getTag("s2_shensuan") == nil or (player:getTag("s2_shensuan"):toString() ~= effect.card:toString()) then return false end
			player:setTag("s2_shensuan", sgs.QVariant(""))
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
			return true
		end
		return false
	end
}


s2_xingyi = sgs.CreateTriggerSkill{
	name = "s2_xingyi" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:isKongcheng()
				and player:getHp() ==  1) or player:canWake(self:objectName()) then
		local skill_names = {}
		local skill_name
		local ac_dt_list = {}
		local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
		for _,skill in sgs.qlist(target:getVisibleSkillList())do
				if skill:isLordSkill() or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake then
					continue
				end
				if not table.contains(skill_names,skill:objectName()) then
					table.insert(skill_names,skill:objectName())
				end
			end
			if #skill_names > 0 then
				skill_name = room:askForChoice(player, "s2_xingyi",table.concat(skill_names,"+"))
			end
			if skill_name ~= "" then
			table.insert(ac_dt_list,skill_name)
		end
		room:handleAcquireDetachSkills(player, table.concat(ac_dt_list,"|"), true)
		room:handleAcquireDetachSkills(target, "-"..skill_name, false, true, true)
		-- room:detachSkillFromPlayer(target, skill_name)
		room:addPlayerMark(player, "s2_xingyi")
		room:addPlayerMark(player, "&s2_xingyi+:+"..skill_name)
		room:addPlayerMark(target, "&s2_xingyi+to+#".. player:objectName() .."+:+"..skill_name)
		room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
	end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getMark("s2_xingyi") == 0)
				and (target:getPhase() == sgs.Player_Start)
				
	end
}
s2_huandou = sgs.CreatePhaseChangeSkill{
	name = "s2_huandou",
	frequency = sgs.Skill_Frequent,
	on_phasechange = function(self, player)
	local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "s2_huandou-invoke", true, true)
			if not target then return false end
				room:loseMaxHp(player)
				player:turnOver()
				room:loseHp(target)
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
		end
	end
}

s2_guimouVS=sgs.CreateViewAsSkill{
	name="s2_guimou",
	n=1,
	response_or_use = true,
	view_filter=function(self,selected,to_select)
		return true
	end,
view_as=function(self,cards)
	if #cards==0 then return nil end
		local card_id=sgs.Self:getMark("s2_guimouskill")
		local card=sgs.Sanguosha:getCard(card_id)
		local acard=cards[1]
		local new_card=sgs.Sanguosha:cloneCard(card:objectName(),acard:getSuit(),acard:getNumber())
		new_card:addSubcard(cards[1])
		new_card:setSkillName(self:objectName())
		return new_card
	end,
	enabled_at_play=function(self, player)
		return player:hasFlag("s2_guimoux") 
	end,
}


s2_guimou = sgs.CreateTriggerSkill{
	name = "s2_guimou",
	events = {sgs.CardUsed},
	view_as_skill = s2_guimouVS,
	--frequency = sgs.Skill_Frequent,
	on_trigger = function(self,event,player,data)
	local room = player:getRoom()
	local card = data:toCardUse().card
	if (player:getPhase() ~= sgs.Player_Play) then return false end
	if event==sgs.CardUsed and not player:hasFlag("s2_guimouused") and not card:isKindOf("Nullification")  then
		if  card:isNDTrick() then
				room:setPlayerFlag(player,"s2_guimoux")
				if not card:isVirtualCard() then
				local card_id=card:getEffectiveId()
				room:setPlayerMark(player,"s2_guimouskill",card_id)
				for _, mark in sgs.list(player:getMarkNames()) do
						if string.find(mark, "s2_guimouUsed") and player:getMark(mark) > 0 then
							room:setPlayerMark(player, mark, 0)
						end
					end
					room:setPlayerMark(player, "&s2_guimouUsed+:+" .. card:objectName() .. "-".. player:getPhase() .."Clear", 1)

				end
				if card:getSkillName() == "s2_guimou" then
					room:setPlayerFlag(player,"s2_guimouused")
					room:setPlayerFlag(player,"-s2_guimoux")
				end
			end
		end
	end
}

s2_god_zhugeliang:addSkill(s2_shensuan)
s2_god_zhugeliang:addSkill(s2_guimou)
s2_god_zhugeliang:addSkill(s2_huandou)
s2_god_zhugeliang:addSkill(s2_xingyi)
--http://tieba.baidu.com/p/1617084079
sgs.LoadTranslationTable{
	["s2_god_zhugeliang"] = "诸葛亮",
	["&s2_god_zhugeliang"] = "诸葛亮",
	["#s2_god_zhugeliang"] = " 大汉军师",
	["designer:s2_god_zhugeliang"] = "卡嘎猴",
	
	["s2_shensuan"] = "神算",
	["$s2_shensuan1"] = "一曲将罢，他定会退兵。",
	["$s2_shensuan2"] = "虚者虚之，疑中生疑。",
	[":s2_shensuan"] = "<font color=\"blue\"><b>锁定技，</b></font>任何非延时类锦囊指定你为目标时，你进行判定，若结果不为红桃，则该锦囊对你无效。 ",
	
	["s2_xingyi"] = "星移",
	["$s2_xingyi1"] = "斗转星移，七星借命",
	["$s2_xingyi2"] = "弗忘天恩，势讨汉贼",
	[":s2_xingyi"] = "<font color=\"purple\"><b>觉醒技，</b></font>回合开始阶段，若你没有手牌，且体力为1时，你可以获得场上任意角色的一项技能，并使该角色失去此技能至游戏结束。 ",
	
	["s2_huandou"] = "换斗",
	["$s2_huandou1"] = "奇亦为正之正，正亦为奇之奇，彼此相穷，循环无穷。",
	["$s2_huandou2"] = "顺天，因时，依人，以利胜。",
	[":s2_huandou"] = "回合结束阶段，你可以选择失去一点体力上限，并将你的武将牌翻面。使一名角色流失一点体力。",
	["s2_huandou-invoke"]  =  "你可以发动“换斗”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	
	["s2_guimouUsed"] = "鬼谋",
	["s2_guimou"] = "鬼谋",
	["$s2_guimou1"] = "一举大胜，天之利",
	["$s2_guimou2"] = "多应借得，赤壁东风。",
	[":s2_guimou"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张牌当作你本回合内前一张使用的锦囊使用。",
} 


s2_guansuo = sgs.General(extension_jx,"s2_guansuo","shu","4")

s2_congfu = sgs.CreateTriggerSkill{
	name = "s2_congfu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local judge = sgs.JudgeStruct()
			judge.pattern = ".|black"
			judge.good = true
			judge.reason = self:objectName()
			judge.who = player
			judge.play_animation = false
			room:judge(judge)
			if judge:isGood() then 
					-- room:handleAcquireDetachSkills(player, "wusheng", true)
					room:acquireOneTurnSkills(player, "s2_congfu", "wusheng")
					room:broadcastSkillInvoke(self:objectName())
				end 
			end
		end
	end
}

s2_yizeiCard = sgs.CreateSkillCard{
	name = "s2_yizei",
	filter = function(self, targets, to_select, player)
		if to_select:objectName() == player:objectName() then return false end
		if #targets == 0 then
			return true
		elseif #targets == 1 then
		if targets[1]:getHp() > sgs.Self:getHp() then
			return to_select:getHp() <= sgs.Self:getHp()
		else
			return to_select:getHp() > sgs.Self:getHp() and not to_select:isKongcheng()
			end
		end
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local from, to
		if targets[1]:getHp() <= source:getHp() then
			from = targets[2]
			to = targets[1]
		else
			from = targets[1]
			to = targets[2]
		end
		if from:isKongcheng() then return false end
		local id = room:askForCardChosen(source, from, "h", "s2_yizei")
		local cd = sgs.Sanguosha:getCard(id)
		source:obtainCard(cd)
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), to:objectName(), "s2_yizei","")
		room:moveCardTo(cd,to,sgs.Player_PlaceHand,reason)
		
	end
}
s2_yizei = sgs.CreateZeroCardViewAsSkill{
	name = "s2_yizei",
	view_as = function() 
		return s2_yizeiCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#s2_yizei")
	end,
}

s2_guansuo:addSkill(s2_congfu)
s2_guansuo:addSkill(s2_yizei)
s2_guansuo:addRelateSkill("wusheng")
sgs.Sanguosha:setAudioType("s2_guansuo","wusheng","7")
--http://tieba.baidu.com/p/1621479361
sgs.LoadTranslationTable{
	["s2_guansuo"] = "关索",
	["&s2_guansuo"] = "关索",
	["#s2_guansuo"] = " 年轻的美少年",
	["designer:s2_guansuo"] = "豆腐白菜花",
	
	["s2_congfu"] = "从父",
	[":s2_congfu"] = "准备阶段开始时，你可进行一次判定，若判定结果为黑色，你获得技能‘武圣’直到回合结束。",
	["$s2_congfu"] = "逆賊，可識得關氏之勇？",
	
	["s2_yizei"] = "义贼",
	[":s2_yizei"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可获得体力值多于你的一名其他角色的一张手牌，将该给体力值不多于你的一名其他角色。",
	
} 

s2_2_guanyu = sgs.General(extension_jx,"s2_2_guanyu","shu","3")

s2_baizou = sgs.CreateTriggerSkill{
	name = "s2_baizou" ,
	events = {sgs.Pindian} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pindian = data:toPindian()
		local can_invoke = false
		local jianyong = nil
		if (pindian.from and pindian.from:isAlive() and pindian.from:hasSkill(self:objectName())) then
			jianyong = pindian.from
			if pindian.from_number <= pindian.to_number then
				can_invoke = true
			end
		elseif (pindian.to and pindian.to:isAlive() and pindian.to:hasSkill(self:objectName())) then
			jianyong = pindian.to
			if pindian.from_number > pindian.to_number then
				can_invoke = true
			end
		end
		if jianyong and can_invoke  then
			jianyong:turnOver()
			room:sendCompulsoryTriggerLog(jianyong, self:objectName(), true)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}


s2_hungui = sgs.CreateTriggerSkill{
	name = "s2_hungui",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
			local damage = death.damage
			if damage then
				local murderer = damage.from
				if murderer then
					local room = player:getRoom()
					room:loseHp(murderer, murderer:getHp())
					room:sendCompulsoryTriggerLog(player, self:objectName(), true)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		if target then
			return target:hasSkill(self:objectName())
		end
		return false
	end
}

s2_zhanjiangCard = sgs.CreateSkillCard{
	name = "s2_zhanjiang",

	filter = function(self, targets, to_select)
		return #targets == 0 and (not to_select:isKongcheng()) and to_select:objectName() ~= sgs.Self:objectName() and to_select:getHp() < sgs.Self:getHp()
	end,

	on_use = function(self, room, source, targets)
		local success = source:pindian(targets[1], "s2_zhanjiang", nil)
		if success then
			room:loseHp(targets[1], targets[1]:getHp())
		end
	end
}
s2_zhanjiang = sgs.CreateZeroCardViewAsSkill{
	name = "s2_zhanjiang",
	view_as = function(self) 
		return s2_zhanjiangCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#s2_zhanjiang") and not player:isKongcheng()
	end, 
}

s2_2_guanyu:addSkill(s2_zhanjiang)
s2_2_guanyu:addSkill(s2_baizou)
s2_2_guanyu:addSkill(s2_hungui)

--http://tieba.baidu.com/p/1417020680?pn=1
sgs.LoadTranslationTable{
	["s2_2_guanyu"] = "关羽",
	["&s2_2_guanyu"] = "关羽",
	["#s2_2_guanyu"] = " 忠义的武圣",
	["designer:s2_2_guanyu"] = "owmasxiao",
	
	["s2_baizou"] = "败走",
	[":s2_baizou"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你拼点没赢，你将你的武将牌翻面。",
	
	["s2_hungui"] = "魂归",
	[":s2_hungui"] = "<font color=\"blue\"><b>锁定技，</b></font>你死亡时，杀死你的角色进入濒死状态。",
	
	["s2_zhanjiang"] = "斩将",
	[":s2_zhanjiang"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以与一名体力值比你少的其他角色拼点。若你赢，其进入濒死状态。",
} 

s2_2_zhaoyun = sgs.General(extension_jx,"s2_2_zhaoyun","shu","4")



s2_changsheng = sgs.CreateTriggerSkill{
	name = "s2_changsheng" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.CardEffected } ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("Duel") then				
				if effect.from and effect.from:isAlive() and effect.from:hasSkill(self:objectName()) then
					can_invoke = true
				end
				if effect.to and effect.to:isAlive() and effect.to:hasSkill(self:objectName()) then
					can_invoke = true
				end
			end
			if not can_invoke then return false end
			if effect.card:isKindOf("Duel") then
				if room:isCanceled(effect) then
					effect.to:setFlags("Global_NonSkillNullify")
					return true;
				end
				if effect.to:isAlive() then
					local second = effect.from
					local first = effect.to
					room:setEmotion(first, "duel");
					room:setEmotion(second, "duel")
					local winer = nil 
					local loser = nil
					if effect.to:hasSkill(self:objectName()) then 
					winer = effect.to
					loser = effect.from
					end 
					if effect.from:hasSkill(self:objectName()) then 
					winer = effect.from
					loser = effect.to
					end 
					if effect.to:hasSkill(self:objectName()) and effect.from:hasSkill(self:objectName()) then 
					return false end 
					if not effect.to:hasSkill(self:objectName()) and not  effect.from:hasSkill(self:objectName()) then 
					return false end 
					local damage = sgs.DamageStruct(effect.card,  winer, loser)
					if second:objectName() ~= effect.from:objectName() then
						damage.by_user = false;
					end
					room:sendCompulsoryTriggerLog(winer, self:objectName(), true)
					room:damage(damage)
				end
				room:setTag("SkipGameRule",sgs.QVariant(tonumber(event)))
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end,
	priority = 1,
}
s2_baima = sgs.CreateDistanceSkill{
	name = "s2_baima",
	correct_func = function(self, from, to)
		if to:hasSkill("s2_baima") then
			return 1
		else
			return 0
		end
	end
}

s2_danqi = sgs.CreateTriggerSkill{
	name = "s2_danqi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
				if room:askForSkillInvoke(player, self:objectName()) then
					local x = player:getHp()
					local has_heart = false
					local ids = room:getNCards(x, false)
					local move = sgs.CardsMoveStruct()
					move.card_ids = ids
					move.to = player
					move.to_place = sgs.Player_PlaceTable
					move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
					room:moveCardsAtomic(move, true)
					local card_to_throw = {}
					local card_to_gotback = {}
					for i=0, x-1, 1 do
						local id = ids:at(i)
						local card = sgs.Sanguosha:getCard(id)
						if card:isKindOf("Slash") then
							table.insert(card_to_throw, id)
						else
							table.insert(card_to_gotback, id)
						end
					end
					if #card_to_throw > 0 then
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, id in ipairs(card_to_throw) do
							dummy:addSubcard(id)
						end 
						room:setPlayerMark(player, self:objectName(), #card_to_throw)
						room:setPlayerMark(player, "&s2_danqi-Clear", #card_to_throw)
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
						room:throwCard(dummy, reason, nil)
						has_heart = true
					end
					if #card_to_gotback > 0 then
						local dummy2 = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, id in ipairs(card_to_gotback) do
							dummy2:addSubcard(id)
						end
						room:obtainCard(player, dummy2)
					end
					return true
			end
		elseif player:getPhase() == sgs.Player_NotActive then 
		room:setPlayerMark(player, self:objectName(), 0)
		end
		return false
	end
}
s2_danqiBuff = sgs.CreateTriggerSkill{
	name = "#s2_danqiBuff",
	frequency = sgs.Skill_Frequent,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local reason = damage.card
		if reason then
			if reason:isKindOf("Slash") then
				damage.damage = damage.damage + player:getMark("s2_danqi")
				data:setValue(damage)
				local log= sgs.LogMessage()
	log.type = "#skill_add_damage"
		log.from = damage.from
		log.to:append(damage.to)
		log.arg = "s2_danqi"
		log.arg2  = damage.damage
		player:getRoom():sendLog(log)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if (target:getMark("s2_danqi") > 0)  then
				return target:isAlive()
			end
		end
		return false
	end
}


s2_2_zhaoyun:addSkill(s2_changsheng)
s2_2_zhaoyun:addSkill(s2_danqiBuff)
s2_2_zhaoyun:addSkill(s2_danqi)
s2_2_zhaoyun:addSkill(s2_baima)
extension_jx:insertRelatedSkills("s2_danqi","#s2_danqiBuff")

--http://tieba.baidu.com/p/1417020680?pn=1
sgs.LoadTranslationTable{
	["s2_2_zhaoyun"] = "赵云",
	["&s2_2_zhaoyun"] = "赵云",
	["#s2_2_zhaoyun"] = " 长阪的战神",
	["designer:s2_2_zhaoyun"] = "owmasxiao",
	
	["s2_changsheng"] = "常胜",
	[":s2_changsheng"] = "<font color=\"blue\"><b>锁定技，</b></font>当你使用【决斗】或成为【决斗】的目标，均视为你赢。",
	
	["s2_baima"] = "白马",
	[":s2_baima"] = "<font color=\"blue\"><b>锁定技，</b></font>其他角色与你的距离+1。",
	
	["s2_danqi"] = "單騎",
	[":s2_danqi"] = "摸牌阶段开始时，你可以放弃摸牌，改为从牌堆顶亮出X张牌（X为你的体力值），你使用的【杀】造成的伤害+Y，直到回合结束，然后将这些【杀】置入弃牌堆，并获得其余的牌。（Y为其中【杀】的数量）",
} 



s2_2_machao = sgs.General(extension_jx,"s2_2_machao","shu","4")

s2_tianjiang = sgs.CreateTriggerSkill{
	name = "s2_tianjiang" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if use.from and (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			local _data = sgs.QVariant()
			_data:setValue(p)
			if player:askForSkillInvoke(self:objectName(), _data) then
				p:setFlags("s2_tianjiangTarget")
				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.good = true
				judge.reason = self:objectName()
				judge.who = player
				player:getRoom():judge(judge)
				if judge.card:getSuitString() == "heart" then
				local log= sgs.LogMessage()
	log.type = "#skill_cant_jink"
		log.from = player
		log.to:append(p)
		log.arg = self:objectName()
		room:sendLog(log)
					jink_table[index] = 0
				elseif judge.card:getSuitString() == "diamond" then 
				if not p:isNude() then 
				local card_id = room:askForCardChosen(player,p,"he",self:objectName())
						room:obtainCard(player,sgs.Sanguosha:getCard(card_id), false)
						end
				elseif judge.card:getSuitString() == "spade" then 
				player:setFlags("s2_tianjiang")
				  room:setCardFlag(use.card, "s2_tianjiang")
				elseif judge.card:getSuitString() == "club" then 
				p:turnOver()
				end
				p:setFlags("-s2_tianjiangTarget")
			end
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	end
	
}

s2_tianjiangBuff = sgs.CreateTriggerSkill{
	name = "#s2_tianjiangBuff",
	frequency = sgs.Skill_Frequent,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local reason = damage.card
		if reason  and reason:hasFlag("s2_tianjiang") then
			if reason:isKindOf("Slash")  then
				damage.damage = damage.damage + 1
				data:setValue(damage)
				local log= sgs.LogMessage()
	log.type = "#skill_add_damage"
		log.from = damage.from
		log.to:append(damage.to)
		log.arg = "s2_tianjiang"
		log.arg2  = damage.damage
		player:getRoom():sendLog(log)
		player:setFlags("-s2_tianjiang")
				
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:hasFlag("s2_tianjiang") then
				return target:isAlive()
			end
		end
		return false
	end
}

s2_tieji = sgs.CreateTriggerSkill{
	name = "s2_tieji",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local reason = damage.card
		if reason  then
			if reason:isKindOf("Slash")  then
				damage.damage = damage.damage + 1
				data:setValue(damage)
				local log= sgs.LogMessage()
	log.type = "#skill_add_damage"
		log.from = damage.from
		log.to:append(damage.to)
		log.arg = self:objectName()
		log.arg2  = damage.damage
		player:getRoom():sendLog(log)
				
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:hasSkill(self:objectName()) then
				return target:isAlive() and (target:getOffensiveHorse() ~= nil or target:getDefensiveHorse() ~= nil )
			end
		end
		return false
	end
}
s2_2_machao:addSkill(s2_tianjiang)
s2_2_machao:addSkill(s2_tianjiangBuff)
s2_2_machao:addSkill(s2_tieji)
extension_jx:insertRelatedSkills("s2_tianjiang","#s2_tianjiangBuff")
--http://tieba.baidu.com/p/1417020680?pn=1
sgs.LoadTranslationTable{
	["s2_2_machao"] = "马超",
	["&s2_2_machao"] = "马超",
	["#s2_2_machao"] = " 西凉的勇士",
	["designer:s2_2_machao"] = "owmasxiao",
	
	["s2_tianjiang"] = "天将",
	[":s2_tianjiang"] = "当你使用【杀】指定一名角色为目标后，你可以进行一次判定，若判定结果为：红桃 该角色不可以使用【闪】对此【杀】进行响应；方块 你可以获得对方的一张牌；梅花 对方将其武将牌翻面；黑桃 你使用的【杀】造成的伤害+1。",
	
	["s2_tieji"] = "铁骑",
	[":s2_tieji"] = "<font color=\"blue\"><b>锁定技，</b></font>当你的装备区中有马匹，你使用的【杀】造成的伤害+1。",
} 


s2_2_zhangfei = sgs.General(extension_jx,"s2_2_zhangfei","shu","3")

s2_nuhou = sgs.CreateTriggerSkill{
	name = "s2_nuhou" ,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed, sgs.CardEffected} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if (not use.to:contains(player)) or (not use.card:isKindOf("TrickCard")) or not use.card:isNDTrick() then
				return false
			end
			if use.from:objectName() == player:objectName() then return false end 
			local prompt = string.format("@s2_nuhou-give:%s:%s", player:objectName(), use.card:objectName())
			room:broadcastSkillInvoke(self:objectName(), math.random(2))
			local card = player:getRoom():askForCard(use.from,".Basic",prompt,data, sgs.Card_MethodNone)
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			if not card then
					player:setTag("s2_nuhou", sgs.QVariant(use.card:toString()))
					else  
					player:obtainCard(card)
				end
		else
			if (not player:isAlive()) or (not player:hasSkill(self:objectName())) then return false end
			local effect = data:toCardEffect()
			if player:getTag("s2_nuhou") == nil or (player:getTag("s2_nuhou"):toString() ~= effect.card:toString()) then return false end
			player:setTag("s2_nuhou", sgs.QVariant(""))
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			return true
		end
		return false
	end
}

s2_haojiu = sgs.CreateTriggerSkill{
	name = "s2_haojiu" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.CardUsed, sgs.CardResponded} ,
	on_trigger = function(self, event, player, data)
		local card
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponded then
			card = data:toCardResponse().m_card
		end
		if card:isKindOf("Analeptic") then
		room:sendCompulsoryTriggerLog(player,self:objectName(), true)
			local dest = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName())
			room:setPlayerFlag(dest, "s2_haojiu")
			local choice = room:askForChoice(player, self:objectName(), "s2_haojiu_losthp+s2_haojiu_draw")
			room:setPlayerFlag(dest, "-s2_haojiu")
			if choice == "s2_haojiu_draw" then 
			dest:drawCards(1, self:objectName())
			player:drawCards(1, self:objectName())
			else
			room:loseHp(dest)
			room:loseHp(player)
			end 
		end
	end
}

s2_cansi = sgs.CreateTriggerSkill{
	name = "s2_cansi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		local source
		if dying.who:objectName() ~= player:objectName() then
			return false
		end
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|heart"
			judge.good = true
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if judge:isBad()  then
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
				if  dying.damage and dying.damage.from then
		source =dying.damage.from 
		local deathdamage = sgs.DamageStruct()
			deathdamage.from = source
			room:killPlayer(player,deathdamage)
			else 
			room:killPlayer(player)
		end 
		return false
	end
	end
}

s2_2_zhangfei:addSkill(s2_nuhou)
s2_2_zhangfei:addSkill(s2_haojiu)
s2_2_zhangfei:addSkill(s2_cansi)
--http://tieba.baidu.com/p/1417020680?pn=2
sgs.LoadTranslationTable{
	["s2_2_zhangfei"] = "张飞",
	["&s2_2_zhangfei"] = "张飞",
	["#s2_2_zhangfei"] = " 火爆的斗士",
	["designer:s2_2_zhangfei"] = "owmasxiao",
	
	["$s2_nuhou1"] = "啊~~~",
	["$s2_nuhou2"] = "燕人张飞在此！",
	["s2_nuhou"] = "怒吼",
	[":s2_nuhou"] = "<font color=\"blue\"><b>锁定技，</b></font>当其他角色使用非延时类锦囊指定你为目标时，需交给你一张基本牌，否则此锦囊对你无效。",
	["@s2_nuhou-give"] = "%src 触发 <font color=\"yellow\"><b>怒吼</b></font> <br>你需交给 %src 一张基本牌，否则 %dest 对其无效。",
	
	["s2_haojiu_draw"] = "各摸一张牌",
	["s2_haojiu_losthp"] = "各流失一点体力",
	["s2_haojiu"] = "好酒",
	[":s2_haojiu"] = "<font color=\"blue\"><b>锁定技，</b></font>当你使用一张【酒】后，你须指定一名角色执行以下一项1. 各流失一点体力。2. 各摸一张牌。",
	
	["s2_cansi"] = "惨死",
	[":s2_cansi"] = "<font color=\"blue\"><b>锁定技，</b></font>你濒死时，须进行一次判定，若判定结果不为红桃，则你立即阵亡。",
	
} 
s2_handang = sgs.General(extension_jx,"s2_handang","wu","4")

s2_shanqiCard = sgs.CreateSkillCard{
	name = "s2_shanqi",
	target_fixed = false,
	filter = function(self, targets, to_select) 
		if #targets ~= 0  then return false end
		local rangefix = 0
		if not self:getSubcards():isEmpty() and sgs.Self:getWeapon() and sgs.Self:getWeapon():getId() == self:getSubcards():first() then
			local card = sgs.Self:getWeapon():getRealCard():toWeapon()
			rangefix = rangefix + card:getRange() - sgs.Self:getAttackRange(false)
		end
		return sgs.Self:inMyAttackRange(to_select, rangefix);
	end,
	on_use = function(self, room, source, targets)
		if targets[1]:isAlive() then
		local choice = room:askForChoice(source, "s2_shanqi", "s2_shanqi_draw+s2_shanqidis")
		if choice == "s2_shanqi_draw" then 
			room:drawCards(targets[1], self:subcardsLength() * 2, "s2_shanqi")
			else
			local x = math.min(self:subcardsLength() * 2, targets[1]:getCards("he"):length())
			room:askForDiscard(targets[1], self:objectName(), x, x, false, true)
		end
	end
	end
}
s2_shanqi = sgs.CreateViewAsSkill{
	name = "s2_shanqi",
	n = 999,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("OffensiveHorse") or to_select:isKindOf("DefensiveHorse")
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local zhiheng_card = s2_shanqiCard:clone()
		for _,card in pairs(cards) do
			zhiheng_card:addSubcard(card)
		end
		zhiheng_card:setSkillName(self:objectName())
		return zhiheng_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#s2_shanqi") and player:canDiscard(player, "he")
	end,
}
s2_baibu = sgs.CreateTriggerSkill{
	name = "s2_baibu" ,
	events = {sgs.TargetConfirmed} ,
	frequency = sgs.Skill_Compulsory, 
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if use.from and (player:objectName() ~= use.from:objectName())  or (not use.card:isKindOf("Slash")) then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		local distance = 0 
		for _, q in sgs.qlist(room:getOtherPlayers(player)) do
		if player:inMyAttackRange(q) then 
		distance = math.max(distance, player:distanceTo(q))
		end
		end
		for _, p in sgs.qlist(use.to) do
			local handcardnum = p:getHandcardNum()
				if distance == player:distanceTo(p) then
					jink_table[index] = 0
					local log= sgs.LogMessage()
	log.type = "#skill_cant_jink"
		log.from = player
		log.to:append(p)
		log.arg = self:objectName()
		room:sendLog(log)
		room:broadcastSkillInvoke(self:objectName(), math.random(2))
			end
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	end
}
s2_handang:addSkill(s2_shanqi)
s2_handang:addSkill(s2_baibu)
--http://tieba.baidu.com/p/1417020680?pn=1
sgs.LoadTranslationTable{
	["s2_handang"] = "韩当",
	["&s2_handang"] = "韩当",
	["#s2_handang"] = " 孙吴的基石",
	["designer:s2_handang"] = "owmasxiao",
	
	["s2_shanqi"] = "善骑",
	[":s2_shanqi"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置至少一张坐骑牌：若如此做，令你攻击范围内的一名角色摸X张牌或弃X张牌。（X为你所弃的坐骑牌数乘2） ",
	["s2_shanqi_draw"] = "令你攻击范围内的一名角色摸X张牌",
	["s2_shanqidis"] = "令你攻击范围内的一名角色弃X张牌",
	
	["s2_baibu"] = "百步",
	[":s2_baibu"] = "<font color=\"blue\"><b>锁定技，</b></font>当你使用【杀】指定了你攻击范围内的与你距离最大的角色时，此【杀】不可以使用【闪】响应。",
	["$s2_baibu1"] = "鼠辈，哪里走！",
	["$s2_baibu2"] = "吃我一箭！",
	
} 



s2_2_godzhaoyun = sgs.General(extension_jx,"s2_2_godzhaoyun","god","1")



function Setlw(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

local patternslw = {"slash", "jink", "analeptic", "nullification", "snatch", "dismantlement", "collateral", "duel", "fire_attack", "amazing_grace", "savage_assault", "archery_attack", "god_salvation", "iron_chain"}
if not (Setlw(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
	table.insert(patternslw, 2, "thunder_slash")
	table.insert(patternslw, 2, "fire_slash")
	table.insert(patternslw, 2, "normal_slash")
end
local slash_patternslw = {"slash", "normal_slash", "thunder_slash", "fire_slash"}
function getPoslw(table, value)
	for i, v in ipairs(table) do
		if v == value then
			return i
		end
	end
	return 0
end
local poslw = 0
s2_longwei_select = sgs.CreateSkillCard {
	name = "s2_longwei_select",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	mute = true,
	on_use = function(self, room, source, targets)
		local basic = {}
		local sttrick = {}
		local mttrick = {}
		for _, cd in ipairs(patternslw) do
			local card = sgs.Sanguosha:cloneCard(cd, sgs.Card_NoSuit, 0)
			if card then
				card:deleteLater()
				if card:isAvailable(source) then
					if card:getTypeId() == sgs.Card_TypeBasic then
						table.insert(basic, cd)
						elseif card:isKindOf("SingleTargetTrick") then
						table.insert(sttrick, cd)
					else
						table.insert(mttrick, cd)
					end
					if cd == "slash" then
						table.insert(basic, "normal_slash")
					end
				end
			end
		end
		local choices = {}
		local yo = ""
		local typechoice = room:askForChoice(source, "s2_longwei-new-choicetype", "basic+single_target_trick+multiple_target_trick")
		if typechoice == "basic" then
			choices = table.copyFrom(basic)
			yo = "BasicCard"
		elseif typechoice == "single_target_trick" then
			choices = table.copyFrom(sttrick)
			yo = "TrickCard"
		elseif typechoice == "multiple_target_trick" then
			choices = table.copyFrom(mttrick)
			yo = "TrickCard"
		end
		local pattern = room:askForChoice(source, "s2_longwei-new", table.concat(choices, "+"))
		if pattern then
			if string.sub(pattern, -5, -1) == "slash" then
				pos = getPoslw(slash_patternslw, pattern)
				room:setPlayerMark(source, "s2_longweiSlashPos", pos)
			end
			pos = getPoslw(patternslw, pattern)
			room:setPlayerMark(source, "s2_longweiPos", pos)
			local prompt = string.format("@@s2_longwei:%s:%s", pattern, yo)
			room:setPlayerFlag(source, yo)
			room:askForUseCard(source, "@s2_longwei", prompt)		
			room:setPlayerFlag(source, "-"..yo)
		end
	end,
}

s2_longweiCard = sgs.CreateSkillCard {
	name = "s2_longwei",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	player = nil,
	on_use = function(self, room, source)
		player = source
	end,
	filter = function(self, targets, to_select, player)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@s2_longwei" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				card:setSkillName("s2_longwei")
			end
			if card and card:targetFixed() then
				return false
			end
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
			return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end		
		local pattern = patternslw[player:getMark("s2_longweiPos")]
		if pattern == "normal_slash" then pattern = "slash" end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("s2_longwei")
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,	
	target_fixed = function(self)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@s2_longwei" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
			end
			return card and card:targetFixed()
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end		
		local pattern = patternslw[player:getMark("s2_longweiPos")]
		if pattern == "normal_slash" then pattern = "slash" end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		return card and card:targetFixed()
	end,	
	feasible = function(self, targets)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@s2_longwei" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				card:setSkillName("s2_longwei")
			end
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
			return card and card:targetsFeasible(qtargets, sgs.Self)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end		
		local pattern = patternslw[sgs.Self:getMark("s2_longweiPos")]
		if pattern == "normal_slash" then pattern = "slash" end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("s2_longwei")
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,	
	on_validate = function(self, card_use)
		local yuji = card_use.from
		local room = yuji:getRoom()		
		local to_guhuo = self:getUserString()		
		if to_guhuo == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@s2_longwei" then
			local guhuo_list = {}
			table.insert(guhuo_list, "slash")
			if not (Setlw(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(guhuo_list, "normal_slash")
				table.insert(guhuo_list, "thunder_slash")
				table.insert(guhuo_list, "fire_slash")
			end
			to_guhuo = room:askForChoice(yuji, "s2_longwei_slash", table.concat(guhuo_list, "+"))
			pos = getPoslw(slash_patternslw, to_guhuo)
			room:setPlayerMark(yuji, "s2_longweiSlashPos", pos)
		end	
			local subcards = self:getSubcards()
			local card = sgs.Sanguosha:getCard(subcards:first())
			local user_str
			if to_guhuo == "slash"  then
				if card:isKindOf("Slash") then
					user_str = card:objectName()
				else
					user_str = "slash"
				end
			elseif to_guhuo == "normal_slash" then
				user_str = "slash"
			else
				user_str = to_guhuo
			end
			local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
			use_card:setSkillName("s2_longwei")
			use_card:addSubcard(card)
			use_card:deleteLater()			
			return use_card
	end,
	on_validate_in_response = function(self, yuji)
		local room = yuji:getRoom()
		local to_guhuo
		if self:getUserString() == "analeptic" then
			local guhuo_list = {}
			if not (Setlw(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(guhuo_list, "analeptic")
			end
			to_guhuo = room:askForChoice(yuji, "guhuo_saveself", table.concat(guhuo_list, "+"))
		elseif self:getUserString() == "slash" then
			local guhuo_list = {}
			table.insert(guhuo_list, "slash")
			if not (Setlw(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(guhuo_list, "normal_slash")
				table.insert(guhuo_list, "thunder_slash")
				table.insert(guhuo_list, "fire_slash")
			end
			to_guhuo = room:askForChoice(yuji, "s2_longwei_slash", table.concat(guhuo_list, "+"))
			pos = getPoslw(slash_patternslw, to_guhuo)
			room:setPlayerMark(yuji, "s2_longweiSlashPos", pos)
		else
			to_guhuo = self:getUserString()
		end		
			local subcards = self:getSubcards()
			local card = sgs.Sanguosha:getCard(subcards:first())
			local user_str
			if to_guhuo == "slash" then
				if card:isKindOf("Slash") then
					user_str = card:objectName()
				else
					user_str = "slash"
				end
			elseif to_guhuo == "normal_slash" then
				user_str = "slash"
			else
				user_str = to_guhuo
			end
			local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
			use_card:setSkillName("s2_longwei")
			use_card:addSubcard(subcards:first())
			use_card:deleteLater()
			return use_card
	end
}

s2_longwei = sgs.CreateViewAsSkill {
	name = "s2_longwei",	
	n = 1,	
	response_or_use = true,
		enabled_at_response = function(self, player, pattern)
		if pattern == "@s2_longwei" then
			return not player:isKongcheng() 
		end
		
		if player:isKongcheng()  or string.sub(pattern, 1, 1) == "." or string.sub(pattern, 1, 1) == "@" then
			return false
		end
		if pattern == "peach"  then return false end
		return true
	end,
	
	enabled_at_play = function(self, player)
		return not player:isKongcheng() 
	end,
	
	view_filter = function(self, selected, to_select)
		if (#selected >= 1) then return false end
		if (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
				or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "jink" then
				return to_select:isKindOf("BasicCard")
			elseif pattern == "nullification" then
				return to_select:isKindOf("TrickCard")
			elseif pattern == "slash" then
				return to_select:isKindOf("BasicCard")
			elseif pattern == "@s2_longwei" then
				if sgs.Self:hasFlag("TrickCard") then
				return to_select:isKindOf("TrickCard")
				elseif sgs.Self:hasFlag("BasicCard") then
				return to_select:isKindOf("BasicCard")
				end
			end
			end
			return false
		end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			if sgs.Sanguosha:getCurrentCardUsePattern() == "@s2_longwei" then
				local pattern = patternslw[sgs.Self:getMark("s2_longweiPos")]
				if pattern == "normal_slash" then pattern = "slash" end
				local c = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
				if c and #cards == 1 then
					c:deleteLater()
					local card = s2_longweiCard:clone()
					if not string.find(c:objectName(), "slash") then
						card:setUserString(c:objectName())
					else
						card:setUserString(slash_patternslw[sgs.Self:getMark("s2_longweiSlashPos")])
					end
					card:addSubcard(cards[1])
					return card
				else
					return nil
				end
			elseif #cards == 1 then
				local card = s2_longweiCard:clone()
				card:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
				card:addSubcard(cards[1])
				return card
			else
				return nil
			end
		else
			local cd = s2_longwei_select:clone()
			return cd
		end
	end,	
	enabled_at_nullification = function(self, player)
				local cards = player:getHandcards()
				for _,c in sgs.qlist(cards) do
					if c:isKindOf("TrickCard") then
						return true
					end
			end
		return false
	end
	}


s2_2_juejing = sgs.CreateMaxCardsSkill{
	name = "s2_2_juejing" ,
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return 1
		end
	end
}

s2_longpo = sgs.CreateTriggerSkill{
	name = "s2_longpo",
	frequency = sgs.Skill_Frequent,
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, zhoutai, data)
		local room = zhoutai:getRoom()
		local dying = data:toDying()
		if dying.who:objectName() ~= zhoutai:objectName() then
			return false
		end
		if zhoutai:getHp() > 0 then return false end
		if room:askForSkillInvoke(zhoutai, self:objectName()) then
		room:notifySkillInvoked(zhoutai,self:objectName())
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|heart"
			judge.good = false
			judge.reason = self:objectName()
			judge.who = zhoutai
			room:judge(judge)
			if judge:isGood()  then
			room:recover(zhoutai, sgs.RecoverStruct(zhoutai, nil, 1-zhoutai:getHp()))
			end
		end
		return false
	end
}


s2_2_godzhaoyun:addSkill(s2_longwei)
s2_2_godzhaoyun:addSkill(s2_longpo)
s2_2_godzhaoyun:addSkill(s2_2_juejing)


--http://tieba.baidu.com/p/1427658683

sgs.LoadTranslationTable{
	["s2_2_godzhaoyun"] = "赵云",
	["&s2_2_godzhaoyun"] = "赵云",
	["#s2_2_godzhaoyun"] = " 无人能挡",
	["designer:s2_2_godzhaoyun"] = "RULE3231",
	
	["s2_longwei"] = "龙威",
	[":s2_longwei"] = "你可以将一张基本牌当【桃】以外的基本牌使用或打出；你可以将一张锦囊牌当【无中生有】以外的锦囊牌使用或打出。",
	["s2_longwei-new"] = "龙威",
	["s2_s2_longwei_select"]  ="龙威",
	["@@s2_longwei"]= "你可以将一张 %dest 当 %src 使用或打出。",
	["~s2_longwei"] = "选择一张牌→点击确定",
	["s2_longwei_slash"] = "龙威【杀】",
	["s2_longwei_select"] = "龙威",
	["s2_longwei-new-choicetype"] = "龙威",
	
	["s2_2_juejing"] = "绝境",
	[":s2_2_juejing"] = "<font color=\"blue\"><b>锁定技，</b></font>你的手牌上限+1。",
	
	["s2_longpo"] = "龙魄",
	[":s2_longpo"] = "每当你处于濒死状态时，你可以进行判定，若结果不为红桃，你回复至1点体力。",
} 


s2_yuejin = sgs.General(extension_jx,"s2_yuejin","wei","4")

s2_tuxi = sgs.CreateTriggerSkill{
	name = "s2_tuxi" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if not use.from then return false end
		if (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
		for _, p in sgs.qlist(use.to) do
		if p:getHandcardNum() >= player:getHp() and player:canDiscard(p, "h") then 
			local _data = sgs.QVariant()
			_data:setValue(p)
			if player:askForSkillInvoke(self:objectName(), _data) then
			player:getRoom():broadcastSkillInvoke(self:objectName(), math.random(2))
				local to_throw = player:getRoom():askForCardChosen(player, p, "h", self:objectName())
					local card = sgs.Sanguosha:getCard(to_throw)
					player:getRoom():throwCard(card, p, player);
				end
			end
		end
	end
}

s2_wuwei = sgs.CreateTriggerSkill{
	name = "s2_wuwei" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	waked_skills = "mengjin",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getHp() <= 2  and player:canWake(self:objectName()) then
			room:addPlayerMark(player, "s2_wuwei")
			if room:changeMaxHpForAwakenSkill(player) then
				room:handleAcquireDetachSkills(player, "mengjin")
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getMark("s2_wuwei") == 0)
				and (target:getPhase() == sgs.Player_Start)
	end
}

s2_yuejin:addSkill(s2_tuxi)
s2_yuejin:addSkill(s2_wuwei)

--http://tieba.baidu.com/p/1647909589
sgs.LoadTranslationTable{
	["s2_yuejin"] = "乐进",
	["&s2_yuejin"] = "乐进",
	["#s2_yuejin"] = " 左将军",
	["designer:s2_yuejin"] = "令人恐怖的男子",
	
	["s2_tuxi"] = "突袭",
	["$s2_tuxi1"] = "骁勇果敢，每战必先！",
	["$s2_tuxi2"] = "奋强突固，无坚不陷！",
	[":s2_tuxi"] = "当你使用【杀】，并指定了一名手牌数大于或等于你当前体力值的角色为目标后，你可以弃掉对方一张手牌。",
	["s2_wuwei"] = "无畏",
	[":s2_wuwei"] = "<font color=\"purple\"><b>觉醒技，</b></font>回合开始阶段，若你的体力值小于或等于2，你须减一点体力上限，并永久获得技能“猛进”。",
	
} 
s2_spguanyu = sgs.General(extension_jx,"s2_spguanyu","wei","4")
s2_suzhan = sgs.CreateTriggerSkill{
	name = "s2_suzhan" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.CardUsed } ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if event == sgs.CardUsed then 
			local use = data:toCardUse()
			if use.card:isKindOf("Duel") and  use.to:getOffensiveHorse() ~=nil and use.from:hasSkill(self:objectName()) then
				local no_respond_list = use.no_respond_list
				table.insert(no_respond_list, "_ALL_TARGETS")
				use.no_respond_list = no_respond_list
				data:setValue(use)
			end
		end
		return false
	end ,
}
--http://tieba.baidu.com/p/1648259904
s2_spguanyu:addSkill("wusheng")
s2_spguanyu:addSkill(s2_suzhan)
sgs.LoadTranslationTable{
	["s2_spguanyu"] = "关羽",
	["&s2_spguanyu"] = "关羽",
	["#s2_spguanyu"] = " 汉寿亭侯",
	["designer:s2_spguanyu"] = "13033166556",
	["s2_suzhan"] = "速斩",
	[":s2_suzhan"] = "<font color=\"blue\"><b>锁定技，</b></font>当你的装备区有-1马时，你的决斗不可被响应。",
	["$s2_suzhan"] = "忠心赤膽，青龍嘯天",
	
} 
s2_bianfuren = sgs.General(extension_jx,"s2_bianfuren","wei","3", false)

s2_shanxianOther = sgs.CreateFilterSkill{
	name = "s2_shanxianOther&",
	view_filter = function(self, to_select)
		return to_select:getSuit() == sgs.Card_Heart
	end,
	view_as = function(self, card)
		local id = card:getEffectiveId()
		local new_card = sgs.Sanguosha:getWrappedCard(id)
		new_card:setSkillName(self:objectName())
		new_card:setSuit(sgs.Card_Spade)
		new_card:setModified(true)
		return new_card
	end
}
s2_shanxian = sgs.CreateTriggerSkill{
	name = "s2_shanxian",
	frequency = sgs.Skill_Frequent,
	events = {sgs.FinishJudge, sgs.EventPhaseEnd, sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local bianfurens = room:findPlayersBySkillName(self:objectName())
		if event == sgs.FinishJudge then 
		local judge = data:toJudge()
		local card = judge.card
		--if player:getPhase() == sgs.Player_Judge then return false end 
		if card:getSuit() == sgs.Card_Heart then 
		for _,bianfuren in sgs.qlist(bianfurens) do
			local dest = sgs.QVariant()
			dest:setValue(player)
			if room:askForSkillInvoke(bianfuren, self:objectName(), dest) then
			bianfuren:drawCards(1, self:objectName())
			room:attachSkillToPlayer(player, "s2_shanxianOther")
			room:addPlayerMark(player, "&s2_shanxian+to+#"..bianfuren:objectName().."-"..player:getPhase().."Clear")
				end
				end
				elseif event == sgs.EventPhaseEnd or (event == sgs.EventLoseSkill and data:toString() == "s2_shanxian") then  
				for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:detachSkillFromPlayer(p, "s2_shanxianOther")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

s2_muyi = sgs.CreateTriggerSkill{
	name = "s2_muyi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local from = damage.from
		local x = damage.damage
		for i = 0, x - 1, 1 do
		if room:askForSkillInvoke(player, self:objectName(), data) then
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|spade"
			judge.good = true
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if judge:isGood() then
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:isWounded() then 
						targets:append(p)
						end
					end
					if targets:isEmpty() then return false end 
					local target = room:askForPlayerChosen(player, targets, self:objectName())
					local recover = sgs.RecoverStruct()
					room:setPlayerFlag(target, "s2_muyi_target")
					if room:askForChoice(player, self:objectName(), "s2_muyi1+s2_muyixd1")== "s2_muyi1" then 
						recover.recover = 1
					else 
					if player:getHandcardNum() > target:getHandcardNum() then 
						recover.recover = player:getHandcardNum() - target:getHandcardNum() - 1
					elseif player:getHandcardNum() < target:getHandcardNum() then  
						recover.recover = target:getHandcardNum() - player:getHandcardNum() - 1 
					end
				end
					recover.who = player
					room:recover(target,recover)
					room:setPlayerFlag(target, "-s2_muyi_target")
				end
			end
		end
	end
}

s2_bianfuren:addSkill(s2_shanxian)
s2_bianfuren:addSkill(s2_muyi)
if not sgs.Sanguosha:getSkill("s2_shanxianOther") then
	s_skillList:append(s2_shanxianOther)
end
--http://tieba.baidu.com/p/1474145670
sgs.LoadTranslationTable{
	["s2_bianfuren"] = "卞夫人",
	["&s2_bianfuren"] = "卞夫人",
	["#s2_bianfuren"] = " 天命玄鳥",
	["designer:s2_bianfuren"] = "_A_N_C_O_",
	
	["s2_shanxian"] = "善贤",
	[":s2_shanxian"] = "一名角色的判定结果为红桃时，你可以摸一张牌，若如此做，该角色当前阶段的红桃牌均视为黑桃牌。",
	["s2_shanxianOther"] = "善贤",
	[":s2_shanxianOther"] = "<font color=\"blue\"><b>锁定技，</b></font>你的红桃牌均视为黑桃牌。",
	
	["s2_muyi"] = "母仪",
	[":s2_muyi"] = "每当你受到1点伤害后，你可以进行一次判定，若判定结果为黑桃，你须令一名角色回复1或X-1点体力，X为你们的手牌数之差。",
	["s2_muyi1"] = "回复1点体力",
	["s2_muyixd1"] = "回复X-1点体力",
} 
s2_spcaocao = sgs.General(extension_jx,"s2_spcaocao$","wei","3")



s2_yaowu = sgs.CreateTriggerSkill{
	name = "s2_yaowu" ,
	events = {sgs.EventPhaseEnd} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then 
		if player:isKongcheng() then return false end
		if player:askForSkillInvoke(self:objectName()) then
		room:showAllCards(player)
		local heart = 0 
		local diamond = 0 
		local spade = 0 
		local club = 0 
		local suit = 0 
		for _,card in sgs.qlist(player:getHandcards()) do
			if card:getSuitString() == "club" then
			club = 1
			elseif card:getSuitString() == "spade" then
			spade = 1
			elseif card:getSuitString() == "diamond" then
			diamond = 1
			elseif card:getSuitString() == "heart" then
			heart = 1
			end
		end
		if club >= 1 then 
		suit = suit + 1 
		end
		if spade >= 1 then 
		suit = suit + 1 
		end
		if diamond >= 1 then 
		suit = suit + 1 
		end
		if heart >= 1 then 
		suit = suit + 1 
		end
		room:setPlayerMark(player, "s2_yaowu",suit)
			end
		elseif player:getPhase() == sgs.Player_Finish then 
		if player:getMark("s2_yaowu") > 0 then 
			player:drawCards(player:getMark("s2_yaowu"), self:objectName())
			if player:getMark("s2_yaowu") >= 3 then 
			player:turnOver()
				end
				room:setPlayerMark(player, "s2_yaowu", 0)
			end
		end
		return false
	end
}


s2_taolueStart = sgs.CreateTriggerSkill{
	name = "#s2_taolue-start" ,
	events = {sgs.GameStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		player:gainMark("@s2_wu")
		room:handleAcquireDetachSkills(player, "secondtenyearjiangchi")
	end ,
}
s2_taolue = sgs.CreateTriggerSkill{
	name = "s2_taolue" ,
	events = {sgs.TurnedOver, sgs.HpChanged, sgs.EventAcquireSkill} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TurnedOver then
			if  player and (player and player:isAlive() and player:hasSkill(self:objectName()))  then
					if player:getMark("@s2_wen") > 0  and (player:faceUp() and  player:getHp() ~= 1) then 
						player:loseMark("@s2_wen")
				player:gainMark("@s2_wu")
				room:handleAcquireDetachSkills(player, "secondtenyearjiangchi|-mobilejiushi")
				elseif not player:faceUp() and player:getMark("@s2_wu") > 0  then  
				player:loseMark("@s2_wu")
				player:gainMark("@s2_wen")
				room:handleAcquireDetachSkills(player, "-secondtenyearjiangchi|mobilejiushi")
				end
			end
		elseif event == sgs.HpChanged  then 
			if player:getHp() == 1 and player:getMark("@s2_wu") > 0 then
				player:loseMark("@s2_wu")
				player:gainMark("@s2_wen")
				room:handleAcquireDetachSkills(player, "-secondtenyearjiangchi|mobilejiushi")
			elseif player:getMark("@s2_wen") > 0  and (player:faceUp() and player:getHp() ~= 1) then
			player:loseMark("@s2_wen")
				player:gainMark("@s2_wu")
				room:handleAcquireDetachSkills(player, "secondtenyearjiangchi|-mobilejiushi")
				end
			elseif event == sgs.EventAcquireSkill  then
			if data:toString() == self:objectName() then
			if  player and (player and player:isAlive() and player:hasSkill(self:objectName()))  then
					if player:faceUp() and player:getHp() ~= 1 then 
				player:gainMark("@s2_wu")
				room:handleAcquireDetachSkills(player, "secondtenyearjiangchi")
				elseif not player:faceUp() and player:getHp() == 1  then  
				player:gainMark("@s2_wen")
				room:handleAcquireDetachSkills(player, "mobilejiushi")
				end
			end
			end
		end
		return false
	end ,
}
s2_taolueClear = sgs.CreateTriggerSkill{
	name = "#s2_taolue-clear" ,
	events = {sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		if data:toString() == "s2_taolue" then
			local room = player:getRoom()
			if player:getMark("@s2_wu") > 0 then
				room:detachSkillFromPlayer(player, "secondtenyearjiangchi")
			elseif player:getMark("@s2_wen") > 0 then
				room:detachSkillFromPlayer(player, "mobilejiushi")
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}

s2_bayeCard = sgs.CreateSkillCard{
	name = "s2_bayeCard",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:hasLordSkill("s2_baye")
		   and to_select:objectName() ~= sgs.Self:objectName() and not to_select:hasFlag("s2_bayeInvoked")
	end,
	on_use = function(self, room, source, targets)
		local zhangjiao = targets[1]
		if zhangjiao:hasLordSkill("s2_baye") then
			room:setPlayerFlag(zhangjiao, "s2_bayeInvoked")
			room:notifySkillInvoked(zhangjiao, "s2_baye")
			zhangjiao:obtainCard(self);
			local zhangjiaos = room:getLieges("qun",zhangjiao)
			local zhangjiaos2 = room:getLieges("shu",zhangjiao)
			local zhangjiaos3 = room:getLieges("wu",zhangjiao)
			local zhangjiaos4 = room:getLieges("wei",zhangjiao)
			
			if zhangjiaos:isEmpty() and zhangjiaos2:isEmpty() and zhangjiaos3:isEmpty() and zhangjiaos4:isEmpty() then
				room:setPlayerFlag(source, "Forbids2_baye")
			end
		end
	end
}
s2_bayeVS = sgs.CreateViewAsSkill{
	name = "s2_bayeVS&",
	n = 1,
	view_filter=function(self,selected,to_select)
		if sgs.Self:getKingdom() == "shu" then
		return to_select:getSuit() == sgs.Card_Spade
		elseif sgs.Self:getKingdom() == "wei" then
		return to_select:getSuit() == sgs.Card_Heart
		elseif sgs.Self:getKingdom() == "wu" then
		return to_select:getSuit() == sgs.Card_Diamond
		elseif sgs.Self:getKingdom() == "qun" then
		return to_select:getSuit() == sgs.Card_Club
		end
		return false 
	end,
	view_as = function(self, cards)
	if #cards == 1 then
		local acard = s2_bayeCard:clone()
		acard:addSubcard(cards[1])
		return acard
		end
	end,
	enabled_at_play = function(self, player)
	if player:getKingdom() == "shu" or player:getKingdom() == "wu" or player:getKingdom() == "qun" or player:getKingdom() == "wei" then
			return not player:hasFlag("Forbids2_baye")
			end
			return false 
	end
}
s2_baye = sgs.CreateTriggerSkill{
	name = "s2_baye$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TurnStart, sgs.EventPhaseChanging,sgs.EventAcquireSkill,sgs.EventLoseSkill},
	on_trigger = function(self, triggerEvent, player, data)
		local room = player:getRoom()
		local lords = room:findPlayersBySkillName(self:objectName())
		if (triggerEvent == sgs.TurnStart)or(triggerEvent == sgs.EventAcquireSkill and data:toString() == "s2_baye") then 
			if lords:isEmpty() then return false end
			local players
			if lords:length() > 1 then
				players = room:getAlivePlayers()
			else
				players = room:getOtherPlayers(lords:first())
			end
			if player:hasLordSkill(self:objectName()) then
			for _,p in sgs.qlist(players) do
				if not p:hasSkill("s2_bayeVS") then
					room:attachSkillToPlayer(p, "s2_bayeVS")
				end
				end
			end
		elseif triggerEvent == sgs.EventLoseSkill and data:toString() == "s2_baye" then
			if lords:length() > 2 then return false end
			local players
			if lords:isEmpty() then
				players = room:getAlivePlayers()
			else
				players:append(lords:first())
			end
			for _,p in sgs.qlist(players) do
				if p:hasSkill("s2_bayeVS") then
					room:detachSkillFromPlayer(p, "s2_bayeVS", true)
				end
			end
		elseif (triggerEvent == sgs.EventPhaseChanging) then
			local phase_change = data:toPhaseChange()
			if phase_change.from ~= sgs.Player_Play then return false end
			if player:hasFlag("Forbids2_baye") then
				room:setPlayerFlag(player, "-Forbids2_baye")
			end
			local players = room:getOtherPlayers(player);
			for _,p in sgs.qlist(players) do
				if p:hasFlag("s2_bayeInvoked") then
					room:setPlayerFlag(p, "-s2_bayeInvoked")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

extension_jx:insertRelatedSkills("s2_taolue","#s2_taolue-start")
extension_jx:insertRelatedSkills("s2_taolue","#s2_taolue-clear")

s2_spcaocao:addSkill(s2_yaowu)
s2_spcaocao:addSkill(s2_taolueStart)
s2_spcaocao:addSkill(s2_taolue)
s2_spcaocao:addSkill(s2_taolueClear)
s2_spcaocao:addSkill(s2_baye)
s2_spcaocao:addRelateSkill("secondtenyearjiangchi")
s2_spcaocao:addRelateSkill("mobilejiushi")
if not sgs.Sanguosha:getSkill("s2_bayeVS") then
	s_skillList:append(s2_bayeVS)
end
--http://tieba.baidu.com/p/1659140826
sgs.LoadTranslationTable{
	["s2_spcaocao"] = "曹操",
	["&s2_spcaocao"] = "sp曹操",
	["#s2_spcaocao"] = " 中原之霸者",
	["designer:s2_spcaocao"] = "太阁大将军紫炎",
	
	["s2_yaowu"] = "耀武",
	[":s2_yaowu"] =  "摸牌阶段结束时，你可以展示所有手牌，若如此做，其中每有一種花色，结束阶段开始时，你摸1张牌，若你以此法获得的牌数不少于三张，然后将你的武将牌翻面。",
	
	["@s2_wen"] = "文",
	["@s2_wu"] = "武",
	["s2_taolue"] = "韜略",
	[":s2_taolue"] = "游戏开始时，你获得一枚“文/武”标记且“武”朝上。當你的武將牌背面向上或你的體力值為1，你的标记为“文”朝上。若“武”朝上，你拥有“将驰”；若“文”朝上，你拥有“酒诗”。 ",

	["s2_baye"] = "霸业",
	[":s2_baye"] = "<font color=\"orange\"><b>主公技，</b></font><font color=\"green\"><b>出牌阶段限一次，</b></font>其他角色可在其各自的出牌阶段按以下规则给你一张牌：魏:红桃 蜀:黑桃 吴:方块 群雄:梅花。",
	["s2_bayeVS"] = "霸业",
	[":s2_bayeVS"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可在你的出牌阶段按以下规则给曹操一张牌：魏:红桃 蜀:黑桃 吴:方块 群雄:梅花。",
	
} 

s2_guanping = sgs.General(extension_jx,"s2_guanping","shu","4")



s2_fenzhan = sgs.CreateViewAsSkill{
	name = "s2_fenzhan",
	n = 2,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return not to_select:isEquipped()
		elseif #selected == 1 then
			local card = selected[1]
			if to_select:getSuit() == card:getSuit() then
				return not to_select:isEquipped()
			end
		else
			return false
		end
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local cardA = cards[1]
			local cardB = cards[2]
			local suit = cardA:getSuit()
			local aa = sgs.Sanguosha:cloneCard("jink", suit, 0);
			aa:addSubcard(cardA)
			aa:addSubcard(cardB)
			aa:setSkillName(self:objectName())
			return aa
		end
	end,
	enabled_at_play = function(self, target)
		return false
	end,
	enabled_at_response = function(self, target, pattern)
		return  (pattern == "jink")
	end
}

s2_fanji = sgs.CreateTriggerSkill{
	name = "s2_fanji",
	events = {sgs.CardOffset},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	if event == sgs.CardOffset then 
		local effect = data:toCardEffect()
		if effect.card:isKindOf("Slash") and effect.to:hasSkill(self:objectName())   then
		local p = sgs.QVariant()
					p:setValue(player)
			if not room:askForSkillInvoke(effect.to,self:objectName(),p) then return false end 
			local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			card:deleteLater()
			card:setSkillName(self:objectName())
		local use = sgs.CardUseStruct()
					use.card = card
					use.from = effect.to
					use.to:append(player)
					room:useCard(use)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = -99
}

s2_guanping:addSkill(s2_fenzhan)
s2_guanping:addSkill(s2_fanji)
--http://tieba.baidu.com/p/1657573716
sgs.LoadTranslationTable{
	["s2_guanping"] = "关平",
	["&s2_guanping"] = "关平",
	["#s2_guanping"] = " 谒忠王",
	["designer:s2_guanping"] = "雪代源刃心",
	
	["s2_fenzhan"] = "奋战",
	[":s2_fenzhan"] = "你可以将两张相同花色的手牌当【闪】使用。",
	
	["s2_fanji"] = "反击",
	[":s2_fanji"] = "当你使用的【闪】抵消目标角色的【杀】时，你可以视为对其使用一张【杀】。",
	
} 


s2_zhangren = sgs.General(extension_jx,"s2_zhangren","qun","4")

s2_maifu = sgs.CreateTriggerSkill{
	name = "s2_maifu", 
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	if event == sgs.EventPhaseStart then
		if player:getPhase() == sgs.Player_RoundStart and player:hasSkill(self:objectName()) then
		local q = nil
		local can_invoke = false
		 for _,p in sgs.qlist(room:getAllPlayers())do
				 if p:getMark("s2_maifu")> 0 then 
				 q = p
				 can_invoke = true
			end
			end
			if not can_invoke then return false end
			room:setPlayerMark(q, "s2_maifu", 0)
			local log= sgs.LogMessage()
	log.type = "#s2_maifuReset"
		log.from = player
		log.to:append(q)
		room:sendLog(log)
			local Qingchenglist = q:getTag("Qingcheng"):toString():split("+")
			if #Qingchenglist == 0 then return false end
			for _,skill_name in pairs(Qingchenglist)do
				room:setPlayerMark(q, "Qingcheng" .. skill_name, 0);
			end
			q:removeTag("Qingcheng")
			for _,p in sgs.qlist(room:getAllPlayers())do
				room:filterCards(p, p:getCards("he"), true)
			end
		--[[    local jsonValue = {
				8
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))]]
		end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Draw and player:hasSkill(self:objectName()) then 
		local x = math.floor(player:getHandcardNum() / 2)
		if player:hasSkill(self:objectName()) and room:askForDiscard(player, self:objectName(), x, x, true, false, "s2_maifu-invoke") then 
			local to = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName())
			local skill_list = {}
		local Qingchenglist = to:getTag("Qingcheng"):toString():split("+") or {}
		for _,skill in sgs.qlist(to:getVisibleSkillList()) do
			if (not table.contains(skill_list,skill:objectName())) and not skill:isAttachedLordSkill() then
				table.insert(skill_list,skill:objectName())
			end
		end
		table.removeTable(skill_list,Qingchenglist)
		local skill_qc = ""
		if (#skill_list > 0) then
			skill_qc = room:askForChoice(player, "s2_maifu", table.concat(skill_list,"+"))
		end
		if (skill_qc ~= "") then
			table.insert(Qingchenglist,skill_qc)
			to:setTag("Qingcheng",sgs.QVariant(table.concat(Qingchenglist,"+")))
			room:addPlayerMark(to, "Qingcheng" .. skill_qc)
			room:addPlayerMark(to, "s2_maifu")
			local log= sgs.LogMessage()
	log.type = "#s2_maifuNullify"
		log.to:append(to)
		log.arg = skill_qc
		log.from = player
		room:sendLog(log)
			for _,p in sgs.qlist(room:getAllPlayers())do
				room:filterCards(p, p:getCards("he"), true)
			end
		--[[	local jsonValue = {
				8
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))]]
		end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = 6
}

s2_zhangren:addSkill(s2_maifu)
--http://tieba.baidu.com/p/1657573716
sgs.LoadTranslationTable{
	["s2_zhangren"] = "张任",
	["&s2_zhangren"] = "张任",
	["#s2_zhangren"] = " 忠心不二",
	["designer:s2_zhangren"] = "雪代源刃心",
	
	["s2_maifu"] = "埋伏",
	["s2_maifu-invoke"] =  "你可以发动“埋伏”<br/> <b>操作提示</b>: 选择一半手牌→选择一名角色→点击确定<br/>",
	[":s2_maifu"] = "摸牌阶段结束时，你可弃一半手牌（向下取整），若如此做，你可指定一名角色废除一项技能直到你的下个回合开始。",
	["#s2_maifuNullify"] = "%to 的技能“%arg”由于“<font color=\"yellow\"><b>埋伏</b></font>”效果无效直到 %from 回合开始时",
	["#s2_maifuReset"] = "%from 回合开始，%to 的技能 恢复有效",

	
} 
s2_zumao = sgs.General(extension_jx,"s2_zumao","wu","4")


s2_shuangdao = sgs.CreateTriggerSkill{
	name = "s2_shuangdao",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardOffset, sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardOffset then 
		local effect = data:toCardEffect()
		local dest = effect.to
		if dest:isAlive() and effect.card:isKindOf("Slash") then
			if effect.from:canSlash(dest, nil, false) then
				local prompt = string.format("s2_shuangdao-slash:%s", dest:objectName())
				local slash = room:askForUseSlashTo(player, dest, prompt, false, false, false, nil, nil, "s2_shuangdao-slash")
				
				end
			end
		elseif event == sgs.TargetConfirmed then 
		local use = data:toCardUse()
		if (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) or (not use.card:hasFlag("s2_shuangdao-slash")) then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			local _data = sgs.QVariant()
			_data:setValue(p)
			if player:askForSkillInvoke(self:objectName(), _data) then
					jink_table[index] = 0
					local log= sgs.LogMessage()
	log.type = "#skill_cant_jink"
		log.from = player
		log.to:append(p)
		log.arg = self:objectName()
		room:sendLog(log)
			end
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		end
		return false
	end,
	priority = -1
}

s2_huzhu = sgs.CreatePhaseChangeSkill{
	name = "s2_huzhu",
	frequency = sgs.Skill_NotFrequent,
	on_phasechange = function(self, player)
	local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
		if p:getEquips():length() > 0 then 
		players:append(p)
		end
		end
			local target = room:askForPlayerChosen(player, players, self:objectName(), "s2_huzhu-invoke", true, true)
			if not target then return false end
			  room:notifySkillInvoked(player, self:objectName())
			  local equips1, equips2 = sgs.IntList(), sgs.IntList()
	for _, equip in sgs.qlist(target:getEquips()) do
		equips1:append(equip:getId())
	end
	for _, equip in sgs.qlist(player:getEquips()) do
		equips2:append(equip:getId())
	end
			  local exchangeMove = sgs.CardsMoveList()
			  local move1 = sgs.CardsMoveStruct(equips1, player, sgs.Player_PlaceEquip, 
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_ROB, target:objectName(), player:objectName(), "s2_huzhu", ""))
	local move2 = sgs.CardsMoveStruct(equips2, nil, sgs.Player_DiscardPile,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_CHANGE_EQUIP, player:objectName(), player:objectName(), "s2_huzhu", ""))
	exchangeMove:append(move2)
	exchangeMove:append(move1)
	room:moveCardsAtomic(exchangeMove, false)
	room:setPlayerMark(target,"&s2_huzhu+to+#"..player:objectName(), 1)
	elseif player:getPhase() == sgs.Player_RoundStart and player:faceUp() then
	for _, p in sgs.qlist(room:getOtherPlayers(player)) do
		room:setPlayerMark(p,"&s2_huzhu+to+#"..player:objectName(), 0)
	end
end
	end
}


s2_huzhu_slash = sgs.CreateTriggerSkill{
	name = "#s2_huzhu_slash",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.TargetConfirming},  
	on_trigger = function(self, event, player, data) 
	local room = player:getRoom()
	if event == sgs.TargetConfirming then
		local use = data:toCardUse()
		local card = use.card
		if card and (card:isKindOf("Slash") or card:isKindOf("Duel")) then
		if use.to:contains(player)  then 
		for _, mark in sgs.list(player:getMarkNames()) do
			if string.find(mark, "s2_huzhu") and player:getMark(mark) > 0 then
				for _,zumao in sgs.list(room:findPlayersBySkillName(self:objectName()))do
					if player:getMark("&s2_huzhu+to+#"..zumao:objectName()) > 0 then
						if card:isKindOf("Slash") then 
							if not use.from:canSlash(zumao, card, false ) then 
							return false end 
							end
						if card:isKindOf("Duel") then 
							if use.from:isProhibited(zumao, card) then 
							return false end 
								end
								room:sendCompulsoryTriggerLog(zumao, "s2_huzhu", true)
							use.to:removeOne(player)
							use.to:append(zumao)
							data:setValue(use)
								end
							end
						end
					end
				end
			end
		end

	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}
	
			 
			   


	  



s2_zumao:addSkill(s2_shuangdao)
s2_zumao:addSkill(s2_huzhu)
s2_zumao:addSkill(s2_huzhu_slash)
extension_jx:insertRelatedSkills("s2_huzhu","#s2_huzhu_slash")
--http://tieba.baidu.com/p/1657573716
sgs.LoadTranslationTable{
	["s2_zumao"] = "祖茂",
	["&s2_zumao"] = "祖茂",
	["#s2_zumao"] = " 舍命救主",
	["designer:s2_zumao"] = "雪代源刃心",
	
	["s2_shuangdao"] = "双刀",
	[":s2_shuangdao"] = "当你使用的【杀】被目标角色的【闪】抵消时，可对其再使用一张【杀】，若如此做，你可以令此【杀】不可被【闪】响应。",
	["s2_shuangdao-slash"] = "你可以发动“双刀”，对 %src 再使用一张【杀】",
	
	["@s2_huzhu"] = "主",
	["s2_huzhu"] = "护主",
	["s2_huzhu-invoke"] =  "你可以发动“护主”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	[":s2_huzhu"] = "回合结束阶段，你可将一名其他角色装备区里的牌移动到你的装备区内，若如此做，直到你的下个回合开始为止，所有对该角色的【杀】和【决斗】，均视为对你使用。",
} 

s2_2_yuejin = sgs.General(extension_jx,"s2_2_yuejin","wei","4")


s2_xiaoguoCard = sgs.CreateSkillCard{
	name = "s2_xiaoguo",

	filter = function(self, targets, to_select)
		return #targets < 2 and (not to_select:isKongcheng()) and to_select:objectName() ~= sgs.Self:objectName()
	end,
		feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		if chadian(source, targets[1], targets[2], "s2_xiaoguo") == "success" then 
		local target = room:askForPlayerChosen(source, room:getAlivePlayers(), self:objectName(), "s2_xiaoguo")
			if not target then return false end
			local damage = sgs.DamageStruct()
						damage.from = source
						damage.to = target
						damage.damage = 1
						room:damage(damage)
			else 
			room:loseHp(source)
			room:setPlayerFlag(source,"s2_xiaoguo_fail")
		end
	end
}
s2_xiaoguoVS = sgs.CreateZeroCardViewAsSkill{
	name = "s2_xiaoguo",
	view_as = function(self) 
		return s2_xiaoguoCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#s2_xiaoguo") and not player:isKongcheng()
	end, 
}
s2_xiaoguo = sgs.CreateTriggerSkill{
	name = "s2_xiaoguo",
	events = {sgs.EventPhaseEnd},
	view_as_skill = s2_xiaoguoVS,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
		if player:hasFlag("s2_xiaoguo_fail") then
			player:getRoom():setPlayerFlag(player, "-s2_xiaoguo_fail")
			player:drawCards(2, self:objectName())
			end
		end
		return false
	end,
}
s2_2_yuejin:addSkill(s2_xiaoguo)

--http://tieba.baidu.com/p/1657573716
sgs.LoadTranslationTable{
	["s2_2_yuejin"] = "乐进",
	["&s2_2_yuejin"] = "乐进",
	["#s2_2_yuejin"] = " 捷足先登",
	["designer:s2_2_yuejin"] = "雪代源刃心",
	
	["#chadian"] = "%from 向 %to 发起了插点",
	["#chadianSuccess"] = "%from (对 %to ) 插点赢！",
	["#chadianFailure"] = "%from (对 %to  ) 插点没赢",
	["#chadianResult"] = "%from 的拼点牌为 %arg",
	
	["s2_xiaoguo"] = "骁果",
	[":s2_xiaoguo"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以指定两名角色插点。若成功，则你对一名角色造成1点伤害。若不成功，则你失去1点体力并在本回合结束阶段摸两张牌。<br>插点：插点的三方各以牌面向下的方式出一张手牌后同时亮出，\
	发动插点的一方牌面点数在其他两方牌面点数中间为成功，发动插点的一方小于牌面点数最小的一方，大于牌面点数最大的一方，\
	和两方任意一方牌面点数相同为不成功。三方将插点所用的牌放进弃牌堆(不能和自己插点)。",
} 


s2_mifuren = sgs.General(extension_jx,"s2_mifuren","shu","2", false)

s2_2_muyi = sgs.CreateMaxCardsSkill{
	name = "s2_2_muyi" ,
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return 2
		end
	end
}

s2_xiandeCard = sgs.CreateSkillCard{
	name = "s2_xiande",

	filter = function(self, targets, to_select)
		return #targets < 2 and (not to_select:isKongcheng()) and to_select:objectName() ~= sgs.Self:objectName()
	end,
		feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		if chadian(source, targets[1], targets[2], "s2_xiande") == "success" then 
		local cards = room:getNCards(2)
		local dummy = sgs.Sanguosha:cloneCard("Slash")
		dummy:deleteLater()
		for _, p in sgs.qlist(cards) do
		dummy:addSubcard(sgs.Sanguosha:getCard(p))
	end
		source:obtainCard(dummy)
		local target = room:askForPlayerChosen(source, room:getAlivePlayers(), "s2_xiande-draw", "s2_xiande-draw")
			if not target then return false end
			target:obtainCard(dummy)
			else 
			room:loseHp(source)
			if source:canDiscard(source,"h") then 
			room:askForDiscard(source, self:objectName(), 1, 1, false, false)
			end
			local target = room:askForPlayerChosen(source, room:getOtherPlayers(source),"s2_xiande-recover", "s2_xiande-recover", true, true)
			if not target then return false end
			local recover = sgs.RecoverStruct()
					recover.who = source
					room:recover(target,recover)
		end
	end
}
s2_xiande = sgs.CreateZeroCardViewAsSkill{
	name = "s2_xiande",
	view_as = function(self) 
		return s2_xiandeCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#s2_xiande") and not player:isKongcheng()
	end, 
}

s2_toujing = sgs.CreateTriggerSkill{
	name = "s2_toujing" ,
	events = {sgs.Death} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		local targets = room:getAlivePlayers()
		if targets:isEmpty() then return false end
		local target = room:askForPlayerChosen(player,targets,self:objectName(), "s2_toujing-invoke", true, true)
		if not target then return false end
		room:handleAcquireDetachSkills(target, "yicong")
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}

s2_mifuren:addSkill(s2_2_muyi)
s2_mifuren:addSkill(s2_xiande)
s2_mifuren:addSkill(s2_toujing)
--http://tieba.baidu.com/p/1657573716
sgs.LoadTranslationTable{
	["s2_mifuren"] = "糜夫人",
	["&s2_mifuren"] = "糜夫人",
	["#s2_mifuren"] = " 深明大义",
	["designer:s2_mifuren"] = "雪代源刃心",
	
	["s2_2_muyi"] = "母仪",
	[":s2_2_muyi"] =  "<font color=\"blue\"><b>锁定技，</b></font>你的手牌上限+2。",
	
	["s2_xiande"] = "贤德",
	["s2_xiande_draw"] = "贤德",
	["s2_xiande_recover"] = "贤德",
	["s2_xiande-draw"] = "你可以发动“贤德”<br/> 你可摸两张牌交给一名角色<b>操作提示<br/></b>: 选择一名角色→点击确定<br/>",
	[":s2_xiande"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以指定两名角色插点。若成功，你可摸两张牌交给一名角色。若不成功，则你失去1点体力和1张手牌令除自己外任一目标角色回复1点体力。",
	["s2_xiande-recover"] =  "你可以发动“贤德”<br/> 令一名其他角色回复1点体力<br/><b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	
	["s2_toujing"] = "投井",
	[":s2_toujing"] = "当你死亡时，你可指定一名角色获得技能“义从”。",
	["s2_toujing-invoke"] =  "你可以发动“投井”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
} 


s2_spzhangliao = sgs.General(extension_jx,"s2_spzhangliao","wei","4")

s2_qiangji = sgs.CreateFilterSkill{
		
	name = "s2_qiangji", 
	view_filter = function(self,to_select)
	local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return (to_select:getSuit() == sgs.Card_Heart) and (place == sgs.Player_PlaceHand) and to_select:isKindOf("Jink")
	end,
	view_as = function(self, originalCard)
		local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
		slash:setSkillName(self:objectName())
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(slash)
		return card
	end
}
s2_qiangjiTargetMod = sgs.CreateTargetModSkill{
	name = "#s2_qiangji-target",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("s2_qiangji") and (card:getSuit() == sgs.Card_Heart) and card:isKindOf("Slash") and card:getSkillName() == "s2_qiangji" then
			return 1000
		else
			return 0
		end
	end
}

s2_qiangji_cardMAX = sgs.CreateMaxCardsSkill{
	name = "#s2_qiangji_cardMAX" ,
	fixed_func = function(self, target)
		local extra = 0
		local kingdom_set = {}
		table.insert(kingdom_set, target:getKingdom())
		for _, p in sgs.qlist(target:getSiblings()) do
			local flag = true
			for _, k in ipairs(kingdom_set) do
				if p:getKingdom() == k then
					flag = false
					break
				end
			end
			if flag then table.insert(kingdom_set, p:getKingdom()) end
		end
		extra = #kingdom_set
		if target:hasSkill("s2_qiangji") then
			return extra  + target:getLostHp()
		end
	end
}



s2_tujin = sgs.CreateTriggerSkill{
	name = "s2_tujin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage, sgs.EventPhaseEnd, sgs.EventPhaseStart, sgs.CardUsed, sgs.PreCardUsed},
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	if event == sgs.PreCardUsed then 
	local use = data:toCardUse()
	if use.from and use.from:hasFlag("s2_tujin") then 
	if use.card:isKindOf("Slash") then 
	use.from:setFlags("-s2_tujin")
			if player:askForSkillInvoke(self:objectName(), data)then
			room:setCardFlag(use.card, "s2_tujin-slash")
			player:turnOver()
			room:handleAcquireDetachSkills(player, "tenyeartuxi")
					room:handleAcquireDetachSkills(player, "qixi")
					room:setPlayerMark(player, self:objectName(), 1)
					player:drawCards(1, self:objectName())
			end
			end
			end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
		player:setFlags("s2_tujin")
			 local card =  room:askForUseCard(player, "slash", "@s2_tujin", sgs.Card_MethodUse)
				if not card then 
				 player:setFlags("-s2_tujin")
			end
		elseif event == sgs.Damage then 
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("s2_tujin-slash") then 
			room:loseHp(damage.from,1)
			if not damage.from:faceUp() then
			damage.from:turnOver()
			end
			local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(damage.from)) do
				if p:getHp() > damage.from:getHp() then 
				targets:append(p)
				end
				end
				if not targets:isEmpty() then 
				local target = room:askForPlayerChosen(damage.from, targets, self:objectName())
				room:loseHp(target, target:getHp() - damage.from:getHp())
				end
			end 
		elseif event == sgs.EventPhaseStart then 
		if player:getPhase() == sgs.Player_Discard then 
		if player:getMark(self:objectName()) > 0 then 
		room:setPlayerMark(player, self:objectName(), 0)
		room:handleAcquireDetachSkills(player, "-tenyeartuxi")
					room:handleAcquireDetachSkills(player, "-qixi")
					end
		end 
		end
	end
}


extension_jx:insertRelatedSkills("s2_qiangji","#s2_qiangji-target")
extension_jx:insertRelatedSkills("s2_qiangji","#s2_qiangji_cardMAX")
s2_spzhangliao:addSkill(s2_qiangji)
s2_spzhangliao:addSkill(s2_qiangjiTargetMod)
s2_spzhangliao:addSkill(s2_qiangji_cardMAX)
s2_spzhangliao:addSkill(s2_tujin)
s2_spzhangliao:addRelateSkill("tenyeartuxi")
s2_spzhangliao:addRelateSkill("qixi")

--http://tieba.baidu.com/p/1663648023

sgs.LoadTranslationTable{
	["s2_spzhangliao"] = "张辽",
	["&s2_spzhangliao"] = "SP张辽",
	["#s2_spzhangliao"] = " 逍遥津之虎",
	["designer:s2_spzhangliao"] = "青苹果1021",
	
	["s2_qiangji"] = "强击",
	[":s2_qiangji"] = "<font color=\"blue\"><b>锁定技，</b></font>你红桃【闪】始终视为无距离限制的【杀】，你的手牌上限为你已损失的体力值+X（X为在场势力数）。",
	
	["s2_tujin"] = "突进",
	["@s2_tujin"] = "你可以发动“突进”",
	[":s2_tujin"] = "你可以在回合结束阶段使用一张【杀】，你可以将武将牌翻面，你获得“突袭”与“奇袭”技能直至下回合弃牌阶段，且摸一张牌;若此【杀】造成伤害，你失去一点体力，然后将武将牌翻回正面，令一名角色扣至与你相同的体力值。",
} 	


s2_spzhenji = sgs.General(extension_jx,"s2_spzhenji","qun","4", false)

s2_zhenyan = sgs.CreatePhaseChangeSkill{
	name = "s2_zhenyan",
	frequency = sgs.Skill_Frequent,
	on_phasechange = function(self, player)
	local room = player:getRoom()
		if player:getPhase() == sgs.Player_Discard  and not player:getArmor() then
			if player:askForSkillInvoke(self:objectName()) then
			local target
			local draw_num = "1+2+3+4+5"
				local num = tonumber(room:askForChoice(player, "s2_zhenyan_draw", draw_num))
				local card_ids = room:getNCards(num)
				local defense_str = {}
					for _,card_id in sgs.qlist(card_ids) do
						table.insert(defense_str, sgs.Sanguosha:getCard(card_id):toString())
					end	
				local msg = sgs.LogMessage()
					msg.type = "$s2_zhenyan_equip"
					msg.from = player
					msg.card_str = table.concat(defense_str, "+")
					room:sendLog(msg)
				room:fillAG(card_ids)
				--room:showCard(player, card_ids)
				local card_id = room:askForAG(player, card_ids, false, "s2_zhenyan")
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				dummy:deleteLater()
				card_ids:removeOne(card_id)
				dummy:addSubcard(card_id)
				room:clearAG()
			if dummy:subcardsLength() > 0 then
				 target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName())
				target:obtainCard(dummy)
				end
		room:clearAG()
		if not card_ids:isEmpty() then
			room:askForGuanxing(player, card_ids, sgs.Room_GuanxingDownOnly)
		end
		if target:getWeapon() then 
		local card = target:getWeapon():getRealCard():toWeapon()
		if card:getNumber() == sgs.Sanguosha:getCard(card_id):getNumber() then 
				local re = sgs.RecoverStruct()
						re.who = player		
						room:recover(player,re,true)
						end
						end
			end
		end
	end
}

s2_boxing = sgs.CreateTriggerSkill{
	name = "s2_boxing" ,
	events = {sgs.DamageInflicted} ,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName(), data) then 
			room:loseMaxHp(player)
			if player:isDead() then return true end
			local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getEquips():length() > 0 then 
				targets:append(p)
				end
				end
				if not targets:isEmpty() then 
				local target = room:askForPlayerChosen(player, targets, self:objectName())
				local dummy = sgs.Sanguosha:cloneCard("slash")
				dummy:deleteLater()
				for _,id in sgs.qlist(target:getEquips()) do
				dummy:addSubcard(id)
				end
				if dummy:subcardsLength() > 0 then
				player:obtainCard(dummy)
				local x = math.min(room:getAlivePlayers():length(), 5)
				if target:getHp() < x  then
				local re = sgs.RecoverStruct()
						re.who = player		
						re.recover = x - target:getHp()
						room:recover(target,re,true)
						end
					end
				end
			return true
		end
		return false
	end
}
s2_spzhenji:addSkill(s2_zhenyan)
s2_spzhenji:addSkill(s2_boxing)

--http://tieba.baidu.com/p/1663648023
sgs.LoadTranslationTable{
	["s2_spzhenji"] = "甄姬",
	["&s2_spzhenji"] = "SP甄姬",
	["#s2_spzhenji"] = " 袁家之妻",
	["designer:s2_spzhenji"] = "青苹果1021",
	
	["s2_zhenyan"] = "珍颜",
	["s2_zhenyan_draw"] = "珍颜数",
	[":s2_zhenyan"] = "弃牌阶段，若你装备区没有防具，你可以观看牌顶堆的任意张牌（最多五张）并展示,然后你将一张分配给场上任意一名角色，剩余牌置于牌堆底，若此牌与该角色装备区的武器牌点数相同，你回复一点体力。",
	["$s2_zhenyan_equip"] = "%from  展示牌顶堆的牌 %card ",
	["s2_boxing"] = "薄幸",
	[":s2_boxing"] = "当你受到伤害时，你可以防止此伤害，改为减1点体力上限。 若如此做，你获得一名角色所有装备区的牌，该角色的体力回复至X点（X为场上存货角色数，X最多为5）。",
}
s2_spdaqiaoxiaoqiao = sgs.General(extension_jx,"s2_spdaqiaoxiaoqiao","qun","2", false)



s2_caoqin= sgs.CreateTriggerSkill{
	name = "s2_caoqin",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	local damage = data:toDamage()
	if damage.from then 
	local source = damage.from
	if source:isMale()then
	local x = math.min(player:getHandcardNum(), source:getHandcardNum())
	if x == 0 then return false end 
	x = math.min(x, player:getLostHp())
		local to_exchangea = room:askForExchange(player, "s2_caoqin", x, x, false,"s2_caoqin", false)
		local to_exchangeb = room:askForExchange(source, "s2_caoqin", x, x, false,"s2_caoqin", false)
			local exchangeMove = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct(to_exchangea:getSubcards(), source, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), source:objectName(), "s2_caoqin", ""))
		local move2 = sgs.CardsMoveStruct(to_exchangeb:getSubcards(), player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, source:objectName(), player:objectName(), "s2_caoqin", ""))
		exchangeMove:append(move1)
		exchangeMove:append(move2)
			room:moveCardsAtomic(exchangeMove, false)
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			end
			end
		end,
		can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end
}

s2_jinchiCard = sgs.CreateSkillCard{
	name = "s2_jinchi",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
	local targetqs = sgs.SPlayerList()
	for _,p  in sgs.qlist(source:getRoom():getAlivePlayers()) do
				if p:getArmor() == nil and p:getHandcardNum()> 5  and p:isMale() then
						targetqs:append(p)
				end
			end
			if targetqs:isEmpty() then return false end 
			room:loseHp(source)
			local target = room:askForPlayerChosen(source, targetqs, self:objectName())
		room:moveCardTo(source:getArmor():getRealCard():toEquipCard(), source, target, sgs.Player_PlaceEquip,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "s2_jinchi", ""))
		source:drawCards(1, "s2_jinchi")
		
		if source:getMaxHp() < 5 then 
		room:setPlayerProperty(source, "maxhp", sgs.QVariant(source:getMaxHp() + 1))
		end
	end
}
s2_jinchi = sgs.CreateZeroCardViewAsSkill{
	name = "s2_jinchi",
	view_as = function(self) 
		return s2_jinchiCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#s2_jinchi") and not player:isKongcheng() and player:getArmor()
	end, 
}

s2_jiaoqing = sgs.CreateTriggerSkill{
	name = "s2_jiaoqing",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.ChoiceMade},
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	local  choice_table = data:toString():split(":")
	if choice_table[1] == "playerChosen" and  choice_table[2] == "s2_jinchi" then 
	local source = choice_table[3]
	local q
	for _,p  in sgs.qlist(room:getAlivePlayers()) do
	if p:objectName() == source then 
	q = p 
	break 
	end
	end
	room:sendCompulsoryTriggerLog(player, "s2_jiaoqing", true)
	local x = math.min(player:getHandcardNum(), q:getHandcardNum())
	if x == 0 then return false end 
	x = math.min(x, player:getLostHp())
		local to_exchangea = room:askForExchange(player, "s2_caoqin", x, x, false,"s2_caoqin", false)
		local to_exchangeb = room:askForExchange(q, "s2_caoqin", x, x, false,"s2_caoqin", false)
			local exchangeMove = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct(to_exchangea:getSubcards(), q, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), q:objectName(), "s2_caoqin", ""))
		local move2 = sgs.CardsMoveStruct(to_exchangeb:getSubcards(), player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, q:objectName(), player:objectName(), "s2_caoqin", ""))
		exchangeMove:append(move1)
		exchangeMove:append(move2)
			room:moveCardsAtomic(exchangeMove, false)
			room:sendCompulsoryTriggerLog(player, "s2_caoqin", true)
			end
			end

}

s2_spdaqiaoxiaoqiao:addSkill(s2_caoqin)
s2_spdaqiaoxiaoqiao:addSkill(s2_jinchi)
s2_spdaqiaoxiaoqiao:addSkill(s2_jiaoqing)

--http://tieba.baidu.com/p/1663648023
sgs.LoadTranslationTable{
	["s2_spdaqiaoxiaoqiao"] = "大乔&小乔",
	["&s2_spdaqiaoxiaoqiao"] = "SP大乔&小乔",
	["#s2_spdaqiaoxiaoqiao"] = "绝色之花",
	["designer:s2_spdaqiaoxiaoqiao"] = "青苹果1021",
	
	["s2_caoqin"] = "操琴",
	[":s2_caoqin"] = "<font color=\"blue\"><b>锁定技，</b></font>当你一名男性角色对你造成伤害后，你和他交换X张手牌（X为你损失的体力值）。",
	
	["s2_jinchi"] = "矜持",
	[":s2_jinchi"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>若场上有一名男性角色的手牌多于五张，且你的装备区的牌不少于一张，你可以自减一点体力，将装备区的防具转移到他的区域上，若如此做，你增加一点体力上限（体力上限最大为5）。",

	["s2_jiaoqing"] = "矫情",
	[":s2_jiaoqing"] = "<font color=\"blue\"><b>锁定技，</b></font>当你发动“矜持”时，视为你对该男性角色使用了一次“操琴”。",
}


s2_sptaishici = sgs.General(extension_jx,"s2_sptaishici","qun","4")
--[[
s2_douba_tr = sgs.CreateTriggerSkill{
	name = "#s2_douba_tr",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.SlashMissed, sgs.CardsMoveOneTime, sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.SlashMissed then 
		player:gainMark("@s2_dou")
		if player:getMark("@s2_dou") > player:getHandcardNum() then 
		local cards = player:getHandcards()
		room:filterCards(player, cards, false)
		else
		local cards = player:getHandcards()
		room:filterCards(player, cards, true)
		end
		elseif event ==sgs.CardResponded then 
			local card_star = data:toCardResponse().m_card
		local room = player:getRoom()
		if card_star:isKindOf("Jink") then
			player:gainMark("@s2_dou")
			if player:getMark("@s2_dou") > player:getHandcardNum() then 
		local cards = player:getHandcards()
		room:filterCards(player, cards, false)
		else
		local cards = player:getHandcards()
		room:filterCards(player, cards, true)
		end
		end
		elseif event ==sgs.CardsMoveOneTime then 
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() then 
		if player:getMark("@s2_dou") > player:getHandcardNum() then 
		local cards = player:getHandcards()
		room:filterCards(player, cards, false)
		else
		local cards = player:getHandcards()
		room:filterCards(player, cards, true)
		end
		end
		end
		return false
	end,
	priority = 2
}

s2_douba = sgs.CreateFilterSkill{	
	name = "s2_douba",
	view_filter = function(self, to_select)
		local splayer = sgs.Sanguosha:currentRoom():getCurrent()
		return (splayer:getMark("@s2_dou") > splayer:getHandcardNum()) and not splayer:hasEquip(to_select) 
	end,	
	view_as = function(self, card)
	local s2_doubacard
		if card:isRed() then
			s2_douba=sgs.Sanguosha:cloneCard("slash",card:getSuit(),card:getNumber())			
		elseif card:isBlack() then
			s2_douba=sgs.Sanguosha:cloneCard("Duel",card:getSuit(),card:getNumber())
		end
		local acard=sgs.Sanguosha:getWrappedCard(card:getId())
		acard:takeOver(s2_douba)
		acard:setSkillName(self:objectName())
		return acard
	end,
}

]]


s2_douba = sgs.CreateOneCardViewAsSkill{
	name = "s2_douba",
	response_or_use = true,
	view_filter = function(self, card)
		if  card:isEquipped() then return false end 
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(card:getEffectiveId())
			slash:deleteLater()
			local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
			duel:addSubcard(card:getEffectiveId())
			duel:deleteLater()
			return (slash:isAvailable(sgs.Self) and card:isRed() or (duel:isAvailable(sgs.Self) and card:isBlack()))
		end
		return card:isRed()
	end,
	view_as = function(self, originalCard)
		if originalCard:isRed() then
			local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
			slash:addSubcard(originalCard:getId())
			slash:setSkillName(self:objectName())
			return slash
		elseif originalCard:isBlack() then
			local duel = sgs.Sanguosha:cloneCard("duel", originalCard:getSuit(), originalCard:getNumber())
			duel:addSubcard(originalCard:getId())
			duel:setSkillName(self:objectName())
			return duel
		end
	end,
	enabled_at_play = function(self, player)
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
			duel:deleteLater()
		return sgs.Slash_IsAvailable(player) or duel:isAvailable(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}



s2_zhanpoTrickCard = sgs.CreateTrickCard{
	name = "_s2_zhanpoTrick",
	class_name = "s2_zhanpoTrick",
	target_fixed = false,
	subclass = sgs.LuaTrickCard_TypeDelayedTrick, -- LuaTrickCard_TypeNormal, LuaTrickCard_TypeSingleTargetTrick, LuaTrickCard_TypeDelayedTrick, LuaTrickCard_TypeAOE, LuaTrickCard_TypeGlobalEffect
	filter = function(self, targets, to_select) 
		if #targets ~= 0 then return false end
		if to_select:containsTrick("s2_zhanpoTrick") then return false end		
		return to_select:objectName() == sgs.Self:objectName()
	end,
	is_cancelable = function(self, effect)
		return false
	end,
}
s2_zhanpoCard = sgs.CreateSkillCard{
	name = "s2_zhanpo",

	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getWeapon() ~= nil
	end,
	
	on_use = function(self, room, source, targets)
		local s2_zhanpoTrick = s2_zhanpoTrickCard:clone()
		s2_zhanpoTrick:addSubcard(targets[1]:getWeapon():getId())
		s2_zhanpoTrick:setSkillName(self:objectName())
		room:obtainCard(source, targets[1]:getWeapon())
		local use =  sgs.CardUseStruct()
			use.from = source
			use.to:append(source)
			use.card = s2_zhanpoTrick
			room:useCard(use, false)
	end,
}
s2_zhanpo = sgs.CreateZeroCardViewAsSkill{
	name = "s2_zhanpo",
	view_as = function(self,originalCard)
		local yanxiao = s2_zhanpoCard:clone()
		return yanxiao
	end,
	enabled_at_play= function(self, player)
	local z = player:getLostHp() + 1
		return not player:hasUsed("#s2_zhanpo") and player:getMark("s2_zhanpoduel") >= z
	end,
}
s2_zhanpo_TM = sgs.CreateTriggerSkill{
	name = "#s2_zhanpo",
	frequency = sgs.Skill_Compulsory, 
	view_as_skill = s2_zhanpoVS,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart, sgs.CardUsed, sgs.Dying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
			local move = data:toMoveOneTime()
						local source = move.from
						if event == sgs.CardsMoveOneTime then 
						if source and source:objectName() == player:objectName() then
							local places = move.from_places
							if places:contains(sgs.Player_PlaceDelayedTrick) then
							for _, id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") and sgs.Sanguosha:getCard(id):objectName() == "s2_zhanpoTrick"  then
				if not source:getPile("s2_zhanpo"):isEmpty() then
					--source:removePileByName("s2_zhanpo")
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					dummy:deleteLater()
						for _,cd in sgs.qlist(source:getPile("s2_zhanpo")) do
							dummy:addSubcard(cd)
						end
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil, self:objectName(), "")
						room:throwCard(dummy, reason, nil)
				end
				end
			end
							end
						end
						elseif event == sgs.EventPhaseStart then 
						if player:getPhase() == sgs.Player_Start and player:containsTrick("s2_zhanpoTrick") then 
						local z = player:getLostHp() + 1
						
							local ids = room:getNCards(z)
							local dummy = sgs.Sanguosha:cloneCard("slash")
							dummy:deleteLater()
							for _,id in sgs.qlist(ids) do
				dummy:addSubcard(sgs.Sanguosha:getCard(id))
				end
				if dummy:subcardsLength() > 0 then
				player:obtainCard(dummy)
							 player:addToPile("s2_zhanpo", ids)
end							 
						elseif player:getPhase() == sgs.Player_NotActive then 
						room:setPlayerMark(player, "s2_zhanpoduel", 0)
						end
						elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			local card = use.card
			if card:isKindOf("Duel") then 
			room:setPlayerMark(player, "s2_zhanpoduel", player:getMark("s2_zhanpoduel") + 1)
			room:addPlayerMark(player, "&s2_zhanpo-Clear")
		end
						elseif event == sgs.Dying then 
						local dying = data:toDying()
						local can_invoke = false 
						if dying.who:objectName() == player:objectName() and player:getPile("s2_zhanpo"):length() > 0  then 
						local dummy = sgs.Sanguosha:cloneCard("slash")
						dummy:deleteLater()
						for _,p in sgs.qlist(player:getPile("s2_zhanpo")) do
						if sgs.Sanguosha:getCard(p):isKindOf("Peach") then 
						can_invoke = true
						break
						end
						end
						if can_invoke then 
						for _, cd in sgs.qlist(player:getPile("s2_zhanpo")) do
			dummy:addSubcard(sgs.Sanguosha:getCard(cd))
		end
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getHandcardNum() < player:getHandcardNum() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then 
		local target = room:askForPlayerChosen(player, targets, "s2_zhanpo", "s2_zhanpo-invoke", true, true)
		if target then
			room:obtainCard(target,dummy)
						end
						end
						end
						end 
						end
	end,
}

extension_jx:insertRelatedSkills("s2_douba","#s2_douba_tr")
extension_jx:insertRelatedSkills("s2_zhanpo","#s2_zhanpo")
--s2_sptaishici:addSkill(s2_douba_tr)
--s2_sptaishici:addSkill(s2_douba)
s2_sptaishici:addSkill(s2_douba)
s2_sptaishici:addSkill(s2_zhanpo)
s2_sptaishici:addSkill(s2_zhanpo_TM)
s2_zhanpoTrickCard:clone():setParent(extension_fakecard)
--http://tieba.baidu.com/p/1663648023
sgs.LoadTranslationTable{
	["s2_sptaishici"] = "太史慈",
	["&s2_sptaishici"] = "SP太史慈",
	["#s2_sptaishici"] = "吴郡先战",
	["designer:s2_sptaishici"] = "青苹果1021",
	
	["@s2_dou"] = "斗",
	["s2_douba"] = "斗霸",
	--[":s2_douba"] = "<font color=\"blue\"><b>锁定技，</b></font>当你的【杀】被闪避或当你使用或打出【闪】时，你获得一个【斗】标记，当你【斗】标记多于你的手牌数时，你的红色手牌视为【杀】，黑色手牌视为【决斗】。",
	[":s2_douba"] = "你可以将红色手牌视为【杀】，黑色手牌视为【决斗】使用或打出。",
	
	["s2_zhanpo-invoke"] = "斩破<br>你可以将武器牌和盖在武器牌上的牌交给一名手牌数小于你的角色",
	["s2_zhanpo"] = "斩破",
	--[":s2_zhanpo"] = "标记技，若你本回合使用【决斗】次数超过X次，你可以将一名角色的武器牌获取，并且置入判定区，每当你回合开始时，你摸X张牌盖到武器牌上，直至你进入濒死阶段，盖在武器牌上的牌若有【桃】，你可以将武器牌和盖在武器牌上的牌交给一名手牌数小于你的角色（X为你手牌数与【斗】标记的差）",
	[":s2_zhanpo"] = "若你本回合使用【决斗】次数不少于X次，你可以将一名角色的武器牌获取，并且置入判定区，每当你回合开始时，你摸X张牌盖到武器牌上，直至你进入濒死阶段，盖在武器牌上的牌若有【桃】，你可以将武器牌和盖在武器牌上的牌交给一名手牌数小于你的角色（X为你的已損失体力值+1）",
	["_s2_zhanpoTrick"] = "斩破",
	
	
	
	
}

s2_spsunjian = sgs.General(extension_jx,"s2_spsunjian","qun","3")

s2_taoni = sgs.CreateTriggerSkill{
	name = "s2_taoni" ,
	events = {sgs.TargetSpecified, sgs.CardFinished},
	frequency = sgs.Skill_NotFrequent, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.TargetSpecified  then
			if (use.card:isKindOf("Slash")) and player:getMark("&s2_taoni-Clear") == 0  then
				if player:askForSkillInvoke(self:objectName(), data) then
				room:addPlayerMark(player, "&s2_taoni-Clear")
					local judge = sgs.JudgeStruct()
				judge.pattern = ".|red"
				judge.good = true
				judge.who = player
				judge.reason = self:objectName()
				room:judge(judge)
				if judge:isGood() then
					room:setCardFlag(use.card, "s2_taoni_sucess")
				end
				end
			end
		elseif event == sgs.CardFinished then 
		if use.card and use.card:isKindOf("Slash")and use.card:hasFlag("s2_taoni_sucess") then 
			room:setCardFlag(use.card, "-s2_taoni_sucess")
			use.card:use(room, use.from, use.to)
		end
		end
		return false
	end,
}


s2_jubing = sgs.CreateTriggerSkill{
	name = "s2_jubing" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@s2_jubing",
	events = {sgs.EventPhaseEnd} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:hasSkill(self:objectName())  and player:getPhase() == sgs.Player_Finish then
			if (room:getAlivePlayers():length() > player:getHp()) and (player:getMark("@s2_jubing") > 0 ) then
				if not player:canDiscard(player, "h") then return false end
				if not room:askForDiscard(player, "s2_jubing", 1, 1, true, true,"@s2_jubing-invoke") then return false end
				player:loseMark("@s2_jubing")
				local _player = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName())
				room:setPlayerMark(_player, self:objectName(), 1)
				room:setPlayerMark(_player, self:objectName()..player:objectName(), 1)
				room:setPlayerMark(_player, "&s2_jubing+to+#"..player:objectName() .. "-SelfClear", 1)
				room:setPlayerMark(player, "s2_jubing_used", 1)
				local p = _player
				local playerdata = sgs.QVariant()
				playerdata:setValue(p)
				room:setTag("s2_jubingTarget", playerdata)
			end
		end
		if player:getPhase() == sgs.Player_Finish then 
		if player:getMark(self:objectName()) > 0 then 
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player:getMark(self:objectName()..p:objectName()) > 0 then 
		local x = p:getHandcardNum()
		room:setPlayerMark(player, self:objectName(), 0)
		if player:getHp() > x then 
		room:loseHp(player, player:getHp()- x)
		elseif player:getHp() < x then 
		local recover = sgs.RecoverStruct()
						recover.who = p
						recover.recover = x - player:getHp()
						room:recover(player, recover)
		end
	end
		end
		end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
s2_jubingGive = sgs.CreateTriggerSkill{
	name = "#s2_jubing-give" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("s2_jubingTarget") then
			local target = room:getTag("s2_jubingTarget"):toPlayer()
			room:removeTag("s2_jubingTarget")
			if target and target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end ,
	priority = 1
}

s2_budai = sgs.CreateTriggerSkill{
	name = "s2_budai",
	frequency = sgs.Skill_Frequent,
	events = {sgs.FinishJudge, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == "s2_taoni" and judge:isBad() and player:hasSkill(self:objectName()) and player:getMark("s2_jubing_used") > 0   then
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAllPlayers()) do
			if player:inMyAttackRange(p) then
				targets:append(p)
			end
			end
			if not targets:isEmpty() then 
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "s2_budai-invoke", true, true)
			if not target then return false end
			room:handleAcquireDetachSkills(target, "yinghun")
			room:addPlayerMark(target, "s2_budaiyinghun"..player:objectName())
			room:broadcastSkillInvoke(self:objectName())
			end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				for _,p in sgs.qlist(room:getAllPlayers()) do
					room:setPlayerMark(p, "s2_budaiyinghun"..player:objectName(), 0)
					room:handleAcquireDetachSkills(p, "-yinghun")
				end
			end
		end
	end,
}

extension_jx:insertRelatedSkills("s2_jubing","#s2_jubing-give")
s2_spsunjian:addSkill(s2_taoni)
s2_spsunjian:addSkill(s2_jubing)
s2_spsunjian:addSkill(s2_jubingGive)
s2_spsunjian:addSkill(s2_budai)
s2_spsunjian:addRelateSkill("yinghun")
sgs.LoadTranslationTable{
	["s2_spsunjian"] = "孙坚",
	["&s2_spsunjian"] = "SP孙坚",
	["#s2_spsunjian"] = " 破虏将军",
	["designer:s2_spsunjian"] = "青苹果1021",
	
	["s2_taoni"] = "讨逆",
	["$s2_taoni"] = "勇冠三軍，方能所向無敵",
	[":s2_taoni"] = "<font color=\"green\"><b>每回合限一次，</b></font>当你使用一张【杀】指定目标后，你可以进行一次判定：若为红色，此杀额外结算一次",
	
	["s2_jubing"] = "举兵",
	["@s2_jubing-invoke"] = "你可以发动“举兵”",
	["@s2_jubing"] = "举兵",
	[":s2_jubing"] = "<font color=\"red\"><b>限定技，</b></font>你的回合结束阶段，若场上角色（包括自己）多于X名,你可以弃置一张牌，然后指定一名角色，该角色立即进入他的回合，他的回合结束阶段，他需要将体力值回复（损失）至你的手牌数的值（X为你的体力值）。",
	
	["s2_budai"] = "不殆",
	["s2_budai-invoke"] = "你可以发动“不殆”<br/> <b>操作提示</b>: 选择一名攻击范围的一名角色→点击确定<br/>",
	["$s2_budai"] = "誰道江南少將材，讓爾等見識一下",
	[":s2_budai"] = "“举兵”技能发动后，你“讨逆”技能判定若为黑色，则你可以选择攻击范围的一名角色，对方获得“英魂”技能直至你下个回合的开始阶段。",
}

s2_spxiahoudun = sgs.General(extension_jx,"s2_spxiahoudun","wei","4")


s2_bashi = sgs.CreateTriggerSkill{
	name = "s2_bashi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local from = damage.from
		local x = damage.damage
		for i = 0, x - 1, 1 do
		local ai_data = sgs.QVariant()
		ai_data:setValue(from)
		if from and from:isAlive() and player:inMyAttackRange(from) and not from:isKongcheng() then
			if room:askForSkillInvoke(player, self:objectName(), ai_data) then
				local to_throw = room:askForCardChosen(player, from, "h", self:objectName())
					--local card = sgs.Sanguosha:getCard(card)
					player:addToPile("s2_shi", to_throw)
				end
			end
		end
	end
}
s2_bashi_TM = sgs.CreateTargetModSkill{
	name = "#s2_bashi_TM",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return player:getPile("s2_shi"):length() + 1
		end
	end,
}
s2_danjingPindian = sgs.CreateTriggerSkill{
	name = "#s2_danjing",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Pindian},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pindian = data:toPindian()
		local source = pindian.from
		if pindian.reason == "s2_danjing" and source:hasSkill("s2_danjing") then
			if pindian.from_card:getNumber() <= pindian.to_card:getNumber() then
				pindian.to:obtainCard(pindian.from_card)
				local x =  pindian.to_card:getNumber() - pindian.from_card:getNumber()
				if x > 0 and x > source:getHp() then
				local recover = sgs.RecoverStruct()
				recover.who = source
				recover.recover = x - source:getHp()
				room:recover(source, recover)
				end
				if pindian.from_card:getNumber() == pindian.to_card:getNumber() then 
				local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
					duel:setSkillName("s2_danjing")
					duel:deleteLater()
					local card_use = sgs.CardUseStruct()
					card_use.from = source
					card_use.to:append(pindian.to)
					card_use.card = duel
					room:useCard(card_use, false)
					end
				
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = -1
}
s2_danjingCard = sgs.CreateSkillCard{
	name = "s2_danjing",
	target_fixed = true, 
	on_use = function(self, room, source, targets)
		local ids = room:getNCards(1, false)
		local move = sgs.CardsMoveStruct()
		move.card_ids = ids
		move.to = source
		move.to_place = sgs.Player_PlaceTable
		move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, source:objectName(), self:objectName(), "")
		room:moveCardsAtomic(move, true)
		local id = ids:first()
		local card = sgs.Sanguosha:getCard(id)
		room:fillAG(ids, source)
		local dealt = false
			local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(source))do 
				if not p:isKongcheng() then 
					targets:append(p) 
				end
			end
			if not targets:isEmpty() then 
				local target = room:askForPlayerChosen(source, targets, self:objectName())
				if target then 
					room:clearAG(source)
					dealt = true
					local success = source:pindian(target, "s2_danjing", card)
					if success then
						if target:getWeapon() then 
							room:obtainCard(source, target:getWeapon():getRealCard():toWeapon())
						end
					end
				end
			 else 
				room:clearAG(source)
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, source:objectName(), self:objectName(), "")
			room:throwCard(card, reason, nil)
	end
}
s2_danjing = sgs.CreateZeroCardViewAsSkill{
	name = "s2_danjing",
	
	view_as = function()
		return s2_danjingCard:clone()
	end,

	enabled_at_play = function(self, player)
		return (not player:hasUsed("#s2_danjing")) and (player:getPile("s2_shi"):length() > player:getLostHp())
	end
}

extension_jx:insertRelatedSkills("s2_bashi","#s2_bashi_TM")
extension_jx:insertRelatedSkills("s2_danjing","#s2_danjing")
s2_spxiahoudun:addSkill(s2_bashi)
s2_spxiahoudun:addSkill(s2_bashi_TM)
s2_spxiahoudun:addSkill(s2_danjingPindian)
s2_spxiahoudun:addSkill(s2_danjing)

sgs.LoadTranslationTable{
	["s2_spxiahoudun"] = "夏侯惇",
	["&s2_spxiahoudun"] = "SP夏侯惇",
	["#s2_spxiahoudun"] = "独眼挺枪",
	["designer:s2_spxiahoudun"] = "青苹果1021",
	
	["s2_bashi"] = "拔矢",
	[":s2_bashi"] = "你每受到一点伤害，若伤害来源在你的攻击范围内，你可以获得其的一张手牌并且盖于武将牌上，称为【矢】，你出牌阶段使用【杀】的次数为X+1（X为【矢】的数量）。",
	["s2_shi"] = "矢",
	
	["s2_danjing"] = "啖睛",
	[":s2_danjing"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>若你的【矢】数量大于你损失的体力值，你可以展示牌堆顶的一张牌，你可以将此牌与一名角色进行拼点，若你赢，你获取其装备区的武器牌，若你输，其获得展示牌，你的体力值恢复至两张拼点牌点数的差，若点数相同，则视为你对其使用了一张【决斗】。",
	
}

s2_zhaoyun = sgs.General(extension_jx,"s2_zhaoyun","shu","4")

s2_tuwei = sgs.CreatePhaseChangeSkill{
	name = "s2_tuwei",
	frequency = sgs.Skill_Frequent,
	on_phasechange = function(self,target)
		local room = target:getRoom()
		if target:getPhase() == sgs.Player_Finish then
		if target:isWounded() and  room:askForSkillInvoke(target,self:objectName()) then
				local extra = 0
		local kingdom_set = {}
		table.insert(kingdom_set, target:getKingdom())
		for _, p in sgs.qlist(target:getSiblings()) do
			local flag = true
			for _, k in ipairs(kingdom_set) do
				if p:getKingdom() == k then
					flag = false
					break
				end
			end
			if flag then table.insert(kingdom_set, p:getKingdom()) end
		end
		extra = #kingdom_set
			target:drawCards(extra, self:objectName())
			end
		end
	end 
}

s2_xuezhan = sgs.CreateTargetModSkill{
	name = "s2_xuezhan",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return player:getLostHp() - 1
		end
	end,
}


s2_zhaoyun:addSkill(s2_tuwei)
s2_zhaoyun:addSkill(s2_xuezhan)
--http://tieba.baidu.com/p/1670365595
sgs.LoadTranslationTable{
	["s2_zhaoyun"] = "赵子龙",
	["&s2_zhaoyun"] = "赵子龙",
	["#s2_zhaoyun"] = "单骑救主",
	["designer:s2_zhaoyun"] = "流天泪心龙",
	["s2_tuwei"] = "突围",
	[":s2_tuwei"] = "回合结束阶段，若你已受伤，你可以摸X张牌，X等于场上存活的势力数。",
	["s2_xuezhan"] = "血战",
	[":s2_xuezhan"] = "出牌阶段，你可以使用X张【杀】，X等于你已损失的体力值。",
	
}
s2_zhangyide = sgs.General(extension_jx,"s2_zhangyide","shu","4")

s2_leiyinCard = sgs.CreateSkillCard{
	name = "s2_leiyin",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if not to_select:isKongcheng() then
				return to_select:objectName() ~= sgs.Self:objectName() and (to_select:getHandcardNum() > sgs.Self:getHandcardNum())
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local success = source:pindian(targets[1], "s2_leiyin", self)
		if success then 
		room:setPlayerCardLimitation(targets[1], "use,response", "BasicCard", true)
		room:addPlayerMark(targets[1], "&s2_leiyin+to+#"..source:objectName().."-Clear")
		else
		source:turnOver()
		end
	end
}
s2_leiyin = sgs.CreateViewAsSkill{
	name = "s2_leiyin",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local daheCard = s2_leiyinCard:clone()
			daheCard:addSubcard(cards[1])
			return daheCard
		end
	end,
	enabled_at_play = function(self, player)
			return not player:isKongcheng()
	end
}
s2_haozhan = sgs.CreateFilterSkill{
	name = "s2_haozhan", 
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		return to_select:isKindOf("TrickCard") 
	end,
	view_as = function(self, originalCard)
		local slash = sgs.Sanguosha:cloneCard("duel", originalCard:getSuit(), originalCard:getNumber())
		slash:setSkillName(self:objectName())
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(slash)
		return card
	end
}
s2_zhangyide:addSkill(s2_leiyin)
s2_zhangyide:addSkill(s2_haozhan)
--http://tieba.baidu.com/p/1670365595
sgs.LoadTranslationTable{
	["s2_zhangyide"] = "张翼德",
	["&s2_zhangyide"] = "张翼德",
	["#s2_zhangyide"] = " 万夫不当",
	["designer:s2_zhangyide"] = "流天泪心龙",
	
	["s2_leiyin"] = "雷音",
	[":s2_leiyin"] = "出牌阶段，你可以与一名手牌多于你的角色拼点，若你赢，此回合内该角色不能使用基本牌，若你没赢，你将武将牌翻面。",
	
	["s2_haozhan"] = "好战",
	[":s2_haozhan"] = "<font color=\"blue\"><b>锁定技，</b></font>你的锦囊牌均视为【决斗】。",
}

s2_mamengqi = sgs.General(extension_jx,"s2_mamengqi","shu","4")

s2_yezhan = sgs.CreateOneCardViewAsSkill{
	name = "s2_yezhan",
	filter_pattern = ".|black|.|.",
	view_as = function(self, originalCard)
		local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
		slash:addSubcard(originalCard:getId())
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}

s2_zhuiji = sgs.CreateTriggerSkill{
	name = "s2_zhuiji",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then 
		local damage = data:toDamage()
		local dest = damage.to
		if dest:isAlive() and damage.card and damage.card:isKindOf("Slash") and player:getMark("s2_zhuiji-Clear") == 0  and not player:hasFlag("s2_zhuiji_using") then
			if damage.from:canSlash(dest, nil, false) then
				room:setPlayerFlag(player, "s2_zhuiji_using")
				local prompt = string.format("s2_zhuiji-slash:%s", dest:objectName())
				if room:askForUseSlashTo(player, dest, prompt) then
				room:addPlayerMark(player, "&s2_zhuiji-Clear")
				room:addPlayerMark(player, "s2_zhuiji-Clear")
					end
				end
				room:setPlayerFlag(player, "-s2_zhuiji_using")
			end
		end
		return false
	end,
	priority = -1
}

s2_mamengqi:addSkill(s2_zhuiji)
s2_mamengqi:addSkill(s2_yezhan)
--http://tieba.baidu.com/p/1670365595
sgs.LoadTranslationTable{
	["s2_mamengqi"] = "马孟起",
	["&s2_mamengqi"] = "马孟起",
	["#s2_mamengqi"] = " 神威天将军",
	["designer:s2_mamengqi"] = "流天泪心龙",
	
	["s2_yezhan"] = "夜战",
	[":s2_yezhan"] = "你可以将黑色的牌当【杀】使用或打出。",
	
	["s2_zhuiji"] = "追击",
	[":s2_zhuiji"] = "<font color=\"green\"><b>每回合限一次，</b></font>当你使用【杀】对一名角色造成伤害时，可以对其再使用一张【杀】。",
	["s2_zhuiji-slash"] = "你可以发动“追击”，对 %src 再使用一张【杀】",
	
}

s2_guanyunzhang = sgs.General(extension_jx,"s2_guanyunzhang","shu","4")

s2_shenwei = sgs.CreateTriggerSkill{
	name = "s2_shenwei",
	events = {sgs.ConfirmDamage,sgs.TargetSpecified},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
			local slash = room:askForCard(use.from,"slash","@s2_shenwei",data,sgs.Card_MethodResponse, use.from);
			if slash then 
			room:setCardFlag(use.card, self:objectName())
			end
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag(self:objectName()) then
					damage.damage = damage.damage + 1
					data:setValue(damage)
					local log= sgs.LogMessage()
	log.type = "#skill_add_damage"
		log.from = damage.from
		log.to:append(damage.to)
		log.arg = self:objectName()
		log.arg2  = damage.damage
		room:sendLog(log)
		end
			end
			return false
	end
}

s2_yizhan = sgs.CreateTriggerSkill{
	name = "s2_yizhan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local slash = damage.card
		if slash and damage.from and damage.from:objectName() ~= damage.to:objectName() then
					if player:askForSkillInvoke(self:objectName(), data) then
						player:drawCards(1, self:objectName())
						  damage.prevented = true
                data:setValue(damage)
                return true
					end
		end
		return false
	end
}
s2_guanyunzhang:addSkill(s2_shenwei)
s2_guanyunzhang:addSkill(s2_yizhan)
sgs.LoadTranslationTable{
	["s2_guanyunzhang"] = "关云长",
	["&s2_guanyunzhang"] = "关云长",
	["#s2_guanyunzhang"] = " 绝伦逸群",
	["designer:s2_guanyunzhang"] = "流天泪心龙",
	
	["s2_shenwei"] = "神威",
	[":s2_shenwei"] = "当你使用【杀】指定一名角色时，可再打出一张【杀】，若如此做，此【杀】造成的伤害+1。",
	["@s2_shenwei"] = "你可以发动“神威”",
	
	["s2_yizhan"] = "义战",
	[":s2_yizhan"] = "当你对其他角色造成1点伤害时，你可防止此伤害，摸一张牌。",
	
}

s2_huanghansheng = sgs.General(extension_jx,"s2_huanghansheng","shu","4")

s2_chuanyang = sgs.CreateTriggerSkill{
	name = "s2_chuanyang",
	events = {sgs.TargetSpecified},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.from and use.from:hasSkill(self:objectName()) then
				if use.card:isKindOf("Slash") then 
					if use.from:objectName() == player:objectName() then
					   for _,p in sgs.qlist(use.to) do 
				if (p:getMark("Equips_of_Others_Nullified_to_You") == 0) then 
					p:addQinggangTag(use.card)
				end
			end 
				room:setEmotion(use.from, "weapon/qinggang_sword")
				room:sendCompulsoryTriggerLog(use.from, "s2_chuanyang", true)
				room:broadcastSkillInvoke(self:objectName())
					end
				end
			end
			return false
		end
	end,
}
s2_chuanyangTargetMod = sgs.CreateTargetModSkill{
	name = "#s2_chuanyang-target",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("s2_chuanyang") and card:isKindOf("Slash") then
			return 1000
		else
			return 0
		end
	end
}
s2_yizhan_2 = sgs.CreateTriggerSkill{
	name = "s2_yizhan_2",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
		if player:isWounded() then
			draw.num = draw.num + player:getLostHp()
			data:setValue(draw)
			room:sendCompulsoryTriggerLog(player, "s2_yizhan_2", true)
		end
	end
}

extension_jx:insertRelatedSkills("s2_chuanyang","#s2_chuanyang-target")
s2_huanghansheng:addSkill(s2_chuanyang)
s2_huanghansheng:addSkill(s2_chuanyangTargetMod)
s2_huanghansheng:addSkill(s2_yizhan_2)
--http://tieba.baidu.com/p/1670365595
sgs.LoadTranslationTable{
	["s2_huanghansheng"] = "黄汉升",
	["&s2_huanghansheng"] = "黄汉升",
	["#s2_huanghansheng"] = "勇冠三军",
	["designer:s2_huanghansheng"] = "流天泪心龙",
	
	["s2_chuanyang"] = "穿杨",
	["$s2_chuanyang"] = "百步穿杨！",
	[":s2_chuanyang"] = "<font color=\"blue\"><b>锁定技，</b></font>你使用的【杀】无距离限制，且无视目标角色的防具。",
	
	["s2_yizhan_2"] = "益战",
	[":s2_yizhan_2"] = "<font color=\"blue\"><b>锁定技，</b></font>摸排阶段，你额外摸X张牌，X等于你已损失的体力值。",
}

s2_z_zhonghui = sgs.General(extension_jx,"s2_z_zhonghui","wei","4")

s2_guimou_2 = sgs.CreateTriggerSkill{
	name = "s2_guimou_2",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged, sgs.CardFinished, sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event ==sgs.Damaged then
		local damage = data:toDamage()
				if room:askForSkillInvoke(player, self:objectName(), data) then
					local judge = sgs.JudgeStruct()
				judge.pattern = ".|diamond"
				judge.good = false
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				end
			elseif event == sgs.CardFinished then 
			local use = data:toCardUse()
			if use.card:isKindOf("Peach") then 
			if room:askForSkillInvoke(player, self:objectName(), data) then
					local judge = sgs.JudgeStruct()
				judge.pattern = ".|diamond"
				judge.good = false
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				end
				end
				elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() and judge:isGood() and room:getCardPlace(judge.card:getEffectiveId()) == sgs.Player_PlaceJudge then
				player:addToPile("s2_gong", judge.card:getEffectiveId())
				room:broadcastSkillInvoke(self:objectName(), math.random(2))
			end
		end
	end
}
s2_guimou_2Distance = sgs.CreateDistanceSkill{
	name = "#s2_guimou_2Distance",
	correct_func = function(self, from, to)
		if to:hasSkill(self:objectName()) then
			return to:getPile("s2_gong"):length()
		else
			return 0
		end
	end  
}

s2_qizha = sgs.CreateTriggerSkill{
	name = "s2_qizha" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	waked_skills = "s2_andu",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "s2_qizha")
		if room:changeMaxHpForAwakenSkill(player) then
			room:handleAcquireDetachSkills(player, "s2_andu")
			room:broadcastSkillInvoke(self:objectName())
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
		   and (target:getPhase() == sgs.Player_Start)
		   and (target:getMark("s2_qizha") == 0)
		   and ((target:getPile("s2_gong"):length() >= 3) or target:canWake(self:objectName()))
	end
}

s2_anduCard = sgs.CreateSkillCard{
	name = "s2_andu" ,
	will_throw = false ,
	target_fixed = true ,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		 room:throwCard(self, nil);
		 if self:subcardsLength() == 2 then
		 	local playerdata = sgs.QVariant()
				playerdata:setValue(source)
				room:setTag("s2_andu", playerdata)
		elseif self:subcardsLength() == 1 then 
		local current = room:getCurrent()
		if current:isAlive() and not  current:isSkipped(sgs.Player_Discard) then
		current:skip(sgs.Player_Discard)
		end
		end
	end
}
s2_andu = sgs.CreateViewAsSkill{
	name = "s2_andu" ,
	n = 999,
	expand_pile = "s2_gong",
	view_filter = function(self, selected, to_select)
	if #selected > 0 then 
		if #selected > 1 then 
		return false 
		else 
		 return sgs.Self:getPile("s2_gong"):contains(to_select:getId())
		 end
		else 
		return sgs.Self:getPile("s2_gong"):contains(to_select:getId())
		end
	end,
	view_as = function(self, cards)
			if #cards > 0 then 
			local acard = s2_anduCard:clone()
			for _, c in ipairs(cards) do
				acard:addSubcard(c)
			end
			acard:setSkillName(self:objectName())
			return acard
			end
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		if  pattern == "@@s2_andu"  then
			return (player:getPile("s2_gong"):length() > 0)
		end
	end,
}
s2_andu_TM = sgs.CreateTriggerSkill{
	name = "#s2_andu" ,
	events = {sgs.TurnStart} ,
	view_as_skill = s2_anduVS,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not player:faceUp() then return false end
		local yuejin = room:findPlayerBySkillName(self:objectName())
		if not yuejin  then return false end
		if yuejin:objectName() == player:objectName() then return false end 
		if yuejin:getPile("s2_gong"):length() > 0  then
			room:askForUseCard(yuejin, "@@s2_andu", "@s2_andu")
		end
		return false
	end
}
s2_anduGive = sgs.CreateTriggerSkill{
	name = "#s2_andu-give" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("s2_andu") then
			local target = room:getTag("s2_andu"):toPlayer()
			room:removeTag("s2_andu")
			if target and target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Start)
	end ,
	priority = 1
}


if not sgs.Sanguosha:getSkill("#s2_andu") then
	s_skillList:append(s2_andu_TM)
end
if not sgs.Sanguosha:getSkill("#s2_andu-give") then
	s_skillList:append(s2_anduGive)
end
if not sgs.Sanguosha:getSkill("s2_andu") then
	s_skillList:append(s2_andu)
end

extension_jx:insertRelatedSkills("s2_guimou_2","#s2_guimou_2Distance")
extension_jx:insertRelatedSkills("s2_andu","#s2_andu")
extension_jx:insertRelatedSkills("s2_andu","#s2_andu-give")

s2_z_zhonghui:addSkill(s2_guimou_2)
s2_z_zhonghui:addSkill(s2_guimou_2Distance)
s2_z_zhonghui:addSkill(s2_qizha)

--http://tieba.baidu.com/p/1268936497
sgs.LoadTranslationTable{
	["s2_z_zhonghui"] = "钟会",
	["&s2_z_zhonghui"] = "钟会",
	["#s2_z_zhonghui"] = "自傲的野心家",
	["designer:s2_z_zhonghui"] = "太阁大将军紫炎",
	
	["s2_gong"] = "功",
	["s2_guimou_2"] = "鬼謀",
	[":s2_guimou_2"] = "每当你受到一次伤害或使用了一张【桃】后，你可以进行一次判定，将非方块结果的判定牌置于你的武将牌上，称为“功”；每有一张“功”，其他角色与你的距离便+1。",
	["$s2_guimou_21"] = "终于轮到我掌权了。",
	["$s2_guimou_22"] = "夺得军权方能施展一番。",
	
	
	["s2_qizha"] = "奇詐",
	["$s2_qizha"] = "时机已到，今日起兵！",
	[":s2_qizha"] = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段开始时，若“功”大于或等于三张，你减1点体力上限，然后获得技能“暗渡”。",
	
	["s2_andu"] = "暗渡",
	[":s2_andu"] =  "其他角色的回合开始前，你可以弃置一张“功”来跳过该角色的弃牌阶段或弃两张“功”，令你进行一个额外的回合。",
}

s2_z_caohui = sgs.General(extension_jx,"s2_z_caohui","wei","4")

s2_congying = sgs.CreateTriggerSkill{
	name = "s2_congying",
	frequency = sgs.Skill_Frequent,
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if (move.from == nil) or (move.from:objectName() == player:objectName()) then return false end
		if (move.to_place == sgs.Player_DiscardPile)
				and ((move.reason.m_reason == sgs.CardMoveReason_S_REASON_JUDGEDONE)) then
			local card_ids = sgs.IntList()
			local i = 0
			for _, card_id in sgs.qlist(move.card_ids) do
				if (sgs.Sanguosha:getCard(card_id):isRed())
						and (((move.reason.m_reason == sgs.CardMoveReason_S_REASON_JUDGEDONE)
						and (move.from_places:at(i) == sgs.Player_PlaceJudge)
						and (move.to_place == sgs.Player_DiscardPile))) then
					card_ids:append(card_id)
				end
				i = i + 1
			end
			if card_ids:isEmpty() then
				return false
			elseif player:askForSkillInvoke(self:objectName(), data) then
				if not card_ids:length() == 1 then 
				while not card_ids:isEmpty() do
					room:fillAG(card_ids, player)
					local id = room:askForAG(player, card_ids, true, self:objectName())
					if id == -1 then
						room:clearAG(player)
						break
					end
					card_ids:removeOne(id)
					room:clearAG(player)
				end
				end
				if not card_ids:isEmpty() then
					for _, id in sgs.qlist(card_ids) do
						if move.card_ids:contains(id) then
							move.from_places:removeAt(listIndexOf(move.card_ids, id))
							move.card_ids:removeOne(id)
							data:setValue(move)
						end
						room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_PlaceHand, move.reason, true)
						if not player:isAlive() then break end
					end
				end
			end
		end
		return false
	end
}

s2_shehua = sgs.CreateTriggerSkill{
	name = "s2_shehua", 
	frequency = sgs.Skill_Wake, 
	events = {sgs.EventPhaseStart}, 
	waked_skills = "s2_shemi",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if 	room:changeMaxHpForAwakenSkill(player, -1) then 
		room:addPlayerMark(player, self:objectName())
		room:handleAcquireDetachSkills(player, "s2_shemi")
		return false
		end
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:getPhase() == sgs.Player_Start and not (target:getMark(self:objectName()) > 0 )then
						return (target:getHp() == 1) or target:canWake(self:objectName())
				end
			end
		end
		return false
	end
}

s2_shemi = sgs.CreateTriggerSkill{
	name = "s2_shemi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
		if room:askForSkillInvoke(player, "s2_shemi", data) then
			draw.num = draw.num + 2 + player:getLostHp()
			data:setValue(draw)
			if draw.num > 5 then
			room:setPlayerFlag(player, self:objectName())
			end
			end
		elseif event == sgs.EventPhaseStart then 
		if player:getPhase()~= sgs.Player_Finish then return false end 
		if player:hasFlag(self:objectName()) then 
		player:turnOver()
		room:sendCompulsoryTriggerLog(player, self:objectName(), true)
		end
		end
	end
}


s2_jiujia = sgs.CreateTriggerSkill{
	name = "s2_jiujia$",
	events = {sgs.AskForPeaches},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.AskForPeaches then
			local dying = data:toDying()
		if dying.who:objectName() ~= player:objectName() or not dying.who:hasLordSkill(self:objectName()) then
			return false
		end
		if player:getHp() > 0 then return false end
		local lieges = room:getLieges("wei", player)
		if lieges:isEmpty() then return false end
		local tohelp = sgs.QVariant()
		tohelp:setValue(player)
		for _, p in sgs.qlist(lieges) do
		if p:faceUp() and not p:hasFlag("Global_PreventPeach") then 
				if  room:askForSkillInvoke(p, self:objectName(), tohelp) then 
				p:turnOver()
				local peach = sgs.Sanguosha:cloneCard("peach",sgs.Card_NoSuit,0)
				peach:deleteLater()
					peach:setSkillName(self:objectName())
					room:useCard(sgs.CardUseStruct(peach,p,player))
					if player:getHp() > 0 then
					break
					end
				end
			end		
				end
			end
		return false
	end
}


if not sgs.Sanguosha:getSkill("s2_shemi") then
	s_skillList:append(s2_shemi)
end

s2_z_caohui:addSkill(s2_congying)
s2_z_caohui:addSkill(s2_shehua)
s2_z_caohui:addSkill(s2_jiujia)
--http://tieba.baidu.com/p/1268936497
sgs.LoadTranslationTable{
	["s2_z_caohui"] = "曹睿",
	["&s2_z_caohui"] = "曹睿",
	["#s2_z_caohui"] = "魏之少主",
	["designer:s2_z_caohui"] = "太阁大将军紫炎",
	
	["s2_congying"] = "聪颖",
	[":s2_congying"] = "当其他角色的红色牌因判定而置入弃牌堆时，你可以获得之。",
	
	["s2_shehua"] = "奢华",
	[":s2_shehua"] = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段开始时，若你的体力值为1，你失去1点体力上限，然后获得“奢靡”。",
	
	["s2_shemi"] = "奢靡",
	[":s2_shemi"] = "摸牌阶段，你可以额外摸x+2张牌。（X为你已失去的体力值）；结束阶段开始时，若你以此法额外摸牌数多于五张，将你的武将牌翻面。",
	
	["s2_jiujia"] = "救驾",
	[":s2_jiujia"] = "<font color=\"orange\"><b>主公技，</b></font>每当你处于濒死状态时，若其他魏势力角色的武将牌正面朝上，其可以将其武将牌翻面视为对你使用一张【桃】。",
	
}

s2_z_zhangyi = sgs.General(extension_jx,"s2_z_zhangyi","shu","4")


s2_feijun = sgs.CreateTriggerSkill{
	name = "s2_feijun",
	events = {sgs.Damage, sgs.CardFinished},
	on_trigger = function(self, event, zhurong, data)
		local room = zhurong:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			local target = damage.to
			if damage.card and damage.card:isKindOf("Slash") and (not zhurong:isKongcheng()) and (not target:isKongcheng()) and (not target:hasFlag("Global_DebutFlag")) and (not damage.chain) and (not damage.transfer) then
				if room:askForSkillInvoke(zhurong, self:objectName(), data) then
					local success = zhurong:pindian(target, "s2_feijun", nil)
					if not success then return false end
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("s2_feijun")
			--room:useCard(sgs.CardUseStruct(slash, zhurong,target), false)
			room:setCardFlag(damage.card, self:objectName())
			room:setPlayerFlag(damage.to, self:objectName())
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:hasFlag(self:objectName()) then
            room:setCardFlag(use.card, "-"..self:objectName())
			local useEX = sgs.CardUseStruct()
						useEX.from = zhurong
						useEX.card = use.card
						
				for _,p in sgs.qlist(use.to) do 
					if p:hasFlag(self:objectName()) then
					room:setPlayerFlag(p, "-"..self:objectName())
					useEX.to:append(p)
					end
				end
					room:useCard(useEX, true) 
					end
		end
		return false
	end
}

s2_z_zhangyi:addSkill(s2_feijun)
sgs.LoadTranslationTable{
	["s2_z_zhangyi"] = "张嶷",
	["&s2_z_zhangyi"] = "张嶷",
	["#s2_z_zhangyi"] = "识断明果",
	["designer:s2_z_zhangyi"] = "太阁大将军紫炎",
	
	["s2_feijun"] = "飞军",
	[":s2_feijun"] = "每当你使用【杀】对目标角色造成伤害后，你可以与该角色拼点：若你赢，视为你对该角色使用了一张【杀】（此杀不计入每阶段的使用限制）。",
	
	
}

s2_z_yangyi = sgs.General(extension_jx,"s2_z_yangyi","shu","4")

s2_zhiyi = sgs.CreateTriggerSkill{
	name = "s2_zhiyi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local cards = room:getNCards(3)
				local left = cards
				local change = 0 
		room:fillAG(left, player)
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		dummy:deleteLater()
		while not left:isEmpty()  do
		if room:askForSkillInvoke(player, "s2_zhiyi_obtain") then 
		change = change + 1
		room:clearAG(player)
		if not left:isEmpty() then
		room:fillAG(left, player)
				local card_id = room:askForAG(player, left, false, "s2_zhiyi")
				left:removeOne(card_id)
				dummy:addSubcard(card_id)
				room:clearAG(player)
		else 
		break
		end
		else 
		break
		end
		end
		if dummy:subcardsLength() > 0 then
				player:obtainCard(dummy)
				end
		room:clearAG(player)
		for i = 1 , change, 1 do
		if not player:isKongcheng() then 
		local card_ex = room:askForExchange(player, self:objectName(), 1,1, false, "s2_zhiyiGoBack", false)
				if card_ex then
				local move = sgs.CardsMoveStruct()
		move.card_ids = card_ex:getSubcards()
		move.to_place = sgs.Player_DrawPile
		 local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "s2_zhiyi", "");
		 move.reason = reason	
			room:setPlayerFlag(player, "Global_GongxinOperator")
			room:moveCardsAtomic(move,false)
			room:setPlayerFlag(player, "-Global_GongxinOperator")
			left:append(sgs.Sanguosha:getCard(card_ex:getSubcards():first()):getEffectiveId())
		end
		end
		end
		if not left:isEmpty() then
			room:askForGuanxing(player, left, sgs.Room_GuanxingUpOnly)
	end
			end
		end
	end
}

s2_chizhaCard = sgs.CreateSkillCard{
	name = "s2_chizha",
	target_fixed = false,
	will_throw = false,
	on_effect = function(self, effect)
		local source = effect.from
		local dest = effect.to
		dest:obtainCard(self)
		local room = source:getRoom()
		local card = room:askForCard(dest, ".|heart|.|hand", "@s2_chizha", sgs.QVariant(), sgs.Card_MethodNone, nil, false, self:objectName(), false)
				if card then
					source:obtainCard(card)
				else
				local victin = sgs.QVariant()
				victin:setValue(dest)
				if dest and source:canPindian(dest)  and source:askForSkillInvoke(self:objectName(), victin) then 
					local success = source:pindian(dest, "s2_chizha", nil)
					if success then 
						dest:throwAllHandCards()
						local recov = sgs.RecoverStruct()
			recov.who = source
			recov.recover = 1
			room:recover(dest, recov)
				else 
				source:throwAllHandCards()
				room:acquireNextTurnSkills(source, "s2_chizha", "kongcheng")
						end
					end
				end
	end
}
s2_chizha = sgs.CreateViewAsSkill{
	name = "s2_chizha",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards)
		if #cards == 1 then
			local xuanhuoCard = s2_chizhaCard:clone()
			xuanhuoCard:addSubcard(cards[1])
			return xuanhuoCard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#s2_chizha")
	end
}

s2_z_yangyi:addSkill(s2_zhiyi)
s2_z_yangyi:addSkill(s2_chizha)
s2_z_yangyi:addRelateSkill("kongcheng")
--http://tieba.baidu.com/p/1268936497
sgs.LoadTranslationTable{
	["s2_z_yangyi"] = "杨仪",
	["&s2_z_yangyi"] = "杨仪",
	["#s2_z_yangyi"] = "以當官顯",
	["designer:s2_z_yangyi"] = "太阁大将军紫炎",
	
	["s2_zhiyi"] = "知意",
	[":s2_zhiyi"] = "准备阶段开始时，你可以观看牌堆顶的三张牌，将其中的等量的牌与你等量的手牌交换，然后将任意数量的牌以任意顺序置于牌堆顶。",
	["s2_zhiyi_obtain"] = "知意",
	["s2_zhiyiGoBack"] = "你需将等量的手牌置于牌堆顶",
	
	["s2_chizha"] = "叱咤",
	[":s2_chizha"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张手牌交给一名其他角色，然后该角色需交给你一张红桃手牌，否则你可以与该角色拼点：若你赢，该角色弃置所有手牌和回复一点体力；若你没赢，你弃置所有手牌和获得技能“空城”直至你下个回合的开始阶段。",
	
}


s2_z_lukang = sgs.General(extension_jx,"s2_z_lukang","wu","4")

s2_qiande = sgs.CreateProhibitSkill{
	name = "s2_qiande",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("Snatch") or (card:isKindOf("TrickCard") and not card:isNDTrick()))
	end
}

s2_hengjiang = sgs.CreateTriggerSkill{
	name = "s2_hengjiang", 
	frequency = sgs.Skill_Wake, 
	events = {sgs.EventPhaseStart}, 
	waked_skills = "s2_qigong",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if 	room:changeMaxHpForAwakenSkill(player, -1) then 
	if player:isWounded() then
				if room:askForChoice(player, self:objectName(), "recover+draw") == "recover" then
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(player, recover)
				else
					room:drawCards(player, 2, self:objectName())
				end
			else
				room:drawCards(player, 2, self:objectName())
			end
		room:addPlayerMark(player, self:objectName())
		room:handleAcquireDetachSkills(player, "s2_qigong")
		return false
		end
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:getPhase() == sgs.Player_Start and not (target:getMark(self:objectName()) > 0 )then
						return (((target:getHp() == 1) or (target:isKongcheng())) or target:canWake(self:objectName()))
				end
			end
		end
		return false
	end
}

s2_qigong = sgs.CreateTriggerSkill{
	name = "s2_qigong" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if (not use.to:contains(player)) or (not use.card:isKindOf("Slash")) then return false end
		for _, lukang in sgs.list(room:findPlayersBySkillName(self:objectName())) do
		if player:objectName() == lukang:objectName() or not lukang:inMyAttackRange(player) then continue end
		if lukang:getPhase() ~= sgs.Player_NotActive then continue end 
		local prompt = string.format("s2_qigong-slash:%s", player:objectName())
				room:askForUseSlashTo(lukang, player, prompt)
		end
	end,
		can_trigger = function(self, target)
		return target
	end,
}
if not sgs.Sanguosha:getSkill("s2_qigong") then
	s_skillList:append(s2_qigong)
end

s2_z_lukang:addSkill(s2_qiande)
s2_z_lukang:addSkill(s2_hengjiang)
--http://tieba.baidu.com/p/1268936497
sgs.LoadTranslationTable{
	["s2_z_lukang"] = "陆抗",
	["&s2_z_lukang"] = "陆抗",
	["#s2_z_lukang"] = "江东的守护神",
	["designer:s2_z_lukang"] = "太阁大将军紫炎",
	
	["s2_qiande"] = "谦德",
	[":s2_qiande"] = "<font color=\"blue\"><b>锁定技，</b></font>你不能被选择为【顺手牵羊】和延时类锦囊的目标。",
	
	["s2_hengjiang"] = "横江",
	[":s2_hengjiang"] = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段开始时，若你的体力值为1或没有手牌，你失去1点体力上限，摸两张牌或回复1点体力，然后获得“齊攻”。",
	
	["s2_qigong"] = "齊攻",
	[":s2_qigong"] = "你的回合外，当你的攻击范围内的其他角色成为【杀】的目标时，你可以对该角色使用一张【杀】。",
	["s2_qigong-slash"] = "你可以发动“齊攻”，对 %src 使用一张【杀】",
	
}

s2_z_panzhang = sgs.General(extension_jx,"s2_z_panzhang","wu","4")
s2_jizhan = sgs.CreateTriggerSkill{
	name = "s2_jizhan",
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.card_ids:isEmpty() then return false end
		if player:getPhase() ~= sgs.Player_NotActive then return false end
		if not (move.from and move.from:isAlive() ) then return false end		
		local basic = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
		if move.from_places:contains(sgs.Player_PlaceTable) and move.to_place == sgs.Player_DiscardPile and
			(basic == sgs.CardMoveReason_S_REASON_USE) then
			local use = move.reason.m_useStruct
			if use.card and use.from and use.card:isKindOf("Slash") and player:objectName() ~= use.from:objectName()  then
				local ids = sgs.IntList()
				if not use.card:isVirtualCard() then					
					ids:append(use.card:getEffectiveId())
				else
					if use.card:subcardsLength() > 0 then
						ids = use.card:getSubcards()
					end
				end
				if not ids:isEmpty() then					
					for _,id in sgs.qlist(move.card_ids) do						
						if not ids:contains(id) then ids:removeOne(id) end
					end
				else
					return false
				end
				local pdata = sgs.QVariant()
				pdata:setValue(use.from)				
				if not ids:isEmpty() then
					if room:askForCard(player,".|"..use.card:getSuitString().."|.|.", string.format("@s2_jizhan-exchange:%s", use.card:getSuitString()),  sgs.QVariant(use.card:getSuitString()), sgs.Card_MethodDiscard) then
					local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
					slash:deleteLater()
					local victims = sgs.SPlayerList()
			slash:setSkillName(self:objectName())
			if not player:isLocked(slash) then
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:canSlash(p, slash, false) then
				victims:append(p)
			end
		end
		if not victims:isEmpty() then
			local use = sgs.CardUseStruct()
			use.from = player
			local dest = room:askForPlayerChosen(player, victims, self:objectName())
			use.to:append(dest)
				use.card = slash
			room:useCard(use)
				end
					end
					end
				end
			end
		end
		return false
	end	
}
s2_z_panzhang:addSkill(s2_jizhan)

sgs.LoadTranslationTable{
	["s2_z_panzhang"] = "潘璋",
	["&s2_z_panzhang"] = "潘璋",
	["#s2_z_panzhang"] = "慷慨相从",
	["designer:s2_z_panzhang"] = "太阁大将军紫炎",
	
	["s2_jizhan"] = "疾斩",
	[":s2_jizhan"] = "你的回合外，其他角色使用【杀】结算完毕后置入弃牌堆时，你可以弃置一张花色相同的牌，然后视为你对一名其他角色使用了一张【杀】。",
	["@s2_jizhan-exchange"] = "你可以发动“疾斩”<br/> <b>操作提示</b>: 选择一张 %src 的牌→点击确定<br/>",
}


s2_z_yanghu = sgs.General(extension_jx,"s2_z_yanghu","qun","4")

s2_xubianCard = sgs.CreateSkillCard{
	name = "s2_xubian",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
	if not source:getPile("s2_zu"):contains(self:getSubcards():first()) then
				source:addToPile("s2_zu", room:getNCards(self:subcardsLength()))
	end
		
		end
}



s2_xubian = sgs.CreateViewAsSkill{
	name = "s2_xubian", 
	n = 999, 
	expand_pile = "s2_zu",
	view_filter = function(self, selected, to_select)
	if  to_select:hasFlag("using") then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
				return not to_select:isEquipped() and not (#selected > 2 ) and sgs.Self:getHandcards():contains(to_select)
		elseif (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
				or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "jink" then
				return sgs.Self:getPile("s2_zu"):contains(to_select:getId()) and (#selected < 1 ) 
			end
			end
			return false
	end ,
	view_as = function(self, cards) 
	if #cards > 0 then
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local se_jcard = s2_xubianCard:clone()
			for i=1, #cards, 1 do
				se_jcard:addSubcard(cards[i]:getId())
			end
			return se_jcard
			else
			local card = sgs.Sanguosha:cloneCard("jink",sgs.Card_NoSuit,0)
				for i=1, #cards, 1 do
				card:addSubcard(cards[i]:getId())
			end
			card:setSkillName(self:objectName())
			return card
			end
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#s2_xubian")
	end,
		enabled_at_response = function(self, player, pattern)
		return	(pattern == "jink") and player:getPile("s2_zu"):length() > 0 
	end ,
	
}

s2_qibei = sgs.CreateTriggerSkill{
	name = "s2_qibei" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	waked_skills = "s2_qingfa",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "s2_qibei")
		if room:changeMaxHpForAwakenSkill(player, -1) then
			room:handleAcquireDetachSkills(player, "s2_qingfa")
			room:setPlayerFlag(player, "s2_qibei")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
		   and (target:getPhase() == sgs.Player_Finish)
		   and (target:getMark("s2_qibei") == 0)
		   and ((target:getPile("s2_zu"):length() >= 3) or target:canWake(self:objectName()))
	end
}
s2_qibei_Turn = sgs.CreateTriggerSkill{
	name = "#s2_qibei" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.EventPhaseEnd} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not player:hasFlag("s2_qibei") then return false end 
			room:setPlayerFlag(player, "-s2_qibei")
			player:gainAnExtraTurn()
		return false
	end ,
}

s2_qingfa_select = sgs.CreateSkillCard {
	name = "s2_qingfa_select",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	mute = true,
	on_use = function(self, room, source, targets)
		local pattern = room:askForChoice(source, "s2_qingfa-new", "snatch+iron_chain")
		if pattern then
		if pattern == "snatch" then 
			room:setPlayerMark(source, "s2_qingfa_select", 1)
		elseif pattern == "iron_chain" then 
			room:setPlayerMark(source, "s2_qingfa_select", 2)
		else 
		return false 
			end
			local prompt = string.format("@@s2_qingfa:%s", pattern)
			room:askForUseCard(source, "@s2_qingfa", prompt)			
		end
	end,
}

s2_qingfaCard = sgs.CreateSkillCard {
	name = "s2_qingfa",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	player = nil,
	on_use = function(self, room, source)
		player = source
	end,
	filter = function(self, targets, to_select, player)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@s2_qingfa" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				card:setSkillName("s2_qingfa")
			end
			if card and card:targetFixed() then
				return false
			end
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
			return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
		end		
		local pattern 
		if sgs.Self:getMark("s2_qingfa_select") == 1 then 
		pattern = "snatch"
		elseif sgs.Self:getMark("s2_qingfa_select") == 2 then 
		pattern = "iron_chain"
		end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("s2_qingfa")
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,	
	target_fixed = function(self)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@s2_qingfa" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
			end
			return card and card:targetFixed()
		end		
		local pattern 
		if sgs.Self:getMark("s2_qingfa_select") == 1 then 
		pattern = "snatch"
		elseif sgs.Self:getMark("s2_qingfa_select") == 2 then 
		pattern = "iron_chain"
		end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		return card and card:targetFixed()
	end,	
	feasible = function(self, targets)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@s2_qingfa" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				card:setSkillName("s2_qingfa")
			end
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
			return card and card:targetsFeasible(qtargets, sgs.Self)
		end		
		local pattern 
		if sgs.Self:getMark("s2_qingfa_select") == 1 then 
		pattern = "snatch"
		elseif sgs.Self:getMark("s2_qingfa_select") == 2 then 
		pattern = "iron_chain"
		end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("s2_qingfa")
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,	
	on_validate = function(self, card_use)
		local yuji = card_use.from
		local room = yuji:getRoom()		
		local to_guhuo = self:getUserString()		
			local subcards = self:getSubcards()
			local cardA = sgs.Sanguosha:getCard(subcards:first())
			local cardB = sgs.Sanguosha:getCard(subcards:last())
			local user_str = to_guhuo
			local use_card = sgs.Sanguosha:cloneCard(user_str, sgs.Card_SuitToBeDecided, -1)
			use_card:setSkillName("s2_qingfa")
			use_card:addSubcard(cardA)
			use_card:addSubcard(cardB)
			use_card:deleteLater()			
			return use_card
	end,
}

s2_qingfa = sgs.CreateViewAsSkill {
	name = "s2_qingfa",	
	n = 2,	
	expand_pile = "s2_zu",
	enabled_at_play = function(self, player)
	return not player:getPile("s2_zu"):isEmpty()
	end ,
	view_as = function(self, cards)
		if  sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			if sgs.Sanguosha:getCurrentCardUsePattern() == "@s2_qingfa" then
				local pattern 
		if sgs.Self:getMark("s2_qingfa_select") == 1 then 
		pattern = "snatch"
		elseif sgs.Self:getMark("s2_qingfa_select") == 2 then 
		pattern = "iron_chain"
		end
				local c = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
				if c and #cards == 2 then
					c:deleteLater()
					local card = s2_qingfaCard:clone()
					card:setUserString(c:objectName())
					card:addSubcard(cards[1])
					card:addSubcard(cards[2])
					return card
				else
					return nil
				end
			else
				return nil
			end
		else
			local cd = s2_qingfa_select:clone()
			return cd
		end
	end,
	view_filter = function(self, selected, to_select)
				return sgs.Self:getPile("s2_zu"):contains(to_select:getId()) and (#selected < 2 ) 
	end ,
enabled_at_response = function(self, player, pattern)
		if pattern == "@s2_qingfa" then
			return not player:getPile("s2_zu"):isEmpty()
		end		
end		
	}




if not sgs.Sanguosha:getSkill("s2_qingfa") then
	s_skillList:append(s2_qingfa)
end

s2_z_yanghu:addSkill(s2_xubian)
s2_z_yanghu:addSkill(s2_qibei_Turn)
s2_z_yanghu:addSkill(s2_qibei)
extension_jx:insertRelatedSkills("s2_qibei","#s2_qibei")

sgs.LoadTranslationTable{
	["s2_z_yanghu"] = "羊祜",
	["&s2_z_yanghu"] = "羊祜",
	["#s2_z_yanghu"] = "西晋的元勋",
	["designer:s2_z_yanghu"] = "太阁大将军紫炎",
	
	["s2_zu"] = "卒",
	["s2_xubian"] = "戌边",
	[":s2_xubian"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置X张手牌，然后从牌堆顶展示X张牌置于你的武将牌上（X 至多为3），称为“卒”；你可以将一张“卒”当【闪】使用或打出。",

	["s2_qibei"] = "齐备",
	[":s2_qibei"] = "<font color=\"purple\"><b>觉醒技，</b></font>回合结束阶段开始时，若“卒”大于或等于三张，你减1点体力上限，然后获得技能“请伐”，然后此回合结束后进行一个额外的回合。",
	
	["s2_qingfa"] = "请伐",
	["~s2_qingfa"] = "选择两张“卒”→点击确定<br/>",
	["@@s2_qingfa"] = "你可以将两张“卒”当 %src 使用。",
	["s2_qingfa_select"] = "请伐",
	["s2_qingfa-new"] = "请伐",
	[":s2_qingfa"] = "你可以将两张“卒”当【顺手牵羊】或【铁索连环】使用。",
}




s2_z_simayan = sgs.General(extension_jx,"s2_z_simayan$","jin","4")


s2_guijin = sgs.CreateTriggerSkill{
	name = "s2_guijin" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.PreCardUsed, sgs.CardResponded, sgs.EventPhaseStart} ,   
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			local can_trigger = true
			if player:hasFlag("s2_guijinSlashInPlayPhase") then
				can_trigger = false
				player:setFlags("-s2_guijinSlashInPlayPhase")
			end
			if  player:isAlive() and player:hasSkill(self:objectName()) then
				local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getKingdom()~= "jin" then
				targets:append(p)
			end
			end
			if targets:isEmpty() then return false end 
				if can_trigger  then
					local target = room:askForPlayerChosen(player, targets, self:objectName(), "s2_guijin-invoke", true, true)
			if not target then return false end
						room:setPlayerProperty(target, "kingdom", sgs.QVariant("jin"))
				end
			end
		elseif event == sgs.PreCardUsed or event == sgs.CardResponded then
			if player:getPhase() == sgs.Player_Play then
				local card = nil
				if event == sgs.PreCardUsed then
					card = data:toCardUse().card
				else
					card = data:toCardResponse().m_card			 
				end
				if card:isKindOf("Slash") then
					player:setFlags("s2_guijinSlashInPlayPhase")
				end
			end
		end
		return false
	end
}


s2_z_baye = sgs.CreateTriggerSkill{
	name = "s2_z_baye" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
		local room = player:getRoom()
		local x = 0 
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getKingdom()== "jin" then
				x = x + 1 
			end
			end
			
		if x >  5 then 
		x = 5
		end
			draw.num = x
			data:setValue(draw)
			room:sendCompulsoryTriggerLog(player, self:objectName(),true)
		return false
	end
}

s2_yitong = sgs.CreateTriggerSkill{
	name = "s2_yitong$",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,
	waked_skills = "jijiang,zhiba,songwei,lianpo",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = 0 
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getKingdom() == "jin" then
				x = x + 1 
			end
		end
		if x > (room:getAlivePlayers():length()/2) or player:canWake(self:objectName()) then 
			room:addPlayerMark(player, "s2_yitong")
			if room:changeMaxHpForAwakenSkill(player, -1) then
				if player:isLord() then
					room:handleAcquireDetachSkills(player, "jijiang")
					room:handleAcquireDetachSkills(player, "zhiba")
					room:handleAcquireDetachSkills(player, "songwei")
					room:handleAcquireDetachSkills(player, "lianpo")
					end
			end
		end
	end,

	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Start)
				and target:hasLordSkill("s2_yitong")
				and target:isAlive()
				and (target:getMark("s2_yitong") == 0)
	end
}

s2_z_simayan:addSkill(s2_guijin)
s2_z_simayan:addSkill(s2_z_baye)
s2_z_simayan:addSkill(s2_yitong)
sgs.LoadTranslationTable{
	["s2_z_simayan"] = "司马炎",
	["&s2_z_simayan"] = "司马炎",
	["#s2_z_simayan"] = "天下霸主",
	["designer:s2_z_simayan"] = "太阁大将军紫炎",
	
	["s2_guijin"] = "归晋",
	[":s2_guijin"] = "若你未于出牌阶段内使用或打出【杀】，回合结束阶段开始时，你可以将一名角色的势力改变为晋。",
	["s2_guijin-invoke"] ="你可以发动“归晋”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	
	["s2_z_baye"] = "霸业",
	[":s2_z_baye"] = "<font color=\"blue\"><b>锁定技，</b></font>摸牌阶段，你摸X张牌。（X为埸上其他晋角色数且至多为5）",
	
	["s2_yitong"] = "一統",
	[":s2_yitong"] = "<font color=\"orange\"><b>主公技，</b></font><font color=\"purple\"><b>觉醒技，</b></font>回合开始阶段开始时，若埸上晋角色数大于其他势力角色数，你减1点体力上限，然后获得技能“激将”、“颂威”、“制霸”、“连破”。",
}


s2_kongrong = sgs.General(extension_jx,"s2_kongrong","qun","3")


s2_gangzhi = sgs.CreateTriggerSkill{
	name = "s2_gangzhi" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.DamageInflicted, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.damage > 1 then 
			room:sendCompulsoryTriggerLog(player, self:objectName(),true)
			 room:setEmotion(player, "armor/silver_lion");
				local log = sgs.LogMessage()
				log.type = "#SilverLion";
				log.from = player;
				log.arg = damage.damage;
				log.arg2 = self:objectName();
				room:sendLog(log);

				damage.damage = 1;
				data:setValue(damage);
		end
		elseif event == sgs.CardsMoveOneTime then 
		local move = data:toMoveOneTime()
			if (not move.from) or (move.from:objectName() ~= player:objectName()) then return false end
			if (move.to_place == sgs.Player_DiscardPile) then	
			if  move.from_places:contains(sgs.Player_PlaceEquip) then
				local room = player:getRoom()
				 if (player:isWounded()) then
						room:setEmotion(player, "armor/silver_lion");
						local recov = sgs.RecoverStruct()
			recov.who = player
			recov.recover = 1
			room:recover(player, recov)
					end
				end
			end
		end
		return false
	end
}


s2_qiangrangCard = sgs.CreateSkillCard{
	name = "s2_qiangrang" ,
	filter = function(self, targets, to_select)
		if #targets > 0 then return false end
		if (to_select:objectName() == sgs.Self:objectName()) then return false end
		local from
		for _, p in sgs.qlist(sgs.Self:getSiblings()) do
			if p:hasFlag("s2_qiangrangSource") then
				from = p
				break
			end
		end
		local card = sgs.Card_Parse(sgs.Self:property("s2_qiangrang"):toString())
		if from and from:isProhibited(to_select, card) then return false end
		return true
	end,
	on_effect = function(self, effect)
		effect.to:setFlags("s2_qiangrangTarget")
	end
}
s2_qiangrangVS = sgs.CreateOneCardViewAsSkill{
	name = "s2_qiangrang" ,
	response_pattern = "@@s2_qiangrang",
	filter_pattern = ".!",
	view_as = function(self, card)
		local liuli_card = s2_qiangrangCard:clone()
		liuli_card:addSubcard(card)
		return liuli_card
	end
}
s2_qiangrang = sgs.CreateTriggerSkill{
	name = "s2_qiangrang" ,
	events = {sgs.TargetConfirming} ,
	view_as_skill = s2_qiangrangVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("TrickCard") and use.card:isNDTrick()
				and use.to:contains(player) and player:canDiscard(player,"he") and use.to:length() > 1  then
			local players = room:getOtherPlayers(player)
			players:removeOne(use.from)
			local can_invoke = false
			for _, p in sgs.qlist(players) do
				if use.from:canSlash(p, use.card) and player:inMyAttackRange(p) then
					can_invoke = true
					break
				end
			end
			if can_invoke then
				local prompt = "@s2_qiangrang:" .. use.from:objectName()
				room:setPlayerFlag(use.from, "s2_qiangrangSource")
				room:setTag("CurrentUseStruct", data)
				room:setPlayerProperty(player, "s2_qiangrang", sgs.QVariant(use.card:toString()))
				if room:askForUseCard(player, "@@s2_qiangrang", prompt, -1, sgs.Card_MethodDiscard) then
					room:setPlayerProperty(player, "s2_qiangrang", sgs.QVariant())
					room:setPlayerFlag(use.from, "-s2_qiangrangSource")
					for _, p in sgs.qlist(players) do
						if p:hasFlag("s2_qiangrangTarget") then
							p:setFlags("-s2_qiangrangTarget")
							use.to:removeOne(player)
							use.to:append(p)
							room:sortByActionOrder(use.to)
							data:setValue(use)
							room:getThread():trigger(sgs.TargetConfirming, room, p, data)
							return false
						end
					end
				else
					room:setPlayerProperty(player, "s2_qiangrang", sgs.QVariant())
					room:setPlayerFlag(use.from, "-s2_qiangrangSource")
				end
				room:removeTag("CurrentUseStruct")
			end
		end
		return false
	end
}

s2_kongrong:addSkill(s2_qiangrang)
s2_kongrong:addSkill(s2_gangzhi)
--http://tieba.baidu.com/p/1675583902



sgs.LoadTranslationTable{
	["s2_kongrong"] = "孔融",
	["&s2_kongrong"] = "孔融",
	["#s2_kongrong"] = "刚直不阿",
	["designer:s2_kongrong"] = "zzm5296776",
	
	["s2_gangzhi"] = "刚直",
	[":s2_gangzhi"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你受到伤害时，若此伤害大于1点，防止多余的伤害。每当你失去一次装备区里的牌时，你回复1点体力。",
	
	["s2_qiangrang"] = "谦让",
	[":s2_qiangrang"] = "若一个锦囊指定了包括你在内的多名目标时，你可以在结算之前弃置一张牌，然后将该锦囊对你的结算转移给一名其他角色。",
	
	
}

s2_2_shenguanyu = sgs.General(extension_jx,"s2_2_shenguanyu","god","5")
s2_mieshicard = sgs.CreateSkillCard{
	name = "s2_mieshi",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
	
	end,
}
s2_mieshiVS = sgs.CreateViewAsSkill{
	name = "s2_mieshi",
	n = 999,
	view_filter = function(self, selected, to_select)
		return to_select:getSuitString() ~=  sgs.Self:property("s2_mieshi"):toString()
	end, 
	view_as = function(self, cards)
	if #cards >= 1 then 
		local card = s2_mieshicard:clone()
		for i=1, #cards, 1 do
		    card:addSubcard(cards[i])
		end
		card:setSkillName(self:objectName())
		return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if  pattern == "@@s2_mieshi"  then
			return not player:isNude()
		end
	end,
}

s2_mieshi = sgs.CreateTriggerSkill{
	name = "s2_mieshi",
	events = {sgs.ConfirmDamage,sgs.TargetSpecified},
	view_as_skill = s2_mieshiVS,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and player:getPhase() == sgs.Player_Play then
			room:setPlayerProperty(use.from, "s2_mieshi", sgs.QVariant(use.card:getSuitString()))
			room:setTag("CurrentUseStruct", data)
			local card =  room:askForUseCard(use.from, "@@s2_mieshi", "@s2_mieshi:"..use.card:getSuitString())
			room:setPlayerProperty(use.from, "s2_mieshi", sgs.QVariant())
			room:removeTag("CurrentUseStruct")
			if card then 
			room:setCardFlag(use.card, self:objectName())
			room:setPlayerMark(use.from, self:objectName(), card:subcardsLength())
			end
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag(self:objectName()) then
					damage.damage = damage.damage + damage.from:getMark(self:objectName())
					data:setValue(damage)
					local log= sgs.LogMessage()
	log.type = "#skill_add_damage"
		log.from = damage.from
		log.to:append(damage.to)
		log.arg = self:objectName()
		log.arg2  = damage.damage
		room:sendLog(log)
		end
			end
			return false
	end
}

s2_zhonghunCard = sgs.CreateSkillCard{
	name = "s2_zhonghun",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0  and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		target:addToPile("s2_zhonghun", self, false)
	end
}
s2_zhonghunVS = sgs.CreateOneCardViewAsSkill{
	name = "s2_zhonghun",
	response_pattern = "@@s2_zhonghun" ,
	filter_pattern = ".|.|.|hand" ,
	view_as = function(self, cd)
		local card = s2_zhonghunCard:clone()
		card:addSubcard(cd)
		return card
	end
}

s2_zhonghun = sgs.CreateTriggerSkill{
	name = "s2_zhonghun" ,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed, sgs.EventPhaseStart} ,
	view_as_skill = s2_zhonghunVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if (not use.to:contains(player)) or (not use.card:isKindOf("Slash")) then
				return false
			end
			if player:getPile("s2_zhonghun"):length() > 0 and player:isAlive() then
			if room:askForSkillInvoke(player, self:objectName(),data) then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
				room:throwCard(sgs.Sanguosha:getCard(player:getPile("s2_zhonghun"):first()), reason, nil)
				local list = use.nullified_list
				table.insert(list,player:objectName())
				use.nullified_list = list
				data:setValue(use)
			end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) then
			room:askForUseCard(player, "@@s2_zhonghun", "@s2_zhonghun")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}




s2_2_shenguanyu:addSkill(s2_mieshi)
s2_2_shenguanyu:addSkill(s2_zhonghun)



sgs.LoadTranslationTable{
	["s2_2_shenguanyu"] = "神关羽",
	["&s2_2_shenguanyu"] = "神关羽",
	["#s2_2_shenguanyu"] = "武神下凡",
	["designer:s2_2_shenguanyu"] = "孔孟老庄胡",
	
	["s2_mieshi"] = "灭世",
	[":s2_mieshi"] = "当你在出牌阶段内使用【杀】指定一名角色为目标后，你可以弃掉任意张与之花色不同的牌，此【杀】伤害增加X（X为弃置牌的数量。）",
	["@s2_mieshi"] = "你可以发动“灭世”",
	["~s2_mieshi"] = "选择任意张与 【杀】 花色不同的牌→点击确定<br/>",
	
	["@s2_zhonghun"] = "你可以发动“忠魂”",
	["s2_zhonghun"] = "忠魂",
	[":s2_zhonghun"] = "结束阶段开始时，你可以将一张手牌移出游戏并选择一名其他角色，该角色成为【杀】的目标时其可以将该牌置入弃牌堆，则该【杀】无效。",
	["~s2_zhonghun"] = "选择一张手牌→选择一名其他角色→点击确定<br/>",
	
}

s2_shenzhugeliang = sgs.General(extension_jx,"s2_shenzhugeliang","god","3")

s2_shenji = sgs.CreateProhibitSkill{
	name = "s2_shenji" ,
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("TrickCard")) 
		and card:getSuit() ~= sgs.Card_Heart 
	end
}

s2_duanjia = sgs.CreateTriggerSkill{
	name = "s2_duanjia" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.EventPhaseChanging} ,   
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Judge and player:isAlive() and player:getJudgingArea():length() > 0 then
				for _,zhugeliang in sgs.list(room:findPlayersBySkillName("s2_duanjia"))do
					if zhugeliang:canDiscard(zhugeliang, "h") and room:askForDiscard(zhugeliang,self:objectName(),1,1,true,false,"s2_duanjia",".") then
						player:skip(sgs.Player_Judge)
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target  ~= nil
	end
}

function getCardList(intlist)
	local ids = sgs.CardList()
	for _, id in sgs.qlist(intlist) do
		ids:append(sgs.Sanguosha:getCard(id))
	end
	return ids
end
s2_guantian = sgs.CreateTriggerSkill{
	name = "s2_guantian",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, shenlvmeng, data)
		if shenlvmeng:getPhase() ~= sgs.Player_Draw then
			return false
		end
		local room = shenlvmeng:getRoom()
		if not shenlvmeng:askForSkillInvoke(self:objectName()) then
			return false
		end
		local card_ids = room:getNCards(5)
		room:fillAG(card_ids)
		local to_get = sgs.IntList()
		local to_throw = sgs.IntList()
		while not card_ids:isEmpty() do
			local card_id = room:askForAG(shenlvmeng, card_ids, false, "s2_guantian")
			card_ids:removeOne(card_id)
			to_get:append(card_id)--弃置剩余所有符合花色的牌(原文：throw the rest cards that matches the same suit)
			local card = sgs.Sanguosha:getCard(card_id)
			local suit = card:getSuit()
			room:takeAG(shenlvmeng, card_id, false)
			local _card_ids = card_ids
			for _,id in sgs.qlist(_card_ids) do
				local c = sgs.Sanguosha:getCard(id)
				if c:getSuit() == suit then
					card_ids:removeOne(id)
					room:takeAG(nil, id, false)
					to_throw:append(id)
				end
			end
			for _,id in sgs.qlist(card_ids) do
				local c = sgs.Sanguosha:getCard(id)
				if c:getSuit() == suit then
					card_ids:removeOne(id)
					room:takeAG(nil, id, false)
					to_throw:append(id)
				end
			end
		end
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		if not to_get:isEmpty() then
			dummy:addSubcards(getCardList(to_get))
			shenlvmeng:obtainCard(dummy)
		end
		dummy:clearSubcards()
		if not to_throw:isEmpty() then
			dummy:addSubcards(getCardList(to_throw))
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, shenlvmeng:objectName(), self:objectName(),"")
			room:throwCard(dummy, reason, nil)
		end
		dummy:deleteLater()
		room:clearAG()
		return true
	end
}


s2_shenzhugeliang:addSkill(s2_shenji)
s2_shenzhugeliang:addSkill(s2_duanjia)
s2_shenzhugeliang:addSkill(s2_guantian)


sgs.LoadTranslationTable{
	["s2_shenzhugeliang"] = "神诸葛亮",
	["&s2_shenzhugeliang"] = "神诸葛亮",
	["#s2_shenzhugeliang"] = "伏龍",
	["designer:s2_shenzhugeliang"] = "孔孟老庄胡",
	
	["s2_shenji"] = "神机",
	[":s2_shenji"] = "<font color=\"blue\"><b>锁定技，</b></font>你不可以成为除红桃花色锦囊牌之外任意锦囊牌的目标。",
	
	["s2_duanjia"] = "遁甲",
	[":s2_duanjia"] = "一名角色的准备阶段开始时，若其的判定区里有牌，你可以弃一张手牌，则该角色跳过判定阶段。",
	
	["s2_guantian"] = "观天",
	[":s2_guantian"] = "摸牌阶段，你可以放弃摸牌且亮出牌顶五张牌，选取花色不同的牌并弃置剩余。",
	
	
}


s2_shenluxun = sgs.General(extension_jx,"s2_shenluxun","god","3")

s2_liantun = sgs.CreateTriggerSkill{
	name = "s2_liantun",
	frequency = sgs.Skill_Frequent, 
	events = {sgs.CardResponded, sgs.TargetSpecified, sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() and judge:isGood() and room:getCardPlace(judge.card:getEffectiveId()) == sgs.Player_PlaceJudge then
				room:obtainCard(player,judge.card)
			end
			end
			local card 
			if event == sgs.CardResponded then 
		local resp = data:toCardResponse()
						 card = resp.m_card
						elseif event == sgs.TargetSpecified then 
						local use = data:toCardUse()
						card = use.card
						end 
						if card and player:getPhase() == sgs.Player_Play and card:isKindOf("BasicCard") then 
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local judge = sgs.JudgeStruct()
					judge.who = player
					judge.pattern = ".|.|2~9"
					judge.reason = self:objectName()
					judge.play_animation = false
					room:judge(judge)
		end 
		end
	end,
}


s2_tiantanCard = sgs.CreateSkillCard{
	name = "s2_tiantan" ,
	filter = function(self, targets, to_select)
			return #targets < 1 
	end ,
	on_effect = function(self, effect)
		effect.from:getRoom():damage(sgs.DamageStruct("s2_tiantan", effect.from, effect.to,1,sgs.DamageStruct_Fire))
	end
}
s2_tiantan =  sgs.CreateViewAsSkill{
	name = "s2_tiantan" ,
	n = 2 ,
	view_filter=function(self,selected,to_select)
		 if #selected == 0 then
			return true
		elseif #selected == 1 then
			local card = selected[1]
			if to_select:getNumber() == card:getNumber() then
				return true
			end
		else
			return false
		end
	end ,
	view_as = function(self, cards)
		if #cards == 2 then
		local duwu = s2_tiantanCard:clone()
			for _, c in ipairs(cards) do
				duwu:addSubcard(c)
			end
			return duwu
		end
	end ,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he")
	end
}



s2_shenluxun:addSkill("huoji")
s2_shenluxun:addSkill(s2_liantun)
s2_shenluxun:addSkill(s2_tiantan)
sgs.LoadTranslationTable{
	["s2_shenluxun"] = "神陆逊",
	["&s2_shenluxun"] = "神陆逊",
	["#s2_shenluxun"] = "連營火神",
	["designer:s2_shenluxun"] = "孔孟老庄胡",
	
	["s2_liantun"] = "连屯",
	[":s2_liantun"] = "当你在出牌阶段内使用或打出一张基本牌时，你可以判定，若为2~9点数，则获得判定牌。",
	
	["s2_tiantan"] = "天焰",
	[":s2_tiantan"] = "出牌阶段，你可以弃置两张相同点数的牌并对一名角色造成1点火焰伤害。",
	
	
}
--[[

s2_shencaocao = sgs.General(extension_jx,"s2_shencaocao","god","4")


s2_xinzhan = sgs.CreateTriggerSkill{
	name = "s2_xinzhan",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local phase = player:getPhase()
		local room = player:getRoom()
		if phase == sgs.Player_Start then
		if player:isNude() then return false end 
		if room:askForDiscard(player,self:objectName(),1,1,true,true,"s2_xinzhan-invoke",".") then
			local shou = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"s2_xinzhan-invoke2")
			if shou then
				room:showAllCards(shou,player)
			end
			end
		end
		return false
	end
}

s2_xiezunCard = sgs.CreateSkillCard{
	name = "s2_xiezun",
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() then return false end
		if #targets == 0 then 
		local xiezun_max = 0
		for _, p in sgs.qlist(sgs.Self:getSiblings()) do
		xiezun_max = math.max(xiezun_max, p:getHandcardNum())
		end
		return to_select:getHandcardNum() == xiezun_max 
		end
		if #targets == 1 then
		local xiezun_min = 999
		for _, p in sgs.qlist(sgs.Self:getSiblings()) do
		xiezun_min = math.min(xiezun_min, p:getHandcardNum())
		end
		return to_select:getHandcardNum() == xiezun_min 
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local a = targets[1]
		local b = targets[2]
		a:setFlags("DimengTarget")
		b:setFlags("DimengTarget")
		local to_exchange = room:askForExchange(a, "s2_xiezun", math.floor(a:getHandcardNum() / 2),math.floor(a:getHandcardNum() / 2))
					room:moveCardTo(to_exchange, b, sgs.Player_PlaceHand, false)
	   	a:setFlags("-DimengTarget")
	   	b:setFlags("-DimengTarget")
	end
}
s2_xiezun = sgs.CreateViewAsSkill{
	name = "s2_xiezun",
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return true
	end ,
	view_as = function(self, cards)
	if #cards == 1 then
		local card = s2_xiezunCard:clone()
	   		card:addSubcard(cards[1])
	   	return card
		end
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#s2_xiezun")
	end
}

s2_yushu = sgs.CreateTriggerSkill{
	name = "s2_yushu",
	events = {sgs.GameStart, sgs.EventAcquireSkill},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.GameStart or ( event == sgs.GameStart and data:toString() == self:objectName() ) then 
		player:setTag("equipEXtra_COS", sgs.QVariant(false))
		player:setTag("equipEXtra", sgs.QVariant(self:objectName()))
		room:setPlayerMark(player,"ExtraEquip",1)
		room:setPlayerMark(player,"ExtraEquipdefensive_horse",1)
		room:setPlayerMark(player,"ExtraEquipoffensive_horse",1)
		room:setPlayerMark(player,"ExtraEquipweapon",1)
		end
	end,
	priority = 3
}


s2_shencaocao:addSkill(s2_xinzhan)
s2_shencaocao:addSkill(s2_xiezun)
s2_shencaocao:addSkill(s2_yushu)


sgs.LoadTranslationTable{
	["s2_shencaocao"] = "神曹操",
	["&s2_shencaocao"] = "神曹操",
	["#s2_shencaocao"] = "霸王之姿",
	["designer:s2_shencaocao"] = "孔孟老庄胡",
	
	["s2_xinzhan"] = "心计",
	[":s2_xinzhan"]  = "回合开始阶段，你可以弃置一张牌并观看一名其他角色的手牌。",
	["s2_xinzhan-invoke"] = "你可以发动“心计”<br/> <b>操作提示</b>: 选择一张手牌→点击确定<br/>",
	["s2_xinzhan-invoke2"] = "你可以发动“心计”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	
	["s2_xiezun"] = "挟尊",
	[":s2_xiezun"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃一张牌，让除自己外手牌最多的角色将一半（向下取整数）给场上手牌最少的角色。",
	
	["s2_yushu"] = "驭术",
	[":s2_yushu"] = "你可以多装备一匹+1马或者一匹-1马。",
	
}
]]

s2_shenlingmeng = sgs.General(extension_jx,"s2_shenlingmeng","touhou","3", false)


s2_danmuCard = sgs.CreateSkillCard{
	name = "s2_danmu",
	will_throw = false,
	target_fixed = false,
	filter = function(self, targets, to_select, player)
		return #targets < self:subcardsLength() and not to_select:hasFlag("s2_danmu") and  sgs.Self:canSlash(to_select,nil)
	end,
	on_use = function(self, room, source, targets)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "s2_danmu", "")
		room:throwCard(self, reason, nil)
		for _,target in ipairs(targets) do
		room:setPlayerFlag(target,"s2_danmu_target")
		end
	end,
}
s2_danmuVS = sgs.CreateViewAsSkill{
	name = "s2_danmu", 
	n = 998,
	expand_pile = "s2_fu",
	view_filter = function(self, selected, to_select)
		local pat = ".|.|.|s2_fu"
				return  sgs.Sanguosha:matchExpPattern(pat, sgs.Self, to_select)
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local dw = s2_danmuCard:clone()
			for _,card in pairs(cards) do
				dw:addSubcard(card)
			end
			return dw
		end
		return nil
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@s2_danmu" 
		end,
		enabled_at_play = function(self, player)
		return false
	end,
}
s2_danmu = sgs.CreateTriggerSkill{
	name = "s2_danmu",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = s2_danmuVS ,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			local room = player:getRoom()
			local targets = sgs.SPlayerList()
			local others = room:getOtherPlayers(player)
			for _,p in sgs.qlist(use.to) do
							room:setPlayerFlag(p, "s2_danmu")
					end
			for _,p in sgs.qlist(others) do
				if player:canSlash(p,use.card) then
					if not use.to:contains(p) then
						if not sgs.Sanguosha:isProhibited(player, p, use.card) then
							targets:append(p)
						end
					end
				end
			end
			if not targets:isEmpty() then
				room:setPlayerMark(player, "card_id", use.card:getEffectiveId())
				if room:askForUseCard(player, "@@s2_danmu", "@s2_danmu-card") then
					for _,p in sgs.qlist(others) do
						if p:hasFlag("s2_danmu_target") then
							room:setPlayerFlag(p, "-s2_danmu_target")
							use.to:append(p)
						end
					end
					for _,p in sgs.qlist(use.to) do
							room:setPlayerFlag(p, "-s2_danmu")
					end
					room:sortByActionOrder(use.to)
					data:setValue(use)
				end
				room:setPlayerMark(player, "card_id", 0)
			end
		end
	end,
	can_trigger = function(self, player)
		return player:isAlive() and player:hasSkill(self:objectName()) and player:getPile("s2_fu"):length() > 0
	end,
}
s2_danmuStart = sgs.CreateTriggerSkill{
	name = "#s2_danmu",
	events = {sgs.DrawNCards,sgs.AfterDrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "InitialHandCards" then return false end
			room:sendCompulsoryTriggerLog(player, "s2_danmu")
			draw.num = draw.num + 12
			data:setValue(draw)
		elseif event == sgs.AfterDrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "InitialHandCards" then return false end
			local exchange_card = room:askForExchange(player, "s2_danmu", 12, 12)
			player:addToPile("s2_fu", exchange_card:getSubcards(), false)
			exchange_card:deleteLater()
		end
		return false
	end,
}

s2_yinyangCard = sgs.CreateSkillCard{
	name = "s2_yinyang" ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@s2_yinyang")
		source:clearOnePrivatePile("s2_fu")
		local players = room:getOtherPlayers(source)
		source:setFlags("s2_yinyangUsing")
		for _, player in sgs.qlist(players) do
			if player:isAlive() then
				room:cardEffect(self, source, player)
			end
		end
		source:setFlags("-s2_yinyangUsing")
	end ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
			room:damage(sgs.DamageStruct("s2_yinyang", effect.from, effect.to, 2))
	end
}
s2_yinyangVS = sgs.CreateViewAsSkill{
	name = "s2_yinyang" ,
	n = 0,
	view_as = function()
		return s2_yinyangCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return player:getMark("@s2_yinyang") >= 1 and player:getPile("s2_fu"):length() > 0 
	end
}
s2_yinyang = sgs.CreateTriggerSkill{
	name = "s2_yinyang" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@s2_yinyang",
	events = {},
	view_as_skill = s2_yinyangVS,
	
	on_trigger = function()
	end
}

s2_saiqian = sgs.CreateTriggerSkill{
	name = "s2_saiqian$" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:hasLordSkill(self:objectName()) then
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
		if not  p:isKongcheng() then 
		targets:append(p)
		end
		end
		if targets:isEmpty() then return false end 
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "s2_saiqian-invoke", true, true)
			if target then
				--[[local card = room:askForExchange(target, self:objectName(), 1, 1,false, "s2_saiqianGive", false)
	local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, target:objectName(), player:objectName(), "s2_saiqian", nil)
	reason.m_playerId = player:objectName()
	room:moveCardTo(card, target, player, sgs.Player_PlaceHand, reason)]]
	
	local card = room:askForCard(target, "..!", "@s2_saiqian", sgs.QVariant(), sgs.Card_MethodNone)
					if card then
						room:moveCardTo(card, player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, target:objectName(), player:objectName(), self:objectName(), ""))
					end
			end
		end
		return false
	end
}

s2_shenlingmeng:addSkill(s2_danmuStart)
s2_shenlingmeng:addSkill(s2_danmu)
extension_jx:insertRelatedSkills("s2_danmu","#s2_danmu")
s2_shenlingmeng:addSkill(s2_yinyang)
s2_shenlingmeng:addSkill(s2_saiqian)
--http://tieba.baidu.com/p/844170175
sgs.LoadTranslationTable{
	["s2_shenlingmeng"] = "神灵梦",
	["&s2_shenlingmeng"] = "神灵梦",
	["#s2_shenlingmeng"] = "無節操巫女",
	["designer:s2_shenlingmeng"] = "aund12",
	
	["s2_danmu"] = "彈幕",
	["~s2_danmu"] = "选择X张“符”→选择X名其他角色→点击确定",
	["@s2_danmu-card"]  = "你可以将X张“符”置入弃牌堆，若如此做，你使用【杀】可以额外选择X名目标。",
	[":s2_danmu"] = "分发起始手牌时，共发你十六张牌，你选四张作为手牌，其余的面朝下置于一旁，称为“符”；你可以将X张“符”置入弃牌堆，若如此做，你使用【杀】可以额外选择X名目标。",
	["s2_fu"] = "符",
	
	["s2_yinyang"] = "陰陽",
	[":s2_yinyang"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以将所有的“符”置入弃牌堆，若如此做，你对所有其他角色造成的2点伤害。",
	["@s2_yinyang"] = "陰陽",
	
	["s2_saiqian"] = "塞钱",
	[":s2_saiqian"] = "<font color=\"orange\"><b>主公技，</b></font>准备阶段开始时，你可以令一名其他角色交給你一張手牌。",
	["s2_saiqian-invoke"] = "你可以发动“塞钱”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["@s2_saiqian"] = "请交给其一张牌",
}

s2_chaomeng = sgs.General(extension_jx,"s2_chaomeng","magic","4")

s2_xianzhi = sgs.CreateTriggerSkill{
	name = "s2_xianzhi",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local phase = player:getPhase()
		local room = player:getRoom()
		if phase == sgs.Player_Start then
		if player:isKongcheng() then return false end 
		if room:askForDiscard(player,self:objectName(),1,1,true,false,"s2_xianzhi-invoke",".") then
			local shou = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"s2_xianzhi-invoke2")
			if shou then
				room:showAllCards(shou,player)
			end
			end
		end
		return false
	end
}

s2_hufu = sgs.CreateTriggerSkill{
	name = "s2_hufu",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Normal then 
				
					room:notifySkillInvoked(player, "s2_hufu")
					room:sendCompulsoryTriggerLog(player, self:objectName(), true)
				return true 
				end
		return false
	end,
}
s2_fuyuan = sgs.CreatePhaseChangeSkill{
	name = "s2_fuyuan",
	frequency = sgs.Skill_Compulsory,
	on_phasechange = function(self, player)
	local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			local can_invoke = true 
			local min , max = 999 , 0 
			for _, p in sgs.qlist(room:getAlivePlayers()) do
			 min = math.min(min, p:getHp())
			 max = math.max(max, p:getHp())
			end
			if player:getHp() ~= min and 	player:getHp() ~= max	then
					if player:isWounded() then 
					room:sendCompulsoryTriggerLog(player, self:objectName(), true)
					local recover=sgs.RecoverStruct()
				recover.who=player
				recover.recover=1
					room:recover(player,recover,true)
					end
					end
			end
	end
}
s2_fuyuan_T = sgs.CreateTriggerSkill{
	name = "#s2_fuyuan_T" ,
	events = {sgs.EventPhaseStart, sgs.HpChanged, sgs.MaxHpChanged} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)		
		local room = player:getRoom()
		local min , max = 999 , 0 
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			 min = math.min(min, p:getHp())
			 max = math.max(max, p:getHp())
			end
		
		if event == sgs.EventPhaseStart then
			local xiahouba = room:findPlayerBySkillName(self:objectName())
			if xiahouba and  xiahouba:getPhase() == sgs.Player_Start  then
			if not xiahouba or not xiahouba:isAlive() then return false end
				if xiahouba:getHp() ~= min and 	xiahouba:getHp() ~= max	then
				room:setPlayerMark(xiahouba, "@s2_fuyuan1", 1)
				room:setPlayerMark(xiahouba, "@s2_fuyuan2", 0)
				else
				room:setPlayerMark(xiahouba, "@s2_fuyuan1", 0)
				room:setPlayerMark(xiahouba, "@s2_fuyuan2", 1)
				end
			elseif xiahouba:getPhase() == sgs.Player_Finish then
					room:setPlayerMark(xiahouba, "@s2_fuyuan1", 0)
					room:setPlayerMark(xiahouba, "@s2_fuyuan2", 0)
				end
			elseif event == sgs.HpChanged or event ==  sgs.MaxHpChanged then
		if not player:isAlive() or not player:hasSkill(self:objectName(), true) or player:getPhase() == sgs.Player_NotActive then return false end	
			if player:getHp() ~= min and 	player:getHp() ~= max	then
				room:setPlayerMark(player, "@s2_fuyuan1", 1)
				room:setPlayerMark(player, "@s2_fuyuan2", 0)
				else
				room:setPlayerMark(player, "@s2_fuyuan1", 0)
				room:setPlayerMark(player, "@s2_fuyuan2", 1)
				end
				end
		return false
	end ,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
s2_chaomeng:addSkill(s2_xianzhi)
s2_chaomeng:addSkill(s2_hufu)
s2_chaomeng:addSkill(s2_fuyuan)
s2_chaomeng:addSkill(s2_fuyuan_T)
extension_jx:insertRelatedSkills("s2_fuyuan","#s2_fuyuan_T")
--http://tieba.baidu.com/p/863717802
sgs.LoadTranslationTable{
	["s2_chaomeng"] = "超梦",
	["&s2_chaomeng"] = "超梦",
	["#s2_chaomeng"] = "至强精灵",
	["designer:s2_chaomeng"] = "孔孟老庄胡",
	
	["s2_xianzhi"] = "先知",
	[":s2_xianzhi"] = "回合开始阶段，你可以弃置一张手牌并观看一名其他角色的手牌。",
	["s2_xianzhi-invoke"] = "你可以发动“先知”<br/> <b>操作提示</b>: 选择一张手牌→点击确定<br/>",
	["s2_xianzhi-invoke2"] = "你可以发动“先知”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	
	["s2_hufu"] = "护符",
	[":s2_hufu"] = "<font color=\"blue\"><b>锁定技，</b></font>你不能受到属性伤害。",
	
	["s2_fuyuan"] = "复原",
	["@s2_fuyuan1"] = "复原",
	["@s2_fuyuan2"] = "复原",
	[":s2_fuyuan"] = "<font color=\"blue\"><b>锁定技，</b></font>回合结束阶段，如果你的当前体力值不是全场最多或者最少的（不含相等情况），则你回复一点体力。",
	
}




s2_3_guanyu = sgs.General(extension_jx,"s2_3_guanyu","shu","4")


s2_aogu = sgs.CreateTriggerSkill{
	name = "s2_aogu" ,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForRetrial, sgs.FinishJudge} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		if event == sgs.AskForRetrial then
		if judge.who:objectName() ~= player:objectName() then return false end
		room:sendCompulsoryTriggerLog(player, self:objectName(), true)
		return true
		elseif event == sgs.FinishJudge then
		local card = judge.card
		if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceJudge and card:isKindOf("Slash") then
			player:obtainCard(card)
					room:sendCompulsoryTriggerLog(player, self:objectName(), true)
		end
		end
	end
}

s2_2_zhanjiangCard = sgs.CreateSkillCard{
	name = "s2_2_zhanjiang", 
	filter = function(self, targets, to_select) 
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:canSlash(to_select,nil,true)
	end,
	on_effect = function(self, effect) 
		local room = effect.from:getRoom();
			local target = effect.to
			local data = sgs.QVariant()
			data:setValue(target)
			effect.from:setTag("s2_2_zhanjiangTarget",data) 
			room:setPlayerFlag(effect.from, "s2_2_zhanjiangSuccess");
			room:setPlayerMark(effect.to, "@s2_2_zhanjiang", 1);
		 room:setPlayerMark(effect.from, self:objectName() .. target:objectName(), 1)
		  room:addPlayerMark(effect.to, "&" .. self:objectName() .. "+to+#" .. effect.from:objectName().."-Clear")
	end,
}

s2_2_zhanjiangVS = sgs.CreateZeroCardViewAsSkill{
	name = "s2_2_zhanjiang",
	view_as = function(self) 
		return s2_2_zhanjiangCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#s2_2_zhanjiang")) 
	end, 
}

s2_2_zhanjiang = sgs.CreateTriggerSkill{
	name = "s2_2_zhanjiang",  
	events = {sgs.EventPhaseChanging,sgs.Death}, 
	view_as_skill = s2_2_zhanjiangVS,
	on_trigger = function(self, event, gaoshun, data)
	local room = gaoshun:getRoom()
		local target = gaoshun:getTag("s2_2_zhanjiangTarget"):toPlayer()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_Play then
				gaoshun:removeTag("s2_2_zhanjiangTarget");
					room:setPlayerFlag(gaoshun, "-s2_2_zhanjiangSuccess");
					 room:setPlayerMark(gaoshun, "s2_2_zhanjiang" .. target:objectName(), 0)
			room:setPlayerMark(target, "@s2_2_zhanjiang", 0);
			end
		end
		if (event == sgs.Death) then
			local death = data:toDeath()
			if death.who:objectName() ~= gaoshun:objectName() then
				if death.who:objectName() == target:objectName() then
					gaoshun:removeTag("s2_2_zhanjiangTarget");
					room:setPlayerFlag(gaoshun, "-s2_2_zhanjiangSuccess");
				 room:setPlayerMark(gaoshun, "s2_2_zhanjiang" .. target:objectName(), 0)
			room:setPlayerMark(target, "@s2_2_zhanjiang", 0);
				end
				return false;
			end
		end
		return false;
	end,
	can_trigger = function(self, target)
		return target and target:getTag("s2_2_zhanjiangTarget"):toPlayer()
	end,
}

s2_2_zhanjiang_buff = sgs.CreateTargetModSkill{
    name = "#s2_2_zhanjiang_buff",
    pattern = ".",
    residue_func = function(self, from, card, to)
        if from:hasSkill("s2_2_zhanjiang") and to and from:getMark("s2_2_zhanjiang" .. to:objectName()) > 0 then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("s2_2_zhanjiang") and to and from:getMark("s2_2_zhanjiang" .. to:objectName()) > 0 then return 1000 end
        return 0
    end,
}


s2_3_guanyu:addSkill(s2_2_zhanjiang)
s2_3_guanyu:addSkill(s2_2_zhanjiang_buff)
extension:insertRelatedSkills("s2_2_zhanjiang", "#s2_2_zhanjiang_buff")
s2_3_guanyu:addSkill(s2_aogu)
--http://tieba.baidu.com/p/887535311
sgs.LoadTranslationTable{
	["s2_3_guanyu"] = "关羽",
	["&s2_3_guanyu"] = "关羽",
	["#s2_3_guanyu"] = "美髯公",
	["designer:s2_3_guanyu"] = "炎龙将",
	
	["s2_aogu"] = "傲骨",
	[":s2_aogu"] = "<font color=\"blue\"><b>锁定技，</b></font>你的判定牌不可被更改，且如果是【杀】则生效后立即收入手牌。",
	
	["$s2_2_zhanjiang"] = "策馬揮刀，安天下，復漢室",
	["s2_2_zhanjiang"] = "斩将",
	["@s2_2_zhanjiang"] = "斩将",
	[":s2_2_zhanjiang"] = "每回合出牌阶段，你可以指定唯一目标使用任意张【杀】。",
}


s2_3_guanxingzhangbao = sgs.General(extension_jx,"s2_3_guanxingzhangbao","shu","4")

s2_2_jiangmen = sgs.CreateTriggerSkill{
	name = "s2_2_jiangmen" ,
	events = {sgs.TargetConfirmed} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if not use.from or (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
		if not use.card:isRed() then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
		local log= sgs.LogMessage()
	log.type = "#skill_cant_jink"
		log.from = player
		log.to:append(p)
		log.arg = self:objectName()
		room:sendLog(log)
		room:broadcastSkillInvoke(self:objectName())
					jink_table[index] = 0
			index = index + 1
			
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	end
}


s2_2_huzi = sgs.CreateTriggerSkill{
	name = "s2_2_huzi" ,
	events = {sgs.TargetSpecified,sgs.DamageCaused},
	frequency = sgs.Skill_NotFrequent, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
		local use = data:toCardUse()
			if use.card:isKindOf("Duel") or (use.card:isKindOf("Slash") and use.card:isBlack()) then
			room:setPlayerMark(player, "s2_2_huzi", 0)
					while player:askForSkillInvoke(self:objectName(), data) do
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|red"
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					judge.time_consuming = true
					room:judge(judge)
					if judge:isGood() then
					room:addPlayerMark(player,"s2_2_huzi")
					room:addPlayerMark(player,"@s2_2_huzi")
					end
					if judge:isBad() then
					room:setCardFlag(use.card,"s2_2_huzi_fail")
						break
					end
				end
				if not use.card:hasFlag("s2_2_huzi_fail") then
				room:setCardFlag(use.card,"s2_2_huzi_suceesss")
				else 
				room:setPlayerMark(player, "s2_2_huzi", 0)
				room:setPlayerMark(player, "@s2_2_huzi", 0)
				end
			end
		elseif event == sgs.DamageCaused then 
		local damage = data:toDamage()
		if damage.card and damage.card:hasFlag("s2_2_huzi_suceesss") and damage.from:getMark("s2_2_huzi") > 0 then 
		damage.damage = damage.damage + damage.from:getMark("s2_2_huzi")
		room:sendCompulsoryTriggerLog(player, self:objectName(), true)
		local log= sgs.LogMessage()
	log.type = "#skill_add_damage"
		log.from = damage.from
		log.to:append(damage.to)
		log.arg = self:objectName()
		log.arg2  = damage.damage
		room:sendLog(log)
		room:broadcastSkillInvoke(self:objectName(), 1)
		data:setValue(damage)
		end
		end
		return false
	end
}
s2_2_huzi_effect = sgs.CreateTriggerSkill{
	name = "#s2_2_huzi_effect" ,
	events = {sgs.CardEffected, sgs.CardFinished} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	if event == sgs.CardEffected then
		local effect = data:toCardEffect()
		if effect.from and effect.to and effect.to:objectName() == effect.from:objectName() then return false end
		if effect.card:hasFlag("s2_2_huzi_fail") then
		room:sendCompulsoryTriggerLog(player, "s2_2_huzi", true)
		room:broadcastSkillInvoke("s2_2_huzi",2)
				return true
			
		end
		elseif event == sgs.CardFinished then
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and use.card:hasFlag("s2_2_huzi_suceesss") then
		room:setPlayerMark(use.from, "@s2_2_huzi", 0)
		end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}




s2_3_guanxingzhangbao:addSkill(s2_2_jiangmen)
s2_3_guanxingzhangbao:addSkill(s2_2_huzi)
s2_3_guanxingzhangbao:addSkill(s2_2_huzi_effect)
extension_jx:insertRelatedSkills("s2_2_huzi","#s2_2_huzi_effect")


sgs.LoadTranslationTable{
	["s2_3_guanxingzhangbao"] = "关兴张苞",
	["&s2_3_guanxingzhangbao"] = "关兴张苞",
	["#s2_3_guanxingzhangbao"] = "龙骧虎翼",
	["designer:s2_3_guanxingzhangbao"] = "青苹果1021",
	
	["$s2_2_jiangmen"] = "一夫当关，望夫莫当！",
	["s2_2_jiangmen"] = "將門",
	[":s2_2_jiangmen"] = "<font color=\"blue\"><b>锁定技，</b></font>你使用的红色【杀】不可以使用【闪】对此【杀】进行响应。",
	
	["$s2_2_huzi1"] = "匹夫之勇，插标卖首！", 
	["$s2_2_huzi2"] = "父辈功勋，望尘莫及……", 
	["s2_2_huzi"] = "虎子",
	["@s2_2_huzi"] = "虎子",
	[":s2_2_huzi"] = "当你的黑色【杀】或决斗指定目标后，你可以进行一次判定：若结果为红色，此牌造成的伤害+1，你可以重复此流程；若出现黑色的判定结果，此牌无效。 ",
--http://tieba.baidu.com/p/1560700244
}



s3_maikelei = sgs.General(extension_bf,"s3_maikelei","science","3", false)

s3_weihezhe = sgs.CreateTriggerSkill{
	name = "s3_weihezhe",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseEnd, sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and player:getMark("s3_weihezhe_stop") ~= 0 then
				room:setPlayerCardLimitation(player, "use", ".", false)
			elseif player:getPhase() == sgs.Player_NotActive then
				room:setPlayerMark(player, self:objectName(), 0)
				room:setPlayerMark(player, "@s3_weihezhe", 0)
				room:setPlayerMark(player, "s3_weihezhe_stop", 0)
			end
		elseif player:getPhase() == sgs.Player_Play and (event == sgs.CardUsed or event == sgs.CardResponded) then
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card:hasFlag("s3_shenqiangshou") then return false end
			if not card:isKindOf("SkillCard") then
			room:addPlayerMark(player, self:objectName())
			room:addPlayerMark(player, "@s3_weihezhe")
			end
			if player:getMark(self:objectName()) == player:getHp() then 
			room:setCardFlag(card, self:objectName())
			end
			if card and card:getHandlingMethod() == sgs.Card_MethodUse and player:getMark(self:objectName()) == 6 then
				room:setPlayerCardLimitation(player, "use", ".", false)
				room:addPlayerMark(player, "s3_weihezhe_stop")
			end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
			room:removePlayerCardLimitation(player, "use", ".")
		elseif event == sgs.DamageCaused then 
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag(self:objectName()) then 
			damage.damage = damage.damage + 1
			local log= sgs.LogMessage()
	log.type = "#skill_add_damage"
		log.from = damage.from
		log.to:append(damage.to)
		log.arg = self:objectName()
		log.arg2  = damage.damage
		room:sendLog(log)
		data:setValue(damage)
			end	
		end
	end
}

s3_shenqiangshou = sgs.CreateTriggerSkill{
	name = "s3_shenqiangshou",  
	frequency = sgs.Skill_Limited,
	limit_mark = "@s3_shenqiangshou",	
	events = {sgs.TargetConfirmed, sgs.Damage, sgs.CardFinished, sgs.TargetSpecified}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local card = use.card
			local source = use.from
			if card:isKindOf("Slash") then
				if use.to:length() == 1 and source:objectName() == player:objectName() and source:getMark("@s3_shenqiangshou") > 0  then
					if room:askForSkillInvoke(player, self:objectName(), data) then
					room:setCardFlag(use.card, self:objectName())
					room:setTag("s3_shenqiangshou_end",sgs.QVariant(true))
					local ap = sgs.QVariant()
					ap:setValue(use.to:first())
					room:setTag("s3_shenqiangshou_first",ap)
					room:setPlayerFlag(use.to:first(), "s3_shenqiangshou_first")
					local ap2 = sgs.QVariant()
					ap2:setValue(use.to:first())
					room:setTag("s3_shenqiangshou_target",ap2)
					player:loseMark("@s3_shenqiangshou")
					local order = room:askForChoice(player, self:objectName(), "s3_shenqiangshou_left+s3_shenqiangshou_right")
					if order == "s3_shenqiangshou_left" then
					room:setPlayerFlag(player, "s3_shenqiangshou_left")
					elseif order == "s3_shenqiangshou_right" then 
					room:setPlayerFlag(player, "s3_shenqiangshou_right")
					end
					end
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag(self:objectName()) then
				room:addPlayerMark(player, self:objectName())
			end
		elseif event == sgs.CardFinished then
			local can_invoke = room:getTag("s3_shenqiangshou_end"):toBool()
			if not can_invoke then return false end
			local use = data:toCardUse()
			local card = use.card
			local source = use.from
			if card:isKindOf("Slash") and card:hasFlag(self:objectName()) and player:getMark(self:objectName()) < 6  then
			local dest 
			local nexttarget = room:getTag("s3_shenqiangshou_target"):toPlayer()
				if player:hasFlag("s3_shenqiangshou_left") then
				for _, p in sgs.qlist(use.to) do
				if p:objectName() == nexttarget:objectName() then
				 dest = p:getNextAlive()
				 break
				 end
				 end
				 if dest:objectName() == player:objectName() then 
			dest = dest:getNextAlive()
			end
				elseif player:hasFlag("s3_shenqiangshou_right") then
				 for _, p in sgs.qlist(use.to) do
				if p:objectName() == nexttarget:objectName() then
				local seat = p:getSeat()
				dest = p:getNextAlive()
				 if dest:objectName() == player:objectName() then 
			dest = player:getNextAlive()
				 end
				 break
				 end
				 end
				end
				local firsttarget = room:getTag("s3_shenqiangshou_first"):toPlayer()
				if dest:hasFlag("s3_shenqiangshou_first") then
					room:setPlayerFlag(use.to:first(), "-s3_shenqiangshou_first")
				else
					if dest:objectName() == firsttarget:objectName() then
					room:setTag("s3_shenqiangshou_end",sgs.QVariant(false))
					room:setCardFlag(use.card, "-"..self:objectName())
						return false
					end
				end
				if source:getMark(self:objectName()) >= 6 or  dest:objectName() == source:objectName() then
				room:setTag("s3_shenqiangshou_end",sgs.QVariant(false))
				room:setCardFlag(use.card, "-"..self:objectName())
					return false
				end
				
				local ap3 = sgs.QVariant()
					ap3:setValue(dest)
					room:setTag("s3_shenqiangshou_target",ap3)
				local useEX = sgs.CardUseStruct()
						useEX.from = player
						useEX.to:append(dest)
						useEX.card = use.card
						room:useCard(useEX, true) 
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
		if not use.card:isKindOf("Slash") then return false end
		if not use.card:hasFlag(self:objectName()) then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			if not player:isAlive() then break end
			local x = math.max(p:getLostHp(), 1)
					jink_table[index] = x
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
		end
	end,
}



s3_maikelei:addSkill(s3_weihezhe)
s3_maikelei:addSkill(s3_shenqiangshou)


sgs.LoadTranslationTable{
	["s3_maikelei"] = "麦克雷",
	["&s3_maikelei"] = "麦克雷",
	["#s3_maikelei"] = "维和者",
	["designer:s3_maikelei"] = "落雁归羽",
	
	["s3_weihezhe"] = "维和者",
	["@s3_weihezhe"] = "维和者",
	[":s3_weihezhe"] = "<font color=\"blue\"><b>锁定技，</b></font>出牌阶段内你至多使用六张牌，使用的第X张牌若造成伤害，令该伤害+1（X为你当前体力）。",
	
	["s3_shenqiangshou_left"] = "逆时针",
	["s3_shenqiangshou_right"] = "顺时针",
	["@s3_shenqiangshou"] = "神枪手",
	["s3_shenqiangshou"] = "神枪手",
	[":s3_shenqiangshou"] = "<font color=\"red\"><b>限定技，</b></font>当你使用一张【杀】指定一个目标后，你可选择一个方向（顺时针或逆时针），将该【杀】的目标依次指定按照你指定方向的所有其他角色，直到该【杀】造成了六次伤害或是经过了所有角色；被指定的角色需要使用X张【闪】才能抵消该【杀】（X为其已损失的体力且至少为1）。",
--http://tieba.baidu.com/p/4709119531?lp=5027&mo_device=1&is_jingpost=0&pn=0&	
	
}

s3_xushu = sgs.General(extension_bf,"s3_xushu","shu","3")


s3_jianyanCard = sgs.CreateSkillCard{
	name = "s3_jianyan" ,
	filter = function(self, selected, to_select)
		return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName()) and to_select:getHandcardNum() < sgs.Self:getHandcardNum()
	end ,
	on_effect = function(self, effect)
		local n = math.min(effect.from:getHandcardNum() - effect.to:getHandcardNum(), 5)
		effect.to:drawCards(n, self:objectName())
		local room = effect.from:getRoom()
		--[[if n > 2 then
			room:loseHp(effect.from)
			effect.from:turnOver()
		end]]
	end
}
s3_jianyan = sgs.CreateViewAsSkill{
	name = "s3_jianyan" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and not to_select:isKindOf("BasicCard")
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = s3_jianyanCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end ,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and (not player:hasUsed("#s3_jianyan"))
	end
}


s3_zhuhai = sgs.CreateTriggerSkill{
	name = "s3_zhuhai" ,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed, sgs.CardEffected, sgs.CardFinished} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if (not use.to:contains(player)) or (not use.card:isKindOf("TrickCard")) or not use.card:isNDTrick() then
				return false
			end
			if (not player:isAlive()) or (not player:hasSkill(self:objectName())) then return false end
			if use.from and use.from:objectName() ~= player:objectName() then
				local choicelist = "cancel+s3_zhuhai_slash"
				if player:canDiscard(player,"he") and player:isAlive() then
					choicelist = string.format("%s+%s", choicelist, "s3_zhuhai_discard")
				end
				room:setTag("CurrentUseStruct", data)
				local choice = room:askForChoice(player,self:objectName(),choicelist)
				room:removeTag("CurrentUseStruct")
				if choice == "s3_zhuhai_discard" then
					if room:askForDiscard(player, self:objectName(),1,1,true,true,"s3_zhuhai-invoke") then
						player:setTag("s3_zhuhai", sgs.QVariant(use.card:toString()))
					end
				elseif choice == "s3_zhuhai_slash" then
					use.from:drawCards(1, self:objectName())
					if player:canSlash(use.from,nil,false) then
						room:setCardFlag(use.card, self:objectName())
						room:setPlayerFlag(player, self:objectName())
					--[[local card1 =  sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
											card1:setSkillName(self:objectName())		
											local useEX = sgs.CardUseStruct()
											useEX.from = player
											useEX.to:append(use.from)
											useEX.card = card1
											room:broadcastSkillInvoke(self:objectName(),1)
											room:useCard(useEX, false)]]
					end
				end
			end
		elseif event == sgs.CardEffected then
			if (not player:isAlive()) or (not player:hasSkill(self:objectName())) then return false end
			local effect = data:toCardEffect()
			if player:getTag("s3_zhuhai") == nil or (player:getTag("s3_zhuhai"):toString() ~= effect.card:toString()) then return false end
			player:setTag("s3_zhuhai", sgs.QVariant(""))
			room:broadcastSkillInvoke(self:objectName(),2)
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			return true
		elseif event == sgs.CardFinished then
		local use = data:toCardUse()
		if use.card and use.card:hasFlag(self:objectName()) then
			local source 
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasFlag(self:objectName()) and p:hasSkill(self:objectName()) then
					room:setPlayerFlag(p, "-"..self:objectName())
					source = p
					break
				end
			end
			if source and source:canSlash(use.from,nil,false) then
			local card1 =  sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
									card1:setSkillName(self:objectName())		
									local useEX = sgs.CardUseStruct()
									useEX.from = source
									useEX.to:append(use.from)
									useEX.card = card1
									room:broadcastSkillInvoke(self:objectName(),1)
									room:useCard(useEX, false)
								end
		end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}



s3_xushu:addSkill(s3_jianyan)
s3_xushu:addSkill(s3_zhuhai)



sgs.LoadTranslationTable{
	["s3_xushu"] = "徐庶",
	["&s3_xushu"] = "徐庶",
	["#s3_xushu"] = "忠孝的侠士",
	["designer:s3_xushu"] = "时城午侯",
	
	["s3_zhuhai-invoke"] =" 你可以发动“诛害”<br/> <b>操作提示</b>: 选择一张牌→点击确定<br/>",
	["s3_zhuhai_slash"] = "令该角色摸一张牌并视为对其使用一张【杀】",
	["s3_zhuhai_discard"] = "弃一张牌使其对你无效",
	["s3_zhuhai"] = "诛害",
	[":s3_zhuhai"] = "当其他角色使用非延时锦囊牌指定目标时，若目标角色有你，则你可以选择一项：1：弃一张牌使其对你无效；2：令该角色摸一张牌并视为对其使用一张【杀】。",
	["$s3_zhuhai1"] = "善恶有报，天道轮回！",
	["$s3_zhuhai2"] = "汝有良策，何必问我。",
	
	["s3_jianyan"] = "荐言",
	--[":s3_jianyan"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃罝一张非基本牌令一名其他手牌数小于你的角色将手牌补至你当前手牌数（最多为5），若该角色获得的牌大于2，你失去1点体力，将武将牌翻面。",
	[":s3_jianyan"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃罝一张非基本牌令一名其他手牌数小于你的角色将手牌补至你当前手牌数（最多为5）。",
	["$s3_jianyan1"] = "开言纳谏，社稷之福。",
	["$s3_jianyan2"] = "如此如此，敌军自破。",
--http://tieba.baidu.com/p/4722793154
}


s3_spzhouyu = sgs.General(extension_bf,"s3_spzhouyu","wu","3")


s3_jiangyong = sgs.CreateTriggerSkill{
	name = "s3_jiangyong",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.DamageCaused},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.DamageCaused then
				if player:askForSkillInvoke(self:objectName()) then
				room:notifySkillInvoked(player, self:objectName())
							player:drawCards(2, self:objectName())
						end	
		end
		return false
	end,
}


s3_jiangzhi = sgs.CreateTriggerSkill{
	name = "s3_jiangzhi",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.GameStart, sgs.CardsMoveOneTime,sgs.EventAcquireSkill,sgs.EventLoseSkill, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.GameStart then
		if player:hasSkill(self:objectName()) then
		local ids = room:getNCards(1, false)
		local move = sgs.CardsMoveStruct()
		move.card_ids = ids
			move.to = player
			move.to_place = sgs.Player_PlaceTable
			move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
			room:moveCardsAtomic(move, true)
						player:addToPile("s3_jiangzhi", ids)
				end
		elseif event == sgs.EventLoseSkill and data:toString() == self:objectName() then
			room:handleAcquireDetachSkills(player,"-s3_jiangyong|-s3_zhijue",true)
		elseif event == sgs.EventAcquireSkill and data:toString() == self:objectName() then
			if not player:getPile("s3_jiangzhi"):isEmpty() then
				room:notifySkillInvoked(player,self:objectName())
				if sgs.Sanguosha:getCard(player:getPile("s3_jiangzhi"):first()):isRed() then
				room:handleAcquireDetachSkills(player,"s3_zhijue")
				else 
				room:handleAcquireDetachSkills(player,"s3_jiangyong")
				end
			end
		elseif event == sgs.CardsMoveOneTime and player:isAlive() and player:hasSkill(self:objectName(),true) then
			local move = data:toMoveOneTime()
			if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceSpecial and move.to_pile_name == "s3_jiangzhi" then
				if player:getPile("s3_jiangzhi"):length() == 1 then
					room:notifySkillInvoked(player,self:objectName())
					if sgs.Sanguosha:getCard(player:getPile("s3_jiangzhi"):first()):isRed() then
				room:handleAcquireDetachSkills(player,"s3_zhijue")
				else 
				room:handleAcquireDetachSkills(player,"s3_jiangyong")
				end
				end
			elseif move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceSpecial) and table.contains(move.from_pile_names,"s3_jiangzhi") then
				if player:getPile("s3_jiangzhi"):isEmpty() then
					room:handleAcquireDetachSkills(player,"-s3_jiangyong|-s3_zhijue",true)
				end
		end
		elseif event == sgs.EventPhaseStart then 
			if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start then
			local card = room:askForCard(player, ".", "@s3_jiangzhi", sgs.QVariant(), sgs.Card_MethodNone)
				if card then
				if not player:getPile("s3_jiangzhi"):isEmpty() then
					local dummy = sgs.Sanguosha:cloneCard("slash")
					dummy:deleteLater()
						for _, cd in sgs.qlist(player:getPile("s3_jiangzhi")) do
			dummy:addSubcard(sgs.Sanguosha:getCard(cd))
		end
		player:obtainCard(dummy)
		end
		player:addToPile("s3_jiangzhi", card)
				end
				end
		end
	end,
	can_trigger = function(self,player)
		return player ~= nil 
	end,
}


s3_zhijue  = sgs.CreateTriggerSkill{
	name = "s3_zhijue",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged,sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if event == sgs.Damaged then
	    local damage = data:toDamage()
		local dest = sgs.QVariant()
		dest:setValue(room:getCurrent())
		if damage.from and room:getCurrent() and damage.from:objectName() ~= player:objectName() and player:hasSkill(self:objectName())
			and player:getMark("s3_zhijuefrom") == 0 and room:askForSkillInvoke(player, self:objectName(), dest) then
			for _,p in sgs.qlist(room:getPlayers()) do
				room:setPlayerMark(p,"s3_zhijuefrom",0)
				room:setPlayerMark(p,"s3_zhijueto",0)
			end
			room:setPlayerMark(player,"s3_zhijuefrom",1)
			room:setPlayerMark(damage.from,"s3_zhijueto",1)
			local log = sgs.LogMessage()
			log.type = "#SkipAllPhase"
			log.from = damage.from
			room:sendLog(log)
			room:clearAG()
			player:gainAnExtraTurn()
			room:throwEvent(sgs.TurnBroken)
		end
	elseif event == sgs.EventPhaseEnd then
	    if player:getPhase() == sgs.Player_Play then
		    if player:getMark("s3_zhijuefrom") > 0 then
			    room:setPlayerMark(player,"s3_zhijuefrom",0)
			end
			for _,p in sgs.qlist(room:getPlayers()) do
				if p:getMark("s3_zhijueto") > 0 then
				    room:setPlayerMark(p,"s3_zhijueto",0)
				end
			end
		end
		end
	end,

}

s3_binglu = sgs.CreateTriggerSkill{
	name = "s3_binglu", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if player:isAlive() then
			if event == sgs.EventPhaseStart then
				if player:getPhase() == sgs.Player_Start then
					if player:getHandcardNum() ~= player:getHp() then
						local x 
						if player:getHandcardNum() > player:getHp() then 
						x = player:getHandcardNum() - player:getHp()
						else
						x = player:getHp() - player:getHp()
						end
						local choicelist = "cancel+s3_binglu_draw"
						if player:canDiscard(player, "he") and player:getCardCount(true, false) >= x  then
						choicelist = string.format("%s+%s", choicelist, "s3_binglu_discard")
						end
						local choice = room:askForChoice(player, self:objectName(), choicelist)
						if choice == "s3_binglu_draw" then 
						player:drawCards(x, self:objectName())
						room:loseHp(player)
						elseif choice == "s3_binglu_discard" then 
						if room:askForDiscard(player, self:objectName(),x,x,true,true,"s3_binglu-invoke") then 
						local re = sgs.RecoverStruct()
												re.who = player
												room:recover(player, re, true)
							end
						end
					end
				end
			end
		end
	end
}






if not sgs.Sanguosha:getSkill("s3_jiangyong") then
	s_skillList:append(s3_jiangyong)
end
if not sgs.Sanguosha:getSkill("s3_zhijue") then
	s_skillList:append(s3_zhijue)
end


s3_spzhouyu:addSkill(s3_jiangzhi)
s3_spzhouyu:addSkill(s3_binglu)
s3_spzhouyu:addRelateSkill("s3_jiangyong")
s3_spzhouyu:addRelateSkill("s3_zhijue")

sgs.LoadTranslationTable{
	["s3_spzhouyu"] = "SP周瑜",
	["&s3_spzhouyu"] = "周瑜",
	["#s3_spzhouyu"] = "智勇双全",
	["designer:s3_spzhouyu"] = "安子无",
	
	["s3_jiangzhi"] = "将智",
	[":s3_jiangzhi"] = "游戏开始时，你须将牌堆顶一张牌置于你的武将牌上，若为黑色则拥有技能“将勇”（当你造成伤害时，你可以摸两张牌。）；若为红色则拥有技能“智绝”（当你受到伤害时，你可以结束该回合，并进入你的一个额外的回合。）。你的回合开始时，你可以用一张牌替代之。",
	["s3_jiangyong"] = "将勇",
	[":s3_jiangyong"] = "当你造成伤害时，你可以摸两张牌。",
	["s3_zhijue"] = "智绝",
	[":s3_zhijue"] = "当你受到伤害时，你可以结束该回合，并进入你的一个额外的回合。",
	["@s3_jiangzhi"] = "你可以用一张牌替代<font color=\"yellow\">将智牌</font>",
	
	["s3_binglu"] = "兵律",
	[":s3_binglu"] = "回合开始阶段，若你的手牌数与当前体力值不等，则你可以二选一：摸X张牌，失去1点体力；弃X张牌，回复1点体力。（X为你的手牌数与当前体力值之差）",
	["s3_binglu_draw"] = "摸X张牌，失去1点体力",
	["s3_binglu_discard"] = "弃X张牌，回复1点体力",
	["s3_binglu-invoke"] =  "你可以发动“兵律”弃X张牌，回复1点体力<br/> <b>操作提示</b>: 选择X张牌→点击确定<br/>",
	
}


s3_spguanyu = sgs.General(extension_bf,"s3_spguanyu","shu","4")

s3_yijue = sgs.CreateTriggerSkill{
	name = "s3_yijue",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Predamage},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if damage.to:hasSkill(self:objectName()) then
		room:loseHp(damage.to, damage.damage)
		room:sendCompulsoryTriggerLog(damage.to, self:objectName(), true)
		return true
		end
	end,
	can_trigger = function(self,player)
		return player ~= nil 
	end,
}


s3_lianzhan = sgs.CreateTriggerSkill{
	name = "s3_lianzhan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.PreCardUsed, sgs.CardFinished, sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") then
			room:setCardFlag(use.card, self:objectName())
			end
		elseif event == sgs.CardFinished then 
			local use = data:toCardUse()
			if use.card and use.card:hasFlag(self:objectName()) then
				if not player:hasFlag("s3_yijue_damage") then 
					if room:askForSkillInvoke(player, self:objectName()) then 
						player:drawCards(1, self:objectName())
					end
				elseif player:hasFlag("s3_yijue_damage") then 
					room:setPlayerFlag(player, "-s3_yijue_damage")
					if player:hasFlag("s3_yijue_use") then
						room:setPlayerFlag(player, "-s3_yijue_use")
						local dest
						for _,p in sgs.qlist(room:getAlivePlayers()) do
							if p:hasFlag("s3_yijue_to") then 
								dest = p 
								room:setPlayerFlag(p, "-s3_yijue_to")
								break
							end
						end
						if player:canSlash(dest, nil, false)  then
							local card_use = sgs.CardUseStruct()
							card_use.from = player
							card_use.to:append(dest)
							card_use.card = use.card
							room:useCard(card_use, false)
							end
						end
					end
				end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag(self:objectName()) then 
			room:setPlayerFlag(player, "s3_yijue_damage")
			if player:canSlash(damage.to:getNextAlive(), damage.card, false) then 
			local dest =sgs.QVariant()
			dest:setValue(damage.to:getNextAlive())
				if room:askForSkillInvoke(player, self:objectName(), dest) then 
					room:setPlayerFlag(player, "s3_yijue_use")
					room:setPlayerFlag(damage.to:getNextAlive(), "s3_yijue_to")
					end
				end
			end
		end
	end,
}



s3_spguanyu:addSkill(s3_lianzhan)
s3_spguanyu:addSkill(s3_yijue)


sgs.LoadTranslationTable{
	["s3_spguanyu"] = "SP关羽",
	["&s3_spguanyu"] = "关羽",
	["#s3_spguanyu"] = "万人敌",
	["designer:s3_spguanyu"] = "安子无",
	
	["s3_yijue"] = "义绝",
	[":s3_yijue"] = "<font color=\"blue\"><b>锁定技，</b></font>你受到的伤害均为体力流失。",
	
	["s3_lianzhan"] = "连斩",
	[":s3_lianzhan"] = "每当你使用的【杀】未造成伤害时，你可摸一张牌。每当你使用的【杀】对目标角色造成伤害后，可指定其下家为新的目标，视为你对其使用了一张【杀】。",
}



s3_spxiahoudun = sgs.General(extension_bf,"s3_spxiahoudun","wei","4")



s3_qiangyuancard = sgs.CreateSkillCard{
	name = "s3_qiangyuan",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, player)
	    return #targets < 2 
	end,
	on_use = function(self, room, source, targets)
		if #targets == 1 then 
		targets[1]:drawCards(2, self:objectName())
		elseif #targets == 2 then 
		targets[1]:drawCards(1, self:objectName())
		targets[2]:drawCards(1, self:objectName())
		end
	end,
}


s3_qiangyuanVS = sgs.CreateViewAsSkill{
	name = "s3_qiangyuan",
	n = 0,
	view_as = function(self, cards)
	   local acard = s3_qiangyuancard:clone()		
		return acard
	end,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response=function(self,player,pattern)
		return pattern == "@@s3_qiangyuan"
	end,
}

s3_qiangyuan = sgs.CreateTriggerSkill{
	name = "s3_qiangyuan",
	events = {sgs.CardUsed, sgs.CardResponded},
	view_as_skill = s3_qiangyuanVS,
	on_trigger = function(self, event, player, data)
		local card
		local room = player:getRoom()
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card			 
		end
		if card and card:isKindOf("Jink") and player:askForSkillInvoke(self:objectName()) then
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|heart"
			judge.good = false
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if judge:isGood() then
				local use = room:askForUseCard(player, "@@s3_qiangyuan", "@s3_qiangyuan")
			end
		end
	end
}


s3_zhenjun = sgs.CreateTriggerSkill{
	name = "s3_zhenjun" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardUsed, sgs.EventPhaseStart} ,   
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local can_trigger = false
			if player:getPhase() == sgs.Player_Finish and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getMark("s3_zhenjunSlashInPlayPhase") > 0  then
				can_trigger = true
				room:setPlayerMark(player, "s3_zhenjunSlashInPlayPhase", 0 )
			end
				if can_trigger  then
					local DiscardPile = room:getDiscardPile()
			local toGainList = sgs.IntList()
			for _,cid in sgs.qlist(DiscardPile) do
				local cd = sgs.Sanguosha:getCard(cid)
				if cd:isKindOf("Jink") then
					toGainList:append(cid)
				end
			end
			if (not toGainList:isEmpty()) and player:askForSkillInvoke(self:objectName()) then
				room:notifySkillInvoked(player , self:objectName())
				room:fillAG(toGainList, player)
				local card_id = room:askForAG(player, toGainList, false, "s3_zhenjun")
				if card_id ~= -1 then
					local gain_card = sgs.Sanguosha:getCard(card_id)
					room:obtainCard(player,gain_card)
				end
				room:clearAG()
					end
				end
			end
		else
			if player:getPhase() == sgs.Player_Play then
				local card = nil
				if event == sgs.CardUsed then
					card = data:toCardUse().card	 
				end
				if card:isKindOf("Slash") then
					room:addPlayerMark(player, "s3_zhenjunSlashInPlayPhase")
					room:addPlayerMark(player, "&s3_zhenjun-Clear")
				end
			end
		end
		return false
	end
}

s3_spxiahoudun:addSkill(s3_qiangyuan)
s3_spxiahoudun:addSkill(s3_zhenjun)






sgs.LoadTranslationTable{
	["s3_spxiahoudun"] = "SP夏侯惇",
	["&s3_spxiahoudun"] = "夏侯惇",
	["#s3_spxiahoudun"] = "独目苍狼",
	["designer:s3_spxiahoudun"] = "安子无",
	
	["s3_qiangyuan"] = "强援",
	[":s3_qiangyuan"] = "每当你使用【闪】选择目标后或打出【闪】，你可以进行判定，若结果不为红桃，则依次指定一至两名角色摸共计两张牌。",
	["@s3_qiangyuan"] = "你可以指定一至两名角色摸共计两张牌",
	["~s3_qiangyuan"] = "选择目标→确定",
	
	["s3_zhenjun"] = "镇军",
	[":s3_zhenjun"] = "回合结束阶段，若你于出牌阶段使用了一张【杀】，则你可从弃牌堆中获得一张【闪】。",
	
}
s3_splvbu = sgs.General(extension_bf,"s3_splvbu","qun","5")

s3_tianwei = sgs.CreateTriggerSkill{
	name = "s3_tianwei" ,
	events = {sgs.Damage, sgs.EventPhaseStart, sgs.CardFinished} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
		if event == sgs.Damage  then 
		local damage = data:toDamage()
		if player:hasSkill(self:objectName()) and damage.card and damage.card:isKindOf("Slash") and (not damage.chain) and (not damage.transfer)
				and damage.to:isAlive() then
				room:setCardFlag(damage.card, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName(), true)
				room:addPlayerMark(damage.to, "&s3_tianwei+to+#" .. player:objectName().."-SelfClear")
				room:setPlayerMark(damage.to, "@skill_invalidity", 1)
					local skill_list = {}
		local Qingchenglist = damage.to:getTag("Qingcheng"):toString():split("+") or {}
		for _,skill in sgs.qlist(damage.to:getVisibleSkillList()) do
			if (not table.contains(skill_list,skill:objectName())) and not skill:isAttachedLordSkill() then
				table.insert(Qingchenglist,skill:objectName())
				room:addPlayerMark(damage.to, "Qingcheng" .. skill:objectName())
			end
		end
			damage.to:setTag("Qingcheng",sgs.QVariant(table.concat(Qingchenglist,"+")))
			for _,p in sgs.qlist(room:getAllPlayers())do
				room:filterCards(p, p:getCards("he"), true)
			end
			local jsonValue = {
				8
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
		end
		elseif event == sgs.EventPhaseStart then
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			local Qingchenglist = player:getTag("Qingcheng"):toString():split("+")
			if #Qingchenglist == 0 then return false end
			for _,skill_name in pairs(Qingchenglist)do
				room:setPlayerMark(player, "Qingcheng" .. skill_name, 0);
			end
			room:setPlayerMark(player, "@skill_invalidity", 0)
			player:removeTag("Qingcheng")
			for _,p in sgs.qlist(room:getAllPlayers())do
				room:filterCards(p, p:getCards("he"), true)
			end
			local jsonValue = {
				8
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
			end
		elseif event == sgs.CardFinished then
		local use =data:toCardUse()
		if use.card and use.card:hasFlag(self:objectName()) then 
			if use.from and use.from:isAlive() then
				room:loseHp(use.from, 1)
			end
		end
	end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = 6
}

s3_xiaohu = sgs.CreateTriggerSkill{
	name = "s3_xiaohu" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	waked_skills = "s3_tianwei",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isWounded() then
			if room:askForChoice(player, self:objectName(), "recover+draw") == "recover" then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
			else
				room:drawCards(player, 2, self:objectName())
			end
		else
			room:drawCards(player, 2, self:objectName())
		end
		room:addPlayerMark(player, "s3_xiaohu")
		if room:changeMaxHpForAwakenSkill(player) then
			room:handleAcquireDetachSkills(player, "s3_tianwei")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getMark("s3_xiaohu") == 0)
				and (target:getPhase() == sgs.Player_Start)
				and (target:isKongcheng() or target:canWake(self:objectName()))
	end
}

if not sgs.Sanguosha:getSkill("s3_tianwei") then
	s_skillList:append(s3_tianwei)
end
s3_splvbu:addSkill(s3_xiaohu)

s3_splvbu:addSkill("wushuang")

sgs.LoadTranslationTable{
--http://tieba.baidu.com/p/1662805945
	["s3_splvbu"] = "SP吕布",
	["&s3_splvbu"] = "吕布",
	["#s3_splvbu"] = "战神",
	["designer:s3_splvbu"] = "安子无",
	
	["s3_xiaohu"] = "哮虎",
	[":s3_xiaohu"] = "<font color=\"purple\"><b>觉醒技，</b></font>回合开始阶段，若你没有手牌，你须回复1点体力或摸两张牌，然后减少1点体力上限，并永久获得技能“天威”（锁定技，当你使用的【杀】对指定目标造成伤害时，将封锁目标的武将技直到其下个回合结束。在此【杀】结算完后，你失去1点体力）。",
	
	["s3_tianwei"] = "天威",
	[":s3_tianwei"] = "<font color=\"blue\"><b>锁定技，</b></font>当你使用的【杀】对指定目标造成伤害时，将封锁目标的武将技直到其下个回合结束。在此【杀】结算完后，你失去1点体力。",
}

s3_zhaoyun = sgs.General(extension_bf,"s3_zhaoyun","shu","4")

s3_youlongCard = sgs.CreateSkillCard {
	name = "s3_youlong",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	player = nil,
	on_use = function(self, room, source)
		player = source
	end,
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("s3_youlong")
		slash:deleteLater()
		return slash:targetFilter(targets_list, to_select, sgs.Self)
	end ,
	on_validate = function(self, card_use)
		local yuji = card_use.from
		local room = yuji:getRoom()		
		local to_guhuo = self:getUserString()		
		if to_guhuo == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE  then
			local guhuo_list = {}
			table.insert(guhuo_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(guhuo_list, "thunder_slash")
				table.insert(guhuo_list, "fire_slash")
			end
			user_str = room:askForChoice(yuji, "s3_youlong_slash", table.concat(guhuo_list, "+"))
		end	
			local subcards = self:getSubcards()
			local card = sgs.Sanguosha:getCard(subcards:first())
			local user_str
			if to_guhuo == "slash"  then
				local guhuo_list = {}
			table.insert(guhuo_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(guhuo_list, "thunder_slash")
				table.insert(guhuo_list, "fire_slash")
			end
			user_str = room:askForChoice(yuji, "s3_youlong_slash", table.concat(guhuo_list, "+"))
			end
			local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
			use_card:setSkillName("s3_youlong")
			use_card:addSubcard(card)
			use_card:deleteLater()			
			return use_card
	end,
	on_validate_in_response = function(self, yuji)
		local room = yuji:getRoom()
		local to_guhuo
		if self:getUserString() == "slash" then
			local guhuo_list = {}
			table.insert(guhuo_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(guhuo_list, "thunder_slash")
				table.insert(guhuo_list, "fire_slash")
			end
			to_guhuo = room:askForChoice(yuji, "s3_youlong_slash", table.concat(guhuo_list, "+"))
		end		
			local subcards = self:getSubcards()
			local card = sgs.Sanguosha:getCard(subcards:first())
			local user_str
			if to_guhuo == "slash" then
				if card:isKindOf("Slash") then
					user_str = card:objectName()
				else
					user_str = "slash"
				end
			else
				user_str = to_guhuo
			end
			local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
			use_card:setSkillName("s3_youlong")
			use_card:addSubcard(subcards:first())
			use_card:deleteLater()
			return use_card
	end
}
s3_youlongVS = sgs.CreateViewAsSkill{
	name = "s3_youlong" ,
	n = 1 ,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected > 0 then return false end
		local card = to_select
		local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return card:isKindOf("Jink")
		elseif (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) or (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				return card:isKindOf("Jink")
			else
				return card:isKindOf("Slash")
			end
		else
			return false
		end
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local originalCard = cards[1]
		if originalCard:isKindOf("Slash") then
			local jink = sgs.Sanguosha:cloneCard("jink", originalCard:getSuit(), originalCard:getNumber())
			jink:addSubcard(originalCard)
			jink:setSkillName(self:objectName())
			return jink
		elseif originalCard:isKindOf("Jink") then
			local card = s3_youlongCard:clone()
			--local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
			card:addSubcard(originalCard)
			card:setUserString("slash")
			card:setSkillName(self:objectName())
			return card
		else
			return nil
		end
	end ,
	enabled_at_play = function(self, target)
		return sgs.Slash_IsAvailable(target)
	end,
	enabled_at_response = function(self, target, pattern)
		return (pattern == "slash") or (pattern == "jink")
	end
}

s3_youlong = sgs.CreateTriggerSkill{
	name = "s3_youlong" ,
	events = {sgs.CardResponded, sgs.TargetSpecified, sgs.CardUsed} ,
	view_as_skill = s3_youlongVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardResponded then
	        	local resp = data:toCardResponse()
	        	if resp.m_card:getSkillName() == "s3_youlong" and resp.m_who and (not resp.m_who:isKongcheng()) then
		            	local _data = sgs.QVariant()
				_data:setValue(resp.m_who)
		                if player:canDiscard(player, "he") and player:askForSkillInvoke(self:objectName(), _data) then
						if room:askForDiscard(player, self:objectName(), 1,1,true, true) then
		                	local card_id = room:askForCardChosen(player, resp.m_who, "h", self:objectName())
		                	local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
		                	room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
							end
		                end
	        	end
	        elseif event == sgs.TargetSpecified then
	            local use = data:toCardUse()
	            if use.card:getSkillName() == "s3_youlong" then
	                for _, p in sgs.qlist(use.to) do
	                	if p:isKongcheng() then continue end
	                	local _data = sgs.QVariant()
				_data:setValue(p)
				p:setFlags("s3_youlongTarget")
	                	local invoke = player:askForSkillInvoke(self:objectName(), _data)
	                	p:setFlags("-s3_youlongTarget")
	                	if player:canDiscard(player, "he") and invoke then
							if room:askForDiscard(player, self:objectName(), 1,1,true, true) then
	                        	local card_id = room:askForCardChosen(player, p, "h", self:objectName())
	                        	local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
	                        	room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
								end
	                    	end
	                end
	            end
				elseif event == sgs.CardUsed then
				local use = data:toCardUse()
	            if use.card:getSkillName() == "s3_youlong" and use.whocard then
					if use.who:isKongcheng() then return false end
	                	local _data = sgs.QVariant()
				_data:setValue(use.who)
				use.who:setFlags("s3_youlongTarget")
	                	local invoke = player:askForSkillInvoke(self:objectName(), _data)
	                	use.who:setFlags("-s3_youlongTarget")
	                	if player:canDiscard(player, "he") and invoke then
							if room:askForDiscard(player, self:objectName(), 1,1,true, true) then
	                        	local card_id = room:askForCardChosen(player, use.who, "h", self:objectName())
	                        	local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
	                        	room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
								end
	                    	end
				end	
	        end
	        return false
	end
}

s3_zhaoyun:addSkill(s3_youlong)

sgs.LoadTranslationTable{
	["s3_zhaoyun"] = "赵云",
	["&s3_zhaoyun"] = "赵云",
	["#s3_zhaoyun"] = "一身是胆",
	["designer:s3_zhaoyun"] = "大爱lbx皇帝",
	
	["s3_youlong"] = "游龙",
	["s3_youlong_slash"] = "游龙【杀】",
	[":s3_youlong"] = "你可以将一张【闪】当【杀】、雷【杀】或火【杀】使用或打出；你可以将一张【杀】当【闪】使用或打出；每当你发动“游龙”使用或打出一张手牌时，你可以弃置一张牌，然后获得对方的一张手牌。",
--http://tieba.baidu.com/p/4760777738	
}

s3_zhoucang = sgs.General(extension_bf,"s3_zhoucang","shu","4")

s3_kangdao = sgs.CreatePhaseChangeSkill{
	name = "s3_kangdao",
	frequency = sgs.Skill_NotFrequent,
	on_phasechange = function(self, player)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "s3_kangdao-invoke",true, true)
			if target then
				room:loseHp(player)
				local qdest = sgs.QVariant()
				qdest:setValue(target)
				room:setTag("s3_kangdao", qdest)
				local victims = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(target)) do
					if target:canSlash(p, nil, true) then
						victims:append(p)
					end
				end
				if not victims:isEmpty() then
					local dest = room:askForPlayerChosen(player, victims, "s3_kangdao_target")
					while target:isAlive() and dest:isAlive() do
						if not room:askForUseSlashTo(target, dest, "s3_kangdao_effect:" .. dest:objectName(), true, false, false) then 
						break
						end
					end
				end
				room:removeTag("s3_kangdao")
			end
		end
		return false
	end
}

s3_zhoucang:addSkill(s3_kangdao)


sgs.LoadTranslationTable{
	["s3_zhoucang"] = "周仓",
	["&s3_zhoucang"] = "周仓",
	["#s3_zhoucang"] = "武圣护卫",
	["designer:s3_zhoucang"] = "青苹果1021",
	
	["s3_kangdao"] = "扛刀",
	["s3_kangdao_target"] = "扛刀",
	["s3_kangdao-invoke"] =  "你可以发动“扛刀”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["s3_kangdao_effect"] = "你可以对 %src 使用任意张【杀】",
	[":s3_kangdao"] = "回合结束阶段，你可以失去一点体力，并指定一名其他角色。该角色可以对你指定的另一位攻击范围内的角色使用任意张【杀】。",
	
--http://tieba.baidu.com/p/1511683439	
}

s3_spluxun = sgs.General(extension_bf,"s3_spluxun","wu","3")

s3_qianeCard = sgs.CreateSkillCard{
	name = "s3_qiane", 
	target_fixed = true, 
	will_throw = true, 
	handling_method = sgs.Card_MethodDiscard ,
	on_use = function(self, room, source, targets)  
	room:setPlayerMark(source, self:objectName(), self:subcardsLength())
	end
}
s3_qianeVS = sgs.CreateViewAsSkill{
	name = "s3_qiane", 
	n = 999, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		if #cards > 0 then
			local first = s3_qianeCard:clone()
			for _,card in pairs(cards) do
				first:addSubcard(card)
			end
			first:setSkillName(self:objectName())
			return first
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@s3_qiane"
	end
}
s3_qiane = sgs.CreatePhaseChangeSkill{
	name = "s3_qiane",
	view_as_skill = s3_qianeVS,
	on_phasechange = function(self, player)
	local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if player:canDiscard(player, "h") then
				room:askForUseCard(player, "@@s3_qiane", "@s3_qiane")
			end
		elseif player:getPhase() == sgs.Player_Finish then
				if player:getMark(self:objectName()) > 0 then 
				player:drawCards(player:getMark(self:objectName()), self:objectName())
				room:notifySkillInvoked(player, self:objectName())
				room:setPlayerMark(player, self:objectName(), 0)
				end
		end
		return false
	end
}

s3_fenzhiCard = sgs.CreateSkillCard{
	name = "s3_fenzhi", 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		return to_select:objectName() ~= sgs.Self:objectName() and #targets == 0
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		room:setPlayerFlag(effect.to, "s3_fenzhi")
		if self:getSubcards():isEmpty() then 
			room:loseHp(effect.from)
		end
		local choicelist = "s3_fenzhidraw"
		if not effect.to:isNude() then
		choicelist = string.format("%s+%s", choicelist, "s3_fenzhiget")
		end
		local choice = room:askForChoice(effect.from, self:objectName(), choicelist)
		room:setPlayerFlag(effect.to, "-s3_fenzhi")
		if choice == "s3_fenzhidraw" then 
		effect.to:drawCards(2, self:objectName())
		elseif choice == "s3_fenzhiget" then 
		local card = room:askForCardChosen(effect.from, effect.to, "he",self:objectName())
		room:obtainCard(effect.from, sgs.Sanguosha:getCard(card), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, effect.from:objectName()), false)
		end
	end
}
s3_fenzhi = sgs.CreateViewAsSkill{
	name = "s3_fenzhi", 
	n = 2, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#s3_fenzhi")
	end,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		if #cards == 0 then
			return s3_fenzhiCard:clone()
		elseif #cards == 2 then
			local card = s3_fenzhiCard:clone()
			card:addSubcard(cards[1])
			card:addSubcard(cards[2])
			return card
		else 
			return nil
		end
	end
}

s3_guyang = sgs.CreateTriggerSkill{
	name = "s3_guyang",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.CardsMoveOneTime}, 
	on_trigger = function(self, event, player, data)
				if player:getPhase() == sgs.Player_NotActive then
						local move = data:toMoveOneTime()
						local source = move.from
						if source and source:objectName() == player:objectName() then
							local places = move.from_places
							local room = player:getRoom()
							local invoked = false
							if places:contains(sgs.Player_PlaceHand) then
								for _, id in sgs.qlist(move.card_ids) do
								if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
									player:drawCards(1, self:objectName())
									invoked = true
								elseif sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
								if player:isWounded() then
									local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
				invoked = true
								end
								end
								end
								if invoked  then
								room:sendCompulsoryTriggerLog(player,self:objectName(), true)
								end
							end
						end
						end
						end
}

s3_spluxun:addSkill(s3_qiane)
s3_spluxun:addSkill(s3_fenzhi)
s3_spluxun:addSkill(s3_guyang)



sgs.LoadTranslationTable{
	["s3_spluxun"] = "SP陆逊",
	["&s3_spluxun"] = "陆逊",
	["#s3_spluxun"] = "江东神君",
	["designer:s3_spluxun"] = "安子无",
	
	["s3_qiane"] = "谦略",
	[":s3_qiane"] = "回合开始阶段开始时，你可弃任意张手牌，若如此做，回合结束阶段开始时，你摸等量的牌。 ",
	["@s3_qiane"] = "你可以发动“谦略”",
	["~s3_qiane"] = "选择任意张手牌→点击确定<br/>",
	
	["s3_fenzhi"] = "愤志",
	["s3_fenzhidraw"] = "令该角色摸两张牌",
	["s3_fenzhiget"] = "你获得该角色一张牌",
	[":s3_fenzhi"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以失去1点体力或弃两张手牌，然后指定一名其他角色执行二选一：你获得该角色一张牌；令该角色摸两张牌。",
	
	["s3_guyang"] = "固养",
	[":s3_guyang"] = "<font color=\"blue\"><b>锁定技，</b></font>你的回合外，每失去一张基本牌就摸一张牌，每失去一张锦囊牌就恢复1点体力。",
--http://tieba.baidu.com/p/1697767972	
}

s3_spyuji = sgs.General(extension_bf,"s3_spyuji","qun","3")

s3_fudaoCard = sgs.CreateSkillCard{
	name = "s3_fudao",
	filter = function(self, targets, to_select) 
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and to_select:getHandcardNum() >= to_select:getHp()
	end,
	on_effect = function(self, effect)
		local zhouyu = effect.from
		local target = effect.to
		local room = zhouyu:getRoom()
		local card_id = zhouyu:getRandomHandCardId()
		local card = sgs.Sanguosha:getCard(card_id)
		local suit = room:askForSuit(target, "s3_fudao")
		local log= sgs.LogMessage()
	log.type = "#ChooseSuit"
	log.from = effect.to
	log.arg = sgs.Card_Suit2String(suit)
	room:sendLog(log)
		room:getThread():delay()
		target:obtainCard(card)
		room:showCard(target, card_id)
		if card:getSuit() ~= suit then
			local dummy2 = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			dummy2:deleteLater()
						for _, id in sgs.qlist(target:getHandcards()) do
							dummy2:addSubcard(id)
						end
			room:obtainCard(zhouyu,dummy2)
		else
			room:loseHp(zhouyu)
		end
	end
}
s3_fudao = sgs.CreateZeroCardViewAsSkill{
	name = "s3_fudao",
	
	view_as = function()
		return s3_fudaoCard:clone()
	end,

	enabled_at_play = function(self, player)
		return (not player:isKongcheng()) and (not player:hasUsed("#s3_fudao"))
	end
}

s3_guizhou = sgs.CreateTriggerSkill{
	name = "s3_guizhou" ,
	events = {sgs.Death, sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		if death.who:hasSkill(self:objectName()) then
		local targets = room:getAlivePlayers()
		if targets:isEmpty() then return false end
		local target = room:askForPlayerChosen(player,targets,self:objectName(), "s3_guizhou-invoke", true, true)
		if not target then return false end
		local recover = sgs.RecoverStruct()
		recover.who = player
		recover.recover = player:getLostHp()
		room:recover(target, recover, true)
		target:gainMark("@s3_guizhou")
		room:addPlayerMark(target, "&s3_guizhou+to+#"..player:objectName())
		end
		elseif event == sgs.EventPhaseStart then
		if player:getMark("@s3_guizhou")>0 and player:getPhase() == sgs.Player_Finish then
		local judge = sgs.JudgeStruct()
		judge.pattern = "."
		judge.good = false
		judge.reason = "s3_guizhou"
		judge.who = player
		room:judge(judge)
		if judge.card:isRed() then
		room:loseMaxHp(player)
		else
		room:loseHp(player)
		end
		end
		end
	end,
	can_trigger = function(self, target)
		return target 
	end
}

s3_spyuji:addSkill(s3_fudao)
s3_spyuji:addSkill(s3_guizhou)
sgs.LoadTranslationTable{
	["s3_spyuji"] = "SP于吉",
	["&s3_spyuji"] = "于吉",
	["#s3_spyuji"] = "太平祖师",
	["designer:s3_spyuji"] = "安子无",
	["s3_fudao"] = "符道",
	[":s3_fudao"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以指定一名手牌数不小于其当前体力值的其他角色，该角色选择一种花色后获得你的一张手牌并展示之，若此牌与所选花色不同，则你获得其全部手牌，否则你失去1点体力。",
	
	["s3_guizhou-invoke"] =  "你可以发动“鬼咒”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["@s3_guizhou"] = "鬼咒",
	["s3_guizhou"] = "鬼咒",
	[":s3_guizhou"] = "你死亡时，可以指定一名其他角色恢复满体力，但此后该角色的每个回合结束阶段需进行判定，若为黑色失去1点体力，若为红色减1点体力上限。",
--http://tieba.baidu.com/p/1692972949	
}
s3_zhangren = sgs.General(extension_bf,"s3_zhangren","qun","4")

s3_luofeng = sgs.CreateTriggerSkill{
	name = "s3_luofeng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Dying, sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Dying then
		local dying = data:toDying()
		local source
		if dying.who:objectName() == player:objectName() then
			return false
		end
		local damage = data:toDying().damage
		if damage and damage.card and damage.card:hasFlag(self:objectName()) then
			room:sendCompulsoryTriggerLog(damage.from, self:objectName(), true)
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|heart"
			judge.good = true
			judge.reason = self:objectName()
			judge.who = dying.who
			room:judge(judge)
			if judge:isBad()  then
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
				if  dying.damage and dying.damage.from then
		source =dying.damage.from 
			room:killPlayer(dying.who,damage)
			else 
			room:killPlayer(dying.who)
			end
		end 
		end
	elseif event == sgs.DamageCaused then
		local damage =data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") then
			if damage.from:objectName() ~= damage.to:objectName() then
			room:setCardFlag(damage.card, self:objectName())
			end
		end
	end
	end
}

s3_sizhan = sgs.CreateTriggerSkill{
	name = "s3_sizhan",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local target = damage.from
		for i = 1, damage.damage, 1 do
			if target:isAlive()and player:isAlive() and damage.to ~= damage.from then
				local _data = sgs.QVariant()
				_data:setValue(target)
				if room:askForCard(player, "..", "@s3_sizhan:", _data, sgs.CardDiscarded) then
					room:notifySkillInvoked(player, self:objectName())
					local duel = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					duel:setSkillName(self:objectName())
					local use = sgs.CardUseStruct()
					use.card = duel
					use.from = player
					use.to:append(target)
					room:useCard(use)
				else
					break
				end
			end
		end
		return false
	end,
}

s3_zhonglie = sgs.CreateTriggerSkill{
	name = "s3_zhonglie" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	waked_skills = "s3_sizhan",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "s3_zhonglie")
		if room:changeMaxHpForAwakenSkill(player) then
			room:handleAcquireDetachSkills(player, "s3_sizhan")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
		   and (target:getPhase() == sgs.Player_Start)
		   and (target:getMark("s3_zhonglie") == 0)
		   and ((target:getHp() <= 2 ) or target:canWake(self:objectName()))
	end
}


s3_zhangren:addSkill(s3_luofeng)
s3_zhangren:addSkill(s3_zhonglie)
if not sgs.Sanguosha:getSkill("s3_sizhan") then
	s_skillList:append(s3_sizhan)
end
sgs.LoadTranslationTable{
	["s3_zhangren"] = "张任",
	["&s3_zhangren"] = "张任",
	["#s3_zhangren"] = "忠勇烈士",
	["designer:s3_zhangren"] = "zzm5296776",
	
	["s3_luofeng"] = "落凤",
	[":s3_luofeng"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你使用【杀】令其他角色进入濒死状态时，该角色须进行判定，除非结果为红桃，否则该角色立即死亡。",
	["@s3_sizhan"] = "你可以弃置一张手牌来发动“死战”",
	["s3_sizhan"] = "死战",
	[":s3_sizhan"] = "你每受到1点伤害，可以弃置一张牌，视为对伤害来源使用了一张【杀】。",
	["s3_zhonglie"] = "忠烈",
	[":s3_zhonglie"] = "<font color=\"purple\"><b>觉醒技，</b></font>回合开始阶段开始时，若你的体力值为2点或更低，你须回复1点体力，然后减1点体力上限，并永久获得技能“死战”（你每受到1点伤害，可以弃置一张牌，视为对伤害来源使用了一张【杀】。）。",
--http://tieba.baidu.com/p/1679633227
}

s3_lubu = sgs.General(extension_bf,"s3_lubu","qun","4")


s3_xiaoyong = sgs.CreateTriggerSkill{
	name = "s3_xiaoyong",  
	events = {sgs.Death, sgs.CardUsed, sgs.CardFinished, sgs.EventLoseSkill, sgs.GameStart, sgs.TurnStart}, 
	on_trigger = function(self, event, player, data)
	local invoke = false
	local lose = false
		local room = player:getRoom()
		if (event == sgs.GameStart) or (event == sgs.TurnStart) then
		local lubu = room:findPlayerBySkillName(self:objectName())
			if not lubu then return false end
		end
		if event == sgs.EventLoseSkill and data:toString() == self:objectName() then
				lose = true
		end
		if event == sgs.CardUsed then
		local use = data:toCardUse()
		if use.from:hasSkill(self:objectName())  then
			invoke = true
			end
		if use.to:contains(player) and player:hasSkill(self:objectName()) then
			invoke = true
		end
		elseif event == sgs.CardFinished then
		local use = data:toCardUse()
		if use.from:hasSkill(self:objectName()) then
			lose = true
			end
		if use.to:contains(player) and player:hasSkill(self:objectName()) then
			lose = true
			end
		end
		if invoke then
				for _,lubu in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
					for _, p in sgs.qlist(room:getOtherPlayers(lubu)) do
						if lubu:distanceTo(p) == 1 then
						room:addPlayerMark(p, "Armor_Nullified");
						room:addPlayerMark(p, "s3_xiaoyong_Nullifed");
						room:addPlayerMark(p, "@s3_xiaoyong");
					end
				end
			end
		end
		if lose then
		for _,lubu in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
				for _, p in sgs.qlist(room:getOtherPlayers(lubu)) do
					if p:getMark("s3_xiaoyong_Nullifed") > 0 then
					room:setPlayerMark(p, "Armor_Nullified", 0);
					room:setPlayerMark(p, "s3_xiaoyong_Nullifed", 0);
					room:setPlayerMark(p, "@s3_xiaoyong", 0);
					end
					end
				end
			end
		return false;
	end,
	can_trigger = function(self, target)
		return target and target:getRoom():findPlayerBySkillName(self:objectName())
	end,
}
s3_xiaoyong_TM = sgs.CreateTriggerSkill{
	name = "#s3_xiaoyong_TM" ,
	events = {sgs.Damage} ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and player:canDiscard(damage.to, "he") then
			local dest = sgs.QVariant()
			dest:setValue(damage.to)
			if player:getRoom():askForSkillInvoke(player, "s3_xiaoyong", dest) then
				local to_throw = player:getRoom():askForCardChosen(player, damage.to, "he", "s3_xiaoyong", false, sgs.Card_MethodDiscard)
				player:getRoom():throwCard(sgs.Sanguosha:getCard(to_throw), damage.to, player)
			end
		end
		return false
	end
}

s3_wumou = sgs.CreateTriggerSkill{
	name = "s3_wumou" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.CardUsed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isNDTrick() then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			if player:canDiscard(player, "h") then
			if not room:askForDiscard(player,self:objectName(), 1,1, true , false) then
			return true
			end
			else
			return true
			end
		end
		return false
	end
}



s3_lubu:addSkill(s3_xiaoyong)
s3_lubu:addSkill(s3_xiaoyong_TM)
extension_bf:insertRelatedSkills("s3_xiaoyong","#s3_xiaoyong_TM")
s3_lubu:addSkill("mashu")
s3_lubu:addSkill(s3_wumou)



sgs.LoadTranslationTable{
	["s3_lubu"] = "吕布",
	["&s3_lubu"] = "吕布",
	["#s3_lubu"] = "骁勇善战",
	["designer:s3_lubu"] = "冥情殇",
	
	["s3_xiaoyong"] = "骁勇",
	[":s3_xiaoyong"] = "你无视与你距离为1的角色的防具；你使用杀造成伤害后，你可以弃置其一张牌。",
	["@s3_xiaoyong"] = "骁勇",
	
	["s3_wumou"] = "无谋",
	[":s3_wumou"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你使用一张非延时锦囊牌时，你须弃置一张手牌，否则该锦囊无效。",
--http://tieba.baidu.com/p/1680091673	
}




s3_mateng = sgs.General(extension_bf,"s3_mateng","qun","4")

s3_xiongyi = sgs.CreateTriggerSkill{
	name = "s3_xiongyi" ,
	events = {sgs.CardUsed} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if not use.card:isKindOf("Slash") then return false end
		if not player:canDiscard(player, "he") then return false end
		local invoked = false
		for _, p in sgs.qlist(use.to) do
			if not player:isAlive() then break end
			local targets = sgs.SPlayerList()
			for _, q in sgs.qlist(room:getOtherPlayers(player)) do
				if p:inMyAttackRange(q) and not use.to:contains(q) then
					targets:append(q)
				end
			end	
			if not targets:isEmpty() then
				local _data = sgs.QVariant()
				_data:setValue(p)
				room:setPlayerFlag(p, "s3_xiongyi_ing")
				if room:askForCard(player, ".." , "s3_xiongyi-invoke", data, sgs.Card_MethodDiscard, player) then
					local target = room:askForPlayerChosen(player, targets, self:objectName())
					room:setPlayerFlag(target, self:objectName())
					if player:inMyAttackRange(target) and player:inMyAttackRange(p) then
						player:drawCards(1, self:objectName())
					end
				end
				room:setPlayerFlag(p, "-s3_xiongyi_ing")
			end
		end
		local logtarget = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
		if p:hasFlag(self:objectName()) then
		room:setPlayerFlag(p, "-"..self:objectName())
		use.to:append(p)
		logtarget:append(p)
		invoked = true
					end
					end
					if invoked then
					local log = sgs.LogMessage()
				log.type = "#BecomeTargetBySkill"
				log.from = player
				log.arg = self:objectName()
				log.to = logtarget
				log.card_str = use.card:toString()
				room:sendLog(log)
					room:sortByActionOrder(use.to)
					data:setValue(use)
					end
	end
}

s3_mateng:addSkill("mashu")
s3_mateng:addSkill(s3_xiongyi)
sgs.LoadTranslationTable{
	["s3_mateng"] = "马腾",
	["&s3_mateng"] = "马腾",
	["#s3_mateng"] = "驰骋西陲",
	["designer:s3_mateng"] = "开心宝贝crl",
	
	["s3_xiongyi-invoke"] = "你可以发动“雄异”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["s3_xiongyi"] = "雄异",
	[":s3_xiongyi"] = "当你使用【杀】指定一个目标后，你可以弃置一张牌，令其攻击范围内的另一名其他角色成为此【杀】的额外目标，然后若两名角色在你的攻击范围内，你摸一张牌。",
--http://tieba.baidu.com/p/4795350207	
}


s3_caocao = sgs.General(extension_bf,"s3_caocao","qun","4")

s3_xiandaoCard = sgs.CreateSkillCard{
	name = "s3_xiandao" ,
	will_throw = false ,
	handling_method = sgs.Card_MethodNone ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		effect.to:obtainCard(self)
		local judge = sgs.JudgeStruct()
				judge.pattern = ".|heart"
				judge.good = false
				judge.reason = self:objectName()
				judge.who = effect.to
				room:judge(judge)
				if judge:isGood() then
						room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
				end
	end
}
s3_xiandao = sgs.CreateViewAsSkill{
	name = "s3_xiandao" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("Weapon")
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local mingcecard = s3_xiandaoCard:clone()
		mingcecard:addSubcard(cards[1])
		return mingcecard
	end ,
	enabled_at_play = function(self, player)
		return not player:isNude()
	end
}

s3_taohui = sgs.CreateDistanceSkill{
	name = "s3_taohui",
	correct_func = function(self, from, to)
		if to:hasSkill("s3_taohui") then
		for _,player in sgs.qlist(to:getSiblings()) do
			if player:isLord() then
				if string.find(player:getGeneralName(), "dongzhuo") or string.find(player:getGeneral2Name(), "dongzhuo") then
					return 1
				end
			end
		end
		else
			return 0
		end
	end
}


s3_xiongzhi = sgs.CreateTriggerSkill{
	name = "s3_xiongzhi",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,
	waked_skills = "guixin",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local can_invoke = true
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if player:getHp() > p:getHp() then
				can_invoke = false
				break
			end
		end
		if (can_invoke and player:isKongcheng()) or player:canWake(self:objectName()) then
			room:addPlayerMark(player, "s3_xiongzhi")
			if room:changeMaxHpForAwakenSkill(player, -1) then
					room:handleAcquireDetachSkills(player, "guixin")
			end
		end
	end,

	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Start)
				and target:hasSkill("s3_xiongzhi")
				and target:isAlive()
				and (target:getMark("s3_xiongzhi") == 0)
	end
}


s3_caocao:addSkill(s3_xiandao)
s3_caocao:addSkill(s3_taohui)
s3_caocao:addSkill(s3_xiongzhi)
sgs.LoadTranslationTable{
	["s3_caocao"] = "曹操",
	["&s3_caocao"] = "曹操",
	["#s3_caocao"] = "亂世之奸雄",
	["designer:s3_caocao"] = "一波小强",
	
	["s3_xiandao"] = "献刀",
	[":s3_xiandao"] = "出牌阶段，你可以将一张武器牌交给一名其他角色，然后令其进行判定，若非红桃，则该角色受到你一点伤害。",
	
	["s3_xiongzhi"] = "雄志",
	[":s3_xiongzhi"] = "<font color=\"purple\"><b>觉醒技，</b></font>回合开始阶段，若你的体力是全场最少的(或之一)，且没有手牌，你须减少一点体力上限，并永久获得技能 “归心”。",
	
	["s3_taohui"] = "韬晦",
	[":s3_taohui"] = "<font color=\"orange\"><b>联动技，</b></font><font color=\"blue\"><b>锁定技，</b></font>当主公为董卓时，你始终视为装备着【+1马】。",
--http://tieba.baidu.com/p/1218052562	
}








s3_yt_liyan = sgs.General(extension_bf,"s3_yt_liyan","shu","3")


s3_yt_fajun = sgs.CreateTriggerSkill{
	name = "s3_yt_fajun&",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
			draw.num = draw.num - 1
			room:sendCompulsoryTriggerLog(player ,self:objectName(), true)
			data:setValue(draw)
	end
}

s3_yt_wangzhi = sgs.CreateTriggerSkill{
	name = "s3_yt_wangzhi" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.PreCardUsed,sgs.EventPhaseStart} , 
	global = true,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
			if player:hasFlag("s3_yt_wangzhi") then 
				room:detachSkillFromPlayer(player, "s3_yt_fajun")
				end
			if player:getMark("s3_yt_wangzhiSlashInPlayPhase") > 0 then
				room:setPlayerMark(player, "s3_yt_wangzhiSlashInPlayPhase", 0)
				room:sendCompulsoryTriggerLog(player, self:objectName(),true)
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHandcardNum()== player:getHandcardNum() then 
					room:handleAcquireDetachSkills(p, "s3_yt_fajun")
					room:addPlayerMark(p, "&s3_yt_wangzhi-SelfClear")
					room:setPlayerFlag(p ,self:objectName())
						end
					end
				end
			end
		else
			if player:getPhase() == sgs.Player_Play and player:hasSkill(self:objectName()) then
				local card = nil
				if event == sgs.PreCardUsed then
					card = data:toCardUse().card 
				end
				if card:isKindOf("Slash") then
					room:setPlayerMark(player, "s3_yt_wangzhiSlashInPlayPhase", 1)
				end
			end
		end
		return false
	end,
	    can_trigger = function(self, target)
		return target
	end
}

s3_yt_fulin = sgs.CreateTriggerSkill{
	name = "s3_yt_fulin" ,
	events = {sgs.CardFinished},
	frequency = sgs.Skill_NotFrequent, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.CardFinished then 
		if use.card  and player:getPhase() == sgs.Player_Play and not player:hasFlag(self:objectName()) and use.to:length() == 1 and use.from:objectName() ~= use.to:first():objectName() and not use.card:isKindOf("SkillCard") then 
		if not use.to:isEmpty() and not use.from:isDead()  then
		for _,p in sgs.qlist(use.to) do
		if p:isDead() then 
		use.to:removeOne(p)
		end
		end
		local dest = sgs.QVariant()
		dest:setValue(use.to:first())
		if not use.to:isEmpty() and room:askForSkillInvoke(player, self:objectName(), data) then 
		use.to:first():drawCards(1, self:objectName())
		room:setPlayerFlag(player, self:objectName())
		room:setPlayerFlag(use.to:first(), self:objectName())
		
		local choice = room:askForChoice(player, self:objectName(), "s3_yt_fulin_draw+s3_yt_fulin_use")
		room:setPlayerFlag(use.to:first(), "-"..self:objectName())
		if choice == "s3_yt_fulin_use" then
			local useEX = sgs.CardUseStruct()
						useEX.from = player
						useEX.to = use.to
						useEX.card = use.card
						room:useCard(useEX, true)
						else
						player:drawCards(1, self:objectName())
						end
						end
		end
		end
		end
		return false
	end,
}


s3_yt_liyan:addSkill(s3_yt_wangzhi)
s3_yt_liyan:addSkill(s3_yt_fulin)


if not sgs.Sanguosha:getSkill("s3_yt_fajun") then
	s_skillList:append(s3_yt_fajun)
end
s3_yt_liyan:addRelateSkill("s3_yt_fajun")

sgs.LoadTranslationTable{
	["s3_yt_liyan"] = "李严",
	["&s3_yt_liyan"] = "李严",
	["#s3_yt_liyan"] = "矜风流务",
	["designer:s3_yt_liyan"] = "怎么了你听得到",
	
	["s3_yt_fajun"] = "乏军",
	[":s3_yt_fajun"] = "<font color=\"blue\"><b>锁定技，</b></font>摸牌阶段，你少摸一张牌。",
	
	["s3_yt_wangzhi"] = "罔滞",
	[":s3_yt_wangzhi"] = "<font color=\"blue\"><b>锁定技，</b></font>结束阶段开始时，若你本回合使用过【杀】，手牌数与你相同的其它角色获得“乏军”直到该角色一个回合结束。",
	
	["s3_yt_fulin"] = "腹鳞",
	["s3_yt_fulin_draw"] = "摸一张牌",
	["s3_yt_fulin_use"] = "令你使用的这张牌进行一次额外的结算",
	[":s3_yt_fulin"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>每当你使用一张仅指定一名其他角色为目标的牌结算后，你可以令其摸一张牌，然后你选择一项：令你使用的这张牌进行一次额外的结算；或摸一张牌。",
--http://tieba.baidu.com/p/3915633656?see_lz=1&pn=1#72101276810l	
}


s3_yt_chendao = sgs.General(extension_bf,"s3_yt_chendao","shu","4")

s3_yt_baier = sgs.CreateViewAsSkill{
	name = "s3_yt_baier" ,
	n = 1 ,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected > 0 then return false end
			return not to_select:isEquipped()
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local originalCard = cards[1]
		if math.ceil(sgs.Self:getHp()/2) * 2 ~= sgs.Self:getHp() then
			local jink = sgs.Sanguosha:cloneCard("jink", originalCard:getSuit(), originalCard:getNumber())
			jink:addSubcard(originalCard)
			jink:setSkillName(self:objectName())
			return jink
		elseif math.ceil(sgs.Self:getHp()/2) * 2 == sgs.Self:getHp() then
			local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
			slash:addSubcard(originalCard)
			slash:setSkillName(self:objectName())
			return slash
		else
			return nil
		end
	end ,
	enabled_at_play = function(self, target)
		return sgs.Slash_IsAvailable(target)  and math.ceil(target:getHp()/2) * 2 == target:getHp()
	end,
	enabled_at_response = function(self, target, pattern)
		return (pattern == "slash"  and math.ceil(target:getHp()/2) * 2 == target:getHp() ) or (pattern == "jink" and math.ceil(target:getHp()/2) * 2 ~= target:getHp())
	end
}
s3_yt_zhentui = sgs.CreateAttackRangeSkill{
	name = "s3_yt_zhentui",
	fixed_func = function(self, player, include_weapon)
		if player:hasSkill("s3_yt_zhentui") then
		local x = 999 
		for _, p in sgs.qlist(player:getSiblings()) do
			x = math.min(x, p:getHp())
		end
			return x
		end
	end,
}

s3_yt_zhentui_t = sgs.CreateTriggerSkill{
	name = "#s3_yt_zhentui_t" ,
	events = {sgs.CardResponded, sgs.TargetSpecified, sgs.EventPhaseEnd},
	frequency = sgs.Skill_NotFrequent, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardResponded then
	        	local resp = data:toCardResponse()
	        	if resp.m_card:getSkillName() == "s3_yt_baier" and player:hasSkill("s3_yt_zhentui")  then
				      room:addPlayerMark(player, "s3_yt_zhentui")
					  if player:getMark("s3_yt_zhentui") == 2 then
					  local current = room:getCurrent()
					  if not current or current:isDead() or current:getPhase() == sgs.Player_NotActive then return false end
					  room:addPlayerMark(current, "s3_yt_zhentui_dest")
					  room:addPlayerMark(current, "@s3_yt_zhentui")
					  end
	        	end
	        elseif event == sgs.TargetSpecified then
	            local use = data:toCardUse()
	            if use.card:getSkillName() == "s3_yt_baier" and player:hasSkill("s3_yt_zhentui") then
	               room:addPlayerMark(player, "s3_yt_zhentui")
				   if player:getMark("s3_yt_zhentui") == 2 then
					  local current = room:getCurrent()
					  if not current or current:isDead() or current:getPhase() == sgs.Player_NotActive then return false end
					  room:addPlayerMark(current, "s3_yt_zhentui_dest")
					  room:addPlayerMark(current, "&s3_yt_zhentui+to+#"..player:objectName().."-Clear")
					  room:addPlayerMark(current, "@s3_yt_zhentui")
					  end
	            end
		elseif event ==sgs.EventPhaseEnd then 
		if player:getPhase() == sgs.Player_Finish then 
		for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("s3_yt_zhentui") > 0 then
					room:setPlayerMark(p, "s3_yt_zhentui", 0)
				end
			end
		for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("s3_yt_zhentui_dest") > 0 then
					room:setPlayerMark(p, "s3_yt_zhentui_dest", 0)
				end
			end
		for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("@s3_yt_zhentui") > 0 then
					room:setPlayerMark(p, "@s3_yt_zhentui", 0)
				end
			end
		end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
s3_yt_zhentuiMaxCards = sgs.CreateMaxCardsSkill{
	name = "#s3_yt_zhentuiMaxCards",

	extra_func = function(self, target)
	if target:getMark("s3_yt_zhentui_dest") > 0 then
		return -1
		end
		end
}

if not sgs.Sanguosha:getSkill("#s3_yt_zhentuiMaxCards") then
	s_skillList:append(s3_yt_zhentuiMaxCards)
end
s3_yt_chendao:addSkill(s3_yt_baier)
s3_yt_chendao:addSkill(s3_yt_zhentui)
s3_yt_chendao:addSkill(s3_yt_zhentui_t)
extension_bf:insertRelatedSkills("s3_yt_zhentui","#s3_yt_zhentui_t")

sgs.LoadTranslationTable{
	["s3_yt_chendao"] = "陈到",
	["&s3_yt_chendao"] = "陈到",
	["#s3_yt_chendao"] = "厚重忠克",
	["designer:s3_yt_chendao"] = "怎么了你听得到",
	
	["s3_yt_baier"] = "白毦",
	[":s3_yt_baier"] = "你的体力值为奇数时，你可以将一张手牌当【闪】使用或打出；你的体力值为偶数时，你可以将一张手牌当【杀】使用或打出。",
	
	["s3_yt_zhentui"] = "镇退",
	["@s3_yt_zhentui"] = "镇退",
	[":s3_yt_zhentui"] = "<font color=\"blue\"><b>锁定技，</b></font>你的攻击范围始终为X；当你一回合内第二次使用“白毦”时，你令当前回合角色于本回合的手牌上张-1。（X为全场体力值最小或之一的角色的体力数）",
	
}



s3_yt_domgyun = sgs.General(extension_bf,"s3_yt_domgyun","shu","3")

s3_yt_kuangjun = sgs.CreateTriggerSkill{
	name = "s3_yt_kuangjun" ,
	frequency = sgs.Skill_NotFrequent ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _,domgyun in sgs.list(room:findPlayersBySkillName(self:objectName()))do
			if domgyun and domgyun:inMyAttackRange(player) then
			local dest = sgs.QVariant()
			dest:setValue(player)
			if room:askForSkillInvoke(domgyun, self:objectName(), dest) then
				player:drawCards(1, self:objectName())
				local card = room:askForCard(player, "TrickCard", string.format("@s3_yt_kuangjun:%s" ,domgyun:objectName()), sgs.QVariant(), sgs.Card_MethodNone, nil, false, self:objectName(), false)
				if card then 
				domgyun:addToPile("s3_yt_kuangjun", card)
				else
					return true
				end
			end
		end
		end
		return false
	end,
		can_trigger = function(self, target)
		return target and target:getPhase() == sgs.Player_Draw
	end
}

s3_yt_huzheng = sgs.CreateTriggerSkill{
	name = "s3_yt_huzheng" ,
	frequency = sgs.Skill_NotFrequent ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _,domgyun in sgs.list(room:findPlayersBySkillName(self:objectName()))do
		if domgyun and domgyun:getPile("s3_yt_kuangjun"):length() > 0 then
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
		if player:canSlash(p, nil, true) then
		targets:append(p)
		end
		end
		if targets:isEmpty() then return false end
		local dest = sgs.QVariant()
		dest:setValue(player)
		if room:askForSkillInvoke(domgyun, self:objectName(), dest) then
			room:notifySkillInvoked(domgyun, self:objectName())
			room:fillAG(domgyun:getPile("s3_yt_kuangjun"), domgyun)
						local cid = room:askForAG(domgyun, domgyun:getPile("s3_yt_kuangjun"), false, self:objectName())
						room:clearAG(domgyun)
						if cid == -1 then
							return
						end
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "s3_yt_huzheng", "");
						room:throwCard(sgs.Sanguosha:getCard(cid), reason, nil)
						local target = room:askForPlayerChosen(player, targets, self:objectName())
						if target then 
						local targets_list = sgs.SPlayerList()
						targets_list:append(target)
						local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						slash:deleteLater()
			slash:setSkillName("s3_yt_huzheng")
			room:useCard(sgs.CardUseStruct(slash, player, targets_list))
			end
		end
	end
		end
		return false
	end,
		can_trigger = function(self, target)
		return target and target:getPhase() == sgs.Player_Finish
	end
}



s3_yt_domgyun:addSkill(s3_yt_kuangjun)
s3_yt_domgyun:addSkill(s3_yt_huzheng)

sgs.LoadTranslationTable{
	["s3_yt_domgyun"] = "董允",
	["&s3_yt_domgyun"] = "董允",
	["#s3_yt_domgyun"] = "秉正之相",
	["designer:s3_yt_domgyun"] = "怎么了你听得到",
	
	["s3_yt_kuangjun"] = "匡君",
	["@s3_yt_kuangjun"] = "你须将一张锦囊牌置于 %src 的武将牌上",
	[":s3_yt_kuangjun"] = "攻击范围内一名角色摸牌阶段开始时，你可令其摸一张牌。然后其须将一张锦囊牌置于你的武将牌上；否则，其跳过摸牌阶段并直接进入出牌阶段。",
	
	["s3_yt_huzheng"] = "护政",
	[":s3_yt_huzheng"] = "一名角色结束阶段开始时，你可以弃置武将牌上一张牌，视为其使用一张有距离限制的【杀】。",
	
}
s3_yt_liuyan = sgs.General(extension_bf,"s3_yt_liuyan","shu","3")


s3_yt_shixu = sgs.CreateTriggerSkill{
	name = "s3_yt_shixu", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd}, 
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseStart then
			if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play then
				player:getRoom():sendCompulsoryTriggerLog(player, self:objectName(), true)
				player:drawCards(2, self:objectName())
				player:getRoom():addPlayerMark(player,"s3_yt_shixu")
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getMark("s3_yt_shixu") > 0 then
			player:getRoom():setPlayerMark(player,"s3_yt_shixu", 0)
		end
		end
		return false
	end
}
s3_yt_shixuMod = sgs.CreateTargetModSkill{
	name = "#s3_yt_shixuMod",
	pattern = "Slash",
	residue_func = function(self, player, card)
		if player:hasSkill("s3_yt_shixu")  then
			return -player:getMark("s3_yt_shixu")
		end
	end,
}


s3_yt_huangyiProhibit = sgs.CreateProhibitSkill{
	name = "#s3_yt_huangyiProhibit" ,
	is_prohibited = function(self, from, to, card)
		if card:getSkillName() == "s3_yt_huangyi" then
			if from:hasSkill("s3_yt_huangyi") then
				return not to:hasFlag("s3_yt_huangyi_T")
			end
		end
		return false
	end
}
s3_yt_huangyivs = sgs.CreateZeroCardViewAsSkill{
	name = "s3_yt_huangyi",
	view_as = function(self)
	    local pattern = sgs.Self:property("s3_yt_huangyi"):toString()
		local acard = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@s3_yt_huangyi"
	end
}

s3_yt_huangyi = sgs.CreateTriggerSkill{
	name = "s3_yt_huangyi",
	events = {sgs.EventPhaseStart},
	view_as_skill = s3_yt_huangyivs,
	can_trigger = function(self, player)
	    return true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local allplayers = room:findPlayersBySkillName(self:objectName())
		if player:getPhase() == sgs.Player_Start then
			if player:hasFlag("s3_yt_huangyi") then
			room:handleAcquireDetachSkills(player, "s3_yt_huangyi")
			end
			for _,selfplayer in sgs.qlist(allplayers) do
				if selfplayer:objectName() ~= player:objectName() then 
				if room:askForSkillInvoke(selfplayer, self:objectName(), data) then
					local xzbasic = {"slash"}
					local xztrick = {"snatch", "dismantlement", "collateral", "ex_nihilo", "duel", "amazing_grace", "savage_assault", "archery_attack", "god_salvation"}
					if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
						table.insert(xztrick, "fire_attack")
						table.insert(xztrick, "iron_chain")
					end
					local choicecard = "TrickCard"
					if selfplayer:canSlash(room:getCurrent(), nil, true) then
					choicecard = string.format("%s+%s", choicecard, "slash")
					end
					local typechoice = room:askForChoice(selfplayer, "s3_yt_huangyi_type",choicecard)
					local choice
					local pattern
					if typechoice == "slash" then
					choice = "slash"
					pattern = xzbasic
					else
						pattern = xztrick
						for _,patt in ipairs(pattern) do
						local poi = sgs.Sanguosha:cloneCard(patt, sgs.Card_NoSuit, 0)
						if not poi:isAvailable(selfplayer) then
							table.removeOne(pattern, patt)
						end
					end
					 choice = room:askForChoice(selfplayer, self:objectName(), table.concat(pattern, "+"), data)
					end
					if choice then
						if choice == "ex_nihilo" or choice == "amazing_grace" or
						choice == "savage_assault" or choice == "archery_attack" or choice == "god_salvation" then
							local use = sgs.CardUseStruct()
							room:setPlayerFlag(room:getCurrent(), "s3_yt_huangyi_T")
							local card = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, 0)
							card:deleteLater()
							card:setSkillName(self:objectName())
							use.card = card
							use.from = selfplayer
							use.to:append(player)
							room:useCard(use)
							room:setPlayerFlag(room:getCurrent(), "-s3_yt_huangyi_T")
							selfplayer:turnOver()
							room:setPlayerFlag(selfplayer, "s3_yt_huangyi")
							room:detachSkillFromPlayer(selfplayer, "s3_yt_huangyi")
						else
							room:setPlayerFlag(room:getCurrent(), "s3_yt_huangyi_T")
							room:setPlayerProperty(selfplayer, "s3_yt_huangyi", sgs.QVariant(choice))
							local prompt = string.format("@s3_yt_huangyi:%s:%s",player:objectName(),choice)
							if room:askForUseCard(selfplayer, "@@s3_yt_huangyi", prompt) then
							selfplayer:turnOver()
							room:setPlayerFlag(selfplayer, "s3_yt_huangyi")
							room:detachSkillFromPlayer(selfplayer, "s3_yt_huangyi")
							end
							room:setPlayerProperty(selfplayer, "s3_yt_huangyi", sgs.QVariant())
							room:setPlayerFlag(room:getCurrent(), "-s3_yt_huangyi_T")
						end
					end
				end
				end
			end
		end
	end
}

s3_yt_liuyan:addSkill(s3_yt_shixu)
s3_yt_liuyan:addSkill(s3_yt_shixuMod)
s3_yt_liuyan:addSkill(s3_yt_huangyi)
s3_yt_liuyan:addSkill(s3_yt_huangyiProhibit)



extension_bf:insertRelatedSkills("s3_yt_shixu","#s3_yt_shixuMod")
sgs.LoadTranslationTable{
	["s3_yt_liuyan"] = "刘琰",
	["&s3_yt_liuyan"] = "刘琰",
	["#s3_yt_liuyan"] = "負乘致寇",
	["designer:s3_yt_liuyan"] = "怎么了你听得到",
	
	["#s3_yt_huangyiProhibit"] = "恍疑",
	["s3_yt_shixu"] = "实虚",
	[":s3_yt_shixu"] = "<font color=\"blue\"><b>锁定技，</b></font>出牌阶段开始时，你摸两张牌，然后你于此阶段可使用【杀】的次数 -1 。",
	["@s3_yt_huangyi"] = "你可以发动“实虚”<br/>视为對 %dest 使用一张 %src",
	["~s3_yt_huangyi"] = "选择目标→确定",
	["s3_yt_huangyi"] = "恍疑",
	["s3_yt_huangyi_type"] = "恍疑",
	[":s3_yt_huangyi"] = "一名其他角色准备阶段开始时 ，你可以视为使用一张非延时类锦囊或【杀】；你以此法使用的牌仅能指定该角色为目标。若如此做，你将你的武将牌翻面，然后失去此技能直到你下回合开始。",
--http://tieba.baidu.com/p/3915633656?see_lz=1&pn=1#	
}

s3_yt_mazhong = sgs.General(extension_bf,"s3_yt_mazhong","shu","4")

s3_yt_zhinan = sgs.CreateTriggerSkill{
	name = "s3_yt_zhinan" ,
	events = {sgs.CardFinished} ,
	frequency = sgs.Skill_NotFrequent ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("SavageAssault") then
			for _,mazhong in sgs.list(room:findPlayersBySkillName(self:objectName()))do
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
				if mazhong:canSlash(p, nil, true) then
				targets:append(p)
				end
				end
				if targets:isEmpty() then continue end
		 local target = room:askForPlayerChosen(mazhong, targets, self:objectName(), "s3_yt_zhinan-invoke", true, true)
						if target then 
						room:notifySkillInvoked(mazhong, self:objectName())
						local targets_list = sgs.SPlayerList()
						targets_list:append(target)
						local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						slash:deleteLater()
			slash:setSkillName("s3_yt_zhinan")
			room:useCard(sgs.CardUseStruct(slash, mazhong, targets_list))
			end
		end
		end
	end ,
	can_trigger = function(self, target)
		return target
	end
}

s3_yt_fuding = sgs.CreateTriggerSkill{
	name = "s3_yt_fuding" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_NotFrequent ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if not player:isNude() then
				local card = room:askForExchange(player, self:objectName(), 1,1, true, "s3_yt_fuding-invoke", true)
				if card then
					room:notifySkillInvoked(player, self:objectName())
					local move = sgs.CardsMoveStruct()
					move.card_ids = card:getSubcards()
					move.to_place = sgs.Player_DrawPile
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "s3_yt_fuding", "");
					move.reason = reason	
					room:setPlayerFlag(player, "Global_GongxinOperator")
					room:moveCardsAtomic(move,false)
					room:setPlayerFlag(player, "-Global_GongxinOperator")
					local x = 0
					for _, p in sgs.qlist(room:getAllPlayers()) do
						if player:inMyAttackRange(p) then
							local slash = room:askForCard(p , "slash", string.format("s3_yt_fuding_push:%s",player:objectName()), sgs.QVariant(), sgs.Card_MethodNone)
							if slash then 
								x = x + 1
								room:showCard(p,slash:getEffectiveId())
								if room:askForSkillInvoke(p, "s3_yt_fuding_recast") then
									 local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, p:objectName())
									reason.m_skillName = self:objectName()
									room:moveCardTo(slash, p, nil, sgs.Player_DiscardPile, reason);
									p:broadcastSkillInvoke("@recast")
									local log = sgs.LogMessage()
									log.type = "#UseCard_Recast"
									log.from = p
									log.card_str = slash:getNumberString()
									room:sendLog(log)
									p:drawCards(1, "recast")
								end
							else
								if player:canDiscard(p, "he") then
									local to_throw = room:askForCardChosen(player, p, "he", self:objectName(), false, sgs.Card_MethodDiscard)
									room:throwCard(sgs.Sanguosha:getCard(to_throw), p, player)
								end
							end
						end
					end
					if player:getHandcardNum() > x then
						room:askForDiscard(player, self:objectName(), player:getHandcardNum() - x, player:getHandcardNum() - x, false, false)
					elseif player:getHandcardNum() < x then
						player:drawCards(x - player:getHandcardNum(), self:objectName())
					end
				end
			end
		end
	end
}


s3_yt_mazhong:addSkill(s3_yt_zhinan)
s3_yt_mazhong:addSkill(s3_yt_fuding)
sgs.LoadTranslationTable{
	["s3_yt_mazhong"] = "马忠",
	["&s3_yt_mazhong"] = "马忠",
	["#s3_yt_mazhong"] = "南中绒威",
	["designer:s3_yt_mazhong"] = "怎么了你听得到",
	
	["s3_yt_zhinan-invoke"] = "你可以发动“治南”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["s3_yt_zhinan"] = "治南",
	[":s3_yt_zhinan"] = "每当一张【南蛮入侵】结算后，你可视为使用一张【杀】。",
	
	["s3_yt_fuding-invoke"] = "你可以发动“抚定”<br/> <b>操作提示</b>: 选择一张牌→点击确定<br/>",
	["s3_yt_fuding_push"] = "你展示一张【杀】或令 %dest 弃置你一张牌",
	["s3_yt_fuding_recast"] = "你可以重铸【杀】",
	["s3_yt_fuding"] = "抚定",
	[":s3_yt_fuding"] = "准备阶段开始时，你可将一张牌置于牌堆顶，然后你攻击范围内的角色依次选择一项：展示一张【杀】并可以重铸之；或令你弃置其一张牌，然后你将手牌调整至 X 张（ X 为因“抚定”展示牌的角色数）。",
	
--http://tieba.baidu.com/p/3915633656?see_lz=1&pn=1#	
}

s3_yt_wangping = sgs.General(extension_bf,"s3_yt_wangping","shu","4")



s3_yt_feijun = sgs.CreateTriggerSkill{
	name = "s3_yt_feijun",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Play then
			local room = player:getRoom()
			if player:getHp() > 2 then
				if  not player:isKongcheng() and room:askForSkillInvoke(player, self:objectName()) then
					room:showAllCards(player)
					room:notifySkillInvoked(player, self:objectName())
					local basic = 0 
					local equip = 0 
					local trick = 0 
					for _, card in sgs.qlist(player:getHandcards()) do
						if card:isKindOf("BasicCard") then 
							basic = basic + 1 
						elseif card:isKindOf("EquipCard") then 
							equip = equip + 1 
						elseif card:isKindOf("TrickCard") then 
							trick = trick + 1 
						end
					end 
					local choicelist = "cancel"
					if basic > 0 then 
						choicelist = string.format("%s+%s", choicelist, "BasicCard")
					end
					if equip > 0 then 
						choicelist = string.format("%s+%s", choicelist, "EquipCard")
					end 
					if trick > 0 then 
						choicelist = string.format("%s+%s", choicelist, "TrickCard") 
					end 
					local choice = room:askForChoice(player, self:objectName(), choicelist)
					local dummy = sgs.Sanguosha:cloneCard("slash")
					dummy:deleteLater()
					for _, card_id in sgs.qlist(player:getHandcards()) do
						if choice == "BasicCard" and card_id:isKindOf("BasicCard") then
						dummy:addSubcard(card_id)
						elseif choice == "EquipCard" and card_id:isKindOf("EquipCard") then
						dummy:addSubcard(card_id)
						elseif choice == "TrickCard" and card_id:isKindOf("TrickCard") then
						dummy:addSubcard(card_id)
						end
					end
					room:throwCard(dummy, player, player)
					local targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if player:canSlash(p, nil, true) then
							targets:append(p)
						end
					end
					if targets:isEmpty() then return false end
					local target = room:askForPlayerChosen(player, targets, self:objectName(), "s3_yt_feijun-invoke")
					if target then 
						local targets_list = sgs.SPlayerList()
						targets_list:append(target)
						local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						slash:deleteLater()
						slash:setSkillName("s3_yt_feijun")
						room:useCard(sgs.CardUseStruct(slash, player, targets_list), false)
					end
				end
			else
			if room:askForSkillInvoke(player, self:objectName()) then
				room:notifySkillInvoked(player, self:objectName())
				player:drawCards(1, self:objectName())
				end
			end
		end
		return false
	end
}


s3_yt_wangping:addSkill(s3_yt_feijun)


sgs.LoadTranslationTable{
	["s3_yt_wangping"] = "王平",
	["&s3_yt_wangping"] = "王平",
	["#s3_yt_wangping"] = "无当飞将",
	["designer:s3_yt_wangping"] = "怎么了你听得到",
	
	["s3_yt_feijun"] = "飞军",
	[":s3_yt_feijun"] = "出牌阶段开始时，若你的体力值：大于 2 ，你可以展示所有手牌并弃置一种类别的所有牌（至少一张），视为你使用一张【杀】（不计入回合出杀次数）。不大于 2 ，你可以摸一张牌。",
	["s3_yt_feijun-invoke"] =  "你发动“飞军”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	
--http://tieba.baidu.com/p/3915633656?see_lz=1&pn=1#	
}

s3_yt_zhangyi = sgs.General(extension_bf,"s3_yt_zhangyi","shu","4")

s3_yt_zhengtao = sgs.CreateTriggerSkill{
	name = "s3_yt_zhengtao",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart, sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = math.max(1, player:getLostHp())
		if player:getMark("s3_yt_kangrui") > 0 then
		x = 1 
		end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_NotActive then
				room:setPlayerMark(player, self:objectName(), 0)
				room:setPlayerMark(player, "@s3_yt_zhengtao", 0)
				room:setPlayerMark(player, "s3_yt_zhengtao_add", 0)
			end
		elseif player:getPhase() == sgs.Player_Play and (event == sgs.CardUsed) then
			if event == sgs.CardUsed then
			local card = data:toCardUse().card
			if not card:isKindOf("SkillCard") then
			room:addPlayerMark(player, self:objectName())
			room:addPlayerMark(player, "@s3_yt_zhengtao")
			end
			if player:getMark(self:objectName()) == x and card:isKindOf("Slash") then
			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "s3_yt_zhengtao-invoke", true, true)
			if not target then return false end
			target:drawCards(1, self:objectName())
			if target:getHandcardNum() >= player:getHandcardNum() then
			room:addPlayerMark(player, "@s3_yt_zhengtao_add")
			end
			end
			end
		end
	end
}

s3_yt_zhengtao_tm = sgs.CreateTargetModSkill{
	name = "#s3_yt_zhengtao_tm",
	frequency = sgs.Skill_NotCompulsory,
	residue_func = function(self, player)
		if player:hasSkill("s3_yt_zhengtao") then
			return player:getMark("@s3_yt_zhengtao_add")
		else
			return 0
		end
	end
}

s3_yt_kangrui = sgs.CreateTriggerSkill{
	name = "s3_yt_kangrui" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
		if p:isKongcheng() then
		targets:append(p)
		end
		end
		if not targets:isEmpty() or player:canWake(self:objectName()) then
		room:sendCompulsoryTriggerLog(player, self:objectName())
		room:addPlayerMark(player, self:objectName(), 1)
		room:addPlayerMark(player,"@waked", 1)
		room:drawCards(targets, 2, self:objectName())
		room:changeTranslation(player,"s3_yt_zhengtao",2)
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getMark("s3_yt_kangrui") == 0)
				and (target:getPhase() == sgs.Player_Finish)
	end
}




if not sgs.Sanguosha:getSkill("#s3_yt_zhengtao_tm") then
	s_skillList:append(s3_yt_zhengtao_tm)
end

s3_yt_zhangyi:addSkill(s3_yt_zhengtao)
s3_yt_zhangyi:addSkill(s3_yt_kangrui)

sgs.LoadTranslationTable{
	["s3_yt_zhangyi"] = "张翼",
	["&s3_yt_zhangyi"] = "张翼",
	["#s3_yt_zhangyi"] = "忠義逆鱗",
	["designer:s3_yt_zhangyi"] = "怎么了你听得到",
	
	["s3_yt_zhengtao-invoke"] = "你可以发动“征讨”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["s3_yt_zhengtao"] = "征讨",
	["@s3_yt_zhengtao"] = "征讨",
	["@s3_yt_zhengtao_add"] = "征讨",
	[":s3_yt_zhengtao"] = "出牌阶段，若你使用的第 X 张牌为【杀】，则你可令一名角色摸一张牌。然后若其的手牌不小于你，你本回合可使用【杀】的次数 +1 （ X 为你已损失的体力值，且至少为 1 ）。",
	[":s3_yt_zhengtao2"] = "出牌阶段，若你使用的第 1 张牌为【杀】，则你可令一名角色摸一张牌。然后若其的手牌不小于你，你本回合可使用【杀】的次数 +1 （ X 为你已损失的体力值，且至少为 1 ）。",

	["s3_yt_kangrui"] = "亢锐",
	[":s3_yt_kangrui"] = "<font color=\"purple\"><b>觉醒技，</b></font>结束阶段开始时，若场上有角色没有手牌，你令没有手牌的所有角色摸两张牌，然后你将“征讨”描述中的“ X ”改为“ 1 ”。",
	
--http://tieba.baidu.com/p/3915633656?see_lz=1&pn=1#	
}


s3_yt_shamoke = sgs.General(extension_bf,"s3_yt_shamoke","shu","4")




s3_yt_mangyong = sgs.CreateTriggerSkill{
	name = "s3_yt_mangyong" ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
			if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
		if (move.from and move.from:objectName() == player:objectName()) and (move.from_places:contains(sgs.Player_PlaceHand) or move.to_place == sgs.Player_PlaceHand) and player:hasSkill(self:objectName()) then
		local x = 0
		for _, p in sgs.qlist(room:getAlivePlayers()) do
		if p:getWeapon() ~= nil then
		x = x + 1
		end
		end
				if player:getHandcardNum() == x and player:getMark("s3_yt_mangyong-Clear") == 0 then
				if room:askForSkillInvoke(player, self:objectName()) then
				room:addPlayerMark(player,"s3_yt_mangyong-Clear")
				room:addPlayerMark(player,"&s3_yt_mangyong-Clear")
				player:throwAllHandCards()
				local savage_assault=sgs.Sanguosha:cloneCard("savage_assault",sgs.Card_NoSuit,0)
		savage_assault:setSkillName(self:objectName())
		savage_assault:deleteLater()
local use=sgs.CardUseStruct()
		use.card=savage_assault
		use.from=player
		room:useCard(use,false)
				end
				end
			end
		end
		return false
	end, 
}





s3_yt_shamoke:addSkill(s3_yt_mangyong)



sgs.LoadTranslationTable{
	["s3_yt_shamoke"] = "沙摩柯",
	["&s3_yt_shamoke"] = "沙摩柯",
	["#s3_yt_shamoke"] = "五溪蛮领",
	["designer:s3_yt_shamoke"] = "怎么了你听得到",
	
	["s3_yt_mangyong"] = "蛮勇",
	[":s3_yt_mangyong"] = "每名角色回合内限一次，当你的手牌数变为X 时，你可以弃置所有手牌，视为你使用一张【南蛮入侵】（ X 为场上的武器牌数）。",
	
--http://tieba.baidu.com/p/3915633656?see_lz=1&pn=1#	
}

s3_yt_huoyi = sgs.General(extension_bf,"s3_yt_huoyi","shu","4")



s3_yt_tongnanCard = sgs.CreateSkillCard{
	name = "s3_yt_tongnan",

	filter = function(self, targets, to_select)
		return #targets == 0 and (not to_select:isNude())
	end,

	on_use = function(self, room, source, targets)
		local card = room:askForCardChosen(source, targets[1], "he", self:objectName())
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, targets[1]:objectName())
				reason.m_skillName = self:objectName()
				room:moveCardTo(sgs.Sanguosha:getCard(card), targets[1], nil, sgs.Player_DiscardPile, reason)
				source:broadcastSkillInvoke("@recast")

				local log = sgs.LogMessage()
				log.type = "#UseCard_Recast"
				log.from = targets[1]
				log.card_str = sgs.Sanguosha:getCard(card):toString()
				room:sendLog(log)
				targets[1]:drawCards(1, "recast")
		if sgs.Sanguosha:getCard(card):isKindOf("Slash") then
			room:addPlayerMark(source, "&s3_yt_tongnan-Clear")
			room:setPlayerFlag(source, "s3_yt_tongnan_success")
			room:setPlayerMark(source, "@s3_yt_tongnan", 1)
		end
	end
}
s3_yt_tongnanVS = sgs.CreateZeroCardViewAsSkill{
	name = "s3_yt_tongnan",
	view_as = function(self) 
		return s3_yt_tongnanCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#s3_yt_tongnan") 
	end, 
}
s3_yt_tongnan = sgs.CreateTriggerSkill{
	name = "s3_yt_tongnan",
	events = {sgs.EventLoseSkill, sgs.EventPhaseEnd},
	view_as_skill = s3_yt_tongnanVS,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	if event == sgs.EventLoseSkill then
		if data:toString() == self:objectName() then
			room:setPlayerFlag(player, "-s3_yt_tongnan_success")
			room:setPlayerMark(player, "@s3_yt_tongnan", 0)
		end
	elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
	room:setPlayerMark(player, "@s3_yt_tongnan", 0)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasFlag("s3_yt_tongnan_success")
	end,
}
s3_yt_tongnanTargetMod = sgs.CreateTargetModSkill{
	name = "#s3_yt_tongnanTargetMod",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player:hasSkill("s3_yt_tongnan") and player:hasFlag("s3_yt_tongnan_success") then
			return 1000
		else
			return 0
		end
	end,
	extra_target_func = function(self, player)
		if player:hasSkill("s3_yt_tongnan") and player:hasFlag("s3_yt_tongnan_success") then
			return 1
		else
			return 0
		end
	end,
}





s3_yt_huoyi:addSkill(s3_yt_tongnan)
s3_yt_huoyi:addSkill(s3_yt_tongnanTargetMod)
extension_bf:insertRelatedSkills("s3_yt_tongnan","#s3_yt_tongnanTargetMod")




sgs.LoadTranslationTable{
	["s3_yt_huoyi"] = "霍弋",
	["&s3_yt_huoyi"] = "霍弋",
	["#s3_yt_huoyi"] = "天都抚安",
	["designer:s3_yt_huoyi"] = "怎么了你听得到",
	
	["s3_yt_tongnan"] = "统南",
	["@s3_yt_tongnan"] = "统南",
	[":s3_yt_tongnan"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可重铸一名角色一张牌。若你以此法重铸了【杀】，则你本回合使用【杀】无距离限制且可额外指定一名角色为目标。",
	
--http://tieba.baidu.com/p/3915633656?see_lz=1&pn=1#	
}

s3_yt_xiangchong = sgs.General(extension_bf,"s3_yt_xiangchong","shu","4")


s3_yt_junlie = sgs.CreateTriggerSkill{
	name = "s3_yt_junlie",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirming, sgs.CardFinished, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			local source = use.from
			local targets = use.to
			local card = use.card
			if source and source:objectName() ~= player:objectName() then
				if targets:contains(player)and not player:isKongcheng() and  use.to:length() == 1 and not player:hasFlag("s3_yt_junlie") and player:hasSkill(self:objectName()) then
					if not card:isKindOf("SkillCard") then
					room:setTag("CurrentUseStruct", data)
					local target = room:askForPlayerChosen(player, room:getOtherPlayers(player),  self:objectName(), "s3_yt_junlie-invoke", true, true)
					room:removeTag("CurrentUseStruct")
						if target then
							room:broadcastSkillInvoke(self:objectName())
							room:setCardFlag(card, "s3_yt_junlie")
							room:setPlayerFlag(player, "s3_yt_junlie")
							target:addMark("s3_yt_junlie")
							target:obtainCard(player:wholeHandCards())
						end
					end
				end
			end
			
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			local card = use.card
			local dest 
			for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:hasFlag(self:objectName()) then
			dest = p
			end
			end
			if card:hasFlag("s3_yt_junlie")  then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getMark("s3_yt_junlie") > 0 then
					p:setMark("s3_yt_junlie", 0)
						room:setCardFlag(card, "-s3_yt_junlie")
				local thisCount = p:getHandcardNum()
				local thatCount = dest:getHp()
				local x = math.min(thatCount, thisCount)
				if x > 0 then
					local to_exchange = nil
					if thisCount == x then
						to_exchange = p:wholeHandCards()
					else
						to_exchange = room:askForExchange(p, string.format("s3_yt_junlie_work:%s:%s", dest:objectName(), x), x, x)
					end
					room:moveCardTo(to_exchange, dest, sgs.Player_PlaceHand, false)
				end
			end
				end
			end
			elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
			room:setPlayerFlag(p, "-s3_yt_junlie")
			end
			end
		end
	end,
		can_trigger = function(self, target)
		return true
	end
}


s3_yt_xiangchong:addSkill(s3_yt_junlie)





sgs.LoadTranslationTable{
	["s3_yt_xiangchong"] = "向宠",
	["&s3_yt_xiangchong"] = "向宠",
	["#s3_yt_xiangchong"] = "曉暢軍事",
	["designer:s3_yt_xiangchong"] = "怎么了你听得到",
	
	["s3_yt_junlie"] = "均略",
	[":s3_yt_junlie"] = "每名角色回合限一次，当你成为其他角色所使用牌的唯一目标时，你可以将全部手牌( 至少一张)交给任意一名其他角色，当这张牌结算完毕后，获得你手牌的角色须交给你X张牌(X为你的体力值)。",
	["s3_yt_junlie_work"] = "你须交给 %src %dest 张牌",
	["s3_yt_junlie-invoke"] = "你可以发动“均略”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	
--http://tieba.baidu.com/p/3915633656?see_lz=1&pn=1#	
}


s3_yt_wenqin = sgs.General(extension_bf,"s3_yt_wenqin","wei","4")

s3_yt_gangyong = sgs.CreateMasochismSkill{
	name = "s3_yt_gangyong" ,
	on_damaged = function(self, player, damage)
		local from = damage.from
		local room = player:getRoom()
		local data = sgs.QVariant()
		data:setValue(damage)
		if from and from:getPhase() == sgs.Player_Play and room:askForSkillInvoke(player, self:objectName(), data) then
			if (not from) or from:isDead() then return end
			room:setPlayerFlag(from, "Global_PlayPhaseTerminated")
		end
	end
}

s3_yt_qibingCard = sgs.CreateSkillCard{
	name = "s3_yt_qibing", 
	filter = function(self, targets, to_select) 
		if #targets ~= 0  then return false end
		return to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		effect.from:loseMark("@s3_yt_qibing", 1)
		room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
		if effect.to:isAlive() then
		if room:changeMaxHpForAwakenSkill(effect.from, -1) then
					room:handleAcquireDetachSkills(effect.from, "s3_yt_panjiang")
			end
		end
	end
}
s3_yt_qibingVS = sgs.CreateViewAsSkill{
	name = "s3_yt_qibing", 
	n = 0, 
	enabled_at_play = function(self, player)
		return  player:getMark("@s3_yt_qibing") > 0
	end,
	view_as = function(self, cards) 
		if #cards == 0 then
			return s3_yt_qibingCard:clone()
		end
	end
}
s3_yt_qibing = sgs.CreateTriggerSkill{
	name = "s3_yt_qibing" ,
	frequency = sgs.Skill_Limited ,
	view_as_skill = s3_yt_qibingVS ,
	limit_mark = "@s3_yt_qibing" ,
	on_trigger = function()
	end
}


s3_yt_panjiang = sgs.CreateTriggerSkill{
	name = "s3_yt_panjiang" ,
	frequency = sgs.Skill_NotFrequent ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, p in sgs.list(room:findPlayersBySkillName(self:objectName())) do
			local dest = sgs.QVariant()
			dest:setValue(player)
			if room:askForDiscard(p,self:objectName(),1,1,true,true,"s3_yt_panjiang-invoke",".") then
				local card = sgs.Sanguosha:getCard(room:drawCard())
				room:obtainCard(player, card)
				room:showCard(player, card:getId())
				if card:isKindOf("EquipCard") then
					p:drawCards(1, self:objectName())
				end
			end
		end
		return false
	end,
		can_trigger = function(self, target)
		return target and target:getPhase() == sgs.Player_Draw
	end
}








s3_yt_wenqin:addSkill(s3_yt_gangyong)
s3_yt_wenqin:addSkill(s3_yt_qibing)
if not sgs.Sanguosha:getSkill("s3_yt_panjiang") then
	s_skillList:append(s3_yt_panjiang)
end
s3_yt_wenqin:addRelateSkill("s3_yt_panjiang")







sgs.LoadTranslationTable{
	["s3_yt_wenqin"] = "文钦",
	["&s3_yt_wenqin"] = "文钦",
	["#s3_yt_wenqin"] = "壮勇节义",
	["designer:s3_yt_wenqin"] = "怎么了你听得到",
	
	["s3_yt_gangyong"] = "刚勇",
	[":s3_yt_gangyong"] = "每当你受到一名角色在其出牌阶段内对你造成的一次伤害后，你可令当前回合角色直接进入弃牌阶段。",
	
	["s3_yt_panjiang"] = "叛降",
	[":s3_yt_panjiang"] = "一名角色摸牌阶段开始时，你可以弃置一张牌，令其摸一张牌。若此牌为装备牌，你摸一张牌。",
	["s3_yt_panjiang-invoke"] = "你可以发动“叛降”<br/> <b>操作提示</b>: 选择一张牌→点击确定<br/>",
	
	["s3_yt_qibing"] = "起兵",
	["@s3_yt_qibing"] = "起兵",
	[":s3_yt_qibing"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以对一名其他角色造成一点伤害。然后若其没有死亡，你减一点体力上限，获得技能“叛降”。",
}

s3_yt_chochun = sgs.General(extension_bf,"s3_yt_chochun","wei","4")


s3_yt_ruiqiDummyCard = sgs.CreateSkillCard {
	name = "s3_yt_ruiqiDummyCard"
}
s3_yt_ruiqi = sgs.CreateTriggerSkill {
	name = "s3_yt_ruiqi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardEffected, sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") or (use.card:isKindOf("TrickCard") and use.card:isNDTrick()) then 
			if not use.to:contains(player) and player:hasSkill(self:objectName()) and player:objectName() == use.from:objectName() and room:askForSkillInvoke(player,self:objectName(), data)then
			room:setCardFlag(use.card, self:objectName())
			end
		end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			local dest = effect.to
			local source = effect.from
			if effect.card and (effect.card:isKindOf("Slash") or effect.card:isNDTrick()) and source:hasSkill(self:objectName()) and effect.card:hasFlag(self:objectName()) then
				room:notifySkillInvoked(source, self:objectName())
				
				local jink = nil
				local log= sgs.LogMessage()
				log.type = "#TriggerSkill"
				log.from = effect.from
				log.arg = self:objectName()
				room:sendLog(log)
				local slasher = player:objectName()
				room:setTag("s3_yt_ruiqi", data)
				jink = room:askForUseCard(effect.to, "@@s3_yt_ruiqiDiscard", "@s3_yt_ruiqi-discard", 5, sgs.Card_MethodDiscard, false, player, effect.card)
				room:removeTag("s3_yt_ruiqi")
				if (jink) then
					effect.to:setFlags("Global_NonSkillNullify")
					jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
					jink:addSubcards(jink:getSubcards())
					jink:deleteLater()
					effect.offset_card = jink
					data:setValue(effect)
					if not room:getThread():trigger(sgs.CardOffset,room,effect.from,data) then
						return true
					end
				else
					effect.offset_card = nil
					effect.no_respond = true
					data:setValue(effect)
				end		
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
s3_yt_ruiqiDiscard = sgs.CreateViewAsSkill{
	name = "#s3_yt_ruiqiDiscard", 
	n = 2, 
	enabled_at_play = function(self, player)
		return  false
	end,
	enabled_at_response = function(self, player, pattern)
			return pattern == "@@s3_yt_ruiqiDiscard"
	end,
	view_filter = function(self, selected, to_select)
	if #selected == 0 then
					return to_select:isKindOf("BasicCard") or to_select:isKindOf("TrickCard")
	elseif #selected == 1 then
		if selected:first():getTypeId() == sgs.Card_TypeTrick then
			return false
		elseif selected:first():getTypeId() == sgs.Card_TypeBasic then
			return to_select:getTypeId() == sgs.Card_TypeBasic
			end
		else 
		return false
					end
	end, 
	view_as = function(self, cards) 
		local ok = false
		if #cards == 1 then
			ok = cards:first():getTypeId() == sgs.Card_TypeTrick 
		elseif #cards == 2 then
			ok = true
			for _,c in sgs.qlist(cards) do
			if c:getTypeId() == sgs.Card_TypeTrick then
			ok = false
			end
			end
		end
		if not ok then
		return nil
		end
		local dummy = sgs.Sanguosha:cloneCard("slash")
		dummy:addSubcards(cards)
		return dummy
	end
}


	  



s3_yt_chochun:addSkill(s3_yt_ruiqi)


if not sgs.Sanguosha:getSkill("#s3_yt_ruiqiDiscard") then
	s_skillList:append(s3_yt_ruiqiDiscard)
end







sgs.LoadTranslationTable{
	["s3_yt_chochun"] = "曹纯",
	["&s3_yt_chochun"] = "曹纯",
	["#s3_yt_chochun"] = "虎豹騎統",
	["designer:s3_yt_chochun"] = "怎么了你听得到",
	
	["s3_yt_ruiqidummy"] = "锐骑",
	["s3_yt_ruiqi"] = "锐骑",
	[":s3_yt_ruiqi"] = "每当你的【杀】或非延时类锦囊牌指定其他角色为目标后，你可令此【杀】或非延时类锦囊牌的抵消方式为弃置两张基本牌或弃置一张锦囊牌。",
	["@s3_yt_ruiqi-discard"] = "<font color=\"yellow\"><b>锐骑</b></font><br>你的抵消方式为弃置两张基本牌或弃置一张锦囊牌。",

}



s3_yt_zhuling = sgs.General(extension_bf,"s3_yt_zhuling","wei","4")


s3_yt_congzheng = sgs.CreateTriggerSkill{
	name = "s3_yt_congzheng" ,
	events = {sgs.EventPhaseStart, sgs.PreCardUsed, sgs.CardResponded} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
		if player:getPhase() == sgs.Player_Start then 
			for _, yuejin in sgs.list(room:findPlayersBySkillName(self:objectName())) do
		if yuejin:canDiscard(yuejin, "he") and room:askForCard(yuejin, "..", "@s3_yt_congzheng", sgs.QVariant(), self:objectName()) then
					local judge = sgs.JudgeStruct()
					judge.pattern = "."
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					player:addMark("s3_yt_congzheng"..yuejin:objectName() .. tostring(judge.card:getTypeId()).."-Clear", 1)
					room:addPlayerMark(player, "&s3_yt_congzheng+to+:+".. judge.card:getType().."+#"..yuejin:objectName().."-Clear", 1)
		end
			end
		elseif player:getPhase() == sgs.Player_Finish then
for _, yuejin in sgs.list(room:findPlayersBySkillName(self:objectName())) do
		if player:getMark("s3_yt_congzheng"..yuejin:objectName().."-Clear") > 0 then

		room:damage(sgs.DamageStruct(self:objectName(), yuejin, player))
		end
	end
		end
		elseif event == sgs.PreCardUsed or event == sgs.CardResponded then
		if player:getPhase() ~= sgs.Player_NotActive then
				local card = nil
				if event == sgs.PreCardUsed then
					card = data:toCardUse().card
				else
					card = data:toCardResponse().m_card			 
				end
				for _, yuejin in sgs.list(room:findPlayersBySkillName(self:objectName())) do
					if player:getMark("s3_yt_congzheng"..yuejin:objectName() .. tostring(card:getTypeId()).."-Clear") > 0 then
						player:addMark("s3_yt_congzheng"..yuejin:objectName().."-Clear", 1)
					end
				end
			end
		end
		return false
	end
}

s3_yt_zhuling:addSkill(s3_yt_congzheng)

sgs.LoadTranslationTable{
	["s3_yt_zhuling"] = "朱灵",
	["&s3_yt_zhuling"] = "朱灵",
	["#s3_yt_zhuling"] = "力亚五子",
	["designer:s3_yt_zhuling"] = "怎么了你听得到",
	
	["s3_yt_congzheng"] = "从征",
	["@s3_yt_congzheng"] = "你可以发动“从征 ”<br/> <b>操作提示</b>: 选择一张牌→点击确定<br/>",
	[":s3_yt_congzheng"] = "一名角色的准备阶段开始时，你可以弃一张牌令其进行一次判定。若该角色于本回合内使用或打出了与判定牌类别相同的牌，则你于结束阶段对该角色造成 1 点伤害。",
}


s3_yt_wangling = sgs.General(extension_bf,"s3_yt_wangling","wei","4")



s3_yt_yinpan = sgs.CreateTriggerSkill{
	name = "s3_yt_yinpan", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart,sgs.CardFinished},   
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
		player:setMark("s3_yt_yinpan",0)
			if player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) and player:getPile("&s3_yinpan"):length() > 0 then
				--player:removePileByName("&s3_yinpan")
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				dummy:deleteLater()
						for _,cd in sgs.qlist(player:getPile("&s3_yinpan")) do
							dummy:addSubcard(cd)
						end
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil, self:objectName(), "")
						room:throwCard(dummy, reason, nil)
				room:loseHp(player)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if not use.card then return end
			if use.card and use.card:getHandlingMethod() == sgs.Card_MethodUse and player:getMark("s3_yt_yinpan") == 0 and player:getPhase() == sgs.Player_Play then
			player:addMark("s3_yt_yinpan")
			if not use.card:isKindOf("BasicCard") and not use.card:isNDTrick() then return end
			for _, p in sgs.list(room:findPlayersBySkillName(self:objectName())) do
			if not p:inMyAttackRange(player) then return end
			local ids = sgs.IntList()
					if not use.card:isVirtualCard() then
						ids:append(use.card:getEffectiveId())
					else
						if use.card:subcardsLength() > 0 then
							ids = use.card:getSubcards()
						end
					end
					p:addToPile("&s3_yinpan", ids)
					return
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}




s3_yt_wangling:addSkill(s3_yt_yinpan)




sgs.LoadTranslationTable{
	["s3_yt_wangling"] = "王凌",
	["&s3_yt_wangling"] = "王凌",
	["#s3_yt_wangling"] = "",
	["designer:s3_yt_wangling"] = "怎么了你听得到",
	
	["&s3_yinpan"] = "引叛",
	["s3_yt_yinpan"] = "引叛",
	[":s3_yt_yinpan"] = "<font color=\"blue\"><b>锁定技，</b></font>你攻击范围内一名角色在出牌阶段使用的第一张牌结算后，若此牌不为装备牌或延时类锦囊牌，你将此牌置于你的武将牌上；你可将武将牌上的牌如手牌般使用或打出，你的一个回合结束时，若你武将牌上有牌，你弃置武将牌上所有牌并失去一点体力。",

}
s3_yt_maolie = sgs.General(extension_bf,"s3_yt_maojie","wei","3")

s3_yt_huamouCard = sgs.CreateSkillCard{
	name = "s3_yt_huamou",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local pattern = sgs.Self:property("s3_yt_huamou"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
		card:setSkillName(self:objectName())
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) 
			and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets)
		local pattern = sgs.Self:property("s3_yt_huamou"):toString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
		card:setSkillName(self:objectName())
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 then
			return false
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,	
	on_validate = function(self, card_use)
		local xunyou = card_use.from
		local room = xunyou:getRoom()
		for _,c in sgs.qlist(self:getSubcards()) do
		room:setCardFlag(c, self:objectName())
			end
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		use_card:setSkillName(self:objectName())
		local available = true
		for _,p in sgs.qlist(card_use.to) do
			if xunyou:isProhibited(p,use_card)	then
				available = false
				break
			end
		end
		available = available and use_card:isAvailable(xunyou)
		if not available then return nil end
		return use_card		
	end,
}
s3_yt_huamouVS = sgs.CreateViewAsSkill{
	name = "s3_yt_huamou",
	n = 2,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local card = s3_yt_huamouCard:clone()
			 local pattern = sgs.Self:property("s3_yt_huamou"):toString()
		local acard = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
			card:setUserString(acard:objectName())	
			card:addSubcard(cards[1])
			card:addSubcard(cards[2])
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@s3_yt_huamou"
	end
}
s3_yt_huamou = sgs.CreateTriggerSkill{
	name = "s3_yt_huamou",
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
	view_as_skill = s3_yt_huamouVS,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	if event == sgs.CardsMoveOneTime then
		local move = data:toMoveOneTime()
		if not room:getTag("FirstRound"):toBool() and not player:hasFlag("using") and player:getPhase() ~= sgs.Player_Draw and move.to and move.to:objectName() == player:objectName() and player:getCardCount() >= 2 and player:hasSkill(self:objectName()) and move.to_place == sgs.Player_PlaceHand and room:askForSkillInvoke(player, self:objectName()) then
			local xztrick = {"snatch", "dismantlement", "collateral", "ex_nihilo", "duel", "amazing_grace", "savage_assault", "archery_attack", "god_salvation"}
					if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
						table.insert(xztrick, "fire_attack")
						table.insert(xztrick, "iron_chain")
					end
					local choice
					local pattern = xztrick
						for _,patt in ipairs(pattern) do
						local poi = sgs.Sanguosha:cloneCard(patt, sgs.Card_NoSuit, 0)
						if not poi:isAvailable(player) then
							table.removeOne(pattern, patt)
						end
					end
					 choice = room:askForChoice(player, self:objectName(), table.concat(pattern, "+"), data)
					if choice then
							room:setPlayerProperty(player, "s3_yt_huamou", sgs.QVariant(choice))
							room:setPlayerFlag(player, "using")
							local prompt = string.format("@s3_yt_huamou:%s:%s",player:objectName(),choice)
							local acard = room:askForUseCard(player, "@@s3_yt_huamou", prompt)
							if acard then
							local dummy = sgs.Sanguosha:cloneCard("slash")
							dummy:addSubcards(acard:getSubcards())
							local put = sgs.IntList()
							for _, c in sgs.qlist(acard:getSubcards()) do 
							put:append(c)
							end
							room:moveCardTo(dummy, player, nil ,sgs.Player_DrawPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "s3_yt_huamou", ""), true)
		room:askForGuanxing(player,put,sgs.Room_GuanxingDownOnly)
							room:handleAcquireDetachSkills(player, "-"..self:objectName())
			room:setPlayerMark(player, self:objectName(), 1)
							end
							room:setPlayerProperty(player, "s3_yt_huamou", sgs.QVariant())
							room:setPlayerFlag(player, "-using")
			end
		end
	elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_NotActive then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getMark(self:objectName()) > 0 then
			room:handleAcquireDetachSkills(p, self:objectName())
			room:setPlayerMark(p, self:objectName(), 0)
			end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
s3_yt_lianzhengCard = sgs.CreateSkillCard{
	name = "s3_yt_lianzheng",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, targets, to_select)
		if (#targets ~= 0) or to_select:objectName() == sgs.Self:objectName() then return false end
		return true
	end,
	on_use = function(self, room, source, targets)
		room:moveCardTo(self, targets[1], sgs.Player_PlaceHand, false)
		if source:canDiscard(source, "he") and  room:askForDiscard(source,self:objectName(),1,1,true,true,"s3_yt_lianzheng-invoke",".")  then
		local choicelist = "s3_yt_huamou"
		if source:isWounded() then
		choicelist = string.format("%s+%s", choicelist, "s3_yt_lianzheng_heal")
		end
		local choice = room:askForChoice(source, "s3_yt_lianzheng", choicelist)
		if choice == "s3_yt_lianzheng_heal" then
		local re = sgs.RecoverStruct()
			re.who = source
			room:recover(source, re, true)
		else
		room:askForUseCard(targets[1], "@@s3_yt_huamou", "@s3_yt_huamou")
		end
		end
	end
}
s3_yt_lianzhengVS = sgs.CreateViewAsSkill{
	name = "s3_yt_lianzheng",
	n = 999,
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() then return false end
		local length = math.floor(sgs.Self:getHandcardNum() / 2)
		return #selected < length
	end,
	view_as = function(self, cards)
		if #cards ~= math.floor(sgs.Self:getHandcardNum() / 2) then return nil end
		local card = s3_yt_lianzhengCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@s3_yt_lianzheng"
	end
}
s3_yt_lianzheng = sgs.CreateTriggerSkill{
	name = "s3_yt_lianzheng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = s3_yt_lianzhengVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then 
			room:askForUseCard(player, "@@s3_yt_lianzheng", "@s3_yt_lianzheng")
		end
	end
}





s3_yt_maolie:addSkill(s3_yt_lianzheng)
s3_yt_maolie:addSkill(s3_yt_huamou)


sgs.LoadTranslationTable{
	["s3_yt_maojie"] = "毛玠",
	["&s3_yt_maojie"] = "毛玠",
	["#s3_yt_maojie"] = "",
	["designer:s3_yt_maojie"] = "怎么了你听得到",
	
	["s3_yt_huamou"] = "划谋",
	[":s3_yt_huamou"] = "每当你于摸牌阶段外获得牌时，你可以将两张牌置于牌堆底，然后你视为使用一张非延时类锦囊牌。若如此做，你失去此技能直到回合结束。",
	
	["s3_yt_lianzheng"] = "廉正",
	[":s3_yt_lianzheng"] = "出牌阶段开始时，你可以将一半的手牌（向下整取）交给一名其他角色。然后你可以弃置一张牌并选择一项：回复一点体力；或令其发动一次“划谋”。",
}



s3_yt_chentai = sgs.General(extension_bf,"s3_yt_chentai","wei","4")


s3_yt_gangjian = sgs.CreateTriggerSkill{
	name = "s3_yt_gangjian" ,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and (player:getPhase() == sgs.Player_Start) then 
		if (not player:isWounded()) or player:getHp() == 1 then return false end
		if room:askForSkillInvoke(player, self:objectName()) then
			room:setPlayerFlag(player, self:objectName())
			if player:getHp() < 1 then
				local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = 1 - player:getHp()
				room:recover(player, recover)
			elseif player:getHp() > 1 then
				player:drawCards(player:getHp() -1, self:objectName() )
				room:loseHp(player, player:getHp() -1 )
			end
			end
		elseif event == sgs.EventPhaseEnd and   player:getPhase() == sgs.Player_Play and player:hasFlag(self:objectName()) then
		local x = player:getMark("damage_point_play_phase")
		if x > 0 then
		local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = x
				room:recover(player, recover)
				end
		end
		return false
	end
}

s3_yt_chentai:addSkill(s3_yt_gangjian)

sgs.LoadTranslationTable{
	["s3_yt_chentai"] = "陈泰",
	["&s3_yt_chentai"] = "陈泰",
	["#s3_yt_chentai"] = "",
	["designer:s3_yt_chentai"] = "怎么了你听得到",
	

	["s3_yt_gangjian"] = "刚简",
	[":s3_yt_gangjian"] = "准备阶段开始时，若你已受伤且体力值不为 1 ，则你可以将体力值调整为 1 ，你以此法每失去 1 点体力你便摸一张牌。若如此做，出牌阶段结束时，你回复 X 点体力。（X为出牌阶段内你造成的伤害数）",
	

}

s3_yt_caoxiu = sgs.General(extension_bf,"s3_yt_caoxiu","wei","4")

s3_yt_qujinCard = sgs.CreateSkillCard{
	name = "s3_yt_qujin",

	filter = function(self, targets, to_select)
		return #targets == 0 and (not to_select:isNude())
	end,

	on_use = function(self, room, source, targets)
		local card = room:askForCardChosen(targets[1], targets[1], "he", self:objectName())
		local cd = sgs.Sanguosha:getCard(card)
				source:addToPile("qujin", cd, true)
				local can_invoke = false
			for _,p in sgs.qlist(source:getPile("qujin")) do
			local c = sgs.Sanguosha:getCard(p)
			if c:isKindOf("Slash") or (c:isKindOf("TrickCard") and c:isBlack()) then
			can_invoke = true
			break
				end
			end
			if can_invoke then
			local dest = sgs.QVariant()
			dest:setValue(source)
			local choice = room:askForChoice(targets[1],"s3_yt_qujin", "s3_yt_qujin_damage+s3_yt_qujin_discard", dest)
			if choice == "s3_yt_qujin_damage" then
				local damage = sgs.DamageStruct()
				damage.from = targets[1]
				damage.to = source
				damage.damage = 1
				room:damage(damage)
			elseif choice == "s3_yt_qujin_discard" then
				for i = 0, source:getPile("qujin"):length()-1, 1 do 
				if not targets[1]:canDiscard(source, "he") then break end
				local id = room:askForCardChosen(targets[1], source, "he", "s3_yt_qujin_caoxiu", false, sgs.Card_MethodDiscard)
										local carda = sgs.Sanguosha:getCard(id)
										room:throwCard(carda, source, targets[1])
				end
				end
				--source:removePileByName("qujin")
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				dummy:deleteLater()
						for _,cd in sgs.qlist(source:getPile("qujin")) do
							dummy:addSubcard(cd)
						end
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil, self:objectName(), "")
						room:throwCard(dummy, reason, nil)
				room:setPlayerFlag(source, "s3_yt_qujin_dis")
			end
	end
}
s3_yt_qujin = sgs.CreateZeroCardViewAsSkill{
	name = "s3_yt_qujin",
	view_as = function(self) 
		return s3_yt_qujinCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:hasFlag("s3_yt_qujin_dis") 
	end, 
}
s3_yt_caoxiu:addSkill(s3_yt_qujin)

sgs.LoadTranslationTable{
	["s3_yt_caoxiu"] = "曹休",
	["&s3_yt_caoxiu"] = "曹休",
	["#s3_yt_caoxiu"] = "",
	["designer:s3_yt_caoxiu"] = "怎么了你听得到",
	
	["qujin"] = "驱",
	["s3_yt_qujin"] = "驱进",
	["s3_yt_qujin_caoxiu"] = "驱进",
	["s3_yt_qujin_damage"] = "对其造成一点伤害",
	["s3_yt_qujin_discard"] = "依次弃置其x张牌",
	[":s3_yt_qujin"] = "出牌阶段，你可指定一名有牌的角色，其须将一张牌置于你的武将牌上，称为“驱”；若此时你的“驱”中有【杀】或黑色锦囊牌时，则该角色选择一项：对你造成一点伤害；或依次弃置你x张牌（x为“驱”的数量）。若如此做，你弃置所有的“驱”且不能发动此技能直到回合结束。",


}


s3_yt_guanning = sgs.General(extension_bf,"s3_yt_guanning","wei","3")



s3_yt_youxue = sgs.CreateTriggerSkill{
	name = "s3_yt_youxue" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardUsed, sgs.CardResponded, sgs.CardFinished} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card
		if  event == sgs.CardUsed or event == sgs.CardResponded  then
			if player:hasSkill(self:objectName()) and event == sgs.CardUsed then
				card = data:toCardUse().card
			elseif player:hasSkill(self:objectName()) and event == sgs.CardResponded then
				local resp = data:toCardResponse()
				if resp.m_isUse then
				card = resp.m_card
				end
			end
		if card and not (card:getTypeId() == sgs.Card_TypeSkill) and player:hasSkill(self:objectName())  then
			local number =  player:getMark("s3_yt_youxueNumber-".. player:getPhase() .."Clear")
			if card:getNumber() < number or number == 0 then
				player:setMark("s3_yt_youxueNumber-".. player:getPhase() .."Clear", card:getNumber())
				number = card:getNumber()
			end
			for _, mark in sgs.list(player:getMarkNames()) do
				if string.find(mark, "s3_yt_youxue") and not string.find(mark, "s3_yt_youxueNumber") and player:getMark(mark) > 0 then
					room:setPlayerMark(player, mark, 0)
				end
			end
			room:setPlayerMark(player, "&s3_yt_youxue+:+" .. tostring(number) .. "-".. player:getPhase() .."Clear", 1)
			
			if card:isBlack() then
				if player:isAlive() and number > 0 and card:getNumber() <= number   then
					room:setPlayerFlag(player , "s3_yt_youxue")
					if event == sgs.CardResponded then
						player:drawCards(1, self:objectName())
						room:setPlayerFlag(player , "-s3_yt_youxue")
					end
				end
			end
		end
		elseif event == sgs.CardFinished then
		local use = data:toCardUse()
			if player:hasFlag("s3_yt_youxue") then 
					player:drawCards(1, self:objectName())
					room:setPlayerFlag(player , "-s3_yt_youxue")
				end
		end
		return false
	end
}

s3_yt_gaojiong = sgs.CreateTriggerSkill{
	name = "s3_yt_gaojiong",
	events = {sgs.Dying},
	limit_mark = "@s3_yt_gaojiong", 
	frequency = sgs.Skill_Limited,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		local _player = dying.who
		if _player:getHp() < 1 then
			local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
			if player:distanceTo(p) == 1 then
				targets:append(p)
			end
		end
		if not targets:isEmpty() and player:getMark("@s3_yt_gaojiong") > 0 and player:askForSkillInvoke(self:objectName(), data) then
		player:loseMark("@s3_yt_gaojiong")
		for _, to in sgs.qlist(targets) do
				local damage = sgs.DamageStruct()
				damage.from = player
				damage.to = to
				damage.damage = 1
				room:damage(damage)
		end
				player:turnOver()
				room:loseHp(player,1)
			end
		end
		return false
	end,
}

s3_yt_guanning:addSkill(s3_yt_youxue)
s3_yt_guanning:addSkill(s3_yt_gaojiong)


sgs.LoadTranslationTable{
	["s3_yt_guanning"] = "管宁",
	["&s3_yt_guanning"] = "管宁",
	["#s3_yt_guanning"] = "",
	["designer:s3_yt_guanning"] = "怎么了你听得到",
	
	["s3_yt_youxue"] = "游学",
	[":s3_yt_youxue"] = "每当你使用一张黑色牌结算后，若此牌为你此阶段使用过的牌中点数最小的牌，你摸一张牌。",
	
	["@s3_yt_gaojiong"] = "高坷",
	["s3_yt_gaojiong"] = "高坷",
	[":s3_yt_gaojiong"] = "<font color=\"red\"><b>限定技，</b></font>当一名角色进入濒死状态时，你可以令距离1以内的所有角色受到1点伤害，然后你将你的武将牌翻面且失去1点体力。",
}


s3_shirou=sgs.General(extension_bf, "s3_shirou", "magic", "3", true)




s3_touying = sgs.CreateTriggerSkill{
	name = "s3_touying",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.TargetConfirmed}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local card = use.card
			local source = use.from
			if use.from:hasSkill(self:objectName()) and  (card:isKindOf("BasicCard") or (card:isKindOf("TrickCard") and card:isNDTrick())) then
				if use.to:length() == 1 and not player:isNude() then
					local card_id = room:askForExchange(player, self:objectName(), 1, 1, true, "QuanjiPush", true):getSubcards():first()
					player:addToPile("s3_jian", card_id)
				end
			end
		end
	end,
}
s3_touying_dis = sgs.CreateDistanceSkill{
	name = "#s3_touying_dis",
	correct_func = function(self, from)
		if from:hasSkill("s3_touying") then
			return - from:getPile("s3_jian"):length()
		else
			return 0
		end
	end,
}


s3_wuxianjianzhi = sgs.CreateTargetModSkill{
	name = "s3_wuxianjianzhi",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return player:getPile("s3_jian"):length()
		else
			return 0
		end
	end,
		extra_target_func = function(self, from, card)
		if from:hasSkill(self:objectName()) then
			return from:getPile("s3_jian"):length()
		end
	end
}

s3_huanxiangbenghuaiCard = sgs.CreateSkillCard{
	name = "s3_huanxiangbenghuai" ,
	will_throw = false ,
	target_fixed = true ,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		 room:throwCard(self, nil);
	end
}
s3_huanxiangbenghuaiVS = sgs.CreateOneCardViewAsSkill{
	name = "s3_huanxiangbenghuai", 
	filter_pattern = ".|.|.|s3_jian",
	expand_pile = "s3_jian",
	view_as = function(self, originalCard) 
		local s3_huanxiangbenghuaiCard = s3_huanxiangbenghuaiCard:clone()
		s3_huanxiangbenghuaiCard:addSubcard(originalCard:getId())
		return s3_huanxiangbenghuaiCard
	end, 
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@s3_huanxiangbenghuai"
	end
}
s3_huanxiangbenghuai = sgs.CreateTriggerSkill{
	name = "s3_huanxiangbenghuai",
	view_as_skill = s3_huanxiangbenghuaiVS,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
			if damage.from:objectName() == player:objectName() and player:getPile("s3_jian"):length() > 0 then
				room:setTag("CurrentDamageStruct", data)
				if player:getRoom():askForUseCard(player, "@@s3_huanxiangbenghuai", "@s3_huanxiangbenghuai") then
				damage.damage = damage.damage + 1
				data:setValue(damage)
				local log= sgs.LogMessage()
	log.type = "#skill_add_damage"
		log.from = damage.from
		log.to:append(damage.to)
		log.arg = self:objectName()
		log.arg2  = damage.damage
		room:sendLog(log)
				end
		room:removeTag("CurrentDamageStruct")
		end
		return false
	end,
}




s3_shirou:addSkill(s3_touying)
s3_shirou:addSkill(s3_touying_dis)
extension_bf:insertRelatedSkills("s3_touying","#s3_touying_dis")
s3_shirou:addSkill(s3_wuxianjianzhi)
s3_shirou:addSkill(s3_huanxiangbenghuai)


sgs.LoadTranslationTable{
	["s3_shirou"]="卫宫士郎",
	["&s3_shirou"] = "卫宫士郎",
	["#s3_shirou"] = "守护者",
	["designer:s3_shirou"] = "祖灬虚源",
	
	["s3_jian"] = "剑",
	["s3_touying"] = "投影术",
	[":s3_touying"] = "每当你使用的基本牌或非延时类锦囊牌指定唯一目标时，你可以将一张牌置于武将牌上，称为“剑”。每有一张“剑”，你计算的与其他角色的距离便-1。",
	
	["s3_wuxianjianzhi"] = "无限剑制",
	[":s3_wuxianjianzhi"] = "<font color=\"blue\"><b>锁定技，</b></font>出牌阶段，你可以额外使用X张【杀】，你使用的【杀】额外指定X个目标（ x为“剑”的数量）。",


	["s3_huanxiangbenghuai"] = "幻想崩坏",
	["@s3_huanxiangbenghuai"] = "你可以发动“幻想崩坏”",
	["~s3_huanxiangbenghuai"] = "选择一张“剑”→点击确定",
	[":s3_huanxiangbenghuai"] = "当你对一名角色造成伤害时，你可以弃置一张“剑”使伤害+1。",

--https://tieba.baidu.com/p/4831691763

}



s3_fans_chengyuanzhi=sgs.General(extension_bf, "s3_fans_chengyuanzhi", "qun", "4", true)


s3_fans_caomin = sgs.CreateProhibitSkill{
	name = "s3_fans_caomin" ,
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("TrickCard") or card:isKindOf("QiceCard")) 
		and (card:isKindOf("Duel") or card:isKindOf("FireAttack") ) and card:getSkillName() ~= "nosguhuo" --特别注意旧蛊惑
	end
}
s3_fans_caomin_tg = sgs.CreateTriggerSkill{
	name = "#s3_fans_caomin", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageCaused},   
	on_trigger = function(self, event, player, data) 
	local room = player:getRoom()
	local damage = data:toDamage()
	if player:objectName() == damage.from:objectName() and player:hasSkill("s3_fans_caomin") then
				room:sendCompulsoryTriggerLog(player,"s3_fans_caomin", true)
				return true
			end

	end
}



s3_fans_jiegan = sgs.CreateTriggerSkill{
	name = "s3_fans_jiegan" ,
	events = {sgs.EventPhaseEnd} ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@s3_fans_jiegan",
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Finish then return false end
		local yuejins = room:findPlayersBySkillName(self:objectName())
        for _,yuejin in sgs.qlist(yuejins) do
            if yuejin:getMark("@s3_fans_jiegan") > 0 then 
            local can_invoke = true
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if yuejin:getHp() > p:getHp() then
                    can_invoke = false
                    break
                end
            end
            if can_invoke and room:askForSkillInvoke(yuejin, self:objectName()) then
            yuejin:loseMark("@s3_fans_jiegan")
            yuejin:addMark("s3_fans_jiegan",1)
            if yuejin:isWounded() then
            local recover = sgs.RecoverStruct()
        recover.recover = 4 - yuejin:getHp()
        recover.who = yuejin
        room:recover(yuejin,recover)
            end
            room:handleAcquireDetachSkills(yuejin, "-s3_fans_caomin")
            room:handleAcquireDetachSkills(yuejin, "-#s3_fans_caomin")
            local p = player
        while yuejin:objectName() ~= p:getNextAlive():objectName() do
                        p = p:getNextAlive()
                        room:setPlayerFlag(p, "s3_fans_jiegan")
                end
                end
            end
        end
		return false
	end
}
s3_fans_jiegan_t = sgs.CreateTriggerSkill{
	name = "#s3_fans_jiegan_t",
	events = {sgs.TurnStart},
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		if not player:hasSkill(self:objectName()) then
			local room = player:getRoom()
			if player:hasFlag("s3_fans_jiegan")  then
			if player:faceUp() then
					player:turnOver()
					room:setPlayerFlag(player, "-s3_fans_jiegan")
					for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("s3_fans_jiegan_turned") then
				room:setPlayerFlag(player, "-s3_fans_jiegan_turned")
				p:turnOver()
			end
		end
			elseif not player:faceUp() then
				room:setPlayerFlag(player, "-s3_fans_jiegan")
				room:setPlayerFlag(player, "s3_fans_jiegan_turned")
					end
				
			end
		end
	end
}
s3_fans_yizhou = sgs.CreateTriggerSkill{
	name = "s3_fans_yizhou",
	events = {sgs.Death} ,
	frequency = sgs.Skill_Compulsory ,
	can_trigger = function(self, target)
		return target ~= nil and target:hasSkill(self:objectName())
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		local killer
		if death.damage then
			killer = death.damage.from
		else
			killer = nil
		end
		if killer and killer:objectName() ~= player:objectName() then
			if player:getMark("s3_fans_jiegan") > 0 then
			room:notifySkillInvoked(player, self:objectName())
			local recover = sgs.RecoverStruct()
	recover.recover = 1
	recover.who = killer
	room:recover(killer,recover)
	killer:drawCards(1, self:objectName())
			end
		end
		return false
	end
}

s3_fans_chengyuanzhi:addSkill(s3_fans_caomin)
s3_fans_chengyuanzhi:addSkill(s3_fans_caomin_tg)
s3_fans_chengyuanzhi:addSkill(s3_fans_jiegan)
s3_fans_chengyuanzhi:addSkill(s3_fans_jiegan_t)
s3_fans_chengyuanzhi:addSkill(s3_fans_yizhou)
extension_bf:insertRelatedSkills("s3_fans_caomin","#s3_fans_caomin")
extension_bf:insertRelatedSkills("s3_fans_jiegan","#s3_fans_jiegan_t")


sgs.LoadTranslationTable{
	["s3_fans_chengyuanzhi"]="程远志",
	["&s3_fans_chengyuanzhi"] = "程远志",
	["#s3_fans_chengyuanzhi"] = "官逼民反",
	["designer:s3_fans_chengyuanzhi"] = "沂琳",
	
	["s3_fans_caomin"] = "草民",
	[":s3_fans_caomin"] = "<font color=\"blue\"><b>锁定技，</b></font>始终防止一切由你造成的伤害；你始终不能成为【决斗】、【火攻】的目标。",
	
	["s3_fans_jiegan"] = "揭竿",
	["@s3_fans_jiegan"] = "揭竿",
	[":s3_fans_jiegan"] = "<font color=\"red\"><b>限定技，</b></font>任意角色回合结束时，若你的体力值为全场最少（或之一），你可将体力回复至4，失去技能“草民”，改为由你开始当前回合。",
	
	["s3_fans_yizhou"] = "遗胄",
	[":s3_fans_yizhou"] = "<font color=\"blue\"><b>锁定技，</b></font>你发动“揭竿”后，杀死你的角色须回复一点体力，并摸一张牌。",
--https://tieba.baidu.com/p/2366306977#33520013794l

}
s3_fans_zhangliao=sgs.General(extension_bf, "s3_fans_zhangliao", "qun", "4", true)

s3_fans_pianji = sgs.CreateTriggerSkill {
	name = "s3_fans_pianji",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		local dest = effect.to
		local source = effect.from
		if effect.card and effect.card:isKindOf("Slash") and source:hasSkill(self:objectName()) then
			room:notifySkillInvoked(source, self:objectName())
			effect.to:setFlags("Global_NonSkillNullify")
			local firstjink, secondjink = nil, nil
			
			local prompt = string.format("@s3_fans_pianji:%s:%s", source:getGeneralName(),dest:getGeneralName())
			local card = room:askForCard(dest, "TrickCard,Slash|.|.", prompt, data, sgs.Card_MethodResponse, effect.from)--discard trickcard
			room:sendCompulsoryTriggerLog(source, self:objectName(), true)
			if card then
				firstjink = card
				if card:isKindOf("Slash") then
					room:addPlayerMark(dest, "s3_fans_pianjiCard"..effect.card:getEffectiveId().."-Clear")
					local card2 = room:askForCard(dest, "Slash|.|.", prompt, data, sgs.Card_MethodResponse, effect.from)
					if card2 then
						secondjink = card2
					end
				end
			end
			local jink = nil
			if (firstjink) then
				jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
				jink:addSubcard(firstjink)
				if secondjink then
					jink:addSubcard(secondjink)
				end
				jink:deleteLater()
				effect.offset_card = jink
				data:setValue(effect)
				if not room:getThread():trigger(sgs.CardOffset,room,effect.from,data) then
					return true
				end
			else
				effect.offset_card = nil
				data:setValue(effect)
				room:getThread():trigger(sgs.CardOnEffect,room,effect.to,data)
				room:damage(sgs.DamageStruct(effect.card, effect.from, effect.to, 1, getCardDamageNature(effect.from, effect.to, effect.card)))
				return true
			end		
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

s3_fans_zhangliao:addSkill(s3_fans_pianji)
s3_fans_zhangliao:addSkill("jinjiu")


sgs.LoadTranslationTable{
	["s3_fans_zhangliao"]="张辽",
	["&s3_fans_zhangliao"] = "张辽",
	["#s3_fans_zhangliao"] = "鬼神之侍",
	["designer:s3_fans_zhangliao"] = "沂琳",
	
	["s3_fans_pianji"] = "偏戟",
	[":s3_fans_pianji"] = "<font color=\"blue\"><b>锁定技，</b></font>你使用【杀】指定一名角色为目标后，该角色不能使用【闪】抵消此【杀】；该角色须连续打出两张【杀】或打出一张锦囊牌才可抵消此【杀】。",
	
}

s3_fans_jiangwei =sgs.General(extension_bf, "s3_fans_jiangwei", "wei", "4", true)

s3_fans_jiongyan = sgs.CreateTriggerSkill{
	name = "s3_fans_jiongyan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardOffset, sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageInflicted then 
		local damage = data:toDamage()
		if damage.from:isAlive() and player:hasSkill(self:objectName()) then
			if player:canSlash(damage.from, nil, false) then
				local prompt = string.format("s3_fans_jiongyan-slash:%s", damage.from:objectName())
				room:askForUseSlashTo(player, damage.from, prompt, false, false, false, nil, nil, "s3_fans_jiongyan-slash")
				end
			end
		elseif event == sgs.CardOffset then 
		local effect = data:toCardEffect()
		if (player:objectName() ~= effect.from:objectName()) or (not effect.card:hasFlag("s3_fans_jiongyan-slash")) then return false end

			if effect.from:canDiscard(effect.to, "he") and  player:askForSkillInvoke(self:objectName(), data) then
			local card_id = room:askForCardChosen(player, effect.to, "he", self:objectName())
					room:throwCard(card_id, effect.to, player)
			end
end			
	end,
	priority = -1
}
s3_fans_guzhi = sgs.CreateTriggerSkill{
	name = "s3_fans_guzhi", 
	frequency = sgs.Skill_Wake, 
	events = {sgs.EventPhaseStart}, 
	waked_skills = "tiaoxin",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:changeMaxHpForAwakenSkill(player, -1) then
		room:addPlayerMark(player, self:objectName())
		if player:isWounded() then
		if room:askForChoice(player, self:objectName(), "s3_fans_guzhirecover+s3_fans_guzhidraw") == "s3_fans_guzhirecover" then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
			else
				room:drawCards(player, 2, self:objectName())
			end
		else
			room:drawCards(player, 2, self:objectName())
		end
			room:handleAcquireDetachSkills(player, "tiaoxin")
		end
	end, 
	can_trigger = function(self, target)
		if target then
			if target:getPhase() == sgs.Player_Start then
				if target:isAlive() and target:hasSkill(self:objectName()) then
					return target:getMark("s3_fans_guzhi") == 0  and (target:getHp() == 1 or target:canWake(self:objectName()))
				end
			end
		end
		return false
	end
}

s3_fans_jiangwei:addSkill(s3_fans_jiongyan)
s3_fans_jiangwei:addSkill(s3_fans_guzhi)

sgs.LoadTranslationTable{
	["s3_fans_jiangwei"]="姜维",
	["&s3_fans_jiangwei"] = "姜维",
	["#s3_fans_jiangwei"] = "天水麒麟儿",
	["designer:s3_fans_jiangwei"] = "沂琳",
	
	["s3_fans_guzhi"] = "孤掷",
	[":s3_fans_guzhi"] = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段开始时，若你体力为1，你须减一点体力上限，并选择：1.回复一点体力；2.摸两张牌。然后你获得技能“挑衅”。",
	
	
	["s3_fans_jiongyan-slash"] = "<b>炯眼</b><br/>你可立即对 %src 使用一张【杀】",
	["s3_fans_jiongyan"] = "炯眼",
	[":s3_fans_jiongyan"] = "当你受到【杀】造成的伤害时，你可立即对伤害来源使用一张【杀】：若以此法使用的【杀】被【闪】抵消，你可弃置该角色的一张牌。",
	["s3_fans_guzhirecover"] = "回复一点体力",
	["s3_fans_guzhidraw"] = "摸两张牌",
}

s3_fans_taishici =sgs.General(extension_bf, "s3_fans_taishici", "qun", "4", true)

s3_fams_wudao = sgs.CreateTriggerSkill{
	name = "s3_fams_wudao" ,
	events = {sgs.CardEffected},
	frequency = sgs.Skill_Compulsory, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardEffected  then
		local effect = data:toCardEffect()
			if effect.card:isKindOf("Duel") and (effect.from:hasSkill(self:objectName())or effect.to:hasSkill(self:objectName())) then
					local x = 0
					local who
					if effect.from:hasSkill(self:objectName()) then
					who = effect.from
					elseif effect.to:hasSkill(self:objectName()) then
					who = effect.to
					end
					room:sendCompulsoryTriggerLog(who, self:objectName(), true)
					if effect.from:getHandcardNum() > effect.to:getHandcardNum() then
					x = effect.from:getHandcardNum() - effect.to:getHandcardNum()
						room:askForDiscard(effect.from, self:objectName(), x,x, false, false)
					elseif effect.to:getHandcardNum() > effect.from:getHandcardNum() then
					x = effect.to:getHandcardNum() - effect.from:getHandcardNum()
					room:askForDiscard(effect.to, self:objectName(), x,x, false, false)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
s3_fans_handouCard = sgs.CreateSkillCard{
	name = "s3_fans_handou",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodPindian,
	filter = function(self, targets, to_select, player)
		if #targets == 0 then
			if not to_select:isKongcheng() then
				return to_select:objectName() ~= player:objectName() and player:canPindian(to_select)
			end
		end
		return false
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local success = effect.from:pindian(effect.to, "s3_fans_handou")
		if success then
				local slash = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
				slash:setSkillName("s3_fans_handou")
				slash:deleteLater()
				local card_use = sgs.CardUseStruct()
				card_use.card = slash
				card_use.from = effect.from
				card_use.to:append(effect.to)
				room:useCard(card_use, false)
		end
	end
}
s3_fans_handouVS = sgs.CreateZeroCardViewAsSkill{
	name = "s3_fans_handou",
	response_pattern = "@@s3_fans_handou",
	view_as = function(self) 
		return s3_fans_handouCard:clone()
	end, 
}
s3_fans_handou = sgs.CreateTriggerSkill{
	name = "s3_fans_handou",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.Pindian},
	view_as_skill = s3_fans_handouVS,
	on_trigger = function(self, event, player, data)
	if event == sgs.EventPhaseStart then
		if player:getPhase() == sgs.Player_Play then
			local room = player:getRoom()
			local can_invoke = false
			local other_players = room:getOtherPlayers(player)
			for _,p in sgs.qlist(other_players) do
				if not player:isKongcheng() then
					can_invoke = true
					break
				end
			end
			if can_invoke and not player:isKongcheng() then
				room:askForUseCard(player, "@@s3_fans_handou", "@s3_fans_handou-card")
			end
		end
		elseif event == sgs.Pindian then
		local pindian = data:toPindian()
			if pindian.reason == "s3_fans_handou" then
				local target = pindian.to
				if pindian.from:hasSkill(self:objectName()) then
					if pindian.from_card:getNumber() <= pindian.to_card:getNumber() then
							target:obtainCard(pindian.from_card)
							target:obtainCard(pindian.to_card)
					end
				end
			end
		end
		return false
	end
}





s3_fans_taishici:addSkill(s3_fams_wudao)
s3_fans_taishici:addSkill(s3_fans_handou)
sgs.LoadTranslationTable{
	["s3_fans_taishici"]="太史慈",
	["&s3_fans_taishici"] = "太史慈",
	["#s3_fans_taishici"] = "恪遵信义",
	["designer:s3_fans_taishici"] = "沂琳",
	
	["s3_fams_wudao"] = "武道",
	[":s3_fams_wudao"] = "<font color=\"blue\"><b>锁定技，</b></font>你使用（指定目标后）或被使用（被指定为目标）的【决斗】生效前，手牌数较多的一方须将手牌弃至与另一方手牌数相同。",
	
	["@s3_fans_handou-card"] = "你可以发动“武道”",
	["s3_fans_handou"] = "酣斗",
	["~s3_fans_handou"] = "选择一名其他角色→点击确定",
	[":s3_fans_handou"] = "出牌阶段开始时，你可与一名其他角色拼点：若你赢，视为你对该角色使用了一张【决斗】。若你没赢，该角色获得双方拼点的牌。",
	
	
}

s3_fans_zhangbao =sgs.General(extension_bf, "s3_fans_zhangbao", "qun", "3", true)

s3_fans_shanlan = sgs.CreateTriggerSkill{
	name = "s3_fans_shanlan",
	events = {sgs.CardResponded,sgs.CardAsked, sgs.CardUsed},

	on_trigger = function(self, event, player, data)
		
		local room = player:getRoom()
		if event == sgs.CardResponded or event == sgs.CardUsed then
			local card
			if event == sgs.CardResponded then
				card = data:toCardResponse().m_card
			elseif event == sgs.CardUsed then
				card = data:toCardUse().card
			end

			if card:isKindOf("Jink") and player:hasSkill(self:objectName()) then
				local targets = room:getOtherPlayers(player)
				for _,p in sgs.qlist(targets) do
					if p:getMark("@s3_fans_shanlan") >= 2 then
						targets:removeOne(p)
					end
				end
				if targets:isEmpty() then return false end
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "s3_fans_shanlan-invoke", true, true)
				if not target then return false end
				room:addPlayerMark(target, "@s3_fans_shanlan")
			end
		elseif event == sgs.CardAsked then
		local str = data:toStringList()
			if #str == 0 then return end
			if str[1] == "jink" then
				if player:getMark("@s3_fans_shanlan") <= 0 then return false end
				if not room:askForSkillInvoke(player,self:objectName(),data) then return false end
				local jinkcard = sgs.Sanguosha:cloneCard("jink",sgs.Card_NoSuit,0)
				jinkcard:setSkillName("s3_fans_shanlan")
				room:provide(jinkcard)
				player:loseMark("@s3_fans_shanlan", 1 )
				return true
		end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

s3_fans_fengzhang = sgs.CreateDistanceSkill{
	name = "s3_fans_fengzhang",
	correct_func = function(self, from, to)
		if to:hasSkill("s3_fans_fengzhang") then
			local x = 0 
			for _,player in sgs.qlist(to:getSiblings()) do
			if player:getMark("@s3_fans_shanlan") > 0 then
			x = x + 1
			end
			end
			return x
		else
			return 0
		end
	end
}

s3_fans_zhangbao:addSkill(s3_fans_shanlan)
s3_fans_zhangbao:addSkill(s3_fans_fengzhang)


sgs.LoadTranslationTable{
	["s3_fans_zhangbao"]="张宝",
	["&s3_fans_zhangbao"] = "张宝",
	["#s3_fans_zhangbao"] = "地公将军",
	["designer:s3_fans_zhangbao"] = "沂琳",
	
	["s3_fans_shanlan"] = "山岚",
	[":s3_fans_shanlan"] = "每当你使用或打出一张【闪】时，你可将一枚“岚”标记置于一名其他角色的武将牌上。该角色可在需要时弃置一枚“岚”，视为使用或打出一张【闪】。（同一名角色武将牌上最多可同时放置两枚“岚”）。",
	["@s3_fans_shanlan"] = "岚",
	
	["s3_fans_fengzhang"] = "风障",
	[":s3_fans_fengzhang"] = "<font color=\"blue\"><b>锁定技，</b></font>每有一名角色武将牌上放置了“岚”，其他角色计算与你的距离便+1。",
}
s3_fans_zhangliang =sgs.General(extension_bf, "s3_fans_zhangliang", "qun", "3", true)

s3_fans_yanfeng = sgs.CreateTriggerSkill{
	name = "s3_fans_yanfeng",
	events = {sgs.CardResponded,sgs.EventPhaseStart, sgs.CardUsed},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardResponded or event == sgs.CardUsed then
			local card
			if event == sgs.CardResponded then
				card = data:toCardResponse().m_card
			elseif event == sgs.CardUsed then
				card = data:toCardUse().card
			end
		if card:isKindOf("Jink") and player:hasSkill(self:objectName()) and player:canDiscard(player, "he") and room:askForDiscard(player, self:objectName(),1,1,true,true,"s3_fans_yanfeng-invoke",".|black|.|.") then
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "s3_fans_yanfeng-invoke2")
			if not target then return false end
			room:addPlayerMark(target, "@s3_fans_yanfeng")
			room:addPlayerMark(target, "s3_fans_yanfeng"..player:objectName())
		end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Discard and player:getMark("@s3_fans_yanfeng") > 0  then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if player:getMark("s3_fans_yanfeng"..p:objectName()) > 0 then
                    room:sendCompulsoryTriggerLog(p, self:objectName())
                end
            end
			local x =  player:getMark("@s3_fans_yanfeng")
			if x > 2 then 
			 x = 2 
			 end
			if player:getMark("@s3_fans_yanfeng") > 0 then
				room:askForDiscard(player, self:objectName(), x, x, false, true)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
s3_fans_luoshi = sgs.CreateTriggerSkill{
	name = "s3_fans_luoshi",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start	then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if player:getMark("s3_fans_yanfeng"..p:objectName()) > 0 then
                        room:sendCompulsoryTriggerLog(p, self:objectName())
                    end
                end
            
            
				local choicelist = "s3_fans_luoshi_lose+cancel"
				if not  (player:isSkipped(sgs.Player_Judge) or player:isSkipped(sgs.Player_Draw)) then
				choicelist = string.format("%s+%s", choicelist, "s3_fans_luoshi_jd")
				end
				if not  (player:isSkipped(sgs.Player_Judge) or player:isSkipped(sgs.Player_Play)) then
				choicelist = string.format("%s+%s", choicelist, "s3_fans_luoshi_jp")
				end
				local choice = room:askForChoice(player, "s3_fans_luoshi", choicelist)
				if choice ~= "cancel" then
                    if choice == "s3_fans_luoshi_jp" then
                        player:skip(sgs.Player_Judge)
                        player:skip(sgs.Player_Play)
                    elseif choice == "s3_fans_luoshi_jd" then
                        player:skip(sgs.Player_Judge)
                        player:skip(sgs.Player_Draw)
                    else
                        room:loseHp(player)
                    end
                    room:setPlayerMark(player, "@s3_fans_yanfeng", 0)
                        for _, p in sgs.qlist(room:findPlayersBySkillName("s3_fans_yanfeng")) do
                            if player:getMark("s3_fans_yanfeng"..p:objectName()) > 0 then
                                room:setPlayerMark(player, "s3_fans_yanfeng"..p:objectName(), 0)
                            end
                        end
                    end
				end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil and target:getMark("@s3_fans_yanfeng") > 0
	end
}
s3_fans_zhangliang:addSkill(s3_fans_yanfeng)
s3_fans_zhangliang:addSkill(s3_fans_luoshi)
sgs.LoadTranslationTable{
	["s3_fans_zhangliang"]="张梁",
	["&s3_fans_zhangliang"] = "张梁",
	["#s3_fans_zhangliang"] = "人公将军",
	["designer:s3_fans_zhangliang"] = "沂琳",
	
	["s3_fans_yanfeng"] = "岩封",
	["@s3_fans_yanfeng"] = "岩",
	["s3_fans_yanfeng-invoke2"] = "你可以发动“岩封”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["s3_fans_yanfeng-invoke"] = "你可以发动“岩封”<br/> <b>操作提示</b>: 选择一张黑色牌→点击确定<br/>",
	[":s3_fans_yanfeng"] = "每当你使用或打出一张【闪】时，你可弃一张黑色牌，将一枚“岩”标记置于一名其他角色的武将牌上。该角色在其每回合的弃牌阶段，须至少弃置X张牌（X为该角色武将牌上“岩”的数量，且最多为2）。",
	
	["s3_fans_luoshi"] = "落石",
	[":s3_fans_luoshi"] = "其他角色的开始阶段开始时，若其武将牌上放置了“岩”标记，该角色可将其全部弃置，若如此做，该角色须选择一项：1.跳过本回合的判定与摸牌阶段；2.跳过本回合的判定与出牌阶段；3.失去一点体力。",
}


s3_fans_zhanghe =sgs.General(extension_bf, "s3_fans_zhanghe", "qun", "4", true)

s3_fans_jibianCard = sgs.CreateSkillCard{
	name = "s3_fans_jibian",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
	if string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), "1") then 
		if #targets < self:subcardsLength() and #targets < player:getHp() then
			return to_select:hasFlag("s3_fans_jibian")
		end
	else 
		return to_select:hasFlag("s3_fans_jibian") and #targets == 0
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		for _,p in ipairs(targets) do
			room:setPlayerFlag(p, "s3_fans_jibianmove")
		end
		if self:subcardsLength() >= 2 then
		local targets = sgs.SPlayerList()
		for _,a in sgs.qlist(room:getOtherPlayers(source)) do
								if not a:isNude() then
									targets:append(a)
								end
							end
		if not targets:isEmpty() then
		local target = room:askForPlayerChosen(source, targets, self:objectName(), "s3_fans_jibian-invoke", true, true)
			if not target then return false end
				local id = room:askForCardChosen(source, target, "eh", "s3_fans_jibian")
				room:moveCardTo(sgs.Sanguosha:getCard(id), source, sgs.Player_PlaceHand, false)
			end
		end
	end
}
s3_fans_jibianVS = sgs.CreateViewAsSkill{
	name = "s3_fans_jibian",
	n = 999,
	view_filter = function(self, selected, to_select)
	if string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), "1") then 
		return #selected < sgs.Self:getHp()
	else 
		return #selected < (sgs.Self:getHp() - 1) 
		end
	end, 
	view_as = function(self, cards)
		if string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), "1") then 
			if #cards > 0 then
				local jibianCard = s3_fans_jibianCard:clone()
				for _,card in pairs(cards) do
					jibianCard:addSubcard(card)
				end
				jibianCard:setSkillName(self:objectName())
				return jibianCard
			end
		else
			if #cards == sgs.Self:getHp() - 1 then
				local jibianCard = s3_fans_jibianCard:clone()
				for _,card in pairs(cards) do
					jibianCard:addSubcard(card)
				end
				jibianCard:setSkillName(self:objectName())
				return jibianCard
			end
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@s3_fans_jibian")
	end
}
s3_fans_jibian = sgs.CreateTriggerSkill{
	name = "s3_fans_jibian",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardsMoveOneTime},
	view_as_skill = s3_fans_jibianVS,
	on_trigger = function(self, event, player, data)
	if event == sgs.CardUsed then
		local use = data:toCardUse()
		local trick = use.card
		if trick and trick:isKindOf("TrickCard") then
			if use.to:length() >= 2 then
				local room = player:getRoom()
				if trick:subcardsLength() ~= 0 or trick:getEffectiveId() ~= -1 then
					room:moveCardTo(trick, nil, sgs.Player_PlaceTable, true)
				end
				local splayer = room:findPlayerBySkillName(self:objectName())
				if splayer then
					local targetlist = {}
					for _,p in sgs.qlist(use.to) do
						room:setPlayerFlag(p,"s3_fans_jibian")
						table.insert(targetlist, p:objectName())
					end
					local cardname = trick:objectName()
					room:setPlayerFlag(splayer, cardname)
					room:setPlayerProperty(splayer, "s3_fans_jibian_target", sgs.QVariant(table.concat(targetlist, "+")))
					room:setTag("s3_fans_jibian" , data)
					if room:askForUseCard(splayer,"@@s3_fans_jibian1","@s3_fans_jibian:"..splayer:getHp()) then
						local newtargets = sgs.SPlayerList()
						for _,p in sgs.qlist(use.to) do
							room:setPlayerFlag(p, "-s3_fans_jibian")
							if p:hasFlag("s3_fans_jibianmove") then
								room:setPlayerFlag(p, "-s3_fans_jibianmove")
							else
								newtargets:append(p)
							end
						end
						room:setPlayerFlag(splayer, "-" .. cardname)
						use.to = newtargets
						if use.to:isEmpty() then
							return true
						end
						data:setValue(use)
					end
					room:removeTag("s3_fans_jibian")
				end
			end
		end
	elseif event == sgs.CardsMoveOneTime then
		local move = data:toMoveOneTime()
		local places = move.to_place
		local source = move.to
		if source and source:objectName() == player:objectName() then
			if places == sgs.Player_PlaceDelayedTrick then
				local room = player:getRoom()
				for _,splayer in sgs.list(room:findPlayersBySkillName(self:objectName()))do
					if splayer and not splayer:hasFlag("s3_fans_jibian_using") then
						local tos = sgs.SPlayerList()
						for _,id in sgs.qlist(move.card_ids) do
							local list = room:getAlivePlayers()
							local card = sgs.Sanguosha:getCard(id)
							if card:isKindOf("TrickCard") and not card:isNDTrick() then
								local list = room:getAlivePlayers()
								for _,p in sgs.qlist(list) do
									if not player:isProhibited(p, card) and not p:containsTrick(card:objectName()) then
										tos:append(p)
										room:setPlayerFlag(p,"s3_fans_jibian")
									end
								end
							end
						if tos:isEmpty() then return false end
						local target = player2serverplayer(room,source)
						local _data = sgs.QVariant()
						_data:setValue(target)
						room:setTag("s3_fans_jibian" , _data)
						if room:askForUseCard(splayer,"@@s3_fans_jibian2",("@s3_fans_jibian2:%s"):format(splayer:getHp() - 1)) then
							room:setPlayerFlag(splayer, "s3_fans_jibian_using")
							local newtargets = sgs.SPlayerList()
							for _,p in sgs.qlist(room:getAlivePlayers()) do
								room:setPlayerFlag(p, "-s3_fans_jibian")
								if p:hasFlag("s3_fans_jibianmove") then
									room:setPlayerFlag(p, "-s3_fans_jibianmove")
									local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, player:objectName(), self:objectName(), "")
									room:moveCardTo(card, from, p, sgs.Player_PlaceDelayedTrick, reason)
								end
							end
							room:removeTag("s3_fans_jibian")
							room:setPlayerFlag(splayer, "-s3_fans_jibian_using")
						end
					end
				end
			end
		end
		return false
	end
		end
	end,
	can_trigger = function(self, target)
		return true
	end
}

s3_fans_zhanghe:addSkill(s3_fans_jibian)
sgs.LoadTranslationTable{
	["s3_fans_zhanghe"]="张郃",
	["&s3_fans_zhanghe"] = "张郃",
	["#s3_fans_zhanghe"] = "进退两难",
	["designer:s3_fans_zhanghe"] = "沂琳",
	
	["@s3_fans_jibian"] = "你可以发动“机变”，指定至多 %src 名成为目标的角色，并弃置同等数量的牌，令该锦囊跳过对这些角色的结算",
	["@s3_fans_jibian2"] = "你可以发动“机变”，弃置 %src 张牌，将该锦囊移动到另一名角色的判定区",
	["~s3_fans_jibian"] = "选择若干张牌→选择若干个目标→点击确定",
	["~s3_fans_jibian2"] = "选择若干张牌→选择另一名角色→点击确定",
	["s3_fans_jibian"] = "机变",
	["s3_fans_jibian-invoke"] = "你可以发动“机变”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	[":s3_fans_jibian"] = "当一张非延时性锦囊牌同时指定了多个目标时，你可指定至多X名成为目标的角色，并弃置同等数量的牌，令该锦囊跳过对这些角色的结算。当一张延时性锦囊牌进入一名角色的判定区时，你可立即弃置X-1张牌，将该锦囊移动到另一名角色的判定区。每当你以上述方法弃置牌数量不小于2时，你可立即获得一名其他角色的一张牌。（X为你当前体力值）",
	
}

s3_fans_xingcai =sgs.General(extension_bf, "s3_fans_xingcai", "shu", "3", false)


s3_fans_feiyan = sgs.CreateViewAsSkill{
	name = "s3_fans_feiyan",
	n = 1,
		view_filter = function(self, selected, to_select)
		return to_select:isKindOf("EquipCard")
	end, 
	view_as = function(self, cards)
	if #cards == 1 then 
		local card =s3_fans_feiyancard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) 
	end,
}

s3_fans_feiyancard = sgs.CreateSkillCard{
	name = "s3_fans_feiyan",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select) --必须
	local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
	card:setSkillName(self:objectName())
	local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
		if to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:canSlash(to_select, card,false) then
			return card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
		end
	end,
	on_use = function(self, room, source, targets) 
		if #targets > 0 then
			local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			card:setSkillName(self:objectName())
			local use = sgs.CardUseStruct()
			use.from = source
			for _,target in ipairs(targets) do
				use.to:append(target)
			end
			use.card = card
			room:useCard(use, false)
		end
	end,
}
s3_fans_qingyu = sgs.CreateTriggerSkill{
	name = "s3_fans_qingyu" ,
	events = {sgs.DamageInflicted} ,
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if player:getEquips():length() > 0 then  return false end 
		if player:askForSkillInvoke(self:objectName(), data) then 
			local judge = sgs.JudgeStruct()
				judge.pattern = ".|red"
				judge.good = true
				judge.reason = self:objectName()
				judge.who = player
				player:getRoom():judge(judge)
				if judge:isGood() then 
				 local log= sgs.LogMessage()
					log.type = "#s_nixing"
					log.from = player
					log.arg = self:objectName()
					log.arg2  = damage.damage
					room:sendLog(log)
				return true 
		end
		end
	end
}

s3_fans_yihun = sgs.CreateTriggerSkill{
	name = "s3_fans_yihun", 
	frequency = sgs.Skill_Wake, 
	events = {sgs.EventPhaseStart}, 
	waked_skills = "s3_fans_caihua",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
			room:setPlayerMark(player, "s3_fans_yihun", 1)
			if room:changeMaxHpForAwakenSkill(player , 1) then
			room:handleAcquireDetachSkills(player, "-s3_fans_qingyu")
			room:handleAcquireDetachSkills(player, "s3_fans_caihua")
			end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:getPhase() == sgs.Player_Start then
				if target:isAlive() and target:hasSkill(self:objectName()) then
					return target:getMark("s3_fans_yihun") == 0 and (target:getEquips():length() >= 4 or target:canWake(self:objectName()))
				end
			end
		end
		return false
	end
}
s3_fans_caihua = sgs.CreateTriggerSkill{
	name = "s3_fans_caihua" ,
	events = {sgs.ConfirmDamage} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local hua = room:findPlayerBySkillName(self:objectName())
		if not hua then return false end
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			local reason = damage.card
			if (not reason) or (damage.from:objectName() ~= hua:objectName()) then return false end
			if reason:isKindOf("Slash") and reason:getSuitString() == "no_suit" then
				damage.damage = damage.damage + 1
				data:setValue(damage)
				local log= sgs.LogMessage()
	log.type = "#skill_add_damage"
		log.from = damage.from
		log.to:append(damage.to)
		log.arg = self:objectName()
		log.arg2  = damage.damage
		room:sendLog(log)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

s3_fans_xingcai:addSkill(s3_fans_feiyan)
s3_fans_xingcai:addSkill(s3_fans_qingyu)
s3_fans_xingcai:addSkill(s3_fans_yihun)
if not sgs.Sanguosha:getSkill("s3_fans_caihua") then
	s_skillList:append(s3_fans_caihua)
end

sgs.LoadTranslationTable{
	["s3_fans_xingcai"]="星彩",
	["&s3_fans_xingcai"] = "星彩",
	["#s3_fans_xingcai"] = "芳华绚烂",
	["designer:s3_fans_xingcai"] = "沂琳",
	
	["s3_fans_feiyan"] = "飞燕",
	[":s3_fans_feiyan"] = "出牌阶段，你可弃置一张装备牌，视为你对一名其他角色使用了一张【杀】。（此【杀】不计入回合限制）",
	
	["s3_fans_qingyu"] = "轻羽",
	[":s3_fans_qingyu"] = "当你即将受到一次伤害时，若你装备区内没有牌，你可进行一次判定：若结果为红色，防止此伤害。",
	
	["s3_fans_yihun"] = "翼魂",
	[":s3_fans_yihun"] = "<font color=\"purple\"><b>觉醒技，</b></font>准备阶段开始时，若你装备区内有四张牌，你须增加一点体力上限，失去技能“轻羽”并获得技能“彩华”（<font color=\"blue\"><b>锁定技，</b></font>你使用的无色【杀】伤害+1。）",
	
	["s3_fans_caihua"] = "彩华",
	[":s3_fans_caihua"] = "<font color=\"blue\"><b>锁定技，</b></font>你使用的无色【杀】伤害+1。",
}

s3_fans_jiangqin =sgs.General(extension_bf, "s3_fans_jiangqin", "wu", "4", true)


s3_fans_yuejian = sgs.CreateTriggerSkill{
	name = "s3_fans_yuejian",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local move = data:toMoveOneTime()
		local room = player:getRoom()
		if  move.to and move.to:objectName() == player:objectName() then
		if not room:getTag("FirstRound"):toBool()  then
			--local ids = player:getCards("he")
			--if ids:isEmpty() then return false end
			--player:setTag("QingjianCurrentMoveSkill", sgs.QVariant(move.reason.m_skillName))
			--[[while room:askForYiji(player, ids, self:objectName(), false, false, true,  1, room:getOtherPlayers(player), sgs.CardMoveReason(), "@s3_fans_yuejian-distribute") do
			--while room:askForYiji(player, ids, self:objectName(), false, false, true, 1, room:getOtherPlayers(player), sgs.CardMoveReason(), "@s3_fans_yuejian-distribute", true) do
			-- sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), to:objectName(), self:objectName(), ""), "bingzheng-distribute", true)
				if player:isDead() then return false end
			end]]
			end
			elseif move.from and move.from:objectName() == player:objectName() and not player:hasFlag(self:objectName()) and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				if move.to_place == sgs.Player_DiscardPile and (move.from_places:contains(sgs.Player_PlaceHand) or  move.from_places:contains(sgs.Player_PlaceEquip) )then
				local ids = sgs.IntList()
				room:setPlayerFlag(player, self:objectName())
				for _,id in sgs.qlist(move.card_ids) do 
				if room:askForDiscard(player,"s3_fans_yuejian",1,1,true,true, ("@s3_fans_yuejian-discard:%s"):format(sgs.Sanguosha:getCard(id):objectName())) then
						ids:append(id)
					end
					end
						if not  ids:isEmpty() then
					for _, id in sgs.qlist(ids) do
						if move.card_ids:contains(id) then
							move.from_places:removeAt(listIndexOf(move.card_ids, id))
							move.card_ids:removeOne(id)
							data:setValue(move)
						end
						room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_PlaceHand, move.reason, true)
						if not player:isAlive() then break end
					end
			end
			room:setPlayerFlag(player, "-"..self:objectName())
				end
		end
		return false
	end
}
s3_fans_qiangong = sgs.CreateTriggerSkill{
name = "s3_fans_qiangong" ,
events = {sgs.BuryVictim},
priority = 5,
on_trigger = function(self, event, player, data)
local room = player:getRoom()
local death = data:toDeath() 
local source = death.damage.from
if death.damage and death.damage.from then
if source:hasSkill(self:objectName()) then
room:setTag("SkipNormalDeathProcess", sgs.QVariant(true))
local target = room:askForPlayerChosen(source, room:getOtherPlayers(source), self:objectName(), "s3_fans_qiangong-invoke", true, true)
			if not target then return false end
			 if (target:isDead() and (room:getMode() == "06_XMode"
		or room:getMode() == "04_boss"
		or room:getMode() == "08_defense")) then
			return 
		end
	if (room:getMode() == "06_3v3") then
		if (sgs.GetConfig("3v3/OfficialRule", "2013").startsWith("201")) then
			target:drawCards(2, "kill")
		else
			target:drawCards(3, "kill")
			end
	 else 
		if (death.who:getRole() == "rebel" and target ~= death.who) then
			target:drawCards(3, "kill")
		elseif (death.who:getRole() == "loyalist"  and  target:getRole() == "lord") then
			target:throwAllHandCardsAndEquips()
		end
		end
	
end
end
end,
can_trigger = function(self, target)
return target ~= nil 
end
}


s3_fans_jiangqin:addSkill(s3_fans_yuejian)
s3_fans_jiangqin:addSkill("qingjian")
s3_fans_jiangqin:addSkill(s3_fans_qiangong)

--https://tieba.baidu.com/p/2366306977#33520013794l
sgs.LoadTranslationTable{
	["s3_fans_jiangqin"]="蒋钦",
	["&s3_fans_jiangqin"] = "蒋钦",
	["#s3_fans_jiangqin"] = "轻赐尚义",
	["designer:s3_fans_jiangqin"] = "沂琳",
	
	["s3_fans_qiangong-invoke"] = "你可以发动“谦功”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["s3_fans_qiangong"] = "谦功",
	[":s3_fans_qiangong"] = "当一名角色被你杀死，亮明身份时，你可令另一名角色代你执行杀死该角色的奖惩。",
	
	["@s3_fans_yuejian-distribute"] = "<b>约俭</b><br/>你可将你的一张牌交给一名其他角色",
	["@s3_fans_yuejian-discard"] = "<b>约俭</b><br/>你可用你的一张牌替换 %src ",
	["s3_fans_yuejian"] = "约俭",
	[":s3_fans_yuejian"] = "每当你获得一次牌时，你可将你的一张牌交给一名其他角色；每当你的一张牌因弃置而进入弃牌堆时，你可用你的一张牌替换之。",
}


s3_fans_guojia =sgs.General(extension_bf, "s3_fans_guojia", "wei", "3", true)

s3_fans_shangjivs = sgs.CreateOneCardViewAsSkill{
	name = "s3_fans_shangji",
	view_filter = function(self, card)
		return sgs.Self:getMark(self:objectName()..card:getId().."-Clear") == 2
	end, 
   view_as = function(self, card)
	    local pattern = sgs.Self:property("s3_fans_shangji"):toString()
		local acard = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
		acard:setSkillName(self:objectName())
		acard:addSubcard(card)
		return acard
	end,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@s3_fans_shangji"
	end
}

s3_fans_shangji = sgs.CreateTriggerSkill{
	name = "s3_fans_shangji", 
	view_as_skill = s3_fans_shangjivs,
	events = {sgs.EventPhaseStart, sgs.BeforeCardsMove, sgs.CardFinished},  
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	if event == sgs.EventPhaseStart then
		if  player:getPhase() == sgs.Player_Start then 
		if player:askForSkillInvoke(self:objectName()) then
		 local judge=sgs.JudgeStruct()
		judge.pattern="."
		judge.reason=self:objectName()
		judge.who=player
		room:judge(judge)
		end
		end
	elseif event == sgs.BeforeCardsMove then
		local move = data:toMoveOneTime()
		if (move.from == nil) or (move.from:objectName() ~= player:objectName()) then return false end
		if (move.to_place == sgs.Player_DiscardPile)
				and (move.reason.m_reason == sgs.CardMoveReason_S_REASON_JUDGEDONE) and move.from_places:contains(sgs.Player_PlaceJudge) then
			if player:askForSkillInvoke(self:objectName(), data) then
					for _, id in sgs.qlist(move.card_ids) do
							move.from_places:removeAt(listIndexOf(move.card_ids, id))
							move.card_ids:removeOne(id)
							data:setValue(move)
						room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_PlaceHand, move.reason, true)
						if not player:isAlive() then break end
						room:addPlayerMark(player, self:objectName()..id.."-Clear", 2)
					local pattern = {"snatch", "dismantlement", "collateral", "ex_nihilo", "duel", "amazing_grace", "savage_assault", "archery_attack", "god_salvation"}
					if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
						table.insert(pattern, "fire_attack")
						table.insert(pattern, "iron_chain")
					end
					for _,patt in ipairs(pattern) do
						local poi = sgs.Sanguosha:cloneCard(patt, sgs.Card_NoSuit, 0)
						if not poi:isAvailable(player) then
							table.removeOne(pattern, patt)
						end
					end
					local choice = room:askForChoice(player, self:objectName(), table.concat(pattern, "+"), data)
					if choice then
						if  choice == "ex_nihilo" or choice == "amazing_grace" or
						choice == "savage_assault" or choice == "archery_attack" or choice == "god_salvation" then
							local use = sgs.CardUseStruct()
							local card = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, -1)
							card:setSkillName(self:objectName())
							card:addSubcard(sgs.Sanguosha:getCard(id))
							use.card = card
							use.from = player
							room:useCard(use)
						else
							room:setPlayerProperty(player, "s3_fans_shangji", sgs.QVariant(choice))
							room:askForUseCard(player, "@@s3_fans_shangji", "@s3_fans_shangji:"..choice)
							room:setPlayerProperty(player, "s3_fans_shangji", sgs.QVariant())
						end
					end
					
				end
			end
			end
		elseif event == sgs.CardFinished then
		local use = data:toCardUse()
		if use.card and use.card:getSkillName() == self:objectName() then
		room:loseHp(use.from)
		room:sendCompulsoryTriggerLog(use.from, self:objectName(), true)
			end
			end
	end
}
s3_fans_yunceProhibit = sgs.CreateProhibitSkill{
	name = "#s3_fans_yunceProhibit" ,
	is_prohibited = function(self, from, to, card)
		if card:getSkillName() == "s3_fans_yunce" then
			if from:hasSkill("s3_fans_yunce") then
				return not to:hasFlag("s3_fans_yunce_T")
			end
		end
		return false
	end
}
s3_fans_yuncevs = sgs.CreateZeroCardViewAsSkill{
	name = "s3_fans_yunce",
	view_as = function(self)
	    local pattern = sgs.Self:property("s3_fans_yunce"):toString()
		local acard = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@s3_fans_yunce"
	end
}

s3_fans_yunce = sgs.CreateTriggerSkill{
	name = "s3_fans_yunce",
	events = {sgs.Death},
	view_as_skill = s3_fans_yuncevs,
	can_trigger = function(self, target)
	    	return target and target:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.Death then
		local death = data:toDeath()
		if death.who:objectName() == player:objectName()  then
			
			for _,selfplayer in sgs.qlist(room:getOtherPlayers(player)) do
		
				if selfplayer:objectName() ~= player:objectName() then 
	
				local dest = sgs.QVariant()
				dest:setValue(selfplayer)
				if room:askForSkillInvoke(player, self:objectName(), dest) then
					--local xztrick = {"snatch", "dismantlement", "collateral", "ex_nihilo", "duel", "amazing_grace", "savage_assault", "archery_attack", "god_salvation"}
					local xztrick = { "ex_nihilo", "duel", "amazing_grace", "savage_assault", "archery_attack", "god_salvation"}
					if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
						table.insert(xztrick, "iron_chain")
					end
					local pattern = xztrick
						for _,patt in ipairs(pattern) do
						local poi = sgs.Sanguosha:cloneCard(patt, sgs.Card_NoSuit, 0)
						if not poi:isAvailable(player) then
							table.removeOne(pattern, patt)
					end
					end
					room:setPlayerFlag(selfplayer, "s3_fans_yunce_T")
					 local  choice = room:askForChoice(player, self:objectName(), table.concat(pattern, "+"), dest)
					
					if choice then
					--[[ if choice == "ex_nihilo" or choice == "amazing_grace" or
						choice == "savage_assault" or choice == "archery_attack" or choice == "god_salvation" then]]
							local use = sgs.CardUseStruct()
							
							local card = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, 0)
							card:deleteLater()
							card:setSkillName(self:objectName())
							use.card = card
							use.from = player
							use.to:append(selfplayer)
							room:useCard(use)
							
					--[[	else
							
							room:setPlayerProperty(player, "s3_fans_yunce", sgs.QVariant(choice))
							local prompt = string.format("@s3_fans_yunce:%s:%s",selfplayer:objectName(),choice)
							local usecard = room:askForUseCard(player, "@@s3_fans_yunce", prompt) 
							if use then
							end
							room:setPlayerProperty(player, "s3_fans_yunce", sgs.QVariant())
							
						end]]
					end
					 room:setPlayerFlag(selfplayer, "-s3_fans_yunce_T")
				end
				end
			end
			end
		end
	end
}    




s3_fans_guojia:addSkill("tiandu")
s3_fans_guojia:addSkill(s3_fans_shangji)
s3_fans_guojia:addSkill(s3_fans_yunce)
s3_fans_guojia:addSkill(s3_fans_yunceProhibit)
extension_bf:insertRelatedSkills("s3_fans_yunce","#s3_fans_yunceProhibit")
sgs.LoadTranslationTable{
	["s3_fans_guojia"]="郭嘉",
	["&s3_fans_guojia"] = "郭嘉",
	["#s3_fans_guojia"] = "逆天之才",
	["designer:s3_fans_guojia"] = "沂琳",
	
	["s3_fans_shangji"] = "殤計",
	["@s3_fans_shangji"] = "殤計<br/>你可以将之当 %src 使用",
	["~s3_fans_shangji"] =	"选择判定牌→选择角色→点击确定",
	[":s3_fans_shangji"] = "准备阶段开始时，你可以进行判定。当你的判定牌置入弃牌堆时，你可以将之当任意一张非延时锦囊牌使用，该锦囊结算完毕后，你失去一点体力。",
	
	["s3_fans_yunce"] = "殒策",
	[":s3_fans_yunce"] = "你死亡时，你可以视为依次对一名其他角色使用一张非延时锦囊牌。",
	
}

s3_fans_guanyu =sgs.General(extension_bf, "s3_fans_guanyu", "shu", "4", true)

s3_fans_wenjiu = sgs.CreateTriggerSkill{
	name = "s3_fans_wenjiu" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.CardEffected} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.to and effect.to:objectName() == player:objectName() and player:hasSkill(self:objectName()) and  effect.card:isKindOf("Analeptic") and not player:hasFlag("Global_Dying") then
			if  player:getMark("drank") == 0 then --Mask
			room:addPlayerMark(player, "drank")
			 player:setMark("drank", 0)
			end
			room:setPlayerFlag(player, self:objectName())
			return true
			end
		end
		return false
	end ,
}
s3_fans_wenjiu_Clear = sgs.CreateTriggerSkill{
	name = "#s3_fans_wenjiu_Clear" ,
	events = {sgs.ConfirmDamage, sgs.EventPhaseEnd} ,
	frequency = sgs.Skill_Compulsory ,
	priority = 3 ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:hasFlag("s3_fans_wenjiu") then
			room:setPlayerFlag(p, "-s3_fans_wenjiu")
			room:setPlayerMark(p, "drank", 0)
			end
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			local reason = damage.card
			if (not reason) or (damage.from:objectName() ~= player:objectName()) then return false end
			if (reason:isKindOf("Slash") or reason:isKindOf("Duel")) and player:hasFlag("s3_fans_wenjiu") and damage.from:objectName() ~= damage.to:objectName() then
				damage.damage = damage.damage + 1
				data:setValue(damage)
				local log= sgs.LogMessage()
	log.type = "#skill_add_damage"
		log.from = damage.from
		log.to:append(damage.to)
		log.arg = "s3_fans_wenjiu"
		log.arg2  = damage.damage
		room:sendLog(log)
				
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
} 

s3_fans_longxiao = sgs.CreateTriggerSkill{
	name = "s3_fans_longxiao" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.CardEffected, sgs.CardOffset, sgs.DamageCaused, sgs.EventPhaseEnd } ,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	if event == sgs.CardEffected then
			local effect = data:toCardEffect()
			local can_invoke = false
			if effect.card:isKindOf("Duel") then				
				if (effect.from and effect.from:isAlive() and effect.from:hasSkill(self:objectName())) or  (effect.to and effect.to:isAlive() and effect.to:hasSkill(self:objectName())) then
					can_invoke = true
				end
			end
			if not can_invoke then return false end
			if effect.card:isKindOf("Duel") then
			if effect.from:hasSkill(self:objectName()) then
				room:handleAcquireDetachSkills(effect.from, "olwushen")
				room:sendCompulsoryTriggerLog(effect.from, self:objectName(),  true)
				room:filterCards(effect.from,effect.from:getCards("he"),true)
				room:addPlayerMark(effect.from, self:objectName())
				end
				if effect.to:hasSkill(self:objectName()) then
				room:handleAcquireDetachSkills(effect.to, "olwushen")
				room:sendCompulsoryTriggerLog(effect.to, self:objectName(),  true)
				room:filterCards(effect.to,effect.to:getCards("he"),true)
				room:addPlayerMark(effect.to, self:objectName())
				end
			end
		elseif event == sgs.CardOffset then 
			local effect = data:toCardEffect()
			if effect.from and effect.from:hasSkill(self:objectName()) and effect.card:isKindOf("Slash") then
			room:addPlayerMark(effect.from, self:objectName())
			room:handleAcquireDetachSkills(effect.from, "olwushen")
			room:sendCompulsoryTriggerLog(effect.from, self:objectName(),  true)
			room:filterCards(effect.from,effect.from:getCards("he"),true)
				end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.from:getMark(self:objectName())==0 then return false end
			room:setPlayerMark(damage.from, self:objectName(), 0)
			room:handleAcquireDetachSkills(damage.from, "-olwushen")
			room:filterCards(damage.from,damage.from:getCards("he"),true)
		elseif event == sgs.EventPhaseEnd then
			for _,to in sgs.qlist(room:getAlivePlayers()) do
				if to:getMark(self:objectName()) > 0 then
				room:setPlayerMark(to, self:objectName(), 0)
				room:handleAcquireDetachSkills(to, "-olwushen")
				room:filterCards(to,to:getCards("he"),true)
			end
		end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end,
	priority = 1,
}

s3_fans_guanyu:addSkill(s3_fans_wenjiu)
s3_fans_guanyu:addSkill(s3_fans_wenjiu_Clear)
extension_bf:insertRelatedSkills("s3_fans_wenjiu","#s3_fans_wenjiu_Clear")
s3_fans_guanyu:addSkill(s3_fans_longxiao)
s3_fans_guanyu:addRelateSkill("olwushen")

sgs.LoadTranslationTable{
	["s3_fans_guanyu"]="关羽",
	["&s3_fans_guanyu"] = "关羽",
	["#s3_fans_guanyu"] = "威震华夏",
	["designer:s3_fans_guanyu"] = "沂琳",
	
	["s3_fans_wenjiu"] = "溫酒",
	[":s3_fans_wenjiu"] = "<font color=\"blue\"><b>锁定技，</b></font>你于非濒死状态下使用的【酒】，效果改为：你于本阶段使用的所有【杀】或【决斗】对其他角色造成伤害时，该伤害+1。",
	
	["s3_fans_longxiao"] = "龙啸",
	[":s3_fans_longxiao"] = "<font color=\"blue\"><b>锁定技，</b></font>当你使用的【杀】被抵消或你进行【决斗】时，你获得技能“武神”，直到你造成一次伤害或该阶段结束。",
	
}


s3_fans_zumao =sgs.General(extension_bf, "s3_fans_zumao", "wu", "4", true)


s3_fans_yinbing = sgs.CreateTriggerSkill{
	name = "s3_fans_yinbing" ,
	events = {sgs.TargetConfirming, sgs.DamageInflicted} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirming then
		local use = data:toCardUse()
		local zumaos = room:findPlayersBySkillName(self:objectName())
        for _,zumao in sgs.qlist(zumaos) do
            if zumao and zumao:isAlive() and zumao:getPhase() == sgs.Player_NotActive then
            if use.card and use.card:isKindOf("Slash")
                    and use.to:contains(player) and not player:isNude() and zumao:objectName() ~= player:objectName() then
                    local dest = sgs.QVariant()
                    dest:setValue(player)
                    room:setTag("CurrentUseStruct", data)
                    if room:askForSkillInvoke(zumao, self:objectName(), dest) then
                    local card =  room:askForExchange(player, self:objectName(), 1,1,true,string.format("s3_fans_yinbing:%s", zumao:objectName()), true, "EquipCard")
                    
                        if card then
                        local card_id = card:getSubcards():first()
                        room:setCardFlag(use.card, self:objectName())
                        --zumao:obtainCard(card)
                        room:obtainCard(zumao, card, false)
                                use.to:removeOne(player)
                                use.to:append(zumao)
                                room:sortByActionOrder(use.to)
                                data:setValue(use)
                                room:getThread():trigger(sgs.TargetConfirming, room, zumao, data)
                                return false
                        end
                    end
                    room:removeTag("CurrentUseStruct")
                    end
                end
            end
		elseif event == sgs.DamageInflicted then
		local damage = data:toDamage()
		if damage.card and damage.card:hasFlag(self:objectName()) and damage.to:hasSkill(self:objectName()) and damage.to:canDiscard(damage.from, "he") then
		if player:objectName() == damage.to:objectName() then
		local to_throw = room:askForCardChosen(player, damage.from, "he", self:objectName(), false, sgs.Card_MethodDiscard)
				room:throwCard(sgs.Sanguosha:getCard(to_throw), damage.from, player)
		end
		end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end,
}
s3_fans_xianjiaCard = sgs.CreateSkillCard{
	name = "s3_fans_xianjia" ,
	will_throw = false ,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, selected, to_select)
		return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_use = function(self, room, source, targets)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "s3_fans_xianjia", "")
		room:obtainCard(targets[1], self, reason, false)
	end
}
s3_fans_xianjia = sgs.CreateViewAsSkill{
	name = "s3_fans_xianjia" ,
	n = 999 ,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("EquipCard")
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local rende_card = s3_fans_xianjiaCard:clone()
		for _, c in ipairs(cards) do
			rende_card:addSubcard(c)
		end
		return rende_card
	end ,
	enabled_at_play = function(self, player)
		return not player:isNude()
	end
}


s3_fans_zumao:addSkill(s3_fans_yinbing)
s3_fans_zumao:addSkill(s3_fans_xianjia)


sgs.LoadTranslationTable{
	["s3_fans_zumao"]="祖茂",
	["&s3_fans_zumao"] = "祖茂",
	["#s3_fans_zumao"] = "血路的先驱",
	["designer:s3_fans_zumao"] = "沂琳",
	
	["s3_fans_yinbing"] = "引兵",
	[":s3_fans_yinbing"] = "你的回合外，当一名其他角色指定为【杀】的目标时，你可询问该角色是否交给你一张装备牌。若该角色同意并如此做，则该【杀】的目标转移为你，当你因此【杀】受到一次伤害时，你可以弃置伤害来源一张牌。",
	
	["s3_fans_xianjia"] = "献甲",
	[":s3_fans_xianjia"] = "出牌阶段，你可将你任意数量的装备牌按任意方式交给任意名其他角色。 ",
	
}


s3_caohong =sgs.General(extension_bf, "s3_caohong", "wei", "4", true)

s3_xianjuCard = sgs.CreateSkillCard{
	name = "s3_xianju", 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		return  #targets == 0
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		if self:getSubcards():isEmpty() then 
			room:loseHp(effect.from)
		end
		room:handleAcquireDetachSkills(effect.to, "feiying")
		room:handleAcquireDetachSkills(effect.to, "mashu")
		room:addPlayerMark(effect.to, self:objectName(), 1)
	end
}
s3_xianjuVS = sgs.CreateViewAsSkill{
	name = "s3_xianju", 
	n = 2, 
	enabled_at_play = function(self, player)
		return false
	end,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		if #cards == 0 then
			return s3_xianjuCard:clone()
		elseif #cards == 2 then
			local card = s3_xianjuCard:clone()
			card:addSubcard(cards[1])
			card:addSubcard(cards[2])
			return card
		else 
			return nil
		end
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@s3_xianju"
	end
}
s3_xianju = sgs.CreateTriggerSkill{
	name = "s3_xianju",
	view_as_skill = s3_xianjuVS,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase()  == sgs.Player_Start  then
		for _,to in sgs.qlist(room:getAlivePlayers()) do
		if to:getMark(self:objectName()) > 0 then
		room:setPlayerMark(to, self:objectName(), 0)
		room:handleAcquireDetachSkills(to, "-mashu")
		room:handleAcquireDetachSkills(to, "-feiying")
			end
			end
		if room:askForUseCard(player, "@@s3_xianju", "@s3_xianju")then
		end
			end
	end,
}

s3_caohong:addSkill("feiying")
s3_caohong:addSkill(s3_xianju)
s3_caohong:addRelateSkill("mashu")
s3_caohong:addRelateSkill("feiying")

sgs.LoadTranslationTable{
	["s3_caohong"]="曹洪",
	["&s3_caohong"] = "曹洪",
	["#s3_caohong"] = "骠骑将军",
	["designer:s3_caohong"] = "zzm5296776",
		
	["s3_xianju"] = "献驹",
	[":s3_xianju"] = "回合开始阶段开始时，你可以失去1点体力或弃置两张手牌，然后指定一名角色，直到你下回合开始，该角色获得技能“马术”和“飞影”。 ",
	["@s3_xianju"] = "你可以发动“献驹”",
	["~s3_xianju"] = "选择失去1点体力或弃置两张手牌→选择一名角色→点击确定",
--https://tieba.baidu.com/p/1732579192	
}

s3_jxwj_hansui =sgs.General(extension_fg_jxyj, "s3_jxwj_hansui", "qun", "4")


s3_jxwj_fange = sgs.CreateTriggerSkill{
	name = "s3_jxwj_fange",
	events = {sgs.CardOffset, sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardOffset then
		local effect = data:toCardEffect()
		local targets = sgs.SPlayerList()
		if effect.card:hasFlag(self:objectName()) then return false end
		if not effect.card:isKindOf("Slash") then return false end
		if effect.from:hasFlag("s3_jxwj_fange_using") then return false end
		for _,p in sgs.qlist(room:getOtherPlayers(effect.to)) do
			if player:inMyAttackRange(p) and player:canSlash(p, effect.card, true) then
			targets:append(p)
			end
		end
		if not targets:isEmpty() then
				room:setCardFlag(effect.card, self:objectName())
				room:setPlayerFlag(effect.to, self:objectName())
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.card:hasFlag(self:objectName()) then
			local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:inMyAttackRange(p) and player:canSlash(p, use.card, true) then				
			targets:append(p)
			end
		end
		for _,p in sgs.qlist(room:getAlivePlayers()) do
		if p:hasFlag(self:objectName()) then
				room:setPlayerFlag(p, "-"..self:objectName())
				targets:removeOne(p)
			end
			end
		if not targets:isEmpty() then
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "s3_jxwj_fange-invoke", true, true)
			if not target then return false end
				room:setCardFlag(use.card, "-"..self:objectName())
				room:setPlayerFlag(player, "s3_jxwj_fange_using")
				room:useCard(sgs.CardUseStruct(use.card, player, target))
				room:setPlayerFlag(player, "-s3_jxwj_fange_using")
				end
			end
			end
		return false
	end,
}

s3_jxwj_hansui:addSkill("mashu")
s3_jxwj_hansui:addSkill(s3_jxwj_fange)
sgs.LoadTranslationTable{
	["extension_fg_jxyj"] = "将星云集包--火狗工作室",
	["s3_jxwj_hansui"]="韩遂",
	["&s3_jxwj_hansui"] = "韩遂",
	["#s3_jxwj_hansui"] = "虎踞关西",
	["designer:s3_jxwj_hansui"] = "火狗工作室",
	
	["s3_jxwj_fange"] = "反戈",
	[":s3_jxwj_fange"] = "当你使用【杀】被目标角色的【闪】抵消时，你可以将此【杀】对攻击范围内的另一名其他角色使用，每张【杀】限一次。",
	["s3_jxwj_fange-invoke"] = "你可以发动“反戈”<br/> <b>操作提示</b>: 选择攻击范围内的另一名其他角色→点击确定<br/>",
	
}


s3_jxwj_liyu =sgs.General(extension_fg_jxyj, "s3_jxwj_liyu", "qun", "3")
s3_jxwj_zhoudao = sgs.CreateTriggerSkill{
	name = "s3_jxwj_zhoudao" ,
	events = {sgs.Damage} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.Damage then
		local 	target = damage.to
		if not target then return false end
		if damage.card:isKindOf("Slash") then
			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "s3_jxwj_zhoudao-invoke", true, true)
			if not target then return false end
				local x = math.max(1, player:getLostHp())
				room:drawCards(target,x,self:objectName())
		end
		end
	end
}

s3_jxwj_duce = sgs.CreateTriggerSkill{
	name = "s3_jxwj_duce" ,
	events = {sgs.DamageForseen} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local liyu = room:findPlayerBySkillName(self:objectName())
		if liyu and liyu:isAlive() then
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and liyu:inMyAttackRange(damage.to) and damage.to:objectName() == player:objectName() and damage.from and damage.from:objectName() ~= liyu:objectName() then
			if liyu:isKongcheng() then return false end
			local card = room:askForCard(liyu, ".|spade|.|hand",  string.format("@s3_jxwj_duce:%s", damage.from:objectName()), data, sgs.Card_MethodNone) 
			if card then
				damage.from:obtainCard(card)
				room:setTag("CurrentDamageStruct", data)
				local choice = room:askForChoice(liyu, self:objectName(), "s3_jxwj_duce_from+s3_jxwj_duce_lost")
				if choice == "s3_jxwj_duce_from" then
				damage.from = liyu
				data:setValue(damage)
				room:sendCompulsoryTriggerLog(liyu, self:objectName(),true)
				else
					room:loseHp(damage.from,1)
					end
				end
				room:removeTag("CurrentDamageStruct")
			end
		end
	end,
		can_trigger = function(self, target)
		return target
	end
}

s3_jxwj_liyu:addSkill(s3_jxwj_duce)
s3_jxwj_liyu:addSkill(s3_jxwj_zhoudao)

sgs.LoadTranslationTable{
	["s3_jxwj_liyu"]="李儒",
	["&s3_jxwj_liyu"] = "李儒",
	["#s3_jxwj_liyu"] = "魔王的幕僚",
	["designer:s3_jxwj_liyu"] = "火狗工作室--一只蜗牛OP ",
	
	["s3_jxwj_zhoudao"] = "纣道",
	["s3_jxwj_zhoudao-invoke"] = "你可以发动“纣道”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	[":s3_jxwj_zhoudao"] = "你每使用【杀】造成一次伤害，可令一名角色摸X张牌，X为你已损失的体力值且至少为1。 ",
	
	["s3_jxwj_duce"] = "毒策",
	["s3_jxwj_duce_from"] = "你成为此次的伤害来源",
	["s3_jxwj_duce_lost"] = "令伤害来源失去1点体力",
	["@s3_jxwj_duce"] = "你可以交给 %src 一张黑桃手牌来发动“毒策”",
	[":s3_jxwj_duce"] = "每当你攻击范围以内的一名角色受到一次其他角色使用的【杀】造成伤害时，你可以交给伤害来源一张黑桃手牌来选择一项：你成为此次的伤害来源；或令伤害来源失去1点体力。",
--https://tieba.baidu.com/p/1740665383?pid=22164643158&cid=0&red_tag=0349217674#22164643158
}


s3_jxwj_kanze =sgs.General(extension_fg_jxyj, "s3_jxwj_kanze", "wu", "3")

s3_jxwj_weiwanCard = sgs.CreateSkillCard{
	name = "s3_jxwj_weiwan",
	target_fixed = true,
	mute = true,
	on_use = function(self,room,handang,targets)
		local current = room:getCurrent()
		if not current or current:isDead() or current:getPhase() == sgs.Player_NotActive then return end
		local who = room:getCurrentDyingPlayer()
		if not who then return end
		if who:isKongcheng() then
		return end
			handang:turnOver()
			room:obtainCard(handang, who:wholeHandCards())
		if who and who:getHp() > 0 then
					local log = sgs.LogMessage()
					log.type = "#NosJiefanNull1"
					log.from = who
					room:sendLog(log)
				elseif who and who:isDead() then
					local log = sgs.LogMessage()
					log.type = "#NosJiefanNull2"
					log.from = who					
					room:sendLog(log)
				elseif handang:hasFlag("Global_PreventPeach") then
					local log = sgs.LogMessage()
					log.type = "#NosJiefanNull3"
					log.from = current
					log.to:append(handang)
					room:sendLog(log)
				else
					local peach = sgs.Sanguosha:cloneCard("peach",sgs.Card_NoSuit,0)
					peach:setSkillName(self:objectName())
					room:useCard(sgs.CardUseStruct(peach,handang,who))
					end
					
			
	end
}
s3_jxwj_weiwan = sgs.CreateViewAsSkill{
	name = "s3_jxwj_weiwan",
	n = 0,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response = function(self,player,pattern)
		if not string.find(pattern,"peach") then return false end
		if player:faceUp() then
		for _,p in sgs.qlist(player:getAliveSiblings()) do
			if p:getHp() < 1 then
				return p:getHandcardNum() > 0
			end
		end
		end
		return false
	end,
	view_as = function(self,cards)
		return s3_jxwj_weiwanCard:clone()
	end
}

s3_jxwj_miaoyan = sgs.CreateTriggerSkill{
	name = "s3_jxwj_miaoyan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirming, sgs.CardEffected},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card = nil
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			card = use.card
			local source = use.from
			local targets = use.to
			if card and card:isNDTrick() then
				if targets:contains(player) then
					if source:objectName() ~= player:objectName() then
						if not source:isKongcheng() then
							if room:askForSkillInvoke(player, self:objectName(), data) then
								local suit = room:askForSuit(player, self:objectName())
								local card_id = room:askForCardChosen(player, source, "h", self:objectName())
								local card = sgs.Sanguosha:getCard(card_id)
								player:obtainCard(card)
								room:showCard(player, card_id)
								if suit == card:getSuit() then
								player:setTag("s3_jxwj_miaoyan", sgs.QVariant(use.card:toString()))
								end
							end
						end
					end
				end
			end
		elseif event == sgs.CardEffected then
		if (not player:isAlive()) or (not player:hasSkill(self:objectName())) then return false end
			local effect = data:toCardEffect()
			if player:getTag("s3_jxwj_miaoyan") == nil or (player:getTag("s3_jxwj_miaoyan"):toString() ~= effect.card:toString()) then return false end
			player:setTag("s3_jxwj_miaoyan", sgs.QVariant(""))
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			return true
		end
		return false
	end
}



s3_jxwj_kanze:addSkill(s3_jxwj_weiwan)
s3_jxwj_kanze:addSkill(s3_jxwj_miaoyan)

sgs.LoadTranslationTable{
	["s3_jxwj_kanze"]="阚泽",
	["&s3_jxwj_kanze"] = "阚泽",
	["#s3_jxwj_kanze"] = "矫杰谦恭",
	["designer:s3_jxwj_kanze"] = "火狗工作室--福尔摩卡斯 ",

	["s3_jxwj_weiwan"] = "危挽",
	[":s3_jxwj_weiwan"] = "一名有手牌的其他角色向你求【桃】时，若你武将牌正面朝上，你可以获得其全部手牌并将你的武将牌翻面，视为你对其使用的一张【桃】。",

	["s3_jxwj_miaoyan"] = "妙言",
	[":s3_jxwj_miaoyan"] = "每当你被使用（成为目标后）一张非延时类锦囊的目标时，你可以选择一种花色后获得该锦囊的使用者一张手牌并展示之，若此牌与所选花色相同，则该锦囊对你无效。",

	
}

s3_jxwj_lukang =sgs.General(extension_fg_jxyj, "s3_jxwj_lukang", "wu", "3")


s3_jxwj_qiande = sgs.CreateProhibitSkill{
	name = "s3_jxwj_qiande",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill("s3_jxwj_qiande") and (card:isKindOf("TrickCard") and not card:isNDTrick())
	end
}

s3_jxwj_dunwei = sgs.CreateTriggerSkill{
	name = "s3_jxwj_dunwei" ,
	frequency = sgs.Skill_Frequent ,
	global = true,
	events = {sgs.EventPhaseChanging, sgs.EventPhaseStart, sgs.CardsMoveOneTime} ,   
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local can_trigger = true
			if player:getMark("s3_jxwj_dunwei")  > 1 then
				can_trigger = false
			end
			local change = data:toPhaseChange()
			if change.from == sgs.Player_Play and player:isAlive() and player:hasSkill(self:objectName()) then
				local log= sgs.LogMessage()
				log.type = "#s3_jxwj_dunwei_num"
				log.from = player
				log.arg = player:getMark("s3_jxwj_dunwei")
				room:sendLog(log)
				room:setPlayerMark(player, "s3_jxwj_dunwei", 0)
				if can_trigger then
					local choicelist = "cancel+s3_jxwj_dunwei_draw"
					if not player:isSkipped(sgs.Player_Discard)  then
						choicelist = string.format("%s+%s", choicelist, "s3_jxwj_dunwei_keji")
					end
					local choice = room:askForChoice(player, self:objectName(), choicelist)
						if choice == "s3_jxwj_dunwei_draw" then
							room:setPlayerFlag(player, "s3_jxwj_dunwei_draw")
						end
						if choice == "s3_jxwj_dunwei_keji" then
							room:setPlayerFlag(player, "s3_jxwj_dunwei_keji")
						end
				end
			end
			if change.to == sgs.Player_Discard then
				if player:hasFlag("s3_jxwj_dunwei_keji") then
					player:skip(sgs.Player_Discard)
					room:setPlayerFlag(player, "-s3_jxwj_dunwei_keji")
				end
			end
		elseif event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Finish and player:hasFlag("s3_jxwj_dunwei_draw") then
				room:setPlayerFlag(player, "-s3_jxwj_dunwei_draw")
				if player:getHandcardNum() < player:getMaxHp() then
					player:drawCards(player:getMaxHp() - player:getHandcardNum(), self:objectName())
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from and (move.from:objectName() == player:objectName()) and player:getPhase() == sgs.Player_Play and (move.from_places:contains(sgs.Player_PlaceHand) 
			or  move.from_places:contains(sgs.Player_PlaceEquip))) and not (move.to and (move.to:objectName() == player:objectName()
			and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)))  and player:hasSkill(self:objectName())
			then
				room:setPlayerMark(player, "s3_jxwj_dunwei", player:getMark("s3_jxwj_dunwei") + move.card_ids:length())
			end
		end
		return false
	end
}


s3_jxwj_lukang:addSkill(s3_jxwj_dunwei)
s3_jxwj_lukang:addSkill(s3_jxwj_qiande)

sgs.LoadTranslationTable{
	["s3_jxwj_lukang"]="陆抗",
	["&s3_jxwj_lukang"] = "陆抗",
	["#s3_jxwj_lukang"] = "江东的守护神",
	["designer:s3_jxwj_lukang"] = "火狗工作室--竹影 ",

	["s3_jxwj_qiande"] = "谦德",
	[":s3_jxwj_qiande"] = "<font color=\"blue\"><b>锁定技，</b></font>你不能成为延时类锦囊的目标。",
	
	["s3_jxwj_dunwei_draw"] = "回合结束阶段开始时将手牌补至体力上限",
	["#s3_jxwj_dunwei_num"] = "你于出牌阶段，失去的牌数为 %arg 张",
	["s3_jxwj_dunwei_keji"] = "跳过此回合的弃牌阶段",
	["s3_jxwj_dunwei"] = "囤围",
	[":s3_jxwj_dunwei"] = "若你于出牌阶段，失去的牌数不多于一张，你可以执行下列两项中的一项：\
1.跳过此回合的弃牌阶段。\
2.回合结束阶段开始时将手牌补至体力上限。",
}

s3_jxwj_dingfeng =sgs.General(extension_fg_jxyj, "s3_jxwj_dingfeng", "wu", "4")


s3_jxwj_boji = sgs.CreateTriggerSkill{
	name = "s3_jxwj_boji" ,
	events = {sgs.DamageCaused} ,
	frequency = sgs.Skill_NotFrequent ,
	priority = 3 ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			local reason = damage.card
			if (not reason) or not (damage.from:objectName() == player:objectName() or damage.to:objectName() == player:objectName())  then return false end
			if reason:isKindOf("Slash")  and (not damage.chain) and (not damage.transfer) then
				if player:hasSkill(self:objectName()) and  room:askForCard(player,".Equip","@s3_jxwj_boji",data, sgs.Card_MethodDiscard) then
					if damage.from:objectName() == player:objectName() then
						damage.damage = damage.damage + 1
					else 
						damage.damage = damage.damage - 1
						if damage.damage <= 0 then
							return true
						end
					end
					data:setValue(damage)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
s3_jxwj_dingfeng:addSkill(s3_jxwj_boji)
sgs.LoadTranslationTable{
	["s3_jxwj_dingfeng"]="丁奉",
	["&s3_jxwj_dingfeng"] = "丁奉",
	["#s3_jxwj_dingfeng"] = "雪中奋短兵",
	["designer:s3_jxwj_dingfeng"] = "火狗工作室--晓绝对 ",
	
	["@s3_jxwj_boji"] = "你可以发动“搏击”<br/> <b>操作提示</b>: 选择一张装备牌→点击确定<br/>",
	["s3_jxwj_boji"] = "搏击",
	[":s3_jxwj_boji"] = " 当你使用【杀】对目标角色造成伤害/受到其他角色对你使用【杀】造成伤害时，你可以弃置一张装备牌令此伤害+ 1 / -1。",
}

s3_jxwj_wangping =sgs.General(extension_fg_jxyj, "s3_jxwj_wangping", "shu", "4")

s3_jxwj_zhuweiCard = sgs.CreateSkillCard{
	name = "s3_jxwj_zhuweiCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self,room,source,targets)		
	    local cardid = self:getSubcards():first()
	    local card = sgs.Sanguosha:getCard(cardid)
	    if card:getSuit() == sgs.Card_Diamond then
	    	local indulgence = sgs.Sanguosha:cloneCard("indulgence",sgs.Card_Diamond,card:getNumber())
	    	indulgence:addSubcard(card)
	    	indulgence:setSkillName("s3_jxwj_zhuwei")
	    	room:useCard(sgs.CardUseStruct(indulgence,source,source))
			indulgence:deleteLater()
	    elseif card:getSuit() == sgs.Card_Club or card:getSuit() == sgs.Card_Spade then
	    	local supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage",sgs.Card_Club,card:getNumber())
	    	supply_shortage:addSubcard(card)
	    	supply_shortage:setSkillName("s3_jxwj_zhuwei")
	    	room:useCard(sgs.CardUseStruct(supply_shortage,source,source))
			supply_shortage:deleteLater()
	    end 	
	end	    
}
s3_jxwj_zhuweiVS = sgs.CreateViewAsSkill{
	name = "s3_jxwj_zhuwei", 
	n = 1, 
	view_filter = function(self,selected,to_select)
		if #selected >0 then return false end		
		if sgs.Self:containsTrick("indulgence") then 
			return not to_select:isKindOf("TrickCard") and (to_select:getSuit() == sgs.Card_Club or to_select:getSuit() == sgs.Card_Spade)
		elseif sgs.Self:containsTrick("supply_shortage") then
			return not to_select:isKindOf("TrickCard") and to_select:getSuit() == sgs.Card_Diamond 
		else
			return not to_select:isKindOf("TrickCard") and (to_select:getSuit() == sgs.Card_Club or to_select:getSuit() == sgs.Card_Diamond or to_select:getSuit() == sgs.Card_Spade)
		end
		return false	
	end,	
	view_as = function(self, cards) 
		if #cards > 0  then
			local card = s3_jxwj_zhuweiCard:clone()
			for _,cd in pairs(cards) do
				card:addSubcard(cd)
			end
			card:setSkillName(self:objectName())
			return card
		end
		return nil
	end, 
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self,player,pattern)
		local indulgence = sgs.Sanguosha:cloneCard("indulgence",sgs.Card_Diamond,0)
		indulgence:deleteLater()
		local supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage",sgs.Card_Club,0)
		supply_shortage:deleteLater()
		return pattern == "@@s3_jxwj_zhuwei"  and
		not ((player:isProhibited(player,indulgence) or player:containsTrick("indulgence")) and 
			(player:isProhibited(player,supply_shortage) or player:containsTrick("supply_shortage")))
	end	
}
s3_jxwj_zhuwei = sgs.CreateTriggerSkill{
	name = "s3_jxwj_zhuwei" ,
	events = {sgs.EventPhaseChanging,sgs.EventPhaseStart} ,   
	view_as_skill = s3_jxwj_zhuweiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Judge and player:isAlive() and player:hasSkill(self:objectName()) then
				if  player:askForSkillInvoke(self:objectName()) then
					player:skip(sgs.Player_Judge)
					player:skip(sgs.Player_Draw)
					room:setPlayerFlag(player, "s3_jxwj_zhuwei")
				end
			end
		else
			if player:getPhase() == sgs.Player_Finish and player:hasFlag("s3_jxwj_zhuwei") then
				if  player:askForSkillInvoke("s3_jxwj_zhuwei_draw") then
					player:drawCards(player:getJudgingArea():length() + 1, self:objectName())
				end
				local indulgence = sgs.Sanguosha:cloneCard("indulgence",sgs.Card_Diamond,card:getNumber())
	    	indulgence:addSubcard(card)
	    	indulgence:setSkillName("s3_jxwj_zhuwei")
			local supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage",sgs.Card_Club,card:getNumber())
	    	supply_shortage:addSubcard(card)
	    	supply_shortage:setSkillName("s3_jxwj_zhuwei")
				if  not ((player:isProhibited(player,indulgence) or player:containsTrick("indulgence")) and 
			(player:isProhibited(player,supply_shortage) or player:containsTrick("supply_shortage"))) then
				room:askForUseCard(player, "@@s3_jxwj_zhuwei", "@s3_jxwj_zhuwei", -1, sgs.Card_MethodUse)
				end
			end
		end
		return false
	end
}

s3_jxwj_wangping:addSkill(s3_jxwj_zhuwei)

sgs.LoadTranslationTable{
	["s3_jxwj_wangping"]="王平",
	["&s3_jxwj_wangping"] = "王平",
	["#s3_jxwj_wangping"] = "蜀汉的北屏",
	["designer:s3_jxwj_wangping"] = "火狗工作室--太阁大将军紫炎 ",
	
	["@s3_jxwj_zhuwei"] = "你可将一张非锦囊牌置于你的判定区内。",
	["s3_jxwj_zhuwei"] = "駐圍",
	["s3_jxwj_zhuwei_draw"] = "駐圍",
	[":s3_jxwj_zhuwei"] = "你可跳过该回合的判定阶段与摸牌阶段，若如此做，结束阶段开始时，你可摸X+1张牌（X为你判定区内的牌数），并可将一张非锦囊牌按以下规则置于你的判定区内。\
	（<font color=\"red\"><b> ♦ </b></font>【乐不思蜀】\
	<font color=\"black\"><b> ♣ </b></font>或<font color=\"black\"><b> ♠ </b></font>【兵粮寸断】）",
}

s3_jxwj_mizhu =sgs.General(extension_fg_jxyj, "s3_jxwj_mizhu", "shu", "3")

s3_jxwj_zijunCard = sgs.CreateSkillCard{
	name = "s3_jxwj_zijun",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return to_select:objectName() ~= sgs.Self:objectName() and #targets == 0 
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local ids = self:getSubcards()
		local obtain = sgs.Sanguosha:cloneCard("slash")
		for _,id in sgs.qlist(ids) do
					obtain:addSubcard(id)
		end 
		target:obtainCard(obtain, false)
		local recover = sgs.RecoverStruct()
					recover.who = source
					room:recover(source,recover)
	end
}
s3_jxwj_zijunVS = sgs.CreateViewAsSkill{
	name = "s3_jxwj_zijun",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = s3_jxwj_zijunCard:clone()
			for _,cd in pairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@s3_jxwj_zijun" 
		end
}
s3_jxwj_zijun = sgs.CreateTriggerSkill{
	name = "s3_jxwj_zijun" ,
	events = {sgs.EventPhaseStart} ,
	view_as_skill = s3_jxwj_zijunVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Finish then return false end
		if player:getEquips():length() == 0 then return false end
		if room:askForUseCard(player, "@@s3_jxwj_zijun", "@s3_jxwj_zijun") then
		end
		return false
	end
}

s3_jxwj_shangdaoCard = sgs.CreateSkillCard{
	name = "s3_jxwj_shangdao" ,
	will_throw = false ,
	target_fixed = false,
	filter = function(self, targets, to_select) 
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and self:subcardsLength() <= to_select:getHandcardNum()
	end,
	handling_method = sgs.Card_MethodNone ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local move = sgs.CardsMoveStruct(self:getSubcards(), effect.from, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, effect.from:objectName(), self:objectName(), ""))
		local moves = sgs.CardsMoveList()
		moves:append(move)
		room:moveCardsAtomic(moves, true)
		local to_exchange = room:askForExchange(effect.to, "s3_jxwj_shangdao", self:subcardsLength(), self:subcardsLength(), false)
		room:moveCardTo(to_exchange, effect.from, sgs.Player_PlaceHand, false)
		effect.to:obtainCard(self)
	end
}
s3_jxwj_shangdao = sgs.CreateViewAsSkill{
	name = "s3_jxwj_shangdao" ,
	n = 999 ,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end ,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = s3_jxwj_shangdaoCard:clone()
			for _,cd in pairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#s3_jxwj_shangdao")
	end
}


s3_jxwj_mizhu:addSkill(s3_jxwj_zijun)
s3_jxwj_mizhu:addSkill(s3_jxwj_shangdao)
sgs.LoadTranslationTable{
	["s3_jxwj_mizhu"]="糜竺",
	["&s3_jxwj_mizhu"] = "糜竺",
	["#s3_jxwj_mizhu"] = "雍容的富商",
	["designer:s3_jxwj_mizhu"] = "火狗工作室--@Destiny丨EL",
	
	["s3_jxwj_zijun"] = "资军",
	["@s3_jxwj_zijun"] = "你可以将装备区内的一张牌交给一名其他角色",
	[":s3_jxwj_zijun"] = "回合结束阶段开始时，你可以将装备区内的一张牌交给一名其他角色，然后你回复1点体力。",
	
	["s3_jxwj_shangdao"] = "商道",
	[":s3_jxwj_shangdao"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可选择一名其他角色将不多于该角色手牌数的手牌背面向上置于桌面，该角色须将相同数量的手牌交给你，然后你将置于桌面的牌交给该角色。",
	
}

s3_jxwj_zhangsong =sgs.General(extension_fg_jxyj, "s3_jxwj_zhangsong", "shu", "3")


s3_jxwj_xiantu = sgs.CreateTriggerSkill{
	name = "s3_jxwj_xiantu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
		local choicelist = "cancel+s3_jxwj_xiantu_show"
		if player:canDiscard(player, "h") then
			choicelist = string.format("%s+%s", choicelist, "s3_jxwj_xiantu_discard")
		end
		local choice = room:askForChoice(player, self:objectName(), choicelist)
		if choice == "s3_jxwj_xiantu_show" then
			room:showAllCards(player)
			draw.num = draw.num + 1
			data:setValue(draw)
		elseif choice == "s3_jxwj_xiantu_discard" then
			if room:askForDiscard(player, self:objectName(), 1,1, true, false) then
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "s3_jxwj_xiantu-invoke", false, true)
				room:showAllCards(target)
			end
		end
	end
}

s3_jxwj_shunshi = sgs.CreateTriggerSkill{
	name = "s3_jxwj_shunshi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			local kingdom = "shu+qun"
			local choice = room:askForChoice(player, "s3_jxwj_shunshi", kingdom)
			room:setPlayerProperty(player, "kingdom", sgs.QVariant(choice))
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to:hasSkill(self:objectName()) then
				room:sendCompulsoryTriggerLog(damage.to, self:objectName(), true)
				if damage.to:getKingdom() == "shu" then
					room:setPlayerProperty(damage.to, "kingdom", sgs.QVariant("qun"))
				elseif damage.to:getKingdom() == "qun" then
					room:setPlayerProperty(damage.to, "kingdom", sgs.QVariant("shu"))
				else 
				local kingdom = "shu+qun"
				local choice = room:askForChoice(damage.to, "s3_jxwj_shunshi", kingdom)
				room:setPlayerProperty(damage.to, "kingdom", sgs.QVariant(choice))
				end
			end
		end
	end
}

s3_jxwj_qiangji = sgs.CreateTriggerSkill{
	name = "s3_jxwj_qiangji",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.BeforeCardsMove,sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("TrickCard") and use.card:isNDTrick() then
				if use.card:isVirtualCard() and (use.card:subcardsLength() ~= 1) then return false end
				if sgs.Sanguosha:getEngineCard(use.card:getEffectiveId())
						and sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()):isKindOf("TrickCard") and use.card:isNDTrick() then
					room:setCardFlag(use.card:getEffectiveId(), "real_NDTrick")
				end
			end
		elseif player and player:isAlive() and player:hasSkill(self:objectName()) then
			local move = data:toMoveOneTime()
			if (move.card_ids:length() == 1) and move.from_places:contains(sgs.Player_PlaceTable) and (move.to_place == sgs.Player_DiscardPile)
					and (move.reason.m_reason == sgs.CardMoveReason_S_REASON_USE) then
				local card = sgs.Sanguosha:getCard(move.card_ids:first())
				if card:hasFlag("real_NDTrick") and (player:objectName() == move.from:objectName()) and not player:hasFlag(self:objectName()) then
					local suit = card:getSuitString()
					local pattern = string.format(".|%s|.|hand",suit)
					if room:askForCard(player, pattern, "@s3_jxwj_qiangji", data, sgs.Card_MethodDiscard) then
					room:setPlayerFlag(player, self:objectName())
					player:obtainCard(card)
					move.card_ids = sgs.IntList()
					data:setValue(move)
					end
				end
			end
		end
	end,
}
s3_jxwj_zhangsong:addSkill(s3_jxwj_xiantu)
s3_jxwj_zhangsong:addSkill(s3_jxwj_qiangji)
s3_jxwj_zhangsong:addSkill(s3_jxwj_shunshi)

sgs.LoadTranslationTable{
	["s3_jxwj_zhangsong"]="张松",
	["&s3_jxwj_zhangsong"] = "张松",
	["#s3_jxwj_zhangsong"] = "貌少才扬",
	["designer:s3_jxwj_zhangsong"] = "火狗工作室--@天命ぃ哼哼哼",
	
	["s3_jxwj_xiantu"] = "献图",
	[":s3_jxwj_xiantu"] = "摸牌阶段摸牌时，你可以选择一项：展示所有手牌，然后额外摸一张牌；或弃置一张手牌，展示一名其他角色的所有手牌。",
	["s3_jxwj_xiantu_show"] = "展示所有手牌，然后额外摸一张牌",
	["s3_jxwj_xiantu_discard"] = "弃置一张手牌，展示一名其他角色的所有手牌",
	["s3_jxwj_xiantu-invoke"] = "你发动“献图”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	
	["s3_jxwj_shunshi"] = "顺势",
	[":s3_jxwj_shunshi"] = "<font color=\"blue\"><b>锁定技，</b></font>游戏开始时，你需群或蜀中选择一个势力；每当你受到一次伤害后，你须将势力改为你的武将牌上的另一个势力。",
	
	["s3_jxwj_qiangji"] = "强记",
	[":s3_jxwj_qiangji"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>每当你使用的非延时类锦囊时在结算后进入弃牌堆时，你可以用一张与之相同颜色的手牌替换之。",
}
s3_jxwj_chengyu =sgs.General(extension_fg_jxyj, "s3_jxwj_chengyu", "wei", "3")

s3_jxwj_gangli = sgs.CreateTriggerSkill{
	name = "s3_jxwj_gangli",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event ==sgs.Damaged then
			local damage = data:toDamage()
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local choicelist = "s3_jxwj_gangli_throwhp"
				if damage.from:getHandcardNum() > player:getHp() then
					choicelist = string.format("%s+%s", choicelist, "s3_jxwj_gangli_throwtohp")
				end
				local choice = room:askForChoice(player,"s3_jxwj_gangli",choicelist, data)
				if choice == "s3_jxwj_gangli_throwhp" then
					local victim = damage.from
					room:setPlayerFlag(victim, "s3_jxwj_gangli_InTempMoving")
								local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								local card_ids = sgs.IntList()
								local original_places = sgs.IntList()
								local x = player:getHp()
								for i = 0, x -1, 1 do
									if  victim:isNude() then break end
									card_ids:append(room:askForCardChosen(player, victim, "he", self:objectName(), false, sgs.Card_MethodNone))
									original_places:append(room:getCardPlace(card_ids:at(i)))
									dummy:addSubcard(card_ids:at(i))
									victim:addToPile("#s3_jxwj_gangli", card_ids:at(i), false)
								end
								for i = 0, dummy:subcardsLength() - 1, 1 do
									room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i)), victim, original_places:at(i), false)
								end
								room:setPlayerFlag(victim, "-s3_jxwj_gangli_InTempMoving")
								if dummy:subcardsLength() > 0 then
									room:throwCard(dummy, victim, player)
								end
				elseif choice == "s3_jxwj_gangli_throwtohp" then
					local x = damage.from:getHandcardNum() - player:getHp()
					room:askForDiscard(damage.from, self:objectName(), x, x, false, false)
				end
				
			end
		end
	end
}

s3_jxwj_gangli_InTempMoving = sgs.CreateTriggerSkill{
	name = "#s3_jxwj_gangli_InTempMoving",
	events = {sgs.BeforeCardsMove,sgs.CardsMoveOneTime},
	priority = 10,
	on_trigger = function(self, event, player, data)
		if player:hasFlag("s3_jxwj_gangli_InTempMoving") then
			return true
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

s3_jxwj_fujiCard = sgs.CreateSkillCard
{
	name = "s3_jxwj_fuji",
	target_fixed = true, 
	will_throw = false, 
	on_use = function(self, room, player, targets)
		player:addToPile("s3_jxwj_fu", self, false)
	end
}

s3_jxwj_fujiVS = sgs.CreateViewAsSkill
{
	name = "s3_jxwj_fuji", 
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards < 1 then return nil end
		local card = s3_jxwj_fujiCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getPile("s3_jxwj_fu"):length() == 0
	end
}

s3_jxwj_fuji = sgs.CreateTriggerSkill
{
	name = "s3_jxwj_fuji",
	view_as_skill = s3_jxwj_fujiVS,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
		local use = data:toCardUse()
		--if use.from:objectName() == player:objectName() then return false end
		for _,chengyu in sgs.list(room:findPlayersBySkillName(self:objectName()))do	
		if chengyu and chengyu:objectName() ~= use.from:objectName() and chengyu:getPile("s3_jxwj_fu"):length() > 0 then 
		if use.card:isNDTrick() and room:askForSkillInvoke(chengyu, self:objectName(), data) then
				local card = sgs.Sanguosha:getCard(chengyu:getPile("s3_jxwj_fu"):first())
				if card:getSuit() == use.card:getSuit() and card:getNumber() == use.card:getNumber() then
					local recover = sgs.RecoverStruct()
					recover.who = chengyu
					room:recover(chengyu,recover)
					room:drawCards(chengyu,2,self:objectName())
					chengyu:obtainCard(use.card)
				elseif card:getSuit() == use.card:getSuit() then
					chengyu:obtainCard(use.card)
				elseif card:getNumber() == use.card:getNumber() then
					local recover = sgs.RecoverStruct()
					recover.who = chengyu
					room:recover(chengyu,recover)
					chengyu:obtainCard(use.card)
				else
					room:drawCards(chengyu,1,self:objectName())
				end
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				dummy:deleteLater()
				for _,cd in sgs.qlist(chengyu:getPile("s3_jxwj_fu")) do
					dummy:addSubcard(cd)
				end
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil, self:objectName(), "")
				room:throwCard(dummy, reason, nil)
				end
			end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,

}

s3_jxwj_chengyu:addSkill(s3_jxwj_gangli)
s3_jxwj_chengyu:addSkill(s3_jxwj_gangli_InTempMoving)
extension_fg_jxyj:insertRelatedSkills("s3_jxwj_chengyu","#s3_jxwj_gangli_InTempMoving")
s3_jxwj_chengyu:addSkill(s3_jxwj_fuji)
sgs.LoadTranslationTable{
	["s3_jxwj_chengyu"]="程昱",
	["&s3_jxwj_chengyu"] = "程昱",
	["#s3_jxwj_chengyu"] = "泰山捧日",
	["designer:s3_jxwj_chengyu"] = "火狗工作室--一个没百度号的路人",
	
	["s3_jxwj_gangli"] = "刚戾",
	[":s3_jxwj_gangli"] = "你每受到一次伤害时，可弃置伤害来源等同于你当前体力值的牌或令其手牌数弃置与你当前体力值相等。",
	["s3_jxwj_gangli_throwhp"] = "弃置伤害来源等同于你当前体力值的牌",
	["s3_jxwj_gangli_throwtohp"] = "令其手牌数弃置与你当前体力值相等",
	
	["s3_jxwj_fu"] = "伏",
	["s3_jxwj_fuji"] = "伏计",
	[":s3_jxwj_fuji"] = "出牌阶段，若你的武将牌上没有牌，你可以将一张手牌背面朝上至于武将牌上，称为“伏”：每当其他角色使用一张非延时类锦囊时，你可以展示伏并弃置，若花色相同，你获得该锦囊，若点数相同，你回复1点体力并获得该锦囊， 若都相同，你回复1点体力，摸两张牌并获得该锦囊，若都不同，你摸一张牌。",
}

s3_jxwj_caohong =sgs.General(extension_fg_jxyj, "s3_jxwj_caohong", "wei", "4")


s3_jxwj_jiujiaCard = sgs.CreateSkillCard{
	name = "s3_jxwj_jiujia",
	will_throw = false ,
	filter = function(self, targets, to_select)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name)
		end
		return card and card:targetFilter(plist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, plist)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
			end
	end ,
	feasible = function(self, targets)
	if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name)
		end
		return card and card:targetsFeasible(plist, sgs.Self)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
			end
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local choicelist = "s3_jxwj_jiujia_lostHp"
		local tos = sgs.SPlayerList()
		if user:getEquips():length() > 0 then
			local list = room:getAlivePlayers()
			for _,p in sgs.qlist(list) do
				if user:getWeapon() then
					if not p:getWeapon() then
						tos:append(p)
					end
				end
				if user:getArmor() then
					if not p:getArmor() then
						tos:append(p)
					end
				end
				if user:getDefensiveHorse() then
					if not p:getDefensiveHorse() then
						tos:append(p)
					end
				end
				if user:getOffensiveHorse() then
					if not p:getOffensiveHorse() then
						tos:append(p)
					end
				end
			end
		end
		if not tos:isEmpty() then
			choicelist = string.format("%s+%s", choicelist, "s3_jxwj_jiujia_equip")
		end
		local choice = room:askForChoice(user, self:objectName(), choicelist)
		if choice == "s3_jxwj_jiujia_equip" then
			local card_id = room:askForCardChosen(user, user, "e", self:objectName())
			local card = sgs.Sanguosha:getCard(card_id)
			local place = room:getCardPlace(card_id)
			local i = -1
			if place == sgs.Player_PlaceEquip then
				if card:isKindOf("Weapon") then
					i = 1
				end
				if card:isKindOf("Armor") then
					i = 2
				end
				if card:isKindOf("DefensiveHorse") then
					i = 3
				end
				if card:isKindOf("OffensiveHorse") then
					i = 4
				end
			end
			local targets = sgs.SPlayerList()
			local list = room:getAlivePlayers()
			for _,p in sgs.qlist(list) do
				if i == 1 then
					if not p:getWeapon() then
						targets:append(p)
					end
				end
				if i == 2 then
					if not p:getArmor() then
						targets:append(p)
					end
				end
				if i == 3 then
					if not p:getDefensiveHorse() then
						targets:append(p)
					end
				end
				if i == 4 then
					if not p:getOffensiveHorse() then
						targets:append(p)
					end
				end
			end
			if targets:isEmpty() then return false end
			local target = room:askForPlayerChosen(user, targets, self:objectName())
			if target then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, user:objectName(), self:objectName(), "")
				room:moveCardTo(card, user, target, place, reason)
			end
		elseif choice == "s3_jxwj_jiujia_lostHp" then
			room:loseHp(user)
			room:drawCards(user, 1, self:objectName())
		end
		local acard = sgs.Sanguosha:cloneCard("Jink", sgs.Card_NoSuit, 0)
		acard:setSkillName("s3_jxwj_jiujia")
		return acard
	end,
	on_validate = function(self, cardUse)
		cardUse.m_isOwnerUse = false
		local user = cardUse.from
		local room = user:getRoom()
		local choicelist = "s3_jxwj_jiujia_lostHp"
		local tos = sgs.SPlayerList()
		if user:getEquips():length() > 0 then
			local list = room:getAlivePlayers()
			for _,p in sgs.qlist(list) do
				if user:getWeapon() then
					if not p:getWeapon() then
						tos:append(p)
					end
				end
				if user:getArmor() then
					if not p:getArmor() then
						tos:append(p)
					end
				end
				if user:getDefensiveHorse() then
					if not p:getDefensiveHorse() then
						tos:append(p)
					end
				end
				if user:getOffensiveHorse() then
					if not p:getOffensiveHorse() then
						tos:append(p)
					end
				end
			end
		end
		if not tos:isEmpty() then
			choicelist = string.format("%s+%s", choicelist, "s3_jxwj_jiujia_equip")
		end
		local choice = room:askForChoice(user, self:objectName(), choicelist)
		if choice == "s3_jxwj_jiujia_equip" then
			local card_id = room:askForCardChosen(user, user, "e", self:objectName())
			local card = sgs.Sanguosha:getCard(card_id)
			local place = room:getCardPlace(card_id)
			local i = -1
			if place == sgs.Player_PlaceEquip then
				if card:isKindOf("Weapon") then
					i = 1
				end
				if card:isKindOf("Armor") then
					i = 2
				end
				if card:isKindOf("DefensiveHorse") then
					i = 3
				end
				if card:isKindOf("OffensiveHorse") then
					i = 4
				end
			end
			local targets = sgs.SPlayerList()
			local list = room:getAlivePlayers()
			for _,p in sgs.qlist(list) do
				if i == 1 then
					if not p:getWeapon() then
						targets:append(p)
					end
				end
				if i == 2 then
					if not p:getArmor() then
						targets:append(p)
					end
				end
				if i == 3 then
					if not p:getDefensiveHorse() then
						targets:append(p)
					end
				end
				if i == 4 then
					if not p:getOffensiveHorse() then
						targets:append(p)
					end
				end
			end
			if targets:isEmpty() then return false end
			local target = room:askForPlayerChosen(user, targets, self:objectName())
			if target then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, user:objectName(), self:objectName(), "")
				room:moveCardTo(card, user, target, place, reason)
			end
		elseif choice == "s3_jxwj_jiujia_lostHp" then
			room:loseHp(user)
			room:drawCards(user, 1, self:objectName())
		end
		local acard = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, 0)
		acard:setSkillName("s3_jxwj_jiujia")
		return acard
	end
}



s3_jxwj_jiujia = sgs.CreateZeroCardViewAsSkill{
	name = "s3_jxwj_jiujia",

enabled_at_play = function(self, player)
	return false
end,
enabled_at_response = function(self, player, pattern)
	local can_invoke = false
	for _, p in sgs.qlist(player:getSiblings()) do
		if p:objectName()~=player:objectName() and not p:isAllNude() then
			can_invoke = true
			break
		end
	end
	if  pattern == "jink" then
		return can_invoke  and player:getPhase() == sgs.Player_NotActive
	end
	return false
end,
view_as = function(self)
	if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or  sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
		local acard = s3_jxwj_jiujiaCard:clone()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		acard:setUserString(pattern)
		return acard
	end
end
}

s3_jxwj_caohong:addSkill(s3_jxwj_jiujia)
sgs.LoadTranslationTable{
	["s3_jxwj_caohong"]="曹洪",
	["&s3_jxwj_caohong"] = "曹洪",
	["#s3_jxwj_caohong"] = "魏武的守卫",
	["designer:s3_jxwj_caohong"] = "火狗工作室",
	
	["s3_jxwj_jiujia"] = "救驾",
	["s3_jxwj_jiujia_equip"] = "将你装备区里的一张牌移动到另一名角色区域的相应位置",
	["s3_jxwj_jiujia_lostHp"] = "自减一点体力并摸一张",
	[":s3_jxwj_jiujia"] = "你的回合外，你可将你装备区里的一张牌移动到另一名角色区域的相应位置或自减一点体力并摸一张牌来视为你使用或打出一张闪。",
	
}
s3_jxwj_guozhao =sgs.General(extension_fg_jxyj, "s3_jxwj_guozhao", "wei", "3", false)

s3_jxwj_taochong = sgs.CreateTriggerSkill{
	name = "s3_jxwj_taochong" ,
	events = {sgs.CardResponded, sgs.TargetSpecified} ,
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _,guozhao in sgs.list(room:findPlayersBySkillName(self:objectName()))do
			if guozhao:getPhase() == sgs.Player_NotActive then continue end
		if event == sgs.CardResponded then
	        	local resp = data:toCardResponse()
	        	if resp.m_card:isKindOf("BasicCard") and resp.m_who and player:objectName() ~= guozhao:objectName()  then
		            if guozhao:askForSkillInvoke(self:objectName(), data) then
						local judge = sgs.JudgeStruct()
						judge.pattern = ".|heart"
						judge.who = guozhao
						judge.reason = self:objectName()
						judge.good = false
						room:judge(judge)
						if judge:isGood() then
							room:obtainCard(guozhao,resp.m_card,false)
						end	
		            end
	        	end
	        else
	            local use = data:toCardUse()
	            if use.card:isKindOf("BasicCard") and use.from:objectName() ~= guozhao:objectName() then
	                if guozhao:askForSkillInvoke(self:objectName(), data) then
	                	local judge = sgs.JudgeStruct()
						judge.pattern = ".|heart"
						judge.who = guozhao
						judge.reason = self:objectName()
						judge.good = false
						room:judge(judge)
						if judge:isGood() then
							room:obtainCard(guozhao,use.card,false)
						end
	                end
	            end
	        end
		end
	    return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

s3_jxwj_xianci = sgs.CreateTriggerSkill{
	name = "s3_jxwj_xianci",
	events = {sgs.EnterDying, sgs.QuitDying},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EnterDying then
			local dying = data:toDying()
			local target = room:getCurrentDyingPlayer()
			if target and player and player:hasSkill(self:objectName()) then
				local dest = sgs.QVariant()
				dest:setValue(target)
				if room:askForSkillInvoke(player, self:objectName(), dest) then
					room:broadcastSkillInvoke(self:objectName())
					target:drawCards(3, self:objectName())
					room:setPlayerMark(target, self:objectName(), 1)
				end
			end
		elseif event == sgs.QuitDying then
			if player:getMark(self:objectName()) > 0 then
				if player:canDiscard(player, "he") then
				room:askForDiscard(player, self:objectName(),1,1,false,true)
				end
				room:setPlayerMark(player, self:objectName(), 0)
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target
	end
}

s3_jxwj_guozhao:addSkill(s3_jxwj_taochong)
s3_jxwj_guozhao:addSkill(s3_jxwj_xianci)

sgs.LoadTranslationTable{
	["s3_jxwj_guozhao"]="郭照",
	["&s3_jxwj_guozhao"] = "郭照",
	["#s3_jxwj_guozhao"] = "九天飞凰",
	["designer:s3_jxwj_guozhao"] = "火狗工作室",
	
	["s3_jxwj_xianci"] = "献辞",
	[":s3_jxwj_xianci"] = "一名角色进入濒死状态时，你可令其摸三张牌，当该角色脱离濒死状态时，须弃置一张牌。",
	
	["s3_jxwj_taochong"] = "讨宠",
	[":s3_jxwj_taochong"] = "你的回合内，每当其他角色使用或打出一张基本牌时，你可进行一次判定，若不为<font color=\"red\">♥</font>，你获得该牌。",
}
--[[

s3_yuxi = sgs.CreateTreasure{
	name = "s3_yuxi",
	class_name = "Yuxi",
	suit = sgs.Card_Heart,
	number = 13,
	on_install = function(self, player)
		local room = player:getRoom()
		player:drawCards(5)
	end,
	on_uninstall = function(self, player)
			local room = player:getRoom()
			if player:isAlive() then
			room:loseHp(player, 1)
			end
		end,
}
s3_yuxi:clone():setParent(extension_card)

sgs.LoadTranslationTable{
	["scarletbjixin_fakecard"] = "黑玉卡牌包",
	["scarletbcuohuojixin_card"] = "紅玉卡牌包",
	["s3_yuxi"] = "玉玺",
	["Yuxi"] = "玉玺",
	[":s3_yuxi"] = "装备牌·宝物\
	<b>宝物技能</b>：\
	1. 锁定技。当此牌置入装备区时，你摸五张牌；当此牌离开装备区时，你失去1点体力。",
--https://tieba.baidu.com/p/4884121333?see_lz=1#100898640320l
}
]]

sgs.Sanguosha:addSkills(s_skillList)
return {extension, extension_sl,extension_jx, extension_bf, extension_card, extension_fg_jxyj, extension_fakecard}
