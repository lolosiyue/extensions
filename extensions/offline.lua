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

sijyuoffline_huyi_skill = sgs.CreateTriggerSkillV2 {
	name = "sijyuoffline_huyi", --一般的话，技能的objectName()和武器的objectName(）用一样的名字
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageCaused },
	can_trigger = function(skill, event, room, player, data)
		if not player or not player:hasWeapon(skill:objectName()) then return false end
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.card:isKindOf("NatureSlash") and not damage.transfer and not damage.chain then
			if damage.from and damage.from:objectName() == player:objectName() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local others = room:askForPlayersChosen(player, room:getAlivePlayers(), skill:objectName(), 0, 2, "@sijyuoffline_huyi", true, true)
		if not others or others:length() == 0 then return false end
		for _, enemy in sgs.qlist(others) do
			ctx.targets:append(enemy)
		end
		return true
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		if not target:isChained() then
			room:setPlayerChained(target)
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
}
sijyuoffline_huyi:setParent(extension_card)

return { extension, extension_card }
