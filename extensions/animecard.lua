module("extensions.animecard",package.seeall)--游戏包
extension=sgs.Package("animecard", sgs.Package_CardPack)--增加拓展包
--要关闭的话把true改成false
--青蔷薇之剑
local GreenRoseUse = true
--阐释者
local ElucidatorUse = true
--令咒
local reijyuuUse = true
--战术link
local SenjyutsuRinkUse = false


if GreenRoseUse then
	GreenRose = sgs.CreateWeapon{
		name = "GreenRose",
		class_name = "GreenRose",
		suit = sgs.Card_Spade,
		number = 9,
		range = 2,
		on_install = function(self, player) --装备时获得技能,摸2张牌
			local room = player:getRoom()
			local skill = sgs.Sanguosha:getSkill(self:objectName())
			if skill then
				if skill:inherits("ViewAsSkill") then
					room:attachSkillToPlayer(player, self:objectName())
				elseif skill:inherits("TriggerSkill") then
					local tirggerskill = sgs.Sanguosha:getTriggerSkill(self:objectName())
					room:getThread():addTriggerSkill(tirggerskill)
				end
			end
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp()+1))
			room:setPlayerProperty(player, "hp", sgs.QVariant(player:getHp()+1))
			player:drawCards(2)
			end,
		on_uninstall = function(self, player) --卸下时移除技能
			local room = player:getRoom()
			local skill = sgs.Sanguosha:getSkill(self:objectName())
			if skill and skill:inherits("ViewAsSkill") then
				room:detachSkillFromPlayer(player, self:objectName(), true)
			end
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp()-1))
		end,
	}

	GreenRose_skill = sgs.CreateTriggerSkill{
		name = "GreenRose", --一般的话，技能的objectName()和武器的objectName(）用一样的名字
		frequency = sgs.Skill_Compulsory,
		events = { sgs.TargetConfirmed },
		can_trigger = function(self, target)
			return target and target:hasWeapon(self:objectName())
		end,
		on_trigger = function(self, event, player, data)
			local use = data:toCardUse()
			local card = use.card
			local source = use.from
			local room = player:getRoom()
			if card:isKindOf("Slash") then
				if source:objectName() == player:objectName() then
					for i = 0, use.to:length() - 1 do
						if use.to:at(i):getArmor() then
							room:throwCard(use.to:at(i):getArmor():getEffectiveId(), use.to:at(i), source)
						end
					end
				end
			end
			return false
		end
	}

	GreenRose:setParent(extension)
	local skills = sgs.SkillList()
	if not sgs.Sanguosha:getSkill("GreenRose") then skills:append(GreenRose_skill) end
	sgs.Sanguosha:addSkills(skills)
end





if ElucidatorUse then
	Se_Elucidator = sgs.CreateWeapon{
		name = "Se_Elucidator",
		class_name = "Se_Elucidator",
		suit = sgs.Card_Club,
		number = 6,
		range = 2,
		on_install = function(self, player)
			local room = player:getRoom()
			local skill = sgs.Sanguosha:getSkill(self:objectName())
			if skill then
				if skill:inherits("ViewAsSkill") then
					room:attachSkillToPlayer(player, self:objectName())
				elseif skill:inherits("TriggerSkill") then
					local tirggerskill = sgs.Sanguosha:getTriggerSkill(self:objectName())
					room:getThread():addTriggerSkill(tirggerskill)
				end
			end
		end,
		on_uninstall = function(self, player) --卸下时移除技能
			local room = player:getRoom()
			local skill = sgs.Sanguosha:getSkill(self:objectName())
			if skill and skill:inherits("ViewAsSkill") then
				room:detachSkillFromPlayer(player, self:objectName(), true)
			end
		end,
	}

	Se_Elucidator_skill = sgs.CreateTriggerSkill{
		name = "Se_Elucidator", --一般的话，技能的objectName()和武器的objectName(）用一样的名字
		frequency = sgs.Skill_NotFrequent,
		events = { sgs.CardOffset },
		can_trigger = function(self, target)
			return target and target:hasWeapon(self:objectName())
		end,
		on_trigger = function(self, event, player, data)
			local effect = data:toCardEffect()
			local room = player:getRoom()
			if effect.card and effect.card:isKindOf("Slash") and effect.from:objectName() == player:objectName() and room:getCurrent():objectName() == player:objectName() then
				if effect.to and effect.to:isAlive() then
					local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
					duel:deleteLater()
					if effect.to:isProhibited(player, duel) then return end
					if room:askForSkillInvoke(player, self:objectName(), data) then
						player:drawCards(1)
						duel:setSkillName(self:objectName())
						room:useCard(sgs.CardUseStruct(duel, player, effect.to, false))
					end
				end
			end
			return false
		end
	}

	Se_Elucidator:setParent(extension)
	local skills = sgs.SkillList()
	if not sgs.Sanguosha:getSkill("Se_Elucidator") then skills:append(Se_Elucidator_skill) end
	sgs.Sanguosha:addSkills(skills)
end



if reijyuuUse then
	reijyuu = sgs.CreateTrickCard{
		name = "reijyuu",
		class_name = "reijyuu",
		suit = sgs.Card_Spade,
		number = 8,
		target_fixed = false,
		can_recast = false,
		subtype = "single_target_trick",
		subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
		filter = function(self, targets, to_select, source)
			if source:isProhibited(to_select,self) then return end
			return #targets == 0
		end,
		available = function(self, player)
			return player and player:isAlive() and not player:isCardLimited(self, sgs.Card_MethodUse, true)
		end,
		is_cancelable = function(self, effect)
			return true
		end,
		on_use = function(self, room, source, targets)
			local target1 = targets[1]
			if not target1 then return end
			local target2 = room:askForPlayerChosen(source, room:getOtherPlayers(target1), "reijyuu")
			target2:setFlags("reijyuuT")
			local choice = room:askForChoice(source, self:objectName(), "reijyuuMove+reijyuuDamage")
			if choice == "reijyuuMove" then
				while target2:objectName() ~= target1:getNextAlive():objectName() do
					room:getThread():delay(200)
					room:swapSeat(target1, target1:getNextAlive())
				end
			else
				local damage = sgs.DamageStruct()
				damage.from = target1
				damage.to = target2
				damage.damage = 1
				room:damage(damage)
			end
			target2:setFlags("-reijyuuT")
		end,
	}

	local rj = reijyuu:clone()
	rj:setParent(extension)
end

if SenjyutsuRinkUse then
	SenjyutsuRink = sgs.CreateTrickCard{
		name = "SenjyutsuRink",
		class_name = "SenjyutsuRink",
		suit = sgs.Card_Diamond,
		number = 1,
		target_fixed = false,
		can_recast = false,
		subtype = "single_target_trick",
		subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
		filter = function(self, targets, to_select)
			for i = 1 , 5 do
				if to_select:getMark(string.format("@SenjyutsuGroup"..i)) > 0 then return false end
			end
			return #targets < 2
		end,
		available = function(self, player)
			return player and player:isAlive() and not player:isCardLimited(self, sgs.Card_MethodUse, true)
		end,
		is_cancelable = function(self, effect)
			return true
		end,
		on_use = function(self, room, source, targets)
			room:doLightbox("$senjyutsuRink", 400)
			group = 0
			for i = 1 , 5 do
				have = false
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark(string.format("@SenjyutsuGroup"..i)) > 0 then
						have = true
					end
				end
				if not have then
					group = i
					break 
				end
			end
			targets[1]:gainMark(string.format("@SenjyutsuGroup"..group))
			targets[2]:gainMark(string.format("@SenjyutsuGroup"..group))
		end,
	}

	local sr = SenjyutsuRink:clone()
	sr:setParent(extension)
	local sr2 = SenjyutsuRink:clone(1, 5)
	sr2:setParent(extension)
	local sr3 = SenjyutsuRink:clone(2, 11)
	sr3:setParent(extension)

	SenjyutsuRink_skill = sgs.CreateTriggerSkill{
		name = "SenjyutsuRinkSkill",
		frequency = sgs.Skill_NotFrequent,
		events = { sgs.TargetConfirmed },
		on_trigger = function(self, event, player, data)
			local use = data:toCardUse()
			local card = use.card
			local source = use.from
			local room = player:getRoom()
			if card:isKindOf("Slash") then
				local group = 0
				for i = 1 , 5 do
					if source:getMark(string.format("@SenjyutsuGroup"..i)) > 0 then
						group = i
					end
				end
				if group == 0 then return end
				local linker = source
				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					if p:getMark(string.format("@SenjyutsuGroup"..group)) > 0 and p:objectName() ~= source:objectName() then
						linker = p
					end
				end
				if linker:askForSkillInvoke(self:objectName(), data) then
					local sl = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					sl:setSkillName(self:objectName())
					local s = sgs.CardUseStruct()
					s.from = linker
					s.to = use.to
					s.card = sl
					room:useCard(s, false)
					source:loseMark(string.format("@SenjyutsuGroup"..group))
					linker:loseMark(string.format("@SenjyutsuGroup"..group))
				end
			end
			return false
		end,
		can_trigger = function(self, target)
            return target
        end
	}


	local skills = sgs.SkillList()
	if not sgs.Sanguosha:getSkill("SenjyutsuRinkSkill") then skills:append(SenjyutsuRink_skill) end
	sgs.Sanguosha:addSkills(skills)
end
if SenjyutsuRinkUse then
	SenjyutsuRink = sgs.CreateTrickCard{
		name = "SenjyutsuRink",
		class_name = "SenjyutsuRink",
		suit = sgs.Card_Diamond,
		number = 1,
		target_fixed = false,
		can_recast = false,
		subtype = "single_target_trick",
		subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
		filter = function(self, targets, to_select)
			for i = 1 , 5 do
				if to_select:getMark(string.format("@SenjyutsuGroup"..i)) > 0 then return false end
			end
			return #targets < 2
		end,
		available = function(self, player)
			return player and player:isAlive() and not player:isCardLimited(self, sgs.Card_MethodUse, true)
		end,
		is_cancelable = function(self, effect)
			return true
		end,
		on_use = function(self, room, source, targets)
			room:doLightbox("$senjyutsuRink", 400)
			group = 0
			for i = 1 , 5 do
				have = false
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark(string.format("@SenjyutsuGroup"..i)) > 0 then
						have = true
					end
				end
				if not have then
					group = i
					break 
				end
			end
			targets[1]:gainMark(string.format("@SenjyutsuGroup"..group))
			targets[2]:gainMark(string.format("@SenjyutsuGroup"..group))
		end,
	}

	local sr = SenjyutsuRink:clone()
	sr:setParent(extension)
	local sr2 = SenjyutsuRink:clone(1, 5)
	sr2:setParent(extension)
	local sr3 = SenjyutsuRink:clone(2, 11)
	sr3:setParent(extension)

	SenjyutsuRink_skill = sgs.CreateTriggerSkill{
		name = "SenjyutsuRinkSkill",
		frequency = sgs.Skill_NotFrequent,
		events = { sgs.TargetConfirmed },
		on_trigger = function(self, event, player, data)
			local use = data:toCardUse()
			local card = use.card
			local source = use.from
			local room = player:getRoom()
			if card:isKindOf("Slash") then
				local group = 0
				for i = 1 , 5 do
					if source:getMark(string.format("@SenjyutsuGroup"..i)) > 0 then
						group = i
					end
				end
				if group == 0 then return end
				local linker = source
				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					if p:getMark(string.format("@SenjyutsuGroup"..group)) > 0 and p:objectName() ~= source:objectName() then
						linker = p
					end
				end
				if linker:askForSkillInvoke(self:objectName(), data) then
					local sl = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					sl:setSkillName(self:objectName())
					local s = sgs.CardUseStruct()
					s.from = linker
					s.to = use.to
					s.card = sl
					room:useCard(s, false)
					source:loseMark(string.format("@SenjyutsuGroup"..group))
					linker:loseMark(string.format("@SenjyutsuGroup"..group))
				end
			end
			return false
		end,
		can_trigger = function(self, target)
            return target
        end
	}


	local skills = sgs.SkillList()
	if not sgs.Sanguosha:getSkill("SenjyutsuRinkSkill") then skills:append(SenjyutsuRink_skill) end
	sgs.Sanguosha:addSkills(skills)
end
sgs.LoadTranslationTable{
["animecard"] = "动漫包卡牌",
["GreenRose"] = "青蔷薇之剑",
["$GreenRose"] = "",
[":GreenRose"] = "装备牌·武器\
	攻击范围：2\
	攻击效果：<font color=\"blue\"><b>锁定技,</b></font>装备时你增加一点体力和体力上限，然后摸两张牌；弃置时你失去一点体力上限。当你使用【杀】指定目标时，你弃置该角色装备区的防具。",
["Se_Elucidator"] = "阐释者",
["$Se_Elucidator"] = "",
[":Se_Elucidator"] = "装备牌·武器\
	攻击范围：2\
	攻击效果：回合内，若你使用的【杀】被【闪】所抵消，你可以摸一张牌并视为对目标使用一张【决斗】。",
["reijyuu"] = "令咒",
["$reijyuu"] = "",
["reijyuuMove"] = "A移动至B的上家位置",
["reijyuuDamage"] = "A对B造成一点伤害",
[":reijyuu"] = "锦囊牌\
	出牌时机：出牌阶段\
	使用目标：一名角色A\
	作用效果：你选择一名A以外的角色B，并选择一项：1.A移动至B的上家位置；2.A对B造成一点伤害。该锦囊无法被【无懈可击】响应。",
["SenjyutsuRink"] = "战术Link",
["$SenjyutsuRink"] = "",
[":SenjyutsuRink"] = "锦囊牌\
	出牌时机：出牌阶段\
	使用目标：一至两名没有战术Link的角色A（和B）\
	作用效果：令这A和B进入战术Link。其中一名角色使用杀时，另一名战术Link的角色可以视为对相同目标使用一张【杀】，然后解除战术Link； 或令A角色进入单人Link（其无法再与任何角色Link）。场上最多存在5条link。",
["$senjyutsuRink"] = "anim=skill/senjyutsuRink",

}

tacos = sgs.CreateBasicCard{
	name = "tacos",
	class_name = "tacos",
	target_fixed = true,
	can_recast = false,
	suit = sgs.Card_Heart,
	number = 13,
	subtype = "basic",
	subclass = sgs.LuaTrickCard_TypeBasic,
	available = function(self, player)
		return player:getMark("tacos-Clear") == 0
	end,
	about_to_use = function(self,room,use)
       	if use.to:isEmpty() then use.to:append(use.from) end
		self:cardOnUse(room,use)
	end,
	on_use = function(self, room, source, targets)
		local use = room:getTag("UseHistory"..self:toString()):toCardUse()
		for _,to in sgs.list(targets)do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = #targets>1
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
			room:cardEffect(effect)
		end
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local n=room:getDiscardPile():length()
		if n==0 then return false end
		local j=math.random(0,n-1)
		effect.to:obtainCard(sgs.Sanguosha:getCard(room:getDiscardPile():at(j)))
		
		
		n=math.floor((room:getDiscardPile():length())*3/4)
		if n==0 then return false end
		local cardslist = sgs.IntList()
			for i=0,n-1 do
				cardslist:append(room:getDiscardPile():at(i))
			end
			-- local move = sgs.CardsMoveStruct()
			-- move.card_ids=cardslist
			-- move.to_place = sgs.Player_DrawPile
			-- move.reason.m_reason=sgs.CardMoveReason_S_REASON_PUT
			-- room:moveCardsAtomic(move,true)
			room:shuffleIntoDrawPile(effect.to, cardslist, "tacos", false)
			room:addPlayerMark(effect.to, "tacos-Clear")
	end,
}

tacos:setParent(extension)
local new_taco2 = tacos:clone(1, 3)
new_taco2:setParent(extension)
sgs.LoadTranslationTable{
	["tacos"] = "tacos",
	[":tacos"] = "基本牌<br />出牌时机：出牌阶段<br />使用目标：自己<br />作用效果：每回合限一次，你获得弃牌堆中的一张牌，然后将弃牌堆3/4的牌置于摸牌堆顶。<br />",
}