extension = sgs.Package("offline", sgs.Package_GeneralPack)
extension_card = sgs.Package("ofl_card", sgs.Package_CardPack)

sgs.LoadTranslationTable {
	["offline"] = "线下官正",
	["ofl_card"] = "线下官正",
}
sgs.LoadTranslationTable {
	["sijyuoffline_zhaoyun"] = "赵云[联想]",
	["&sijyuoffline_zhaoyun"] = "赵云",
	["#sijyuoffline_zhaoyun"] = "白马先锋",
	["~sijyuoffline_zhaoyun"] = "",
	["designer:sijyuoffline_zhaoyun"] = "",
	["cv:sijyuoffline_zhaoyun"] = "",
	["illustrator:sijyuoffline_zhaoyun"] = "VINCENT",

	--三国杀旧藏版：往昔龙吟
	--yt_shencaocao skin
	["zhaoyeyushizi"] = "照夜玉狮子",
	[":zhaoyeyushizi"] = "装备牌·坐骑<br /><b>坐骑技能</b>：你与其他角色的距离-1。",

	--徐荣礼盒
	["sijyuoffline_huyi"] = "虎翼",
	[":sijyuoffline_huyi"] = "装备牌·武器\
	攻击范围：3\
	攻击效果：你使用【杀】对目标造成属性伤害时，你可以横置至多两名角色。",
	["@sijyuoffline_huyi"] = "虎翼：你可以横置至多两名角色",
}

sijyuoffline_zhaoyun = sgs.General(extension, "sijyuoffline_zhaoyun", "shu", 3)

sijyuoffline_zhaoyun:addSkill("longdan")
sijyuoffline_zhaoyun:addSkill("chongzhen")

zhaoyeyushizi = sgs.CreateOffensiveHorse {
	name = "zhaoyeyushizi",
	class_name = "Zhaoyeyushizi",
	suit = sgs.Card_Heart,
	number = 5,
}
zhaoyeyushizi:setParent(extension_card)

--[[
	技能名：虎翼
	技能描述：你使用【杀】对目标造成属性伤害时，你可以横置至多两名角色。
	引用：sfofl_yice
]]
--

sijyuoffline_huyi_skill = sgs.CreateTriggerSkill {
	name = "sijyuoffline_huyi", --一般的话，技能的objectName()和武器的objectName(）用一样的名字
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageCaused },
	can_trigger = function(self, target)
		return target and target:hasWeapon(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if damage.card and damage.card:isKindOf("Slash") and damage.card:isKindOf("NatureSlash") and not damage.transfer and not damage.chain then
			if damage.from:objectName() == player:objectName() then
				local others = room:askForPlayersChosen(player, room:getAlivePlayers(), self:objectName(), 0, 2, "@sijyuoffline_huyi", true, true)
				if others and others:length() > 0 then
					for _, enemy in sgs.qlist(others) do
						if not enemy:isChained() then
							room:setPlayerChained(enemy)
						end
					end
				end
			end
		end
		return false
	end,
}
sijyuoffline_huyi = sgs.CreateWeapon {
	name = "sijyuoffline_huyi",
	class_name = "Huyi",
	suit = sgs.Card_Spade,
	number = 11,
	range = 3,
	equip_skill = sijyuoffline_huyi_skill,
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
sijyuoffline_huyi:setParent(extension_card)

return { extension, extension_card }
