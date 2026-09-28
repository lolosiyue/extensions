module("extensions.LuaOldEnemy", package.seeall)
extension = sgs.Package("LuaOldEnemy", sgs.Package_CardPack)

-- 宿敌规则，规则技能君
-- version 2.1
--[[宿敌规则：
1.当一名角色受到另一名角色造成的伤害时，若这两名角色均不存在宿敌关系，二者建立宿敌关系。
2.一名角色与其宿敌角色计算距离时始终-1 。
3.一名角色杀死其一名宿敌角色时，该角色回复一点体力。
4.一名存在宿敌关系的角色死亡时，相应宿敌关系解除。

相关概念及解释：
1.宿敌角色：与一名角色存在相应宿敌关系的另一名角色或公敌角色。
2.宿敌关系：指两名角色互为对方宿敌角色的特殊关系，此关系可以建立、解除。
①.宿敌关系的建立：两名角色以造成伤害的渠道建立宿敌关系时，其中伤害来源称为“主动方”，受伤角色称为“被迫方”。由主动方向被迫方强制建立此关系。
②.宿敌关系的解除：互为宿敌的两名角色以一方死亡的渠道解除宿敌关系时，其中死亡角色称为“主动方”，存活角色称为“被迫方”。由主动方向被迫方强制解除此关系。


公敌规则：
1.一名角色第二次（或以上）以“被迫方”身份解除宿敌关系时，若此时场上没有公敌角色，该角色成为公敌角色。
2.公敌角色不与任何角色存在宿敌关系。
3.公敌角色为所有其他角色的宿敌角色（之一）。
4.一名角色杀死公敌角色时，该角色摸两张牌。
5.公敌角色杀死其他角色时，可获得该角色装备区一张牌。
6.公敌角色回合开始时，若场上存活角色数不大于其已损失体力值，公敌角色摸一张牌并解除公敌状态。


隐者规则：
1.一名角色连续两个回合不存在宿敌关系，回合结束时该角色成为隐者角色直到该角色建立宿敌关系。
2.隐者角色以“被迫方”身份建立宿敌关系时，可获得“主动方”区域内的一张牌。
3.隐者角色以“主动方”身份建立宿敌关系时，须展示所有手牌。
4.隐者角色死亡时可将所有手牌交给一名其他角色。
]]
--

require "lua.luaoldenemy_lib"

local skilllist = sgs.SkillList()

LuaOldEnemy = sgs.CreateTriggerSkillV2 {
	name = "#LuaOldEnemy",
	events = { sgs.GameReady, sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.DamageInflicted, sgs.Death },
	global = true,
	frequency = sgs.Skill_Compulsory,

	can_trigger = function(skill, event, room, player, data)
		if not player or table.contains(sgs.Sanguosha:getBanPackages(), "LuaOldEnemy") then
			return false
		end
		if event == sgs.GameReady then
			return skill:objectName()
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start
				and (getOEMark(player) or player:getMark("@LuaPublicEnemy") > 0) then
				return skill:objectName()
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				return skill:objectName()
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if not damage.from or damage.from:objectName() == damage.to:objectName() then
				return false
			end
			if findMyOE(damage.from) or findMyOE(damage.to) then
				return false
			end
			if damage.from:getMark("@LuaPublicEnemy") > 0 or damage.to:getMark("@LuaPublicEnemy") > 0 then
				return false
			end
			return skill:objectName()
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() == player:objectName() then
				return skill:objectName()
			end
		end
		return false
	end,

	on_effect = function(skill, event, room, player, ctx)
		-- V2 觸發需要持有者實例：為缺少實例的角色補掛 acquired 實例
		-- （晚於本擴展載入的武將、國戰暗將、中途換將均會缺 innate 實例；
		-- acquired 實例不受暗將 preshow 限制）。已有實例者跳過，避免雙實例重複觸發。
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getSkillInstanceIds("#LuaOldEnemy"):isEmpty() then
				room:attachSkillToPlayer(p, "#LuaOldEnemy")
			end
		end
		if event == sgs.GameReady then return false end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			if getOEMark(player) or player:getMark("@LuaPublicEnemy") > 0 then
				room:setPlayerFlag(player, "OEHermit")
				if player:getMark("@LuaPublicEnemy") > 0 and room:getAlivePlayers():length() <= player:getLostHp() then --解除公敌
					player:loseAllMarks("@LuaPublicEnemy")
					player:drawCards(1)
				end
			end
		end
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then --设置隐者标记
			if player:hasFlag("OEHermit") then
				room:setPlayerMark(player, "OEHermit", 0)
			else
				room:addPlayerMark(player, "OEHermit", 1)
				if player:getMark("OEHermit") >= 3 and player:getMark("@LuaOldEnemyHermit") == 0 then
					player:gainMark("@LuaOldEnemyHermit")
				end
			end
		end
		if event == sgs.DamageInflicted then
			local damage = ctx.original_data:toDamage()
			-- 與 can_trigger 相同的條件在執行時再判一次：收集 context 到執行之間
			-- 宿敵關係可能已被其他觸發建立（舊版係執行時判斷，此處保留該時序語義）
			if not damage.from or damage.from:objectName() == damage.to:objectName() then
				return false
			end
			if findMyOE(damage.from) or findMyOE(damage.to) then
				return false
			end
			if damage.from:getMark("@LuaPublicEnemy") > 0 or damage.to:getMark("@LuaPublicEnemy") > 0 then
				return false
			end
			if damage.from:getMark("@LuaOldEnemyHermit") > 0 then --隐者主动方展示手牌
				room:showAllCards(damage.from)
			end
			if damage.to:getMark("@LuaOldEnemyHermit") > 0 then --隐者被迫方获得牌
				if not damage.from:isAllNude() then
					local ai_data = sgs.QVariant()
					ai_data:setValue(damage.from)
					room:setTag("OldEnemyHermit", ai_data)
					if room:askForSkillInvoke(damage.to, "LuaOldEnemyHermit", sgs.QVariant("Hermit_getCard:" .. damage.from:objectName())) then
						local card = room:askForCardChosen(damage.to, damage.from, "hej", "LuaOldEnemyHermit")
						room:obtainCard(damage.to, card)
					end
					room:removeTag("OldEnemyHermit")
				end
			end
			establishOE(room, damage.from, damage.to)
		end
		if event == sgs.Death then
			local death = ctx.original_data:toDeath()
			local OldEnemy = findMyOE(death.who, room)
			if OldEnemy then
				relieveOE(room, death.who)
				room:addPlayerMark(OldEnemy, "OEs", 1)
			end
			if death.who:getMark("@LuaOldEnemyHermit") > 0 and not death.who:isKongcheng() then --隐者被杀给牌
				local target = room:askForPlayerChosen(death.who, room:getOtherPlayers(death.who), "LuaOldEnemyHermit", "@LuaOldEnemyHermit-invoke", true)
				if target then
					local dummy = sgs.Sanguosha:cloneCard("jink")
					local cards = death.who:getHandcards()
					for _, card in sgs.qlist(cards) do
						dummy:addSubcard(card)
					end
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, death.who:objectName(), target:objectName(), "LuaOldEnemyHermit", "")
					room:moveCardTo(dummy, target, sgs.Player_PlaceHand, reason)
					dummy:deleteLater()
				end
			end
			if death.damage and death.damage.from then
				if OldEnemy and death.damage.from:objectName() == OldEnemy:objectName() then --杀死宿敌回血
					if OldEnemy:isWounded() then
						room:recover(OldEnemy, sgs.RecoverStruct())
					end
				end
				if death.who:getMark("@LuaPublicEnemy") > 0 then --杀死公敌摸牌
					death.damage.from:drawCards(2)
					if death.damage.from:isWounded() then
						room:recover(death.damage.from, sgs.RecoverStruct())
					end
				end
				if death.damage.from:getMark("@LuaPublicEnemy") > 0 then --公敌杀人拿装备
					if death.who:getEquips():length() > 0 then
						if room:askForSkillInvoke(death.damage.from, "LuaPublicEnemy", sgs.QVariant("PublicEnemy_getEquip:" .. death.who:objectName())) then
							local card = room:askForCardChosen(death.damage.from, death.who, "e", "LuaPublicEnemy")
							room:obtainCard(death.damage.from, card)
						end
					end
				end
			end
			if OldEnemy and OldEnemy:getMark("OEs") >= 2 then
				setPublicEnemy(room, OldEnemy)
			end --设置公敌
		end
		return false
	end,
}

if not sgs.Sanguosha:getSkill("#LuaOldEnemy") then
	skilllist:append(LuaOldEnemy)
end

LuaOldEnemyDistance = sgs.CreateDistanceSkillV2 {
	name = "#LuaOldEnemyDistance",
	-- 全局规则技能：无持有者实例，按 (from,to) 每次评估一次
	holder_selector = sgs.CorrectSkill_System,
	correct_func = function(skill, ctx)
		if table.contains(sgs.Sanguosha:getBanPackages(), "LuaOldEnemy") then
			return nil
		end
		local from = ctx:getPrimary()
		local to = ctx:getSecondary()
		if not from or not to then return nil end
		if findMyOE(from) and findMyOE(from):objectName() == to:objectName() then
			return -1
		end
		if to:getMark("@LuaPublicEnemy") > 0 then
			return -1
		end
		return nil
	end,
}

if not sgs.Sanguosha:getSkill("#LuaOldEnemyDistance") then
	skilllist:append(LuaOldEnemyDistance)
end

sgs.Sanguosha:addSkills(skilllist)

-- V2 触发技能需要持有者实例：规则技挂到所有武将作为 bootstrap；
-- 加载顺序更晚的武将/暗将在 on_effect 里再补挂 acquired 实例
for _, gen in sgs.qlist(sgs.Sanguosha:getAllGenerals()) do
	gen:addSkill("#LuaOldEnemy")
end

sgs.LoadTranslationTable {
	["LuaOldEnemy"] = "宿敌规则",
	["#LuaOldEnemy"] = "宿敌规则",
	["@LuaOldEnemy0"] = "宿敌",
	["@LuaOldEnemy1"] = "宿敌",
	["@LuaOldEnemy2"] = "宿敌",
	["@LuaOldEnemy3"] = "宿敌",
	["@LuaOldEnemy4"] = "宿敌",
	["@LuaOldEnemy5"] = "宿敌",
	["@LuaOldEnemy6"] = "宿敌",
	["@LuaOldEnemy7"] = "宿敌",
	["@LuaOldEnemy8"] = "宿敌",
	["@LuaOldEnemy9"] = "宿敌",
	["@LuaPublicEnemy"] = "公敌",
	["LuaPublicEnemy"] = "公敌规则",
	["LuaPublicEnemy:PublicEnemy_getEquip"] = "是否获得 %src 装备区一张牌？",
	["@LuaOldEnemyHermit"] = "隐者",
	["LuaOldEnemyHermit"] = "隐者规则",
	["LuaOldEnemyHermit:Hermit_getCard"] = "是否获得 %src 区域内一张牌？",
	["@LuaOldEnemyHermit-invoke"] = "你可以将手牌交给一名其他角色",
}
return { extension }
