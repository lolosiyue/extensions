extension = sgs.Package("YY")

--赵云
gz_zhaoyun = sgs.General(extension, "gz_zhaoyun", "qun", 4, true, true, false, 3, 2)
Qinggangex = sgs.CreateViewAsEquipSkill {
	name = "#Qinggangex",
	view_as_equip = function(self, player)
		return "silver_lion"
	end,
}
--[[
Qinggang = sgs.CreateTriggerSkill{
	  name="Qinggang",
        events={sgs.TargetSpecified,sgs.Damage},
        priority=2,
        frequency=sgs.Skill_Compulsory,
        on_trigger=function(self,event,player,data)
		local room=player:getRoom()
-- 无视防具
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
				room:broadcastSkillInvoke("Qinggang")
				room:sendCompulsoryTriggerLog(use.from, "Qinggang", true)
					end
				end
			end
-- 吸血
elseif event  == sgs.Damage then
		local damage = data:toDamage()
		if damage.from:hasSkill(self:objectName()) and damage.from:objectName() ~= damage.to:objectName()then		
			if damage.from:isWounded() then
				room:broadcastSkillInvoke("longhun")  --音效
				local recover = sgs.RecoverStruct()
				recover.who = damage.from
				recover.recover = damage.damage
				room:recover(damage.from,recover)
				room:sendCompulsoryTriggerLog(damage.from, "Qinggang", true)
			end
		end
		end
		end
}
]]

Qinggang = sgs.CreateTriggerSkillV2 {
	name = "Qinggang",
	events = { sgs.Damage },
	priority = 2,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.Damage then return false end
		local damage = data:toDamage()
		if damage.from and damage.to
			and damage.from:objectName() == player:objectName()
			and player:hasSkill(skill:objectName())
			and damage.from:objectName() ~= damage.to:objectName()
			and damage.from:isWounded() then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		room:broadcastSkillInvoke("longhun") --音效
		local recover = sgs.RecoverStruct()
		recover.who = damage.from
		recover.recover = damage.damage
		--room:recover(damage.from, recover)
		room:sendCompulsoryTriggerLog(damage.from, "Qinggang", true)
		return false
	end,
}
--攻击距离

luanixi = sgs.CreateAttackRangeSkillV2 {
	name = "luanixi",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local player = ctx:getHolder()
		if player and player:hasSkill("luanixi") then
			return 0
			-- return player:getMark("&fenyong_y") + 4
		end
	end,
}

luanixi_tr = sgs.CreateTriggerSkillV2 {
	name = "#luanixi_tr",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damaged, sgs.DrawNCards, sgs.TurnStart, sgs.RoundStart },
	can_trigger = function(skill, event, room, player, data)
		if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) then
			return false
		end
		if event == sgs.DrawNCards then
			--if player:isWounded() then
			if player:getPhase() ~= sgs.Player_Draw then return false end
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			--end
		end
		return skill:objectName()
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.Damaged then
			local damage = ctx.original_data:toDamage()
			room:broadcastSkillInvoke("longdan") --音效
			player:gainMark("&fenyong_y", damage.damage)
			for i = 1, damage.damage, 1 do
				local x = player:getLostHp()
				if x > 0 then
					room:sendCompulsoryTriggerLog(player, "luanixi", true)
					player:drawCards(x)
				end
			end
			for _, sk in sgs.qlist(player:getVisibleSkillList()) do
				if sk:getFrequency(player) == sgs.Skill_Wake then
					player:setCanWake(sk:objectName(), sk:objectName())
				end
			end
		elseif event == sgs.DrawNCards then
			local draw = ctx.original_data:toDraw()
			-- room:loseHp(player, player:getHp()-1)
			room:sendCompulsoryTriggerLog(player, "luanixi", true)
			draw.num = draw.num + 4
			-- ctx.original_data:setValue(draw)
			room:broadcastSkillInvoke("juejing")
		elseif event == sgs.RoundStart then
			player:gainAnExtraTurn()
		elseif event == sgs.TurnStart then
			-- room:loseHp(player)
			-- room:loseHp(player)
			--room:killPlayer(player)
			--room:playMovie(player,"image/fullskin/generals/full/sunshangxiang.png.gif", 0)
			-- room:doAnimate(2,"skill=Dynamic:yo")
			room:doLightbox("spine=test/XingXiang", 3000, 0)
			player:gainMark("@testing", 1)
			for _, sk in sgs.qlist(player:getVisibleSkillList()) do
				if sk:getFrequency(player) == sgs.Skill_Wake then
					player:setCanWake(sk:objectName(), sk:objectName())
				end
			end

			local ids = sgs.IntList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				for _, card in sgs.qlist(p:getCards("ej")) do
					if card:isKindOf("Slash") then
						ids:append(card:getId())
					end
				end
			end
			for _, id in sgs.qlist(room:getDiscardPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
					ids:append(id)
					break
				end
			end
			for _, id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
					ids:append(id)
					break
				end
			end
			if not ids:isEmpty() then
				-- local id = room:askForAG(player, ids, false, skill:objectName())
				local to_handcard_x = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _, id in sgs.qlist(ids) do
					to_handcard_x:addSubcard(id)
				end
				-- player:obtainCard(to_handcard_x)
				to_handcard_x:deleteLater()
			end
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				-- room:setPlayerChained(p, true)
				-- room:setPlayerProperty(p, "kingdom", sgs.QVariant("wei"))
			end
		end
		return false
	end,
}
luanixi_Keep = sgs.CreateMaxCardsSkillV2 {
	name = "#luanixi_Keep",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local target = ctx:getHolder()
		if target and target:hasSkill(skill:objectName()) then
			return target:getMark("&fenyong_y")
			-- return 0
		else
			return 0
		end
	end,
}

debugchangehero = sgs.CreateTriggerSkillV2 {
	name = "debugchangehero",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.GameReady },
	priority = 100,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local playerlist = room:getOtherPlayers(player) -- 获取所有角色名单
		room:handleAcquireDetachSkills(player, "-debugchangehero", false) -- 失去此技能
		local general_table = {}
		local all = sgs.Sanguosha:getLimitedGeneralNames()
		for _, _general in ipairs(all) do
			if
				(sgs.Sanguosha:getGeneral(_general):getPackage() == "sfofl_e" or sgs.Sanguosha:getGeneral(_general):getPackage() == "sfofl_s")
				or sgs.Sanguosha:getGeneral(_general):getPackage() == "sfofl_gai"
				or sgs.Sanguosha:getGeneral(_general):getPackage() == "sfofl_war"
			then
				table.insert(general_table, _general)
			end
		end
		for _, play in sgs.qlist(playerlist) do -- 对名单中的所有角色进行扫描
			local start = false
			if play:getSeat() < player:getSeat() then -- 座位在自己之前，需重新进行游戏开始
				start = true
			end

			local new_general = room:askForGeneral(play, table.concat(general_table, "+")) -- 选将
			room:changeHero(play, new_general, true, start, false, true) -- 变身
			table.removeOne(general_table, new_general) -- 移除
			local General2Name = play:getGeneral2Name()
			if General2Name and General2Name ~= "" then -- 副将
				local new_general = room:askForGeneral(play, table.concat(general_table, "+")) -- 选将
				room:changeHero(play, new_general, true, start, true, true) -- 变身
				table.removeOne(general_table, new_general) -- 移除
			end
		end
		return false
	end,
}

-- gz_zhaoyun:addSkill(Qinggang)
-- gz_zhaoyun:addSkill(debugchangehero)
gz_zhaoyun:addSkill(Qinggangex)
-- extension:insertRelatedSkills("Qinggang", "#Qinggangex")
gz_zhaoyun:addSkill(luanixi) --攻击距离
gz_zhaoyun:addSkill(luanixi_tr)
gz_zhaoyun:addSkill(luanixi_Keep)
extension:insertRelatedSkills("luanixi", "#luanixi_tr")
-- gz_zhaoyun:addSkill("dangxian")
gz_zhaoyun:addSkill("bahu")
gz_zhaoyun:addSkill("feiyang")
-- gz_zhaoyun:addSkill("keolbotu")
-- gz_zhaoyun:addSkill("lianpo")
-- gz_zhaoyun:addSkill("jiansu")
-- gz_zhaoyun:addSkill("new_sgkgodyoulong")
-- gz_zhaoyun:addSkill("tuntian")
--gz_zhaoyun:addSkill("wusheng")
-- gz_zhaoyun:addSkill("qicai")
-- gz_zhaoyun:addSkill("sfofl_zhonghu")
-- gz_zhaoyun:addSkill("s_w_juling")

extension:insertRelatedSkills("luanixi", "#luanixi_Keep")

debug_skill = sgs.CreateTriggerSkillV2 {
	name = "debug_skill",
	events = { sgs.GameStart },
	global = true,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.GameStart then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local owner = room:getOwner()
		if owner and owner:isAlive() then
			room:acquireSkill(owner, "bahu")
			room:acquireSkill(owner, "feiyang")
			room:acquireSkill(owner, "#luanixi_tr")
		end
		return false
	end,
}
--extension:addSkills(debug_skill)

sgs.LoadTranslationTable {
	["#gz_zhaoyun"] = "白马先锋",
	["gz_zhaoyun"] = "☆赵云",
	["Qinggang"] = "青釭",
	["$Qinggang"] = "(拔剑声)",
	[":Qinggang"] = '<font color="blue"><b>锁定技，</b></font>你使用的【杀】无视目标角色的防具。你对其他角色造成伤害时，回复相应体力。',
	["fenyong_y"] = "勇",
	["luanixi"] = "逆袭",
	[":luanixi"] = '<font color="blue"><b>锁定技，</b></font>摸牌阶段额外摸X张牌.你每受到1点伤害，你摸X张牌(X为你已损体力值)，同时你获得1枚勇标记，每有1枚勇标记，你的攻击范围+1，手牌上限+1。',
}
return { extension }
