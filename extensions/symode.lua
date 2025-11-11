--module("extensions.symode", package.seeall)
extension = sgs.Package("symode")

sgs.LoadTranslationTable{
	["symode"] = "三英模式",
}

sy1stboss = function(who)
	return string.find(who:getGeneralName(), "sy_") and string.find(who:getGeneralName(), "1")
end


sy_mode = sgs.CreateTriggerSkill{
	name = "#sy_mode",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	priority = 99,
	global = true,
	on_trigger = function(self, event, player, data, room)
		if room:getMode() ~= "custom_scenario" then return false end
		local change = data:toPhaseChange()
		if change.from == sgs.Player_NotActive and room:getLord() and room:getLord():getMark("@syfirstturn") > 0 then
			local sanyingmode = room:getTag("sanyingmode"):toBool()
			if not sanyingmode then
				room:setTag("sanyingmode", sgs.QVariant(true))
			end
		end
	end
}


first = true
invoke = false	
sy_1stturnplay = sgs.CreateTriggerSkill{
	name = "#sy_1stturnplay",
	events = {sgs.TurnStart, sgs.EventPhaseChanging, sgs.CardsMoveOneTime, sgs.EventPhaseStart},
	global = true,
	priority = 1,
	on_trigger = function(self, event, player, data, room)
		local xianfeng
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("@syfirstturn") > 0 then
				invoke = true
			end
		end
		for i = 4, 2, -1 do
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getSeat() == i then
					xianfeng = p
				end
			end
		end
		if not invoke then return false end
		if event == sgs.TurnStart then
			if first and player:getMark("@syfirstturn") > 0 then 
				first = false
				return true 
			end
			if player:getMark("sy_playmark") > 0 and player:getMark("@syfirstturn") > 0 and player:isLord() then return true end
			if player:objectName() == xianfeng:objectName() and room:getLord():getMark("@sy_wake") == 0 then
				for _,p in sgs.qlist(room:getPlayers()) do
					if p:isDead() then
						room:addPlayerMark(p, "sy_playmark"..p:getGeneralName())
						if p:getMark("sy_playmark"..p:getGeneralName()) == 4 then
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
							if not p:faceUp() then p:turnOver() end
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_NotActive then
				if (not player:isLord()) and sy1stboss(room:getLord()) and room:getLord():getMark("@sy_wake") == 0 then
					room:setPlayerMark(room:getLord(), "sy_playmark", 0)
					room:getLord():gainAnExtraTurn()
					room:addPlayerMark(room:getLord(), "sy_playmark")
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local is_2ndmode = room:getTag("sy2ndmode"):toBool()
				if is_2ndmode then return false end
				if not player:isLord() and string.find(room:getLord():getGeneralName(), "sy_") and room:getLord():getMark("@sy_wake") == 0 then 
					if player:getMark("@sy_actioned") == 0 then room:addPlayerMark(player, "@sy_actioned") end
				elseif player:isLord() and string.find(room:getLord():getGeneralName(), "sy_") and room:getLord():getMark("@sy_wake") == 0 then
					local all_actioned = true
					for _, t in sgs.qlist(room:getOtherPlayers(room:getLord())) do
						if t:getMark("@sy_actioned") == 0 then
							all_actioned = false
							break
						end
					end
					if all_actioned then
						for _, t in sgs.qlist(room:getOtherPlayers(room:getLord())) do
							room:setPlayerMark(t, "@sy_actioned", 0)
						end
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			if room:getTag("SwapPile"):toInt() >= 3 then
				room:gameOver("lord+rebel")
			end
		end
	end
}


sy2ndrevive = sgs.CreateTriggerSkill{
	name = "#sy2ndrevive",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TurnStart},
	on_trigger = function(self, event, player, data, room)
		if room:getMode() ~= "custom_scenario" then return false end
		local cando = room:getTag("sanyingmode"):toBool()
		if not cando then return false end
		local flag = false
		for _, t in sgs.qlist(room:getAllPlayers()) do
			if t:getMark("@sy_wake") > 0 then
				flag = true
				break
			end
		end
		if not flag then return false end
		for _,p in sgs.qlist(room:getPlayers()) do
			if p:isDead() then
				room:addPlayerMark(p, "sy_playmark"..p:getGeneralName())
				if p:getMark("sy_playmark"..p:getGeneralName()) == 6 then
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
					if not p:faceUp() then p:turnOver() end
				end
			end
		end
	end
}


function SanyingBanGeneral(name)
	if name == "sgkgodguojia" then return true end
	if name == "sgkgodsimahui" then return true end
	if name == "sgkgoddiaochan" then return true end
	if name == "sgkgodzhuge" then return true end
	if name == "sgkgodxiahoudun" then return true end
	if name == "sgkgodzhaoyun" then return true end
	if name == "shenzhugeliang" then return true end
	if name == "shenguanyu" then return true end
	if name == "sgkgodguanyu" then return true end
	if name == "bgm_pangtong" then return true end
	if name == "bgm_xiahoudun" then return true end
	if name == "dengai" then return true end
	if name == "zhonghui" then return true end
	if name == "sunce" then return true end
	if name == "caiwenji" then return true end
	if name == "sp_caiwenji" then return true end
	if name == "zhugedan" then return true end
	if name == "Yukina" then return true end
	if name == "liushan" then return true end
	if name == "zhangchunhua" then return true end
	if name == "liuzan" then return true end
	if name == "sr_xiahoudun" then return true end
	if name == "masu" then return true end
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

local json = require ("json")
sanyingchoose = sgs.CreateTriggerSkill{
	name = "#sanyingchoose",
	frequency = sgs.Skill_Compulsory,
	global = true,
	priority = 12,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if room:getMode() ~= "custom_scenario" then return false end
		local cando = room:getTag("sanyingmode"):toBool()
		if not cando then return false end
		local lord = room:getLord()
		local change = data:toPhaseChange()
		if change.from == sgs.Player_NotActive and lord:getMark(self:objectName()) == 0 then
			local flag = true
			for _, t in sgs.qlist(room:getPlayers()) do
				if t:getMark(self:objectName()) > 0 then
					flag = false
					break
				end
			end
			if not flag then return false end
			lord:setMark(self:objectName(), 1)
			local sy_bosses = {"sy_lvbu1", "sy_dongzhuo1", "sy_zhangjiao1", "sy_zhangrang1", "sy_weiyan1", "sy_caifuren1", "sy_sunhao1", "sy_simayi1",
			"sy_simashi1", "sy_miku1"}
			local copy = {"sy_lvbu1", "sy_dongzhuo1", "sy_zhangjiao1", "sy_zhangrang1", "sy_weiyan1", "sy_caifuren1", "sy_sunhao1", "sy_simayi1",
			"sy_simashi1", "sy_miku1"}
			local first_boss = {}
			for i = 1, 3 do
				local x = math.random(1, #copy)
				table.insert(first_boss, copy[x])
				table.remove(copy, x)
			end
			local general1 = room:askForGeneral(lord, table.concat(first_boss, "+"), first_boss[math.random(1, #first_boss)])
			room:changeHero(lord, general1, true, true, false, true)
			if lord:getGeneral2() then
				local copy2 = {"sy_lvbu1", "sy_dongzhuo1", "sy_zhangjiao1", "sy_zhangrang1", "sy_weiyan1", "sy_caifuren1", "sy_sunhao1", "sy_simayi1",
				"sy_simashi1", "sy_miku1"}
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
					table.removeTable(all,sgs.GetConfig("Banlist/Roles",""):split(","))
					table.removeTable(all,sgs.GetConfig("Banlist/HulaoPass",""):split(","))
					table.removeTable(all,sgs.GetConfig("Banlist/XMode",""):split(","))
					for _, p in sgs.qlist(room:getAlivePlayers())do
						table.removeTable(all,(p:getTag("XModeBackup"):toStringList()) or {})
					end
					table.removeTable(all,sgs.GetConfig("Banlist/1v1",""):split(","))
					for _, p in sgs.qlist(room:getAlivePlayers())do
						table.removeTable(all,(p:getTag("1v1Arrange"):toStringList()) or {})
					end
					for _, _t in sgs.qlist(room:getAllPlayers()) do
						table.removeOne(all, _t:getGeneralName())
						table.removeOne(all, _t:getGeneral2Name())
					end
					for _, _general in ipairs(all) do
						for _, _player in sgs.qlist(room:getAlivePlayers())do
							local name = _player:getGeneralName()
							if sgs.Sanguosha:isGeneralHidden(name) then
								local fname = sgs.Sanguosha:findConvertFrom(name);
								if fname ~= "" then name = fname end
							end
							table.removeOne(all,name)	
							if _player:getGeneral2() ~= nil then name = _player:getGeneral2Name() end
							if sgs.Sanguosha:isGeneralHidden(name) then
								local fname = sgs.Sanguosha:findConvertFrom(name);
								if fname ~= "" then name = fname end
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
						if need_remove then table.removeOne(all, _general) end
						if sgs.Sanguosha:getGeneral(_general):getPackage() == "sy" then table.removeOne(all, _general) end
						if sgs.Sanguosha:isGeneralHidden(_general) then table.removeOne(all, _general) end
						if SanyingBanGeneral(_general) then table.removeOne(all, _general) end
					end
					local rests = {}
					for _, name in ipairs(all) do
						if name ~= "sgkgodguojia" and name ~= "sgkgodsimahui" and name ~= "sgkgoddiaochan" and name ~= "sgkgodzhuge" and
						name ~= "sgkgodxiahoudun" and name ~= "shenzhugeliang" and name ~= "shenguanyu" and name ~= "sgkgodguanyu" and
						name ~= "bgm_pangtong" and name ~= "bgm_xiahoudun" and name ~= "dengai" and name ~= "zhonghui" and name ~= "sunce" and
						name ~= "caiwenji" and name ~= "sp_caiwenji" and name ~= "zhugedan" and name ~= "Yukina" and name ~= "liushan" and
						name ~= "zhangchunhua" and name ~= "liuzan" and name ~= "sr_xiahoudun" and name ~= "masu" and name ~= "caopi" and
						name ~= "manchong" and name ~= "sr_xuchu" and name ~= "lvbu" and name ~= "zuoci" and name ~= "daqiao" and name ~= "yuji" 
						and name ~= "nosdaqiao" and name ~= "nosyuji" then
							table.insert(rests, name)
						end
					end
					local mains = {}
					for i = 1, 5 do
						local x = math.random(1, #rests)
						table.insert(mains, rests[x])
						table.remove(rests, x)
						if #rests == 0 then break end
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
							if #rests == 0 then break end
						end
						local sub_general = room:askForGeneral(t, table.concat(subs, "+"), subs[math.random(1, #subs)])
						room:changeHero(t, sub_general, true, true, true, true)
						table.removeOne(rests, t:getGeneral2Name())
					end
				end
			end
		end
	end
}


sanyingmodeproperty = sgs.CreateTriggerSkill{
	name = "#sanyingmodeproperty",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	global = true,
	priority = 8,
	on_trigger = function(self, event, player, data, room)
		if room:getMode() ~= "custom_scenario" then return false end
		local cando = room:getTag("sanyingmode"):toBool()
		if not cando then return false end
		local change = data:toPhaseChange()
		local lord = room:getLord()
		if change.from == sgs.Player_NotActive then
			if lord:getMark(self:objectName()) == 0 then
				local flag = true
				for _, t in sgs.qlist(room:getPlayers()) do
					if t:getMark(self:objectName()) > 0 then
						flag = false
						break
					end
				end
				if not flag then return false end
				lord:setMark(self:objectName(), 1)
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
						room:setPlayerProperty(t, "maxhp", sgs.QVariant(x+y-3))
						room:setPlayerProperty(t, "hp", sgs.QVariant(x+y-3))
					end
				end
			end
			return false
		end
	end
}


--联军重整摸牌
sy_frienddraw = sgs.CreateTriggerSkill{
	name = "#sy_frienddraw",
	frequency = sgs.Skill_Compulsory,
	priority = 4,
	events = {sgs.BuryVictim},
	on_trigger = function(self, event, player, data, room)
		local cando = room:getTag("sanyingmode"):toBool()
		if not cando then return false end
		local death = data:toDeath()
		if not death.who:isLord() then
			room:setTag("SkipNormalDeathProcess", sgs.QVariant(true))
			player:bury()
			for _, t in sgs.qlist(room:getAlivePlayers()) do
				if not t:isLord() then
					t:drawCards(1)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}


sy_diedclear = sgs.CreateTriggerSkill{
	name = "#sy_diedclear",
	frequency = sgs.Skill_Compulsory,
	priority = -1,
	events = {sgs.BuryVictim},
	on_trigger = function(self, event, player, data, room)
		if room:getMode() ~= "custom_scenario" then return false end
		local cando = room:getTag("sanyingmode"):toBool()
		if not cando then return false end
		room:setTag("SkipNormalDeathProcess", sgs.QVariant(false))
		if room:getLord():getPhase() == sgs.Player_NotActive and (not player:getNextAlive():isLord()) and (not room:getTag("sy2ndmode"):toBool()) then
			room:getLord():gainAnExtraTurn()
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}


sy_2ndstart = sgs.CreateTriggerSkill{
	name = "#sy_2ndstart",
	frequency = sgs.Skill_Compulsory,
	global = true,
	priority = 30,
	events = {sgs.TurnStart},
	on_trigger = function(self, event, player, data, room)
		local trigger_2nd = room:getTag("sy2ndmode"):toBool()
		if trigger_2nd and player:getMark("2nd_stop") > 0 then
			room:setPlayerMark(player, "2nd_stop", 0)
			return true
		end
	end
}


local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#sy_1stturnplay") then skills:append(sy_1stturnplay) end
if not sgs.Sanguosha:getSkill("#sy_frienddraw") then skills:append(sy_frienddraw) end
if not sgs.Sanguosha:getSkill("#sy_diedclear") then skills:append(sy_diedclear) end
if not sgs.Sanguosha:getSkill("#sy2ndrevive") then skills:append(sy2ndrevive) end
if not sgs.Sanguosha:getSkill("#sanyingchoose") then skills:append(sanyingchoose) end
if not sgs.Sanguosha:getSkill("#sanyingmodeproperty") then skills:append(sanyingmodeproperty) end
if not sgs.Sanguosha:getSkill("#sy_mode") then skills:append(sy_mode) end
if not sgs.Sanguosha:getSkill("#sy_2ndstart") then skills:append(sy_2ndstart) end
sgs.Sanguosha:addSkills(skills)


sgs.LoadTranslationTable{
	["@sy_actioned"]="已行动",
	["@syfirstturn"]="三英",
}


return {extension}