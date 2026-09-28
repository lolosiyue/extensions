--===============================--
extension = sgs.Package("extendeffects", sgs.Package_GeneralPack)
--===============================--
sgs.LoadTranslationTable {
	["extendeffects"] = "特效",
}
--================================--
ENABLE_LV5_EFFECT = true
--================================--
TexiaoAnjiang = sgs.General(extension, "TexiaoAnjiang", "god", 5, true, true, true)

-- V2 觸發技能須由玩家持有實例才會派發：全域規則技在命中條件時為缺實例的事件目標補掛 acquired 實例
-- （等效舊版 global=true 的全場派發；隱藏名不進入 getVisibleSkillList，不污染存檔與面板）
local function ext_effects_attach_instance(room, player, skill_name)
	if player and player:getSkillInstanceIds(skill_name):isEmpty() then
		room:attachSkillToPlayer(player, skill_name)
	end
end

local function ext_effects_can_trigger(room, player, skill)
	if table.contains(sgs.Sanguosha:getBanPackages(), "extendeffects") then
		return false
	end
	ext_effects_attach_instance(room, player, skill:objectName())
	return skill:objectName()
end

LuaTexiao = sgs.CreateTriggerSkillV2 {
	name = "#LuaTexiao",
	events = { sgs.FinishJudge },
	global = true,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		return ext_effects_can_trigger(room, player, skill)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local judge = ctx.original_data:toJudge()
		local shadiao = judge.who
		if judge:isGood() then
			return false
		end
		if judge.reason == "indulgence" then
			room:setEmotion(shadiao, "indulgence")
		elseif judge.reason == "supply_shortage" then
			room:setEmotion(shadiao, "supply_shortage")
		elseif judge.reason == "lightning" then
			room:setEmotion(shadiao, "lightning")
		end
		return false
	end,
}
--=============================--
LuaTexiaoWujie = sgs.CreateTriggerSkillV2 {
	name = "#LuaTexiaoWujie",
	events = { sgs.CardUsed, sgs.CardResponded },
	global = true,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		return ext_effects_can_trigger(room, player, skill)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local card_star
		if event == sgs.CardUsed then
			card_star = ctx.original_data:toCardUse().card
		else
			card_star = ctx.original_data:toCardResponse().m_card
		end
		if not card_star then
			return false
		end
		if card_star:isKindOf("EquipCard") then
			return false
		end
		room:setEmotion(player, "wujie/" .. card_star:objectName())
		return false
	end,
}

lianpoeffect = sgs.CreateTriggerSkillV2{
	name = "#lianpoeffect",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart,sgs.GameOverJudge},
	priority = 4,
	can_trigger = function(skill, event, room, player, data)
		return ext_effects_can_trigger(room, player, skill)
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.GameOverJudge then
			local current = room:getCurrent()
			-- room:addPlayerMark(current,"havekilled",1)
			local x = current:getMark("havekilled-Clear")
			--current:speak("sdgsdsg"..x)
			if (x>1) and (x<8) then
				room:setEmotion(current,"lianpo\\"..x)
			end
		end
		return false
	end,
}
--===========================--
TexiaoAnjiang:addSkill(LuaTexiao)
TexiaoAnjiang:addSkill(lianpoeffect)
if ENABLE_LV5_EFFECT then
	TexiaoAnjiang:addSkill(LuaTexiaoWujie)
end
sgs.LoadTranslationTable {
	["#mvpeffect"] = "全场最佳：",
}
--=============================--
return extension
