extension = sgs.Package("YY")

--赵云
gz_zhaoyun = sgs.General(extension, "gz_zhaoyun", "qun", 4, true, true, false, 3, 2)
Qinggangex = sgs.CreateViewAsEquipSkill {
	name = "#Qinggangex",
	view_as_equip = function(self, player)
		return "silver_lion"
	end
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

Qinggang = sgs.CreateTriggerSkill {
	name = "Qinggang",
	events = { sgs.Damage },
	priority = 2,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from:hasSkill(self:objectName()) and damage.from:objectName() ~= damage.to:objectName() then
				if damage.from:isWounded() then
					room:broadcastSkillInvoke("longhun") --音效
					local recover = sgs.RecoverStruct()
					recover.who = damage.from
					recover.recover = damage.damage
					--room:recover(damage.from, recover)
					room:sendCompulsoryTriggerLog(damage.from, "Qinggang", true)
				end
			end
		end
	end
}
--攻击距离


luanixi = sgs.CreateAttackRangeSkill {
	name = "luanixi",
	extra_func = function(self, player, include_weapon)
		if player:hasSkill("luanixi") then
			return 0
			-- return player:getMark("&fenyong_y") + 4
		end
	end,
}

luanixi_tr = sgs.CreateTriggerSkill {
	name = "#luanixi_tr",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damaged, sgs.DrawNCards, sgs.TurnStart, sgs.RoundStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			room:broadcastSkillInvoke("longdan") --音效
			player:gainMark("&fenyong_y", damage.damage);
			for i = 1, damage.damage, 1 do
				local x = player:getLostHp()
				if x > 0 then
					room:sendCompulsoryTriggerLog(player, "luanixi", true)
					-- player:drawCards(x)
				end
			end
			for _, skill in sgs.qlist(player:getVisibleSkillList()) do
				if skill:getFrequency(player) == sgs.Skill_Wake then
					player:setCanWake(skill:objectName(), skill:objectName())
				end
			end
		elseif event == sgs.DrawNCards then
			--if player:isWounded() then
			if player:getPhase() == sgs.Player_Draw then
				local draw = data:toDraw()
				if draw.reason ~= "draw_phase" then return false end
				-- room:loseHp(player, player:getHp()-1)
				room:sendCompulsoryTriggerLog(player, "luanixi", true)
				draw.num = draw.num + 4
				-- data:setValue(draw)
				room:broadcastSkillInvoke("juejing")
				
			end
			--end
		elseif event == sgs.RoundStart then
			player:gainAnExtraTurn()
		elseif event == sgs.TurnStart then
			-- room:loseHp(player)
			-- room:loseHp(player)
			--room:killPlayer(player)
			--room:playMovie(player,"image/fullskin/generals/full/sunshangxiang.png.gif", 0)
			room:doAnimate(2,"skill=Dynamic:yo")
			for _, skill in sgs.qlist(player:getVisibleSkillList()) do
				if skill:getFrequency(player) == sgs.Skill_Wake then
					player:setCanWake(skill:objectName(), skill:objectName())
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
				-- local id = room:askForAG(player, ids, false, self:objectName())
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
	end
}
luanixi_Keep = sgs.CreateMaxCardsSkill {
	name = "#luanixi_Keep",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return target:getMark("&fenyong_y")
			-- return 0
		else
			return 0
		end
	end
}

jibian = sgs.CreateTriggerSkill {
	name = "jibian",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.HpChanged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		--if not room:askForSkillInvoke(player,self:objectName(),data) then return end
		--if player:getHandcardNum()>player:getHp() then
		--	player:drawCards(1)
		--	room:askForDiscard(player,self:objectName(),1,1,false,false)
		--else
		--	local x=math.min(7,player:getMaxHp()-player:getHandcardNum())	
		--	player:drawCards(x)
		--end
		if player:getHandcardNum() < player:getHp() then
			local x = math.min(7, player:getMaxHp() - player:getHandcardNum())
			player:drawCards(x)
		end
	end
}

function getQhGeneral()
    local new_generaltable = {}
    local n = 0
    for i = 1, 30 do
        local name = general_table[math.random(1, #general_table)]
        if not table.contains(new_generaltable, name) then -- 不包含
            table.insert(new_generaltable, name)
            n = n + 1                                      -- 计数
            if n == 7 then
                break                                      -- 终止循环
            end
        end
    end
    return new_generaltable
end

debugchangehero = sgs.CreateTriggerSkill {
    name = "debugchangehero",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.GameReady },
    priority = 100,
    on_trigger = function(self, event, player, data, room)
        local playerlist = room:getOtherPlayers(player)                                -- 获取所有角色名单
        room:handleAcquireDetachSkills(player, "-debugchangehero", false) -- 失去此技能
		local general_table = {}
		local all = sgs.Sanguosha:getLimitedGeneralNames()
		for _, _general in ipairs(all) do
			if (sgs.Sanguosha:getGeneral(_general):getPackage() == "sfofl_e" 
			or sgs.Sanguosha:getGeneral(_general):getPackage() == "sfofl_s") 
			or sgs.Sanguosha:getGeneral(_general):getPackage() == "sfofl_gai" 
			or sgs.Sanguosha:getGeneral(_general):getPackage() == "sfofl_war" 
			then table.insert(general_table, _general) end
		end
        for _, play in sgs.qlist(playerlist) do                                -- 对名单中的所有角色进行扫描
            local start = false
            if play:getSeat() < player:getSeat() then                          -- 座位在自己之前，需重新进行游戏开始
                start = true
            end
			
            local new_general = room:askForGeneral(play, table.concat(general_table, "+"))     -- 选将
            room:changeHero(play, new_general, true, start, false, true)                          -- 变身
            table.removeOne(general_table, new_general)                                           -- 移除
            local General2Name = play:getGeneral2Name()
            if General2Name and General2Name ~= "" then                                           -- 副将
                local new_general = room:askForGeneral(play, table.concat(general_table, "+")) -- 选将
                room:changeHero(play, new_general, true, start, true, true)                       -- 变身
                table.removeOne(general_table, new_general)                                       -- 移除
            end
        end
    end
}

--gz_zhaoyun:addSkill(jibian)
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

extension:insertRelatedSkills("luanixi","#luanixi_Keep")

debug_skill = sgs.CreateTriggerSkill{
	name = "debug_skill",
	events = {sgs.GameStart},
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			local owner = room:getOwner()
			if owner and owner:isAlive() then
				room:acquireSkill(owner, "bahu")
				room:acquireSkill(owner, "feiyang")
				room:acquireSkill(owner, "#luanixi_tr")
			end
		end
	end
}
extension:addSkills(debug_skill)


sgs.LoadTranslationTable {
	["#gz_zhaoyun"] = "白马先锋",
	["gz_zhaoyun"] = "☆赵云",
	["Qinggang"] = "青釭",
	["$Qinggang"] = "(拔剑声)",
	[":Qinggang"] = "<font color=\"blue\"><b>锁定技，</b></font>你使用的【杀】无视目标角色的防具。你对其他角色造成伤害时，回复相应体力。",
	["fenyong_y"] = "勇",
	["luanixi"] = "逆袭",
	[":luanixi"] = "<font color=\"blue\"><b>锁定技，</b></font>摸牌阶段额外摸X张牌.你每受到1点伤害，你摸X张牌(X为你已损体力值)，同时你获得1枚勇标记，每有1枚勇标记，你的攻击范围+1，手牌上限+1。",
	["jibian"] = "机变",
	[":jibian"] = "当你的体力值发生变动时，若手牌数小于你的当前体力值，你可令手牌补将手牌补至X张（X为你的体力上限）。",
}
return { extension }
