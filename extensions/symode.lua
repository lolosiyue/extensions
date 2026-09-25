--module("extensions.symode", package.seeall)
extension = sgs.Package("symode")

sgs.LoadTranslationTable {
	["symode"] = "三英模式",
}

sy1stboss = function(who)
	return string.find(who:getGeneralName(), "sy_") and string.find(who:getGeneralName(), "1")
end

-- V2 觸發技能須由玩家持有實例才會派發：全域規則技於檔末掛到所有武將（innate 實例）；
-- 此處在命中條件時為缺實例的事件目標補掛 acquired 實例（晚於本擴展載入的武將／換將後）。
local function sy_attach_instance(room, player, skill_name)
	if player and player:getSkillInstanceIds(skill_name):isEmpty() then
		room:attachSkillToPlayer(player, skill_name)
	end
end

-- 舊版 on_trigger 每次派發前掃座位 4→2 取最後命中者；純查詢，照原樣保留。
local function sy_xianfeng_player(room)
	local xianfeng
	for i = 4, 2, -1 do
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getSeat() == i then
				xianfeng = p
			end
		end
	end
	return xianfeng
end

-- 非 global 技能只在曾被授予時存活：以首位持有有效實例者為 owner，
-- 等效舊版 can_trigger(target) ~= nil 對任意目標派發一次的行為。
local function sy_first_holder(room, skill_name)
	for _, p in sgs.qlist(room:getAllPlayers(true)) do
		if not p:getValidSkillInstanceIds(skill_name):isEmpty() then
			return p
		end
	end
	return nil
end

sy_mode = sgs.CreateTriggerSkillV2 {
	name = "#sy_mode",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseChanging },
	priority = 99,
	global = true,
	can_trigger = function(skill, event, room, player, data)
		if room:getMode() ~= "custom_scenario" then
			return false
		end
		local change = data:toPhaseChange()
		local lord = room:getLord()
		if change.from == sgs.Player_NotActive and lord and lord:getMark("@syfirstturn") > 0
			and not room:getTag("sanyingmode"):toBool() then
			sy_attach_instance(room, player, skill:objectName())
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:setTag("sanyingmode", sgs.QVariant(true))
		return false
	end,
}

first = true
invoke = false
sy_1stturnplay = sgs.CreateTriggerSkillV2 {
	name = "#sy_1stturnplay",
	events = { sgs.TurnStart, sgs.EventPhaseChanging, sgs.CardsMoveOneTime, sgs.EventPhaseStart },
	global = true,
	priority = 1,
	can_trigger = function(skill, event, room, player, data)
		-- 舊版每次派發先掃一次 @syfirstturn；invoke 為單向旗標，此處保留同一掃描時機
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("@syfirstturn") > 0 then
				invoke = true
			end
		end
		if not invoke then
			return false
		end
		local fire = false
		if event == sgs.TurnStart then
			if first and player:getMark("@syfirstturn") > 0 then
				fire = true
			elseif player:getMark("sy_playmark") > 0 and player:getMark("@syfirstturn") > 0 and player:isLord() then
				fire = true
			else
				local xianfeng = sy_xianfeng_player(room)
				local lord = room:getLord()
				if xianfeng and lord and player:objectName() == xianfeng:objectName()
					and lord:getMark("@sy_wake") == 0 then
					fire = true
				end
			end
		elseif event == sgs.EventPhaseStart then
			local lord = room:getLord()
			if player:getPhase() == sgs.Player_NotActive and (not player:isLord()) and lord
				and sy1stboss(lord) and lord:getMark("@sy_wake") == 0 then
				fire = true
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and not room:getTag("sy2ndmode"):toBool() then
				local lord = room:getLord()
				if lord and string.find(lord:getGeneralName(), "sy_") and lord:getMark("@sy_wake") == 0 then
					if not player:isLord() then
						if player:getMark("@sy_actioned") == 0 then
							fire = true
						end
					else
						local all_actioned = true
						for _, t in sgs.qlist(room:getOtherPlayers(lord)) do
							if t:getMark("@sy_actioned") == 0 then
								all_actioned = false
								break
							end
						end
						if all_actioned then
							fire = true
						end
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			if room:getTag("SwapPile"):toInt() >= 3 then
				fire = true
			end
		end
		if not fire then
			return false
		end
		sy_attach_instance(room, player, skill:objectName())
		-- 掛技為強制後果（無「可以」）：sys_+_force 標記令 trigger-order 不可取消
		room:addPlayerMark(player, "#sy_1stturnplay+sys_+_force")
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		room:setPlayerMark(player, "#sy_1stturnplay+sys_+_force", 0)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		-- 與 can_trigger 相同的條件在執行時再判一次：收集 context 到執行之間狀態可能已變
		if event == sgs.TurnStart then
			if first and player:getMark("@syfirstturn") > 0 then
				first = false
				return true
			end
			if player:getMark("sy_playmark") > 0 and player:getMark("@syfirstturn") > 0 and player:isLord() then
				return true
			end
			local xianfeng = sy_xianfeng_player(room)
			local lord = room:getLord()
			if xianfeng and lord and player:objectName() == xianfeng:objectName()
				and lord:getMark("@sy_wake") == 0 then
				for _, p in sgs.qlist(room:getPlayers()) do
					if p:isDead() then
						room:addPlayerMark(p, "sy_playmark" .. p:getGeneralName())
						if p:getMark("sy_playmark" .. p:getGeneralName()) == 4 then
							local x = p:getGeneral():getMaxHp()
							local y = 0
							local n = 0
							if p:getGeneral2() then
								y = p:getGeneral2():getMaxHp()
								n = x + y - 3
							else
								n = x
							end
							room:setPlayerProperty(p, "maxhp", sgs.QVariant(n))
							room:setPlayerProperty(p, "hp", sgs.QVariant(math.min(3, n)))
							room:revivePlayer(p)
							p:drawCards(3)
							if not p:faceUp() then
								p:turnOver()
							end
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			local lord = room:getLord()
			if player:getPhase() == sgs.Player_NotActive and (not player:isLord()) and lord
				and sy1stboss(lord) and lord:getMark("@sy_wake") == 0 then
				room:setPlayerMark(lord, "sy_playmark", 0)
				lord:gainAnExtraTurn()
				room:addPlayerMark(lord, "sy_playmark")
			end
		elseif event == sgs.EventPhaseChanging then
			local change = ctx.original_data:toPhaseChange()
			if change.to == sgs.Player_NotActive and not room:getTag("sy2ndmode"):toBool() then
				local lord = room:getLord()
				if lord and string.find(lord:getGeneralName(), "sy_") and lord:getMark("@sy_wake") == 0 then
					if not player:isLord() then
						if player:getMark("@sy_actioned") == 0 then
							room:addPlayerMark(player, "@sy_actioned")
						end
					else
						local all_actioned = true
						for _, t in sgs.qlist(room:getOtherPlayers(lord)) do
							if t:getMark("@sy_actioned") == 0 then
								all_actioned = false
								break
							end
						end
						if all_actioned then
							for _, t in sgs.qlist(room:getOtherPlayers(lord)) do
								room:setPlayerMark(t, "@sy_actioned", 0)
							end
						end
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			if room:getTag("SwapPile"):toInt() >= 3 then
				room:gameOver("lord+rebel")
			end
		end
		return false
	end,
}

sy2ndrevive = sgs.CreateTriggerSkillV2 {
	name = "#sy2ndrevive",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TurnStart },
	can_trigger = function(skill, event, room, player, data)
		if room:getMode() ~= "custom_scenario" then
			return false
		end
		local cando = room:getTag("sanyingmode"):toBool()
		if not cando then
			return false
		end
		-- 舊版無 can_trigger：等效 triggerable(target) 的存活且持有檢查（V2 由實例解析保證持有）
		if not player:isAlive() then
			return false
		end
		local flag = false
		for _, t in sgs.qlist(room:getAllPlayers()) do
			if t:getMark("@sy_wake") > 0 then
				flag = true
				break
			end
		end
		if not flag then
			return false
		end
		return skill:objectName()
	end,
	on_effect = function(skill, event, room, player, ctx)
		for _, p in sgs.qlist(room:getPlayers()) do
			if p:isDead() then
				room:addPlayerMark(p, "sy_playmark" .. p:getGeneralName())
				if p:getMark("sy_playmark" .. p:getGeneralName()) == 6 then
					local x = p:getGeneral():getMaxHp()
					local y = 0
					local n = 0
					if p:getGeneral2() then
						y = p:getGeneral2():getMaxHp()
						n = x + y - 3
					else
						n = x
					end
					room:setPlayerProperty(p, "maxhp", sgs.QVariant(n))
					room:setPlayerProperty(p, "hp", sgs.QVariant(math.min(3, n)))
					room:revivePlayer(p)
					p:drawCards(3)
					if not p:faceUp() then
						p:turnOver()
					end
				end
			end
		end
		return false
	end,
}

function SanyingBanGeneral(name)
	if name == "sgkgodguojia" then
		return true
	end
	if name == "sgkgodsimahui" then
		return true
	end
	if name == "sgkgoddiaochan" then
		return true
	end
	if name == "sgkgodzhuge" then
		return true
	end
	if name == "sgkgodxiahoudun" then
		return true
	end
	if name == "sgkgodzhaoyun" then
		return true
	end
	if name == "shenzhugeliang" then
		return true
	end
	if name == "shenguanyu" then
		return true
	end
	if name == "sgkgodguanyu" then
		return true
	end
	if name == "bgm_pangtong" then
		return true
	end
	if name == "bgm_xiahoudun" then
		return true
	end
	if name == "dengai" then
		return true
	end
	if name == "zhonghui" then
		return true
	end
	if name == "sunce" then
		return true
	end
	if name == "caiwenji" then
		return true
	end
	if name == "sp_caiwenji" then
		return true
	end
	if name == "zhugedan" then
		return true
	end
	if name == "Yukina" then
		return true
	end
	if name == "liushan" then
		return true
	end
	if name == "zhangchunhua" then
		return true
	end
	if name == "liuzan" then
		return true
	end
	if name == "sr_xiahoudun" then
		return true
	end
	if name == "masu" then
		return true
	end
	return false
end

function hasLimitedSkill(general)
	local flag = false
	for _, skill in sgs.qlist(sgs.Sanguosha:getGeneral(general):getVisibleSkillList()) do
		if skill:getFrequency() == sgs.Skill_Wake then
			flag = true
			break
		end
	end
	return flag
end

local json = require("json")
sanyingchoose = sgs.CreateTriggerSkillV2 {
	name = "#sanyingchoose",
	frequency = sgs.Skill_Compulsory,
	global = true,
	priority = 12,
	events = { sgs.EventPhaseChanging },
	can_trigger = function(skill, event, room, player, data)
		if room:getMode() ~= "custom_scenario" then
			return false
		end
		local cando = room:getTag("sanyingmode"):toBool()
		if not cando then
			return false
		end
		local lord = room:getLord()
		local change = data:toPhaseChange()
		if not lord or change.from ~= sgs.Player_NotActive or lord:getMark(skill:objectName()) ~= 0 then
			return false
		end
		for _, t in sgs.qlist(room:getPlayers()) do
			if t:getMark(skill:objectName()) > 0 then
				return false
			end
		end
		sy_attach_instance(room, player, skill:objectName())
		return skill:objectName()
	end,
	on_effect = function(skill, event, room, player, ctx)
		local lord = room:getLord()
		lord:setMark(skill:objectName(), 1)
		local sy_bosses = { "sy_lvbu1", "sy_dongzhuo1", "sy_zhangjiao1", "sy_zhangrang1", "sy_weiyan1", "sy_caifuren1", "sy_sunhao1", "sy_simayi1", "sy_simashi1", "sy_miku1" }
		local copy = { "sy_lvbu1", "sy_dongzhuo1", "sy_zhangjiao1", "sy_zhangrang1", "sy_weiyan1", "sy_caifuren1", "sy_sunhao1", "sy_simayi1", "sy_simashi1", "sy_miku1" }
		local first_boss = {}
		for i = 1, 3 do
			local x = math.random(1, #copy)
			table.insert(first_boss, copy[x])
			table.remove(copy, x)
		end
		local general1 = room:askForGeneral(lord, table.concat(first_boss, "+"), first_boss[math.random(1, #first_boss)])
		room:changeHero(lord, general1, true, true, false, true)
		if lord:getGeneral2() then
			local copy2 = { "sy_lvbu1", "sy_dongzhuo1", "sy_zhangjiao1", "sy_zhangrang1", "sy_weiyan1", "sy_caifuren1", "sy_sunhao1", "sy_simayi1", "sy_simashi1", "sy_miku1" }
			table.removeOne(copy2, lord:getGeneralName())
			local second_boss = {}
			for i = 1, 3 do
				local x = math.random(1, #copy2)
				table.insert(second_boss, copy2[x])
				table.remove(copy2, x)
			end
			local general2 = room:askForGeneral(lord, table.concat(second_boss, "+"), second_boss[math.random(1, #second_boss)])
			room:changeHero(lord, general2, true, true, true, true)
		end
		for _, t in sgs.qlist(room:getAlivePlayers()) do
			if t:getRole() == "rebel" then
				local all = sgs.Sanguosha:getLimitedGeneralNames()
				table.removeTable(all, sgs.GetConfig("Banlist/Roles", ""):split(","))
				table.removeTable(all, sgs.GetConfig("Banlist/HulaoPass", ""):split(","))
				table.removeTable(all, sgs.GetConfig("Banlist/XMode", ""):split(","))
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					table.removeTable(all, (p:getTag("XModeBackup"):toStringList()) or {})
				end
				table.removeTable(all, sgs.GetConfig("Banlist/1v1", ""):split(","))
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					table.removeTable(all, (p:getTag("1v1Arrange"):toStringList()) or {})
				end
				for _, _t in sgs.qlist(room:getAllPlayers()) do
					table.removeOne(all, _t:getGeneralName())
					table.removeOne(all, _t:getGeneral2Name())
				end
				for _, _general in ipairs(all) do
					for _, _player in sgs.qlist(room:getAlivePlayers()) do
						local name = _player:getGeneralName()
						if sgs.Sanguosha:isGeneralHidden(name) then
							local fname = sgs.Sanguosha:findConvertFrom(name)
							if fname ~= "" then
								name = fname
							end
						end
						table.removeOne(all, name)
						if _player:getGeneral2() ~= nil then
							name = _player:getGeneral2Name()
						end
						if sgs.Sanguosha:isGeneralHidden(name) then
							local fname = sgs.Sanguosha:findConvertFrom(name)
							if fname ~= "" then
								name = fname
							end
						end
						table.removeOne(all, name)
					end
					local _g = sgs.Sanguosha:getGeneral(_general)
					local need_remove = false
					for _, skill in sgs.qlist(_g:getVisibleSkillList()) do
						if skill:getFrequency() == sgs.Skill_Wake then
							need_remove = true
							break
						end
					end
					if need_remove then
						table.removeOne(all, _general)
					end
					if sgs.Sanguosha:getGeneral(_general):getPackage() == "sy" then
						table.removeOne(all, _general)
					end
					if sgs.Sanguosha:isGeneralHidden(_general) then
						table.removeOne(all, _general)
					end
					if SanyingBanGeneral(_general) then
						table.removeOne(all, _general)
					end
				end
				local rests = {}
				for _, name in ipairs(all) do
					if
						name ~= "sgkgodguojia"
						and name ~= "sgkgodsimahui"
						and name ~= "sgkgoddiaochan"
						and name ~= "sgkgodzhuge"
						and name ~= "sgkgodxiahoudun"
						and name ~= "shenzhugeliang"
						and name ~= "shenguanyu"
						and name ~= "sgkgodguanyu"
						and name ~= "bgm_pangtong"
						and name ~= "bgm_xiahoudun"
						and name ~= "dengai"
						and name ~= "zhonghui"
						and name ~= "sunce"
						and name ~= "caiwenji"
						and name ~= "sp_caiwenji"
						and name ~= "zhugedan"
						and name ~= "Yukina"
						and name ~= "liushan"
						and name ~= "zhangchunhua"
						and name ~= "liuzan"
						and name ~= "sr_xiahoudun"
						and name ~= "masu"
						and name ~= "caopi"
						and name ~= "manchong"
						and name ~= "sr_xuchu"
						and name ~= "lvbu"
						and name ~= "zuoci"
						and name ~= "daqiao"
						and name ~= "yuji"
						and name ~= "nosdaqiao"
						and name ~= "nosyuji"
					then
						table.insert(rests, name)
					end
				end
				local mains = {}
				for i = 1, 5 do
					local x = math.random(1, #rests)
					table.insert(mains, rests[x])
					table.remove(rests, x)
					if #rests == 0 then
						break
					end
				end
				local main_general = room:askForGeneral(t, table.concat(mains, "+"), mains[math.random(1, #mains)])
				room:changeHero(t, main_general, true, true, false, true)
				table.removeOne(rests, t:getGeneralName())
				if t:getGeneral2() then
					local subs = {}
					for i = 1, 5 do
						local x = math.random(1, #rests)
						table.insert(subs, rests[x])
						table.remove(rests, x)
						if #rests == 0 then
							break
						end
					end
					local sub_general = room:askForGeneral(t, table.concat(subs, "+"), subs[math.random(1, #subs)])
					room:changeHero(t, sub_general, true, true, true, true)
					table.removeOne(rests, t:getGeneral2Name())
				end
			end
		end
		return false
	end,
}

sanyingmodeproperty = sgs.CreateTriggerSkillV2 {
	name = "#sanyingmodeproperty",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseChanging },
	global = true,
	priority = 8,
	can_trigger = function(skill, event, room, player, data)
		if room:getMode() ~= "custom_scenario" then
			return false
		end
		local cando = room:getTag("sanyingmode"):toBool()
		if not cando then
			return false
		end
		local change = data:toPhaseChange()
		local lord = room:getLord()
		if not lord or change.from ~= sgs.Player_NotActive or lord:getMark(skill:objectName()) ~= 0 then
			return false
		end
		for _, t in sgs.qlist(room:getPlayers()) do
			if t:getMark(skill:objectName()) > 0 then
				return false
			end
		end
		sy_attach_instance(room, player, skill:objectName())
		return skill:objectName()
	end,
	on_effect = function(skill, event, room, player, ctx)
		local lord = room:getLord()
		lord:setMark(skill:objectName(), 1)
		if lord:getGeneral2() then
			local general1 = lord:getGeneral()
			local general2 = lord:getGeneral2()
			if general1:getMaxHp() == 7 or general2:getMaxHp() == 7 then
				room:setPlayerProperty(lord, "maxhp", sgs.QVariant(7))
				room:setPlayerProperty(lord, "hp", sgs.QVariant(7))
			else
				if general1:getMaxHp() == 8 and general2:getMaxHp() == 8 then
					room:setPlayerProperty(lord, "maxhp", sgs.QVariant(8))
					room:setPlayerProperty(lord, "hp", sgs.QVariant(8))
				end
			end
		else
			local general1 = lord:getGeneral()
			room:setPlayerProperty(lord, "maxhp", sgs.QVariant(general1:getMaxHp()))
			room:setPlayerProperty(lord, "hp", sgs.QVariant(general1:getMaxHp()))
		end
		for _, t in sgs.qlist(room:getOtherPlayers(lord)) do
			if t:getGeneral2() then
				local x = t:getGeneral():getMaxHp()
				local y = t:getGeneral2():getMaxHp()
				room:setPlayerProperty(t, "maxhp", sgs.QVariant(x + y - 3))
				room:setPlayerProperty(t, "hp", sgs.QVariant(x + y - 3))
			end
		end
		return false
	end,
}

--联军重整摸牌
sy_frienddraw = sgs.CreateTriggerSkillV2 {
	name = "#sy_frienddraw",
	frequency = sgs.Skill_Compulsory,
	priority = 4,
	events = { sgs.BuryVictim },
	can_trigger = function(skill, event, room, player, data)
		local cando = room:getTag("sanyingmode"):toBool()
		if not cando then
			return false
		end
		-- 舊版 can_trigger(target) ~= nil：技能一經授予即對任意目標派發一次；
		-- 以持有者為 owner，死者本人為 ctx.invoker
		local holder = sy_first_holder(room, skill:objectName())
		if not holder then
			return false
		end
		return skill:objectName(), holder
	end,
	on_effect = function(skill, event, room, player, ctx)
		local death = ctx.original_data:toDeath()
		if not death.who:isLord() then
			room:setTag("SkipNormalDeathProcess", sgs.QVariant(true))
			death.who:bury()
			for _, t in sgs.qlist(room:getAlivePlayers()) do
				if not t:isLord() then
					t:drawCards(1)
				end
			end
		end
		return false
	end,
}

sy_diedclear = sgs.CreateTriggerSkillV2 {
	name = "#sy_diedclear",
	frequency = sgs.Skill_Compulsory,
	priority = -1,
	events = { sgs.BuryVictim },
	can_trigger = function(skill, event, room, player, data)
		if room:getMode() ~= "custom_scenario" then
			return false
		end
		local cando = room:getTag("sanyingmode"):toBool()
		if not cando then
			return false
		end
		local holder = sy_first_holder(room, skill:objectName())
		if not holder then
			return false
		end
		return skill:objectName(), holder
	end,
	on_effect = function(skill, event, room, player, ctx)
		-- 舊版 player 為事件目標（死者）；V2 owner 為持有者，死者本人取 ctx.invoker
		local victim = ctx.invoker
		room:setTag("SkipNormalDeathProcess", sgs.QVariant(false))
		local lord = room:getLord()
		local next_alive = victim and victim:getNextAlive()
		if lord and lord:getPhase() == sgs.Player_NotActive and next_alive and (not next_alive:isLord())
			and (not room:getTag("sy2ndmode"):toBool()) then
			lord:gainAnExtraTurn()
		end
		return false
	end,
}

sy_2ndstart = sgs.CreateTriggerSkillV2 {
	name = "#sy_2ndstart",
	frequency = sgs.Skill_Compulsory,
	global = true,
	priority = 30,
	events = { sgs.TurnStart },
	can_trigger = function(skill, event, room, player, data)
		local trigger_2nd = room:getTag("sy2ndmode"):toBool()
		if trigger_2nd and player:getMark("2nd_stop") > 0 then
			sy_attach_instance(room, player, skill:objectName())
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:setPlayerMark(player, "2nd_stop", 0)
		return true
	end,
}

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#sy_1stturnplay") then
	skills:append(sy_1stturnplay)
end
if not sgs.Sanguosha:getSkill("#sy_frienddraw") then
	skills:append(sy_frienddraw)
end
if not sgs.Sanguosha:getSkill("#sy_diedclear") then
	skills:append(sy_diedclear)
end
if not sgs.Sanguosha:getSkill("#sy2ndrevive") then
	skills:append(sy2ndrevive)
end
if not sgs.Sanguosha:getSkill("#sanyingchoose") then
	skills:append(sanyingchoose)
end
if not sgs.Sanguosha:getSkill("#sanyingmodeproperty") then
	skills:append(sanyingmodeproperty)
end
if not sgs.Sanguosha:getSkill("#sy_mode") then
	skills:append(sy_mode)
end
if not sgs.Sanguosha:getSkill("#sy_2ndstart") then
	skills:append(sy_2ndstart)
end
sgs.Sanguosha:addSkills(skills)

-- V2 觸發技能須由玩家持有實例才會派發：五個全域規則技掛到所有武將作為 innate 實例；
-- 晚於本擴展載入的武將或換將後缺實例者，由各技能 can_trigger 命中條件時補掛 acquired 實例。
-- 三個非 global 技能（sy2ndrevive/sy_frienddraw/sy_diedclear）維持授予才存活的語義，不掛武將。
for _, gen in sgs.qlist(sgs.Sanguosha:getAllGenerals()) do
	gen:addSkill("#sy_mode")
	gen:addSkill("#sy_1stturnplay")
	gen:addSkill("#sanyingchoose")
	gen:addSkill("#sanyingmodeproperty")
	gen:addSkill("#sy_2ndstart")
end

sgs.LoadTranslationTable {
	["@sy_actioned"] = "已行动",
	["@syfirstturn"] = "三英",
}

return { extension }
