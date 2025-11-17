--[[英雄联盟穿越包]]--
module("extensions.legends", package.seeall)
extension = sgs.Package("legends", sgs.Package_GeneralPack)  --武将包
extension_card = sgs.Package("legends_card", sgs.Package_CardPack)  --卡牌包
sgs.Sanguosha:addPackage(extension_card)  --整合武将包和卡牌包
sgs.LoadTranslationTable{
    ["legends"] = "英雄联盟",
	["legends_card"] = "英雄联盟",
}
local skills = sgs.SkillList()  --定义非列表技能表
Table2IntList = function(theTable)  --杀不能闪的前提
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

--英雄
--德玛西亚皇子·嘉文四世
JarvanIV = sgs.General(extension, "JarvanIV$", "shu", "4", true, false, false)
lvdong = sgs.CreateTriggerSkill{
	name = "lvdong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.chain or damage.transfer or not damage.by_user then
			return false
		end
		if damage.to:getMark("@lvdong") == 0 then
		local dest = sgs.QVariant()
		dest:setValue(damage.to)
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local count = damage.damage
				local msg = sgs.LogMessage()
				msg.type = "#lvdong"
				msg.from = damage.from
				msg.to:append(damage.to)
				msg.arg = count
				count = count + 1
				msg.arg2 = count
				room:sendLog(msg) --发送提示信息
				room:broadcastSkillInvoke("lvdong") --播放配音
				damage.damage = count
				data:setValue(damage)
				damage.to:gainMark("@lvdong", 1)
				room:setPlayerCardLimitation(damage.to, "use", "Armor,DefensiveHorse", false)
			end
		end
	end
}
tulong = sgs.CreateTriggerSkill{
	name = "tulong$", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		local JarvanIVs = sgs.SPlayerList()
		if damage then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasLordSkill(self:objectName()) then
					JarvanIVs:append(p)
				end
			end
		end
		while not JarvanIVs:isEmpty() do
			local JarvanIV = room:askForPlayerChosen(player, JarvanIVs, self:objectName(), "@tulong-to", true)
			if JarvanIV then
				room:broadcastSkillInvoke("tulong")
				JarvanIV:drawCards(1, self:objectName())
				JarvanIVs:removeOne(JarvanIV)
			else
				break
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target and (target:getKingdom() == "shu")
	end
}
pojia_lol = sgs.CreateProhibitSkill{ 
	name = "pojia_lol",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("Armor") or card:isKindOf("DefensiveHorse"))
	end
}
if not sgs.Sanguosha:getSkill("pojia_lol") then skills:append(pojia_lol) end 
JarvanIV:addSkill(lvdong)
JarvanIV:addSkill(tulong)
sgs.LoadTranslationTable{
	["JarvanIV"] = "嘉文四世",
	["&JarvanIV"] = "嘉文四世",
	["#JarvanIV"] = "德玛西亚皇子",
	["~JarvanIV"] = "我……还不能死……",

	["lvdong"] = "律动",
	[":lvdong"] = "当你对一名角色造成伤害时，你可令此伤害+1（每名角色每局游戏限一次），然后该角色不可使用防具和防御马直到游戏结束。",
	["@lvdong"] = "律",
	["#lvdong"] = "因 %from 的“<font color=\"yellow\"><b>律动</b></font>”效果，%to 受到的伤害从 %arg 点上升至 %arg2 点。",
	["$lvdong"] = "犯我德邦者，虽远必诛！",
	
	["tulong"] = "屠龙",
	[":tulong"] = "<font color=\"orange\"><b>主公技，</b></font>其他蜀势力的角色每造成一次伤害，可令你摸一张牌。",
	["@tulong-to"] = "请选择“屠龙”的目标角色",
	["$tulong"] = "谁敢违抗我的意志？",
	
	["pojia_lol"] = "破甲",
	[":pojia_lol"] = "<font color=\"blue\"><b>锁定技，</b></font>拥有“律”标记的角色不能使用防具或防御马。",
}

--德玛西亚之力·盖伦
Garen = sgs.General(extension, "Garen", "shu", "4", true, false, false)
lol_zhiming = sgs.CreateTriggerSkill{
	name = "lol_zhiming",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			if p:getHp() < player:getHp() then
				if player:distanceTo(p) <= 1 then
					local room = player:getRoom()
					local msg = sgs.LogMessage()
					msg.type = "#lol_zhiming"
					msg.from = player
					msg.to:append(p)
					room:sendLog(msg)
					room:broadcastSkillInvoke("lol_zhiming", math.random(1, 2))
					local _data = sgs.QVariant()
					_data:setValue(p)
					jink_table[index] = 0
				end
			end
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	end
}
yongqi = sgs.CreateTriggerSkill{
	name = "yongqi",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				for _, hero in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					hero:addMark("yong")
				end
			end
		elseif event == sgs.TargetConfirmed then
			if player and player:isAlive() and player:hasSkill(self:objectName()) then
				local use = data:toCardUse()
				if use.to:contains(player) and (use.from:objectName() ~= player:objectName()) then
					if use.card:isKindOf("Slash") or use.card:isKindOf("TrickCard") then
						player:setMark("yong", 0)
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, hero in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if hero:getMark("yong") > 0 then
						hero:setMark("yong", 0)
						hero:gainMark("@yongqi")
					end
					if hero:getMark("@yongqi") >= 5 then
						hero:loseAllMarks("@yongqi")
						if hero:isWounded() then
							local msg = sgs.LogMessage()
							msg.type = "#yongqiEffect1"
							msg.from = hero
							room:sendLog(msg)
							room:broadcastSkillInvoke("yongqi", math.random(1, 2))
							local recover = sgs.RecoverStruct()
							recover.who = hero
							room:recover(hero, recover)
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}
lol_zhengyiCard = sgs.CreateSkillCard{
	name = "lol_zhengyiCard",
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() or (#targets == 1) then
			return false
		end
		return sgs.Self:inMyAttackRange(to_select)
	end,
	on_use = function(self, room, source, targets)
		room:doLightbox("$lol_zhengyiQP")
		source:loseMark("@lol_zhengyi")
		for _,p in pairs(targets) do
			local hurt = math.max(1, p:getLostHp())
			local damage = sgs.DamageStruct()
			damage.reason = "lol_zhengyi"
			damage.from = source
			damage.to = p
			damage.damage = hurt
			room:damage(damage)
			room:broadcastSkillInvoke("lol_zhengyi", math.random(1, 2))
		end
	end
}
lol_zhengyiVS = sgs.CreateZeroCardViewAsSkill{
	name = "lol_zhengyi",
	view_as = function()
		return lol_zhengyiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@lol_zhengyi") > 0
	end
}
lol_zhengyi = sgs.CreateTriggerSkill{
	name = "lol_zhengyi",
	frequency = sgs.Skill_Limited,
	limit_mark = "@lol_zhengyi",
	events = {sgs.GameStart},
	view_as_skill = lol_zhengyiVS,
	on_trigger = function(self, event, player, data)
	end
}
Garen:addSkill(lol_zhiming)
Garen:addSkill(yongqi)
Garen:addSkill(lol_zhengyi)
sgs.LoadTranslationTable{
	["Garen"] = "盖伦",
	["&Garen"] = "盖伦",
	["#Garen"] = "德玛西亚之力",
	["~Garen"] = "",

	["lol_zhiming"] = "致命",
	[":lol_zhiming"] = "<font color=\"blue\"><b>锁定技，</b></font>你对距离1以内的角色使用【杀】时，若其体力值少于你，则此【杀】不可闪避。",
	["#lol_zhiming"] = "%from 的“<font color=\"yellow\"><b>致命</b></font>”被触发，%to 不能使用【<font color=\"yellow\"><b>闪</b></font>】响应此【<font color=\"yellow\"><b>杀</b></font>】",
	["$lol_zhiming1"] = "",
	["$lol_zhiming2"] = "",
	
	["yongqi"] = "勇气",
	[":yongqi"] = "<font color=\"blue\"><b>锁定技，</b></font>一名角色回合结束时，若你于此回合没有成为【杀】或锦囊牌的目标，你获得一枚“勇气”标记；当“勇气”标记达到5枚或更多时，弃置这些标记，然后若你已受伤，你回复1点体力。",--当你受到一次不小于2点的伤害时，此伤害-1。
	["@yongqi"] = "勇气",
	["#yongqiEffect1"] = "%from 的“<font color=\"yellow\"><b>勇气</b></font>”标记达到5枚，回复1点体力",
	["#yongqiEffect2"] = "%from 的“<font color=\"yellow\"><b>勇气</b></font>”被触发，%from 受到的伤害从 %arg 点下降到 %arg2 点",
	["$yongqi1"] = "",
	["$yongqi2"] = "",
	
	["lol_zhengyi"] = "正义",
	["lol_zhengyiCard"] = "正义",
	[":lol_zhengyi"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你选择攻击范围内的一名角色，对其造成X点伤害（X为该角色已失去的体力值且至少为1）。",
	["@lol_zhengyi"] = "正义",
	["$lol_zhengyiQP"] = "正义",
}

--德邦总管·赵信
XinZhao = sgs.General(extension, "XinZhao", "shu", "4", true, false, false)
chongfeng = sgs.CreateViewAsSkill{
	name = "chongfeng" ,
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
	end ,
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		local slash = sgs.Sanguosha:cloneCard("Slash", sgs.Card_SuitToBeDecided, 0)
		slash:setSkillName(self:objectName())
		slash:addSubcard(cards[1])
		slash:addSubcard(cards[2])
		return slash
	end ,
	enabled_at_play = function(self, player)
		return (player:getHandcardNum() >= 2) and sgs.Slash_IsAvailable(player)
	end ,
	enabled_at_response = function(self, player, pattern)
		return (player:getHandcardNum() >= 2) and (pattern == "slash")
	end
}
chongfengMod = sgs.CreateTargetModSkill{
	name = "#chongfengMod",
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player:hasSkill("chongfeng") and (card:getSkillName() == "chongfeng") then
			return 1000
		end
	end,
}
extension:insertRelatedSkills("chongfeng", "#chongfengMod")
wuwei = sgs.CreateTriggerSkill{
	name = "wuwei",
	events = {sgs.Damage, sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") then
			local target
			if event == sgs.Damage then
				target = damage.to
			elseif event == sgs.Damaged then
				target = damage.from
			end
			if target:isAlive() and damage.to ~= damage.from then
				local dest = sgs.QVariant()
				dest:setValue(target)
				if room:askForCard(player, ".", "@wuweidis:", dest, sgs.CardDiscarded) then
					room:broadcastSkillInvoke("wuwei", math.random(1, 2))
					local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
					duel:setSkillName(self:objectName())
					duel:deleteLater()
					local use = sgs.CardUseStruct()
					use.card = duel
					use.from = player
					use.to:append(target)
					room:useCard(use)
				end
			end
		end
		return false
	end,
}
XinZhao:addSkill(chongfeng)
XinZhao:addSkill(chongfengMod)
XinZhao:addSkill(wuwei)
sgs.LoadTranslationTable{
	["XinZhao"] = "赵信",
	["&XinZhao"] = "赵信",
	["#XinZhao"] = "德邦总管",
	["~XinZhao"] = "",
	
	["chongfeng"] = "冲锋",
	[":chongfeng"] = "你可以将两张花色相同的手牌当一张不受距离限制的【杀】使用或打出。",--，且若此【杀】造成伤害，你回复1点体力。",

	["wuwei"] = "无畏",
	[":wuwei"] = "每当你使用或受到【杀】造成的伤害后，你可以弃置一张手牌，视为你对目标角色或伤害来源使用一张【决斗】。",
	["@wuweidis"] = "你可以弃置一张手牌来发动“无畏”",
}

--无双剑姬·菲奥娜
Fiora = sgs.General(extension, "Fiora", "shu", "4", false, false, false)
xinyan = sgs.CreateTriggerSkill{
	name = "xinyan" ,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Pindian, sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local from = use.from
			if use.card and use.card:isKindOf("Slash") and (not from:isKongcheng()) and (not player:isKongcheng()) then
				if use.to:contains(player) then
					room:setTag("xinyan", data)
					if room:askForSkillInvoke(player, self:objectName(), data) then
						local success = player:pindian(from, self:objectName(), nil)
						if success then
							local nullified_list = use.nullified_list
							table.insert(nullified_list, player:objectName())
							use.nullified_list = nullified_list
							data:setValue(use)
						end
					end
					room:removeTag("xinyan")
				end
			end
		elseif event == sgs.Pindian then
			local pindian = data:toPindian()
			if (pindian.reason == self:objectName() and pindian.success) then
				if pindian.to_card:getSuit() == pindian.from_card:getSuit() then
					local damage = data:toDamage()
					local msg = sgs.LogMessage()
					msg.type = "#xinyanEffect2"
					msg.from = pindian.from
					msg.to:append(pindian.to)
					room:sendLog(msg)
					room:broadcastSkillInvoke("xinyan", 2)
					room:damage(sgs.DamageStruct("xinyan", pindian.from, pindian.to))  --花色相同造成伤害
				end
			end
		end
	end
}
daren = sgs.CreateTriggerSkill{
	name = "daren" ,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused, sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local reason = damage.card
		if damage.chain or damage.transfer then return false end
		if reason then
			if reason:isKindOf("Duel") then
				if player:hasSkill(self:objectName()) then
					if event == sgs.DamageCaused then
						local msg = sgs.LogMessage()
						msg.type = "#darenEffect1"
						msg.from = player
						room:sendLog(msg)
						room:broadcastSkillInvoke("daren", 1)
						if player:isWounded() then
							local recover = sgs.RecoverStruct()
							recover.who = player
							room:recover(player, recover)
						end
						player:drawCards(1, self:objectName())
					elseif event == sgs.DamageInflicted then
						local msg = sgs.LogMessage()
						msg.type = "#darenEffect2"
						msg.to:append(damage.to)
						room:sendLog(msg)
						room:broadcastSkillInvoke("daren", 2)
						damage.prevented = true
						data:setValue(damage)
						return true
					end
				end
			end
		end
	end
}
pokong = sgs.CreateTriggerSkill{
	name = "pokong", 
	frequency = sgs.Skill_Wake, 
	events = {sgs.EventPhaseStart}, 
	waked_skills = "jianwu",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:doLightbox("$pokongQP")
		local msg = sgs.LogMessage()
		msg.type = "#pokong"
		msg.from = player
		room:sendLog(msg)
		room:broadcastSkillInvoke("pokong")
		room:setPlayerMark(player, "pokong", 1)
		room:changeMaxHpForAwakenSkill(player, -1, self:objectName())
		room:acquireSkill(player, "jianwu")
		room:acquireSkill(player, "#jianwuMod")		
		return false
	end, 
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		local can_invoke = true
		local list = room:getOtherPlayers(player)
		for _,p in sgs.qlist(list) do
			if not player:inMyAttackRange(p) then
				can_invoke = false
				break
			end
		end
		if can_invoke then
			return true
		end
		return false
	end,
}
jianwu = sgs.CreateTriggerSkill{
	name = "jianwu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local card
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponded then
			card = data:toCardResponse().m_card
		end
		if card and card:isKindOf("Slash") then
			if player:askForSkillInvoke(self:objectName()) then
				local room = player:getRoom()
				room:broadcastSkillInvoke("jianwu")
				player:drawCards(1, self:objectName())
			end
		end
		return false
	end
}
jianwuMod = sgs.CreateTargetModSkill{
	name = "#jianwuMod",
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player:hasSkill("jianwu") and card:isRed() then
			return 1000
		end
	end,
	residue_func = function(self, player)
		if player:hasSkill("jianwu") then
			return 1
		else
			return 0
		end
	end
}
extension:insertRelatedSkills("jianwu", "#jianwuMod")
if not sgs.Sanguosha:getSkill("jianwu") then skills:append(jianwu) end 
if not sgs.Sanguosha:getSkill("#jianwuMod") then skills:append(jianwuMod) end 
Fiora:addSkill(xinyan)
Fiora:addSkill(daren)
Fiora:addSkill(pokong)
sgs.LoadTranslationTable{
	["Fiora"] = "菲奥娜",
	["&Fiora"] = "菲奥娜",
	["#Fiora"] = "无双剑姬",

	["xinyan"] = "心眼",
	[":xinyan"] = "当你成为【杀】的目标后，你可以和对方拼点：若你赢，此【杀】对你无效，然后若2张拼点牌花色相同，你对其造成1点伤害。",
	["#xinyanEffect1"] = "%from 拼点胜利，此【<font color=\"yellow\"><b>杀</b></font>】对 %from 无效",
	["#xinyanEffect2"] = "因 2 张拼点牌花色相同，%to 受到 %from 造成的 <font color=\"yellow\"><b>1</b></font> 点伤害",

	["daren"] = "达人",
	[":daren"] = "<font color=\"blue\"><b>锁定技，</b></font>当你【决斗】胜利时，你回复1点体力并摸1张牌；你不会受到【决斗】造成的伤害。",
	["#darenEffect1"] = "%from 决斗胜利，回复 <font color=\"yellow\"><b>1</b></font> 点体力并摸 <font color=\"yellow\"><b>1</b></font> 张牌",
	["#darenEffect2"] = "%to 的“<font color=\"yellow\"><b>达人</b></font>”被触发，%to 不会受到【<font color=\"yellow\"><b>决斗</b></font>】造成的伤害",

	["pokong"] = "破空",
	[":pokong"] = "<font color=\"purple\"><b>觉醒技，</b></font>回合开始阶段，若所有其他角色均在你攻击范围内，你减少1点体力值上限并永久获得技能“剑舞”。",
	["#pokong"] = "%from 符合觉醒条件，失去 <font color=\"yellow\"><b>1</b></font> 点体力值上限并获得技能“<font color=\"yellow\"><b>剑舞</b></font>”",
	["$pokongQP"] = "破空",
	
	["jianwu"] = "剑舞",
	[":jianwu"] = "当你使用或打出一张【杀】时，你可以摸一张牌；你使用的红色【杀】无距离限制；出牌阶段，你可以额外使用一张【杀】。",
}

--众星之子·索拉卡
Soraka = sgs.General(extension, "Soraka", "shu", "3", false, false, false)
lol_jiushuCard = sgs.CreateSkillCard{
	name = "lol_jiushuCard",
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() or (#targets == 1) then
			return false
		end
		return to_select:isWounded()
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:broadcastSkillInvoke("jiushu", math.random(1, 2))
		room:loseHp(source)
		local recover = sgs.RecoverStruct()
		recover.who = target
		room:recover(target, recover)
		source:drawCards(1, "lol_jiushu")
	end
}
lol_jiushu = sgs.CreateZeroCardViewAsSkill{
	name = "lol_jiushu",
	view_as = function()
		return lol_jiushuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getHp() > 1
	end
}
guanzhuCard = sgs.CreateSkillCard{
	name = "guanzhuCard", 
	target_fixed = false, 
	will_throw = false,
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() then
			return false
		end
		return #targets == 0
	end,
	on_effect = function(self, effect) 
		local dest = effect.to
		local source = effect.from
		local room = dest:getRoom()
		dest:obtainCard(self)
		if self:getSuit() == sgs.Card_Spade then
			local damage = sgs.DamageStruct()
			damage.reason = "guanzhu"
			damage.from = source
			damage.to = dest
			room:damage(damage)
			room:broadcastSkillInvoke("guanzhu", 1)
		elseif self:getSuit() == sgs.Card_Heart then
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(source, recover)
			room:broadcastSkillInvoke("guanzhu", 2)
		else
			room:broadcastSkillInvoke("guanzhu", 3)
		end
	end
}
guanzhu = sgs.CreateViewAsSkill{
	name = "guanzhu", 
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local uscard = guanzhuCard:clone()
			uscard:addSubcard(card)
			return uscard
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#guanzhuCard")
	end
}
lol_qiyuanCard = sgs.CreateSkillCard{
	name = "lol_qiyuanCard",
	filter = function(self, targets, to_select)
		return to_select:isWounded()
	end,
	on_use = function(self, room, source, targets)
		room:doLightbox("$lol_qiyuanQP")
		source:loseMark("@lol_qiyuan_l")
		room:broadcastSkillInvoke("lol_qiyuan", math.random(1, 2))
		for _,p in pairs(targets) do
			local recover = sgs.RecoverStruct()
			recover.who = p
			room:recover(p, recover)
		end
	end
}
lol_qiyuanVS = sgs.CreateZeroCardViewAsSkill{
	name = "lol_qiyuan",
	view_as = function()
		return lol_qiyuanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@lol_qiyuan_l") > 0
	end
}
lol_qiyuan = sgs.CreateTriggerSkill{
	name = "lol_qiyuan",
	frequency = sgs.Skill_Limited,
	limit_mark = "@lol_qiyuan_l",
	events = {sgs.GameStart},
	view_as_skill = lol_qiyuanVS,
	on_trigger = function(self, event, player, data)
	end
}
Soraka:addSkill(lol_jiushu)
Soraka:addSkill(guanzhu)
Soraka:addSkill(lol_qiyuan)
sgs.LoadTranslationTable{
	["Soraka"] = "索拉卡",
	["&Soraka"] = "索拉卡",
	["#Soraka"] = "众星之子",

	["lol_jiushu"] = "救赎",
	["jiushuCard"] = "救赎",
	[":lol_jiushu"] = "出牌阶段，若你的体力值大于1，你可以自减1点体力令一名已受伤的其他角色回复1点体力，然后你摸一张牌。",

	["guanzhu"] = "贯注",
	["guanzhuCard"] = "贯注",
	[":guanzhu"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张手牌交给一名其他角色。然后若此牌为♠，你对该角色造成1点伤害；若为<font color=\"red\">♥</font>，你回复1点体力。",

	["lol_qiyuan"] = "祈愿",
	["lol_qiyuanCard"] = "祈愿",
	[":lol_qiyuan"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以指定任意名已受伤的角色各回复1点体力。",
	["@lol_qiyuan_l"] = "祈愿",
	["$lol_qiyuanQP"] = "祈愿",
}

--刀锋意志·艾瑞莉娅
Irelia = sgs.General(extension, "Irelia", "shu", "4", false, false, false)
recheng = sgs.CreateProhibitSkill{
	name = "recheng",
	is_prohibited = function(self, from, to, card)
		if to:hasSkill(self:objectName()) then
			if to:getJudgingArea():length() > 0 then
				return card:isKindOf("DelayedTrick")
			end
		end
	end
}
function ChangeToVSCard(skillcard) --自定义函数，用于根据技能卡的子卡构成产生视为的卡牌，参数skillcard为技能卡
	local subcards = skillcard:getSubcards() --获取此技能卡的子卡列表
	local id = subcards:first() --第一张子卡的编号（其实此技能卡只有此一张子卡）
	local card = sgs.Sanguosha:getCard(id) --根据子卡编号找到用于发动技能的子卡卡牌
	local suit = card:getSuit() --用于发动技能的卡牌的花色
	local point = card:getNumber() --用于发动技能的卡牌的点数
	local vs_card = nil --将视为的卡牌（可能是乐不思蜀，也可能是兵粮寸断，要根据花色随后确定）
	if card:isRed() then --如果用于发动技能的卡牌是红色牌
		vs_card = sgs.Sanguosha:cloneCard("indulgence", suit, point) --产生一张视为的乐不思蜀
	elseif card:isBlack() then --如果用于发动技能的卡牌是黑色牌
		vs_card = sgs.Sanguosha:cloneCard("supply_shortage", suit, point) --产生一张视为的兵粮寸断
	end
	if vs_card then --如果产生了视为的卡牌
		vs_card:addSubcard(id) --为此视为的卡牌添加子卡（子卡应为用于发动技能的卡牌）
		vs_card:setSkillName("junheng") --设置技能名，说明此视为的卡牌是通过"junheng"技能产生的
	end
	return vs_card --将视为的卡牌作为此自定义函数的结果返回
end
junhengCard = sgs.CreateSkillCard{ --技能卡
	name = "junhengCard", --技能卡的名字
	target_fixed = false, --技能卡是否不需要指定目标（乐不思蜀和兵粮寸断都需要指定一名角色作为目标，所以这里填false）
	will_throw = false, --技能卡使用后是否置入弃牌堆（因为子卡将被视为延时性锦囊进入目标角色的判定区，所以填false）
	filter = function(self, targets, to_select) --判断一名角色to_select是否可以作为此技能卡self的目标
		local card = ChangeToVSCard(self) --利用自定义函数产生视为的卡牌（可能是乐不思蜀也可能是兵粮寸断）
		if card then --如果成功产生了视为的卡牌
			if to_select:getHp() >= sgs.Self:getHp() then --如果待判断的角色to_select的体力值不少于自己sgs.Self的体力值
				local selected = sgs.PlayerList() --以下四行，将table类型的targets转化为sgs.PlayerList类型，
				for _,p in ipairs(targets) do --因为接下来需要利用targetFilter判断to_select是否可以作为card的目标，
					selected:append(p) --要提前做好准备。
				end
				return card:targetFilter(selected, to_select, sgs.Self) --交给card进行具体的判断
			end
		end
		return false
	end,
	feasible = function(self, targets) --判断技能卡self的使用目标是否已经选择完毕
		local card = ChangeToVSCard(self) --同上，利用自定义函数产生视为的卡牌
		if card then
			local selected = sgs.PlayerList() --同上，以下四行，将table类型的targets转化为sgs.PlayerList类型
			for _,p in ipairs(targets) do
				selected:append(p)
			end
			return card:targetsFeasible(selected, sgs.Self) --交给card进行具体的判断
		end
		return false
	end,
	on_validate = function(self, use) --在使用前产生具体的卡牌代替原有技能卡
		local source = use.from --从卡牌使用结构体use中取得技能卡的使用者，也就是自己
		local room = source:getRoom() --找出当前房间
		room:broadcastSkillInvoke("junheng") --播放配音。其实以上三句只是为了产生音效，完全可以不写
		return ChangeToVSCard(self) --利用自定义函数产生视为的卡牌
		--至此，视为的卡牌已被改变。原先用于发动技能的卡牌被视作了技能卡，而现在则被视作了新产生的延时性锦囊牌
	end,
}
junheng = sgs.CreateViewAsSkill{ --视为技
	name = "junheng", --视为技的名字
	n = 1, --发动视为技所需要的最大卡牌数目
	response_or_use = true,
	view_filter = function(self, selected, to_select) --判断卡牌to_select是否可以被选来发动技能self
		return not to_select:isEquipped() --如果待判断的卡牌to_select没有被装备（意味着是手牌）则可以被选择
	end,
	view_as = function(self, cards) --利用所有已选择的卡牌cards根据此视为技self产生被视作的卡牌
		if #cards == 1 then --如果恰好选择了一张卡牌
			local card = junhengCard:clone() --产生一张技能卡（以作为被视作的卡牌）
			card:addSubcard(cards[1]) --为此技能卡添加子卡（子卡即被选出的用于发动技能的卡牌）
			return card --将此技能卡作为被视作的卡牌返回
		end
	end,
}
zhizun = sgs.CreateTriggerSkill{
	name = "zhizun", 
	frequency = sgs.Skill_Wake, 
	events = {sgs.EventPhaseStart}, 
	waked_skills = "lol_liren",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:doLightbox("$zhizunQP")
		local msg = sgs.LogMessage()
		msg.type = "#zhizun"
		msg.from = player
		room:sendLog(msg)
		room:broadcastSkillInvoke("zhizun")
		room:setPlayerMark(player, "zhizun", 1)
		room:changeMaxHpForAwakenSkill(player, -1, self:objectName())
		room:acquireSkill(player, "lol_liren")
		return false
	end, 
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		local can_invoke = true
		local list = room:getOtherPlayers(player)
		for _,p in sgs.qlist(list) do
			if player:getEquips():length() <= p:getEquips():length() then
				can_invoke = false
				break
			end
		end
		if can_invoke then
			return true
		end
		return false
	end,
}
lol_lirenCard = sgs.CreateSkillCard{
	name = "lol_lirenCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:broadcastSkillInvoke("lol_liren") --播放配音
		room:setPlayerFlag(target, "lol_LirenTarget")
		room:addPlayerMark(target, "Armor_Nullified")
		-- target:setCardLimitation("use,response", ".|.|.|hand", true)
		room:setPlayerCardLimitation(target, "use,response", ".|.|.|hand", true)
		local msg = sgs.LogMessage()
		msg.type = "#lol_LirenEffect"
		msg.from = source
		msg.to:append(target)
		msg.arg = "lol_liren"
		room:sendLog(msg) --发送提示信息
		room:addPlayerMark(target, "&lol_liren+to+#"..source:objectName().."-SelfClear")
	end,
}
lol_lirenVS = sgs.CreateViewAsSkill{
	name = "lol_liren",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = lol_lirenCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:isKongcheng() then
			return false
		elseif player:hasUsed("#lol_lirenCard") then
			return false
		end
		return true
	end,
}
lol_liren = sgs.CreateTriggerSkill{
	name = "lol_liren",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd},
	view_as_skill = lol_lirenVS,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			local alives = room:getAlivePlayers()
			for _,p in sgs.qlist(alives) do
				if p:hasFlag("lol_LirenTarget") then
					room:removePlayerMark(p, "Armor_Nullified")
					p:removeCardLimitation("use,response", ".|.|.|hand$1")
					room:setPlayerFlag(p, "-lol_LirenTarget")
					local msg = sgs.LogMessage()
					msg.type = "#lol_LirenClear"
					msg.from = player
					msg.to:append(p)
					msg.arg = "lol_liren"
					room:sendLog(msg) --发送提示信息
				end
			end
		end
 	end,
}
if not sgs.Sanguosha:getSkill("lol_liren") then skills:append(lol_liren) end 
Irelia:addSkill(junheng)
Irelia:addSkill(recheng)
Irelia:addSkill(zhizun)
sgs.LoadTranslationTable{
	["Irelia"] = "艾瑞莉娅",
	["&Irelia"] = "艾瑞莉娅",
	["#Irelia"] = "刀锋意志",

	["junheng"] = "均衡",
	["junhengCard"] = "均衡",
	[":junheng"] = "出牌阶段，你可以将你的红色手牌当【乐不思蜀】或黑色手牌当【兵粮寸断】对体力值不小于你的角色使用。",
	["$junheng"] = "平衡，存乎万物之间。",

	["recheng"] = "热诚",
	[":recheng"] = "<font color=\"blue\"><b>锁定技，</b></font>若你的判定区内有牌，则你不能成为延时锦囊的目标。",

	["zhizun"] = "至尊",
	[":zhizun"] = "<font color=\"purple\"><b>觉醒技，</b></font>回合开始阶段，若你装备区的牌为全场最多，则你减少1点体力上限并永久获得技能“利刃”。",
	["#zhizun"] = "%from 符合觉醒条件，失去 <font color=\"yellow\"><b>1</b></font> 点体力值上限并获得技能“<font color=\"yellow\"><b>利刃</b></font>”",
	["$zhizun"] = "真正的意志是不会被击败的！",
	["$zhizunQP"] = "至尊",

	["lol_liren"] = "利刃",
	["lol_lirenCard"] = "利刃",
	[":lol_liren"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张牌并指定一名角色，若如此做，该角色的防具无效且不能使用或打出其手牌直到回合结束。",
	["$lol_liren"] = "我的剑刃不但准而且狠。",
	["#lol_LirenEffect"] = "受 %from 的技能“%arg”的影响，本回合内 %to 的防具无效且不能使用或打出手牌",
	["#lol_LirenClear"] = "%from 的回合结束，%to 受到的技能“%arg”的影响消失",
}

--无极剑圣·易
MasterYi = sgs.General(extension, "MasterYi", "shu", "4", true, false, false)
wujijian = sgs.CreateOneCardViewAsSkill{
	name = "wujijian",
	response_or_use = true,
	view_filter = function(self, card)
    	return card:isKindOf("TrickCard")
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
wujijianMod = sgs.CreateTargetModSkill{
	name = "#wujijianMod" ,
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player:hasSkill("wujijian") and card:isRed() then
			return 1000
		end
	end,
	extra_target_func = function(self, from, card)
		if from:hasSkill("wujijian") then
			return 1
		end
	end,
	residue_func = function(self, player)
		if player:hasSkill("wujijian") then
			return 1
		end
	end,
}
extension:insertRelatedSkills("wujijian", "#wujijianMod")
mingxiangCard = sgs.CreateSkillCard{
	name = "mingxiangCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:doLightbox("$mingxiangQP")
		source:drawCards(3, "mingxiang")
		source:loseMark("@mingxiang")
		room:setPlayerFlag(source, "mingxiangTarget")
		room:broadcastSkillInvoke("mingxiang", 1)
		room:addPlayerMark(source,"&mingxiang-Clear")
	end
}
mingxiangVS = sgs.CreateZeroCardViewAsSkill{
	name = "mingxiang",
	view_as = function()
		return mingxiangCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@mingxiang") > 0
	end
}
mingxiang = sgs.CreateTriggerSkill{
	name = "mingxiang",
	frequency = sgs.Skill_Limited,
	limit_mark = "@mingxiang",
	events = {sgs.EventPhaseChanging},
	view_as_skill = mingxiangVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			if player:hasFlag("mingxiangTarget") then
				room:broadcastSkillInvoke("mingxiang", math.random(2,3))
				room:loseMaxHp(player)
				room:acquireSkill(player, "jiandao")
			end
		end
	end
}
mingxiangMod = sgs.CreateTargetModSkill{
	name = "#mingxiangMod",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill("mingxiang") and player:hasFlag("mingxiangTarget") then
			return 1000
		end
	end,
}
extension:insertRelatedSkills("mingxiang", "#mingxiangMod")
jiandao = sgs.CreateTriggerSkill{
	name = "jiandao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage, sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			local reason = damage.card
			if damage.chain or damage.transfer then return false end
			if reason then
				if reason:isKindOf("Slash") then
					if player:hasSkill(self:objectName()) then
						local msg = sgs.LogMessage()
						msg.type = "#jiandaoEffect1"
						msg.from = player
						msg.arg = "jiandao"
						room:sendLog(msg)
						room:broadcastSkillInvoke("jiandao", 1)
						player:drawCards(damage.damage, self:objectName())
					end
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				if use.card:isRed() then
					local msg = sgs.LogMessage()
					msg.type = "#jiandaoEffect2"
					msg.from = player
					msg.to:append(p)
					msg.arg = "jiandao"
					room:sendLog(msg)
					room:broadcastSkillInvoke("jiandao", 2)
					local _data = sgs.QVariant()
					_data:setValue(p)
					jink_table[index] = 0
				end
				index = index + 1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
			return false
		end
	end
}
if not sgs.Sanguosha:getSkill("jiandao") then skills:append(jiandao) end 
MasterYi:addSkill(wujijian)
MasterYi:addSkill(wujijianMod)
MasterYi:addSkill(mingxiang)
MasterYi:addSkill(mingxiangMod)
MasterYi:addRelateSkill("jiandao")
sgs.LoadTranslationTable{
	["MasterYi"] = "易",
	["&MasterYi"] = "易",
	["#MasterYi"] = "无极剑圣",
	
	["wujijian"] = "无极",
	[":wujijian"] = "你可以将一张锦囊牌当【杀】使用或打出；<font color=\"blue\"><b>锁定技，</b></font>你使用的【杀】可以额外选择一名角色为目标；出牌阶段你可以额外使用一张【杀】；你使用的红色【杀】无距离限制。",

	["mingxiang"] = "冥想",
	["mingxiangCard"] = "冥想",
	[":mingxiang"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以摸3张牌。若如此做，此阶段你可以使用任意数量的【杀】；回合结束时，你失去1点体力值上限并永久获得技能“剑道”（<font color=\"blue\"><b>锁定技，</b></font>当你使用【杀】造成1点伤害后，你摸一张牌；你使用的红色【杀】不可闪避）。",
	["@mingxiang"] = "冥想",
	["$mingxiangQP"] = "冥想",

	["jiandao"] = "剑道",
	[":jiandao"] = "<font color=\"blue\"><b>锁定技，</b></font>当你使用【杀】造成1点伤害后，你摸一张牌；你使用的红色【杀】不可闪避。",
	["#jiandaoEffect1"] = "%from 的“%arg”被触发",
	["#jiandaoEffect2"] = "%from 的“%arg”被触发，%to 不能使用【<font color=\"yellow\"><b>闪</b></font>】响应此【<font color=\"yellow\"><b>杀</b></font>】",
}

--暮光之眼·慎
Shen = sgs.General(extension, "Shen", "shu", "4", true, false, false)
quexieVS = sgs.CreateOneCardViewAsSkill{
	name = "quexie",
	response_or_use = true,
	view_filter = function(self, card)
		--[[if not card:getSuit() == sgs.Card_Diamond then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
    		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        	slash:addSubcard(card:getEffectiveId())
        	slash:deleteLater()
        	return slash:isAvailable(sgs.Self)
    	end]]--
    	return card:getSuit() == sgs.Card_Diamond
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
quexie = sgs.CreateTriggerSkill{
	name = "quexie",
	events = {sgs.Damage},
	view_as_skill = quexieVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and (damage.card:getSkillName() == self:objectName()) then
			local list = room:getAlivePlayers()
			local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(list) do
				if p:isWounded() then
					targets:append(p)
				end
			end

			local target = room:askForPlayerChosen(player, targets, self:objectName(), "quexieinvoke", true, true)
			if target then
				local recover = sgs.RecoverStruct()
				recover.who = target
				room:recover(target, recover)
			end
		end
	end,
}
xieliCard = sgs.CreateSkillCard{
	name = "xieliCard",
	will_throw = true,
	filter = function(self, targets, to_select, player) 
		return #targets ~= 1 and to_select:objectName() ~= player:objectName() and to_select:getMark("@xieli") == 0
	end,
	on_use = function(self, room, source, targets) 
		for _,target in ipairs(targets) do
			room:addPlayerMark(target, "@xieli", 1)
			room:addPlayerMark(source, "@xieli", 1)
			room:broadcastSkillInvoke("xieli", math.random(1,2))
			room:attachSkillToPlayer(target, "xielidest")
		end
		room:attachSkillToPlayer(source, "xielidest")
	end, 
}
xieliVS = sgs.CreateViewAsSkill{
	name = "xieli",
	n = 0,
	view_as = function(self, cards)
		local card = xieliCard:clone()
		return card 
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#xieliCard")
	end,
}
xieli = sgs.CreateTriggerSkill{
	name = "xieli" ,
	events = {sgs.CardAsked} ,
	view_as_skill = xieliVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pattern = data:toStringList()[1]
		local prompt = data:toStringList()[2]
		local targets = room:getAlivePlayers()
		if player:hasFlag("xieli_using") then return false end
		if string.find(prompt, "@@xieli") then return false end
		if string.find(prompt, "@xieli") then return false end
		if (pattern == "jink") then 
			if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			local tohelp = sgs.QVariant()
			tohelp:setValue(player)
			room:setPlayerFlag(player, "xieli_using")
			for _, p in sgs.qlist(targets) do
				if p:objectName() ~= player:objectName() and p:getMark("@xieli") > 0 then
					local prompt = string.format("@xieli-jink:%s", player:objectName())
					local jink = room:askForCard(p, "jink", prompt, tohelp, sgs.Card_MethodResponse, player, false,"", true)
					if jink then
						room:provide(jink)
						room:setPlayerFlag(player, "-xieli_using")
						return true
					end
				end
			end
			room:setPlayerFlag(player, "-xieli_using")
			return false
		elseif (pattern == "slash") then
			if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			local tohelp = sgs.QVariant()
			tohelp:setValue(player)
			room:setPlayerFlag(player, "xieli_using")
			for _, p in sgs.qlist(targets) do
				if p:objectName() ~= player:objectName() and p:getMark("@xieli") > 0 then
					local slash = room:askForCard(p, "slash", "@xieli-slash:" .. player:objectName(), tohelp, sgs.Card_MethodResponse, player)
					if slash then
						room:provide(slash)
						room:setPlayerFlag(player, "-xieli_using")
						return true
					end
				end
			end
			room:setPlayerFlag(player, "-xieli_using")
			return false
		end
	end ,
	can_trigger = function(self, target)
		return target and target:getMark("@xieli") > 0 and target:getPhase() == sgs.Player_NotActive
	end
}
xieliClear = sgs.CreateTriggerSkill{
	name = "#xieliClear",
	events = {sgs.EventPhaseChanging, sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_Start then return end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() or player:objectName() ~= room:getCurrent():objectName() then
				return
			end
		end
		local list = room:getAllPlayers()
		for _,p in sgs.qlist(list) do
			local m = p:getMark("@xieli")
			if m > 0 then
				room:setPlayerMark(p, "@xieli", 0)
				room:detachSkillFromPlayer(p, "xielidest")
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill("xieli")
	end
}
xielidestCard = sgs.CreateSkillCard {
	name = "xielidestCard",
	will_throw = false,

	filter = function(self, targets, to_select)
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
		return card and card:targetFilter(plist, to_select, sgs.Self) and
			not sgs.Self:isProhibited(to_select, card, plist)
	end,
	feasible = function(self, targets, from)
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
		return card and card:targetsFeasible(plist, from)
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local aocaistring = self:getUserString()
		local names = aocaistring:split("+")
		if table.contains(names, "slash") then
			table.insert(names, "fire_slash")
			table.insert(names, "thunder_slash")
		end
		local prompt = string.format("@@xieli:%s", self:getUserString():split("+")[1])
		local dt = sgs.QVariant()
		dt:setValue(user)
		room:setPlayerFlag(user, "xieli_using")
		for _, p in sgs.qlist(room:getOtherPlayers(user)) do
			if p:getMark("@xieli") > 0 and not p:hasFlag("Global_xieliFailed") then
				local card = room:askForCard(p, self:getUserString():split("+")[1], prompt, dt, sgs.Card_MethodResponse, p);
				if card then
					room:setPlayerFlag(user, "-xieli_using")
					return card
				else
					room:setPlayerFlag(p, "Global_xieliFailed")
				end
			end
		end
		room:setPlayerFlag(user, "-xieli_using")
		room:setPlayerFlag(user, "Global_xieliFailed")
		return nil
	end,
	on_validate = function(self, cardUse)
		cardUse.m_isOwnerUse = false
		local user = cardUse.from
		local room = user:getRoom()
		local aocaistring = self:getUserString()
		local names = aocaistring:split("+")
		if table.contains(names, "slash") then
			table.insert(names, "fire_slash")
			table.insert(names, "thunder_slash")
		end
		local prompt = string.format("@@xieli:%s", self:getUserString():split("+")[1])
		local dt = sgs.QVariant()
		dt:setValue(user)
		room:setPlayerFlag(user, "xieli_using")
		for _, p in sgs.qlist(room:getOtherPlayers(user)) do
			if p:getMark("@xieli") > 0 then
				local card = room:askForCard(p, self:getUserString():split("+")[1], prompt, dt, sgs.Card_MethodResponse, p);
				if card then
					room:setPlayerFlag(user, "-xieli_using")
					return card
				else
					room:setPlayerFlag(p, "Global_xieliFailed")
				end
			end
		end
		room:setPlayerFlag(user, "-xieli_using")
		room:setPlayerFlag(user, "Global_xieliFailed")
		return nil
	end
}
xielidest = sgs.CreateZeroCardViewAsSkill {
	name = "xielidest&",
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if player:getPhase() ~= sgs.Player_NotActive or player:hasFlag("Global_xieliFailed") then return false end
		if player:hasFlag("xieli_using") then return false end
		if string.find(pattern,"@xieli") then return false end
		if string.find(pattern,"@@xieli") then return false end
		if string.find(pattern,"slash") or string.find(pattern,"jink") then
			return true
		end
		return false
	end,
	view_as = function(self)
		local acard = xielidestCard:clone()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		local names = pattern:split("+")
        if #names ~= 1 then pattern = names[1] end
        if pattern == "Slash" then pattern = "slash" end
        if pattern == "Jink" then pattern = "jink" end
		acard:setUserString(pattern)
		return acard
	end
}


extension:insertRelatedSkills("xieli", "#xieliClear")
Shen:addSkill(quexie)
Shen:addSkill(xieli)
Shen:addSkill(xieliClear)
if not sgs.Sanguosha:getSkill("xielidest") then skills:append(xielidest) end
sgs.LoadTranslationTable{
	["Shen"] = "慎",
	["&Shen"] = "慎",
	["#Shen"] = "暮光之眼",
	
	["quexie"] = "却邪",
	[":quexie"] = "你可以将你的<font color=\"red\">♦</font>牌当【杀】使用或打出。当你以此法使用的【杀】造成伤害后，你可以令一名已受伤的角色回复1点体力。",
	["quexieinvoke"] = "请选择一名已受伤的角色",
	
	["xielidest"] = "协力",
	[":xielidest"] = "每当你或者慎于回合外需要使用或打出【杀】或【闪】时，可由对方代替使用或打出。",
	["xieli"] = "协力",
	["xieliCard"] = "协力",
	[":xieli"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以指定一名其他角色：直到你下个回合开始，每当你或者该角色于回合外需要使用或打出【杀】或【闪】时，可由对方代替使用或打出。",
	["@xieli"] = "协力",
}

--暗影之拳·阿卡丽
Akali = sgs.General(extension, "Akali", "shu", "3", false, false, false)
cangfei = sgs.CreateTriggerSkill{
	name = "cangfei",
	frequency = sgs.Skill_Compulsory,
	events= {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if card and damage.to ~= damage.from then
			if card:isKindOf("Slash") then
				if damage.to:getMark("@cang") == 0 and damage.to:isAlive() then
					damage.to:gainMark("@cang")
				end
				if damage.to:getMark("@fei") > 0 then
					damage.to:loseAllMarks("@fei")
					local count = damage.damage
					local msg = sgs.LogMessage()
					msg.type = "#shuanglvEffect1"
					msg.from = damage.from
					msg.to:append(damage.to)
					msg.arg = count
					count = count + 1
					msg.arg2 = count
					room:sendLog(msg)
					room:broadcastSkillInvoke("cangfei", 1)
					damage.damage = count
					data:setValue(damage)
				end
			elseif card:isKindOf("TrickCard") then
				if damage.to:getMark("@fei") == 0 and damage.to:isAlive() then
					damage.to:gainMark("@fei")
				end
				if damage.to:getMark("@cang") > 0 then
					damage.to:loseAllMarks("@cang")
					room:broadcastSkillInvoke("cangfei", 2)
					if player:isWounded() then
						local msg = sgs.LogMessage()
						msg.type = "#shuanglvEffect2"
						msg.from = player
						room:sendLog(msg)
						local recover = sgs.RecoverStruct()
						recover.who = player
						room:recover(player, recover)
					end
				end
			end
		end
	end
}
huanyinCard = sgs.CreateSkillCard{
	name = "huanyinCard",
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() or (#targets == 1) then
			return false
		end
		return true
	end,
	on_use = function(self, room, source, targets)
		local dest = sgs.QVariant()
		dest:setValue(targets[1])
		local ucard
		local choice = room:askForChoice(source, self:objectName(), "slash+duel", dest)
		if choice == "slash" then
			ucard = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		elseif choice == "duel" then
			ucard = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		end
		ucard:setSkillName(self:objectName())
		ucard:deleteLater()
		local use = sgs.CardUseStruct()
		use.card = ucard
		use.from = source
		for _,p in pairs(targets) do
			use.to:append(p)
		end
		room:useCard(use)
		room:broadcastSkillInvoke("huanyin", math.random(1,2))
		source:loseMark("@huanyin")
	end
}
huanyinVS = sgs.CreateZeroCardViewAsSkill{
	name = "huanyin",
	view_as = function()
		return huanyinCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@huanyin") > 0
	end
}
huanyin = sgs.CreateTriggerSkill{
	name = "huanyin" ,
	events = {sgs.EventPhaseStart, sgs.CardUsed} ,
	view_as_skill = huanyinVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if player:getMark("@huanyin") < 3 then
					player:gainMark("@huanyin")
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.card:getSkillName() == "huanyinCard" then
				if use.m_addHistory then
					room:addPlayerHistory(player, use.card:getClassName(),-1)
				end
			end
		end
	end
}
Akali:addSkill(cangfei)
Akali:addSkill(huanyin)
sgs.LoadTranslationTable{
	["Akali"] = "阿卡丽",
	["&Akali"] = "阿卡丽",
	["#Akali"] = "暗影之拳",

	["cangfei"] = "苍绯",
	[":cangfei"] = "<font color=\"blue\"><b>锁定技，</b></font>若你使用【杀】对其他角色造成过一次伤害，当你使用的下一张锦囊牌对其造成伤害后，你回复1点体力；若你使用锦囊牌对其他角色造成过一次伤害，当你使用的下一张【杀】对其造成伤害时，此伤害+1。",
	["@cang"] = "苍",
	["@fei"] = "绯",
	["#shuanglvEffect1"] = "%from 的“<font color=\"yellow\"><b>苍绯</b></font>”被触发，%from 对 %to 的伤害从 %arg 点上升至 %arg2 点",
	["#shuanglvEffect2"] = "%from 的“<font color=\"yellow\"><b>苍绯</b></font>”被触发，%from 回复 <font color=\"yellow\"><b>1</b></font> 点体力",

	["huanyin"] = "幻樱",
	["huanyinCard"] = "幻樱",
	[":huanyin"] = "出牌阶段，你可以弃置一枚“樱”标记并指定一名其他角色，视为对其额外使用一张【杀】或【决斗】；<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，你获得一枚“樱”标记（至多3枚）。",
	["@huanyin"] = "樱",
}

--诺克萨斯之手·德莱厄斯
Darius = sgs.General(extension, "Darius$", "wei", "4", true, false, false)
zhican = sgs.CreateTriggerSkill{
	name = "zhican", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.to:isAlive() and damage.to:objectName() ~= player:objectName() then
			if damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel") then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					if not room:askForCard(damage.to, ".red", "@zhicandis:", data, sgs.CardDiscarded) then
						damage.to:gainMark("@blood")
					end
				end
			end
		end
	end
}
duantouCard = sgs.CreateSkillCard{
	name = "duantouCard",
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() or (#targets == 1) then
			return false
		end
		return sgs.Self:inMyAttackRange(to_select)
	end,
	on_use = function(self, room, source, targets)
		room:doLightbox("$duantouQP")
		source:loseMark("@duantou")
		source:addMark("zhansha")
		room:setPlayerFlag(source, "zhansha")
		for _,p in pairs(targets) do
			local hurt = math.max(1, p:getMark("@blood"))
			local damage = sgs.DamageStruct()
			damage.reason = "duantou"
			damage.from = source
			damage.to = p
			damage.damage = hurt
			room:damage(damage)
			room:broadcastSkillInvoke("duantou", math.random(1, 2))
		end
	end
}
duantouVS = sgs.CreateZeroCardViewAsSkill{
	name = "duantou",
	view_as = function()
		return duantouCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@duantou") > 0
	end
}
duantou = sgs.CreateTriggerSkill{
	name = "duantou",
	frequency = sgs.Skill_Limited,
	limit_mark = "@duantou",
	events = {sgs.Death, sgs.EventPhaseEnd, sgs.DamageCaused},
	view_as_skill = duantouVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.DamageCaused then
			if player:hasSkill(self:objectName()) then
				if damage.card:getSkillName() ~= "duantouCard" then
					player:setMark("zhansha", 0)
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			local card = damage.card
			if death.who:objectName() ~= player:objectName() then return false end
			local killer = damage.from
			if death.damage then
				killer = death.damage.from
			else
				killer = nil
			end
			local current = player:getRoom():getCurrent()
			if killer and current and current:isAlive() then
				if killer:hasSkill(self:objectName()) then
					if killer:getMark("zhansha") > 0 then
						local msg = sgs.LogMessage()
						msg.type = "#duantouEffect"
						msg.from = killer
						msg.arg = "duantou"
						room:sendLog(msg)
						room:broadcastSkillInvoke("duantou", 3)
						killer:gainMark("@duantou")
					end
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				if player:getMark("zhansha") > 0 or player:hasFlag("zhansha") then
					player:setMark("zhansha", 0)
					player:loseAllMarks("@duantou")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
tieshou = sgs.CreateTriggerSkill{
	name = "tieshou$", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		local Dariuss = sgs.SPlayerList()
		if damage then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasLordSkill(self:objectName()) then
					Dariuss:append(p)
				end
			end
		end
		if damage.to:isAlive() then
			while not Dariuss:isEmpty() do
				local Darius = room:askForPlayerChosen(player, Dariuss, self:objectName(), "tieshou-invoke", true, true)
				if Darius then
					damage.to:gainMark("@blood")
					Dariuss:removeOne(Darius)
				else
					break
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target and (target:getKingdom() == "wei")
	end
}
Darius:addSkill(zhican)
Darius:addSkill(duantou)
Darius:addSkill(tieshou)
sgs.LoadTranslationTable{
	["Darius"] = "德莱厄斯",
	["&Darius"] = "德莱厄斯",
	["#Darius"] = "诺克萨斯之手",

	["zhican"] = "致残",
	[":zhican"] = "每当你使用【杀】或【决斗】对一名其他角色造成一次伤害后，你可以令其选择：弃置一张红色手牌，或获得一枚“血”标记。",
	["@blood"] = "血",
	["@zhicandis"] = "请弃置一张红色手牌，否则失去一点体力",

	["duantou"] = "断头",
	["duantouCard"] = "断头",
	[":duantou"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你选择攻击范围内的一名角色，对其造成X点伤害（X为该角色拥有的“血”标记数且至少为1），若你以此法杀死一名角色，则此阶段你可以再使用一次“断头”。",
	["@duantou"] = "断头",
	["$duantouQP"] = "断头",
	["#duantouEffect"] = "%from 杀死了一名角色，此阶段可以再使用一次“%arg”",
	["$duantou1"] = "",
	["$duantou2"] = "",
	["$duantou3"] = "",

	["tieshou"] = "铁手",
	[":tieshou"] = "<font color=\"orange\"><b>主公技，</b></font>其他魏势力的角色对一名角色造成伤害后，可令该角色获得一枚“血”标记。",
	["$tieshou"] = "",
}

--不祥之刃·卡特琳娜
Katarina = sgs.General(extension, "Katarina", "wei", "3", false, false, false)
buxiang = sgs.CreateTriggerSkill{
	name = "buxiang",
	frequency = sgs.Skill_Compulsory,
	events= {sgs.Damage, sgs.DamageCaused, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.Damage then
			if damage.to:isAlive() and damage.from:objectName() ~= damage.to:objectName() then
				if player:getPhase() == sgs.Player_Play then
					damage.to:gainMark("@buxiang", 1)
				end
			end
		elseif event == sgs.DamageCaused then
			if damage.chain or damage.transfer then return false end
			local markcot = damage.to:getMark("@buxiang")
			local count = damage.damage
			local msg = sgs.LogMessage()
			msg.type = "#BuxiangEffect"
			msg.from = damage.from
			msg.to:append(damage.to)
			msg.arg = count
			count = count + markcot
			msg.arg2 = count
			if markcot > 0 then 
				room:sendLog(msg) --发送提示信息
				room:broadcastSkillInvoke("buxiang", math.random(1, 2)) --播放配音
			end
			damage.damage = count
			data:setValue(damage)
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				local list = room:getAllPlayers()
				for _,p in sgs.qlist(list) do
					p:loseAllMarks("@buxiang")
				end
			end
		end
	end
}
lol_lianhua = sgs.CreateTriggerSkill{
	name = "lol_lianhua" ,
	events = {sgs.Death, sgs.DrawNCards} ,
	frequency = sgs.Skill_Compulsory, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			local damage = data:toDamage()
			if death.who:objectName() ~= player:objectName() then return false end
			local killer = damage.from
			if death.damage then
				killer = death.damage.from
			else
				killer = nil
			end
			local current = player:getRoom():getCurrent()
			if killer and current and current:isAlive() then
				if killer:hasSkill(self:objectName()) then
					room:doLightbox("$lol_lianhuaQP")
					room:broadcastSkillInvoke("lol_lianhua", 1)
					killer:gainMark("@lol_lianhua")
					killer:drawCards(1, self:objectName())
				end
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			if player:getMark("@lol_lianhua") > 0 then
				local count = player:getMark("@lol_lianhua")
				local msg = sgs.LogMessage()
				msg.type = "#lol_lianhuaDK"
				msg.from = player
				msg.arg = count
				room:sendLog(msg)
				room:broadcastSkillInvoke("lol_lianhua", 2)
				draw.num = draw.num + count
				data:setValue(draw)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
lol_lianhuaHS = sgs.CreateMaxCardsSkill{
	name = "#lol_lianhuaHS",
	extra_func = function(self, target)
		if target:hasSkill("lol_lianhua") then
			local count = target:getMark("@lol_lianhua")
			return count
		end
	end
}
extension:insertRelatedSkills("lol_lianhua", "#lol_lianhuaHS")
Katarina:addSkill(buxiang)
Katarina:addSkill(lol_lianhua)
Katarina:addSkill(lol_lianhuaHS)
sgs.LoadTranslationTable{
	["Katarina"] = "卡特琳娜",
	["&Katarina"] = "卡特琳娜",
	["#Katarina"] = "不祥之刃",

	["buxiang"] = "不详",
	[":buxiang"] = "<font color=\"blue\"><b>锁定技，</b></font>当你对一名其他角色造成伤害时，此伤害+X（X为该回合你对目标角色造成伤害的次数）。",
	["@buxiang"] = "不详",
	["#BuxiangEffect"] = "%from 的“<font color=\"yellow\"><b>不祥</b></font>”被触发，%from 对 %to 的伤害从 %arg 点上升至 %arg2 点",
	["$buxiang1"] = "不要心存怜悯。",
	["$buxiang2"] = "",

	["lol_lianhua"] = "莲华",
	[":lol_lianhua"] = "<font color=\"blue\"><b>锁定技，</b></font>当你杀死一名角色时，你摸一张牌；你的手牌上限和摸牌阶段摸牌数+X（X为你杀死的角色数）。",
	["@lol_lianhua"] = "莲华",
	["$lol_lianhuaQP"] = "莲华",
	["#lol_lianhuaDK"] = "%from 的“<font color=\"yellow\">莲华</font>”被触发，%from 额外摸了 %arg 张牌",
	["$lol_lianhua1"] = "",
	["$lol_lianhua2"] = "非常迷人。",
}

--刀锋之影·泰隆
Talon = sgs.General(extension, "Talon", "wei", "3", true, false, false)
lianmin = sgs.CreateTriggerSkill{
	name = "lianmin",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local source = damage.from
		local victim = damage.to
		if source and source:objectName() == player:objectName() and victim:objectName() ~= source:objectName() then
			local judges = victim:getJudgingArea()
			if (not judges:isEmpty()) or (not (victim:faceUp())) then
				local room = player:getRoom()
				room:broadcastSkillInvoke("lianmin") --播放配音
				local count = damage.damage
				local msg = sgs.LogMessage()
				msg.type = "#LianminEffect"
				msg.from = source
				msg.to:append(victim)
				msg.arg = count
				count = count + 1
				msg.arg2 = count
				room:sendLog(msg) --发送提示信息
				damage.damage = count
				data:setValue(damage)
			end
		end
	end,
}
gehouCard = sgs.CreateSkillCard{
	name = "gehouCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:isKongcheng() then
				return false
			elseif to_select:objectName() == sgs.Self:objectName() then
				return false
			end
			return true
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:broadcastSkillInvoke("gehou") --播放配音
		local success = source:pindian(target, "gehou", self)
		if success then
			-- target:setCardLimitation("use", ".|.|.|hand", true)
			room:setPlayerCardLimitation(target, "use,response", ".|.|.|hand", true)
			local record = sgs.QVariant(target:objectName())
			source:setTag("GehouTarget", record)
			local msg = sgs.LogMessage()
			msg.type = "#GehouSuccess"
			msg.from = source
			msg.to:append(target)
			room:sendLog(msg) --发送提示信息
			room:addPlayerMark(target, "&gehou-Clear")
		else
			room:setPlayerFlag(source, "GehouSkipPlay")
			local msg = sgs.LogMessage()
			msg.type = "#GehouFailed"
			msg.from = source
			room:sendLog(msg) --发送提示信息
		end
	end,
}
gehouVS = sgs.CreateViewAsSkill{
	name = "gehou",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = gehouCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@gehou"
	end,
}
gehou = sgs.CreateTriggerSkill{
	name = "gehou",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.DamageCaused},
	view_as_skill = gehouVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				if player:isKongcheng() then
					return false
				end
				local can_invoke = false
				local others = room:getOtherPlayers(player)
				for _,p in sgs.qlist(others) do
					if not p:isKongcheng() then
						can_invoke = true
						break
					end
				end
				if can_invoke then
					room:askForUseCard(player, "@@gehou", "@gehou")
				end
				if player:hasFlag("GehouSkipPlay") then
					room:setPlayerFlag(player, "-GehouSkipPlay")
					return true
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				local record = player:getTag("GehouTarget"):toString()
				if record ~= "" then
					local alives = room:getAlivePlayers()
					for _,target in sgs.qlist(alives) do
						if target:objectName() == record then
							target:removeCardLimitation("use", ".|.|.|hand$1")
							local msg = sgs.LogMessage()
							msg.type = "#GehouClear"
							msg.from = player
							msg.arg = "gehou"
							msg.to:append(target)
							room:sendLog(msg) --发送提示信息
							break
						end
					end
					player:removeTag("GehouTarget")
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			local source = damage.from
			if source and source:objectName() == player:objectName() then
				local victim = damage.to
				local record = player:getTag("GehouTarget"):toString()
				if victim and victim:objectName() == record then
					local count = damage.damage
					local msg = sgs.LogMessage()
					msg.type = "#GehouEffect"
					msg.from = source
					msg.to:append(victim)
					msg.arg = count
					count = count + 1
					msg.arg2 = count
					room:sendLog(msg) --发送提示信息
					damage.damage = count
					data:setValue(damage)
				end
			end
		end
	end,
}
Talon:addSkill(gehou)
Talon:addSkill(lianmin)
sgs.LoadTranslationTable{
	["Talon"] = "泰隆",
	["&Talon"] = "泰隆",
	["#Talon"] = "刀锋之影",

	["gehou"] = "割喉",
	["gehouCard"] = "割喉",
	[":gehou"] = "出牌阶段开始时，你可以与一名角色拼点：若你赢，该角色不能使用或打出其手牌且你对其造成的伤害+1，直到回合结束；若你没赢，你结束出牌阶段。",
	["#GehouEffect"] = "%from 的技能“<font color=\"yellow\">割喉</font>”被触发，对 %to 造成的伤害+1，从 %arg 点上升到 %arg2 点",
	["@gehou"] = "您可以发动“割喉”与一名角色拼点",
	["~gehou"] = "选择一张手牌->选择一名有手牌的其他角色->点击“确定”",
	["#GehouSuccess"] = "%from 拼点赢，本回合内 %to 不能使用手牌且 %from 对 %to 造成的伤害+1",
	["#GehouFailed"] = "%from 拼点没有赢，结束出牌阶段",
	["#GehouClear"] = "%from 的回合结束，%to 受到的技能“%arg”的影响消失",
	["$gehou"] = "游走于刀尖之上。",
	["$gehouWin"] = "又是一具阴沟里的尸体。",
	["$gehouFall"] = "我从不妥协。",

	["lianmin"] = "怜悯",
	[":lianmin"] = "<font color=\"blue\"><b>锁定技，</b></font>当你对一名其他角色造成伤害时，若其武将牌背面朝上或判定区内有牌，此伤害+1。",
	["#LianminEffect"] = "因 %to 武将牌背面朝上或判定区内有牌，受技能“<font color=\"yellow\"><b>怜悯</b></font>”的影响，%from 对 %to 造成的伤害+1，从 %arg 点上升至 %arg2 点",
	["$lianmin"] = "真是可怜。",
}

--嗜血猎手·沃里克
Warwich = sgs.General(extension, "Warwich", "wei", "4", true, false, false)
shixueCard = sgs.CreateSkillCard{
	name = "shixueCard", 
	target_fixed = false, 
	will_throw = true,
	filter = function(self, targets, to_select) 
		if to_select:objectName() == sgs.Self:objectName() or (#targets == 1) then
			return false
		end
		return sgs.Self:distanceTo(to_select) <= 1
	end,
	on_use = function(self, room, source, targets)
		for _,p in pairs(targets) do
			local damage = sgs.DamageStruct()
			damage.reason = "shixue"
			damage.from = source
			damage.to = p
			room:damage(damage)
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(source, recover)
			room:broadcastSkillInvoke("shixue", math.random(1, 2))
		end
	end
}
shixue = sgs.CreateViewAsSkill{
	name = "shixue", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:getSuit() == sgs.Card_Spade
		end
		return false
	end, 
	view_as = function(self, cards)
		if #cards ==1 then
			local card = cards[1]
			local sx_card = shixueCard:clone()
			sx_card:addSubcard(card)
			return sx_card
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#shixueCard")
	end
}
xieji = sgs.CreateDistanceSkill{
	name = "xieji",
	correct_func = function(self, from, to)
		if from:hasSkill(self:objectName()) then
			local others = from:getAliveSiblings()
			local fix = 0
			for _, p in sgs.qlist(others) do
				if p:isWounded() and p:getHp() < from:getHp() then 
					fix = fix - 1
				end
			end
			return fix
		end
		return 0
	end,
}
Warwich:addSkill(shixue)
Warwich:addSkill(xieji)
sgs.LoadTranslationTable{
	["Warwich"] = "沃里克",
	["&Warwich"] = "沃里克",
	["#Warwich"] = "嗜血猎手",
	
	["shixue"] = "嗜血",
	["shixueCard"] = "嗜血",
	[":shixue"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张♠牌并选择距离1以内的一名其他角色，你对其造成1点伤害，然后你回复1点体力。",

	["xieji"] = "血迹",
	[":xieji"] = "<font color=\"blue\"><b>锁定技，</b></font>场上每有一名体力值不满且少于你的其他角色，你与其他角色计算距离时便-1。",
}

--亡灵勇士·赛恩
old_Sion = sgs.General(extension, "old_Sion", "wei", "5", true, false, false)
ningshi = sgs.CreateTriggerSkill{
	name = "ningshi", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DamageCaused}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		local count = damage.damage
		local reason = damage.card
		if reason and reason:isKindOf("Slash") then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:loseHp(player, 1)
				local msg = sgs.LogMessage()
				msg.type = "#ningshiEffect"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = count
				count = count + 1
				msg.arg2 = count
				room:sendLog(msg)
				room:broadcastSkillInvoke("ningshi", 1)
				damage.damage = count
				data:setValue(damage)
			end
		end
	end,
}
yongbaoCard = sgs.CreateSkillCard{
	name = "yongbaoCard",
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() or (#targets == 1) then
			return false
		end
		return sgs.Self:inMyAttackRange(to_select)
	end,
	on_use = function(self, room, source, targets)
		local hurt = source:getMark("@yongbao")
		for _,p in pairs(targets) do
			local damage = sgs.DamageStruct()
			damage.reason = "yongbao"
			damage.from = source
			damage.to = p
			damage.damage = hurt
			room:damage(damage)
			room:broadcastSkillInvoke("yongbao", 3)
		end
		source:loseMark("@yongbao")
		room:loseMaxHp(source)
	end
}
yongbaoVS = sgs.CreateZeroCardViewAsSkill{
	name = "yongbao",
	view_as = function()
		return yongbaoCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@yongbao") > 0
	end
}
yongbao = sgs.CreateTriggerSkill{
	name = "yongbao",
	events = {sgs.Death},
	view_as_skill = yongbaoVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local damage = data:toDamage()
		if death.who:objectName() ~= player:objectName() then return false end
		local killer = damage.from
		if death.damage then
			killer = death.damage.from
		else
			killer = nil
		end
		local current = player:getRoom():getCurrent()
		if killer and current and current:isAlive() then
			if killer:hasSkill(self:objectName()) then
				killer:gainMark("@yongbao")
				local maxhp = killer:getMaxHp() + 1
				room:setPlayerProperty(killer, "maxhp", sgs.QVariant(maxhp))
				local recover = sgs.RecoverStruct()
				recover.who = killer
				room:recover(killer, recover) 
				room:broadcastSkillInvoke("yongbao", math.random(1, 2))
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
old_Sion:addSkill(ningshi)
old_Sion:addSkill(yongbao)
sgs.LoadTranslationTable{
	["old_Sion"] = "旧·赛恩",
	["&old_Sion"] = "赛恩",
	["#old_Sion"] = "亡灵勇士",
	
	["ningshi"] = "凝视",
	[":ningshi"] = "当你使用【杀】造成伤害时，你可以自减一点体力令此伤害+1。",

	["yongbao"] = "拥抱",
	["yongbaoCard"] = "拥抱",
	[":yongbao"] = "当你杀死一名角色后，你增加一点体力上限并回复1点体力。出牌阶段，你可以减少一点体力值上限对攻击范围内一名其他角色造成X点伤害（X为因“拥抱”增加的体力值上限数）。",
}

--亡灵战神·赛恩
Sion = sgs.General(extension, "Sion", "wei", "4", true, false, false)
cannueCard = sgs.CreateSkillCard{
	name = "cannueCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:throwCard(self, source)
		if source:isAlive() then
			local count = self:subcardsLength()
			source:addMark("cannue", count)
			room:broadcastSkillInvoke("cannue", math.random(1, 2))
			room:setPlayerMark(source, "&cannue-Clear", count)
		end
	end
}
cannueVS = sgs.CreateViewAsSkill{
	name = "cannue",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local cannue_card = cannueCard:clone()
			for _,card in pairs(cards) do
				cannue_card:addSubcard(card)
			end
			cannue_card:setSkillName(self:objectName())
			return cannue_card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#cannueCard")
	end
}
cannue = sgs.CreateTriggerSkill{
	name = "cannue",
	events= {sgs.DamageCaused, sgs.EventPhaseEnd},
	view_as_skill = cannueVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			local markcot = player:getMark("cannue")
			if damage.card and damage.card:isKindOf("Slash") and markcot > 0 then
				local count = damage.damage
				local msg = sgs.LogMessage()
				msg.type = "#cannueEffect"
				msg.from = damage.from
				msg.to:append(damage.to)
				msg.arg = count
				count = count + markcot
				msg.arg2 = count
				damage.damage = count
				data:setValue(damage)
				player:setMark("cannue", 0)
				room:sendLog(msg) --发送提示信息
				room:broadcastSkillInvoke("cannue", 3) --播放配音
				room:setPlayerMark(player, "&cannue-Clear", 0)
				if damage.damage >= 3 and damage.to:isAlive() then
					damage.to:turnOver()
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				player:setMark("cannue", 0)
			end
		end
	end
}
manheng = sgs.CreateTriggerSkill{
	name = "manheng",
	frequency = sgs.Skill_Limited,
	limit_mark = "@manheng",
	events = {sgs.HpChanged, sgs.Damage, sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.HpChanged then
			if player:getHp() < 1 then
				if player:getMark("@manheng") > 0 then
					local num = player:getHandcardNum()
					if num > 0 then
						local other = room:getOtherPlayers(player)
						local target = room:askForPlayerChosen(player, other, self:objectName(), "manhenginvoke", true, true)
						if target then
							room:broadcastSkillInvoke("manheng")
							player:loseMark("@manheng")
							player:throwAllHandCards()
							for i=1, num, 1 do
								if target:isAlive() then
									player:addMark("manhengslash")
									local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
									slash:deleteLater()
									slash:setSkillName(self:objectName())
									local use = sgs.CardUseStruct()
									use.card = slash
									use.from = player
									use.to:append(target)
									room:useCard(use)
								end
							end
						end
					end
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card:isKindOf("Slash") and player:getMark("manhengslash") > 0 then
				if player:isWounded() and player:isAlive() then
					local recover = sgs.RecoverStruct()
					recover.recover = damage.damage
					recover.who = player
					room:recover(player, recover)
				end
				player:setMark("manhengslash", 0)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				player:setMark("manhengslash", 0)
			end
		end
	end
}
Sion:addSkill(cannue)
Sion:addSkill(manheng)
sgs.LoadTranslationTable{
	["Sion"] = "赛恩",
	["&Sion"] = "赛恩",
	["#Sion"] = "亡灵战神",

	["cannue"] = "残虐",
	[":cannue"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置任意数量的牌。若如此做，本回合你使用【杀】第一次造成伤害时，此伤害+X（X为你以此法弃置的牌数），且若此伤害不小于3，你将目标角色武将牌翻面。",
	["#cannueEffect"] = "受技能“<font color=\"yellow\"><b>残虐</b></font>”的影响，%from 对 %to 造成的伤害从 %arg 点上升至 %arg2 点",
	
	["manheng"] = "蛮横",
	[":manheng"] = "<font color=\"red\"><b>限定技，</b></font>当你濒死时，你可以弃置所有手牌（至少1张）并指定一名其他角色，视为你对其使用X张【杀】（X为你以此法弃置的手牌数），你以此法每造成1点伤害，你回复1点体力。",
	["@manheng"] = "蛮横",
	["manhenginvoke"] = "你可以选择一名其他角色来发动“蛮横”",

}

--黑暗之女·安妮
Annie = sgs.General(extension, "Annie", "wei", "3", false, false, false)
shihuo = sgs.CreateTriggerSkill{
	name = "shihuo",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardResponded, sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed or event == sgs.CardResponded then
			local card = nil
			if event == sgs.CardUsed then
				local use = data:toCardUse()
				card = use.card
			elseif event == sgs.CardResponded then
				card = data:toCardResponse().m_card
			end
			if card:isKindOf("TrickCard") then
				player:gainMark("@huo")
			end
			return false
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if player:getMark("@huo") >= 4 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					player:loseMark("@huo", 4)
					local count = damage.damage
					local msg = sgs.LogMessage()
					msg.type = "#shihuoEffect"
					msg.from = damage.from
					msg.to:append(damage.to)
					msg.arg = count
					count = count + 1
					msg.arg2 = count
					room:sendLog(msg) --发送提示信息
					room:broadcastSkillInvoke("shihuo", math.random(1, 2)) --播放配音
					damage.damage = count
					if damage.nature ~= sgs.DamageStruct_Fire then
						damage.nature = sgs.DamageStruct_Fire
					end
					data:setValue(damage)
					damage.to:turnOver()
				end
			end
		end
	end
}
fenshao = sgs.CreateTriggerSkill{
	name = "fenshao",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage and damage.nature ~= sgs.DamageStruct_Normal then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke("fenshao", math.random(1, 2)) --播放配音
				player:drawCards(damage.damage, self:objectName())
			end
		end
	end
}
Annie:addSkill(shihuo)
Annie:addSkill(fenshao)
sgs.LoadTranslationTable{
	["Annie"] = "安妮",
	["&Annie"] = "安妮",
	["#Annie"] = "黑暗之女",
	
	["shihuo"] = "嗜火",
	[":shihuo"] = "当你使用或打出一张锦囊牌时，你获得一枚“火”标记；当你对一名角色造成伤害时，若你拥有的“火”标记不少于4枚，你可以弃置4枚“火”标记，令此伤害+1且视为火属性伤害，然后将目标角色的武将牌翻面。",
	["@huo"] = "火",
	["#shihuoEffect"] = "%from 发动了“<font color=\"yellow\"><b>嗜火</b></font>”，%from 对 %to 造成的伤害从 %arg 点上升至 %arg2 点",

	["fenshao"] = "焚烧",
	[":fenshao"] = "每当你造成1点属性伤害后，你可以摸一张牌。",
}

--寒冰射手·艾希
Ashe = sgs.General(extension, "Ashe", "wu", "3", false, false, false)
jianshen = sgs.CreateViewAsSkill{
	name = "jianshen",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("Slash")
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		elseif #cards == 1 then
			local card = cards[1]
			local d_card = sgs.Sanguosha:cloneCard("archery_attack", card:getSuit(), card:getNumber())
			d_card:addSubcard(card:getId())
			d_card:setSkillName(self:objectName())
			return d_card
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("Forbidjianshen-PlayClear")
	end,
	enabled_at_response = function()
		return false
	end,
}
jianshenForbid = sgs.CreateTriggerSkill{
	name = "#jianshen-forbid",
	events = {sgs.CardUsed, sgs.CardResponded, sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if event == sgs.CardUsed then
			if use.card:isKindOf("Slash") and (player:getPhase() == sgs.Player_Play) and (player:getMark("Forbidjianshen-PlayClear") == 0 ) then
				room:addPlayerMark(player, "Forbidjianshen-PlayClear")
			end
		elseif event ==sgs.CardResponded then
			local resp = data:toCardResponse()
			if resp.m_card and resp.m_card:isKindOf("Slash") and resp.m_isUse and (player:getPhase() == sgs.Player_Play) and (player:getMark("Forbidjianshen-PlayClear") == 0 )  then
				room:addPlayerMark(player, "Forbidjianshen-PlayClear")
			end
		elseif event ==sgs.TargetConfirmed then
			if (use.from:objectName() == player:objectName()) and (use.card:getSkillName() == "jianshen") then
				player:getRoom():setPlayerCardLimitation(player, "use", "Slash", true)
				room:addPlayerMark(player, "Forbidjianshen-PlayClear")
			end
		end
		return false
	end
}
extension:insertRelatedSkills("jianshen", "#jianshen-forbid")
zhuanzhuCard = sgs.CreateSkillCard{
	name = "zhuanzhuCard",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
		if #targets < player:getHp() then
			return to_select:hasFlag("zhuanzhu")
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		for _,p in ipairs(targets) do
			room:setPlayerFlag(p, "zhuanzhuremove")
		end
	end
}
zhuanzhuVS = sgs.CreateViewAsSkill{
	name = "zhuanzhu",
	n = 0,
	view_as = function(self, cards)
		return zhuanzhuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@zhuanzhu"
	end,
}
zhuanzhu = sgs.CreateTriggerSkill{
	name = "zhuanzhu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed},
	view_as_skill = zhuanzhuVS,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local trick = use.card
		if trick and trick:isKindOf("ArcheryAttack") then
			local room = player:getRoom()
			if trick:subcardsLength() ~= 0 or trick:getEffectiveId() ~= -1 then
				room:moveCardTo(trick, nil, sgs.Player_PlaceTable, true)
			end
			if player:hasSkill(self:objectName()) then
				for _,p in sgs.qlist(use.to) do
					room:setPlayerFlag(p,"zhuanzhu")
				end
				player:setTag("zhuanzhu", data)
				if room:askForUseCard(player,"@@zhuanzhu","@zhuanzhu") then
					local newtargets = sgs.SPlayerList()
					for _,p in sgs.qlist(use.to) do
						room:setPlayerFlag(p, "-zhuanzhu")
						if p:hasFlag("zhuanzhuremove") then
							room:setPlayerFlag(p, "-zhuanzhuremove")
						else
							newtargets:append(p)
						end
					end
					use.to = newtargets
					if use.to:isEmpty() then
						return true
					end
					data:setValue(use)
				end
				player:removeTag("zhuanzhu")
			end
		end
	end,
	can_trigger = function(self, target)
		return true
	end
}
yingyanCard = sgs.CreateSkillCard{
	name = "yingyanCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if to_select:isKongcheng() then
			return false
		elseif to_select:objectName() == sgs.Self:objectName() then
			return false
		end
		return true
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("yingyan", 1) --播放配音
		local target = targets[1]
		local hp = source:getHp()
		local mynum = source:getHandcardNum()
		local num = target:getHandcardNum()
		local x = math.min(hp, math.min(mynum, num))
		if x == 0 then
			if num > 0 then
				room:showAllCards(target, source)
			end
		else
			local handcard_ids = target:handCards()
			local selected = sgs.IntList()
			local count = 0
			room:fillAG(handcard_ids, source)
			for i=1, x, 1 do
				local id = room:askForAG(source, handcard_ids, true, "yingyan")
				if id > 0 then
					handcard_ids:removeOne(id)
					--room:takeAG(nil, id, false)
					selected:append(id)
					count = count + 1
				else
					break
				end
			end
			room:clearAG(source)
			if count > 0 then
				local to_exchange = room:askForExchange(source, "yingyan", count, count, false)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, source:objectName())
				local moveA = sgs.CardsMoveStruct(selected, source, sgs.Player_PlaceHand, reason)
				local moveB = sgs.CardsMoveStruct(to_exchange:getSubcards(), target, sgs.Player_PlaceHand, reason)
				local moves = sgs.CardsMoveList()
				moves:append(moveA)
				moves:append(moveB)
				room:moveCardsAtomic(moves, false)
			end
		end
	end,
}
yingyan = sgs.CreateViewAsSkill{
	name = "yingyan",
	n = 0,
	view_as = function(self, cards)
		return yingyanCard:clone()
	end,
	enabled_at_play = function(self, player)
		if player:hasUsed("#yingyanCard") then
			return false
		else
			local others = player:getSiblings()
			for _,p in sgs.qlist(others) do
				if not p:isKongcheng() then
					return true
				end
			end
		end
		return false
	end,
}
Ashe:addSkill(jianshen)
Ashe:addSkill(jianshenForbid)
Ashe:addSkill(yingyan)
Ashe:addSkill(zhuanzhu)
sgs.LoadTranslationTable{
	["Ashe"] = "艾希",
	["&Ashe"] = "艾希",
	["#Ashe"] = "寒冰射手",

	["jianshen"] = "箭神",
	[":jianshen"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>若你未于本阶段使用过【杀】，你可以将1张【杀】当【万箭齐发】使用，然后你不能使用【杀】直到回合结束。",
	["$jianshen"] = "正中眉心！",

	["zhuanzhu"] = "专注",
	["zhuanzhuCard"] = "专注",
	[":zhuanzhu"] = "当你使用【万箭齐发】时，你可以指定至多X名角色，此【万箭齐发】对这些角色无效（X为你当前体力值）。",
	["@zhuanzhu"] = "您可以发动“专注”",
	["~zhuanzhu"] = "选择至多X名角色->点击“确定”（X为你当前体力值）",
	["$zhuanzhu"] = "我瞄的很稳。",

	["yingyan"] = "鹰眼",
	["yingyanCard"] = "鹰眼",
	[":yingyan"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以观看一名其他角色的手牌，并可以将你的至多X张手牌与其相同数量的手牌交换（X为你当前体力值）。",
	["$yingyan"] = "你要来几发吗？",

}

--蛮族之王·泰达米尔
Tryndamere = sgs.General(extension, "Tryndamere", "wu", "4", true, false, false)
kuangnu = sgs.CreateTriggerSkill{
	name = "kuangnu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseEnd, sgs.DamageCaused, sgs.TargetConfirmed, sgs.PreCardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				if not player:hasFlag("Global_SlashInPlayPhase") then
					if player:getLostHp() >= 1 then
						if player:askForSkillInvoke(self:objectName()) then
							local recover = sgs.RecoverStruct()
							recover.who = player
							room:broadcastSkillInvoke("kuangnu", 1)
							room:recover(player, recover)
						end
					end
				end
			end
			return false
		elseif event == sgs.DamageCaused then
			if player:getLostHp() >= 3 then
				local damage = data:toDamage()
				local card = damage.card
				if card then
					if card:isKindOf("Slash") or card:isKindOf("Duel") then
						local count = damage.damage
						local knhurt = sgs.LogMessage()
						knhurt.from = player
						knhurt.type = "#knhurt"
						knhurt.arg = count
						count = count + 1
						knhurt.arg2 = count
						knhurt.to:append(damage.to)
						room:sendLog(knhurt)
						room:broadcastSkillInvoke("kuangnu", 2)
						damage.damage = count
						data:setValue(damage)
					end
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				if player:getLostHp() >= 4 then
					local msg = sgs.LogMessage()
					msg.type = "#knSlash"
					msg.from = player
					msg.to:append(p)
					room:sendLog(msg)
					room:broadcastSkillInvoke("kuangnu", 3)
					local _data = sgs.QVariant()
					_data:setValue(p)
					jink_table[index] = 0
				end
				index = index + 1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
			return false
		elseif event == sgs.PreCardUsed or event == sgs.CardResponded then
			if player:getPhase() == sgs.Player_Play then
				local card = nil
				if event == sgs.PreCardUsed then
					card = data:toCardUse().card
				else
					card = data:toCardResponse().m_card
				end
				if card:isKindOf("Slash") then
					player:setFlags("Global_SlashInPlayPhase")
				end
			end
		end
	end,
}
kuangnuMod = sgs.CreateTargetModSkill{
	name = "#kuangnuMod",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill("kuangnu") and player:getLostHp() >= 2 then
			return player:getLostHp()
		end
	end,
	distance_limit_func = function(self, player, card)
		if player:hasSkill("kuangnu") and player:getLostHp() >= 2 then
			return player:getLostHp()
		end
	end,
}
extension:insertRelatedSkills("kuangnu", "#kuangnuMod")
lol_nuhuo = sgs.CreateTriggerSkill{
	name = "lol_nuhuo",
	frequency = sgs.Skill_Limited,
	limit_mark = "@lol_nuhuo",
	events = {sgs.HpChanged, sgs.DamageCaused, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.HpChanged then
			if player:getHp() < 1 then
				if player:getMark("@lol_nuhuo") > 0 then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:doLightbox("$nuhuoQP")
						room:broadcastSkillInvoke("lol_nuhuo", math.random(1, 2))
						room:setTag(self:objectName(), sgs.QVariant())
						player:addMark("wjnh")
						player:loseMark("@lol_nuhuo")
						room:setTag("SkipGameRule",sgs.QVariant(tonumber(event)))
						room:addPlayerMark(player, "&lol_nuhuo-SelfClear")
					end
				elseif player:getMark("wjnh") > 0 then
					room:setTag("SkipGameRule",sgs.QVariant(tonumber(event)))
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if player:getMark("wjnh") > 0 then
				room:addPlayerMark(player, "&lol_nuhuo+:+damage-Clear")
				player:addMark("nuqi-Clear", damage.damage)
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				if player:getMark("wjnh") > 0 then
					local hp = math.min(math.max(player:getMark("nuqi-Clear"), 1), player:getMaxHp())
					room:setPlayerProperty(player, "hp", sgs.QVariant(hp))
					player:turnOver()
					player:setMark("wjnh", 0)
				end
				player:setMark("nuqi-Clear", 0)
			end
		end
	end,
}
Tryndamere:addSkill(kuangnu)
Tryndamere:addSkill(kuangnuMod)
Tryndamere:addSkill(lol_nuhuo)
sgs.LoadTranslationTable{
	["Tryndamere"] = "泰达米尔",
	["&Tryndamere"] = "泰达米尔",
	["#Tryndamere"] = "蛮族之王",

	["kuangnu"] = "狂怒",
	[":kuangnu"] = "依照你已损失的体力值，你获得以下效果：1点或更多：若你于出牌阶段没有使用或打出【杀】，回合结束时你可以回复1点体力；2点或更多：<font color=\"blue\"><b>锁定技，</b></font>出牌阶段你可以额外使用X张【杀】，你的攻击范围+X（X为你已损失的体力值）；3点或更多：<font color=\"blue\"><b>锁定技，</b></font>你使用的【杀】或【决斗】造成的伤害+1；4点或更多：<font color=\"blue\"><b>锁定技，</b></font>你的【杀】不能被闪避。",
	["#knhurt"] = "%from 的“<font color=\"yellow\"><b>狂怒</b></font>”被触发，对 %to 的伤害从 %arg 增加至 %arg2 点。",
	["#knSlash"] = "%from 的“<font color=\"yellow\"><b>狂怒</b></font>”被触发，%to 不能使用【<font color=\"yellow\"><b>闪</b></font>】响应此【<font color=\"yellow\"><b>杀</b></font>】",
	
	["lol_nuhuo"] = "怒火",
	[":lol_nuhuo"] = "<font color=\"red\"><b>限定技，</b></font>当你濒死时，你可以不死去。若如此做，直到你下个回合结束阶段，你不会死亡；你下个回合结束时，将体力回复至X点并将武将牌翻面（X为该回合造成的伤害数且至少为1）。",
	["@lol_nuhuo"] = "怒火",
	["$nuhuoQP"] = "怒火",
}

--狂战士·奥拉夫
Olaf = sgs.General(extension, "Olaf", "wu", "4", true, false, false)
lumangCard = sgs.CreateSkillCard{
	name = "lumangCard", 
	filter = function(self, targets, to_select) 
		if to_select:objectName() == sgs.Self:objectName() or (#targets == 1) then
			return false
		end
		return sgs.Self:inMyAttackRange(to_select)
	end,
	on_use = function(self, room, source, targets)
		for _,p in pairs(targets) do
			if source:getHp() <= p:getHp() then
				source:addMark("lm")
			end
			room:loseHp(source)
			local x = 1
			local damage = sgs.DamageStruct()
			damage.reason = "lumang"
			damage.from = source
			damage.to = p
			if source:getMark("huanghun") > 0 then
				x = x + 1
			end
			damage.damage = x
			room:damage(damage)
			if source:getMark("lm") > 0 then
				source:setMark("lm", 0)
				if source:isWounded() then
					local recover = sgs.RecoverStruct()
					recover.who = source
					room:recover(source, recover)
				end
			end
			room:broadcastSkillInvoke("lumang", math.random(1, 2))
		end
	end
}
lumang = sgs.CreateZeroCardViewAsSkill{
	name = "lumang", 
	view_as = function(self, cards)
		return lumangCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lumangCard")
	end
}
huanghun = sgs.CreateTriggerSkill{
	name = "huanghun",
	frequency = sgs.Skill_Limited,
	limit_mark = "@huanghun",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			player:setMark("huanghun", 0)
			room:setPlayerMark(player, "&huanghun", 0)
			if player:getMark("@huanghun") > 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:doLightbox("$huanghunQP")
					player:loseMark("@huanghun")
					local x = player:getJudgingArea():length()
					for _, c in sgs.qlist(player:getJudgingArea()) do
						room:throwCard(c, player)
					end
					player:drawCards(x + 1, self:objectName())
					player:addMark("huanghun")
					room:addPlayerMark(player, "&huanghun")
				end
			end
		end
	end
}
huanghunPS = sgs.CreateProhibitSkill{
	name = "#huanghunPS",
	is_prohibited = function(self, from, to, card)
		if to:getMark("huanghun") > 0 then
			return card:isKindOf("DelayedTrick")
		end
	end
}
extension:insertRelatedSkills("huanghun", "#huanghunPS")
Olaf:addSkill(lumang)
Olaf:addSkill(huanghun)
Olaf:addSkill(huanghunPS)
sgs.LoadTranslationTable{
	["Olaf"] = "奥拉夫",
	["&Olaf"] = "奥拉夫",
	["#Olaf"] = "狂战士",

	["lumang"] = "鲁莽",
	["lumangCard"] = "鲁莽",
	[":lumang"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以选择攻击范围内的一名其他角色，你自减一点体力并对其造成1点伤害；额外的，若你选择的角色体力值不少于你，你回复1点体力。",
	
	["huanghun"] = "黄昏",
	[":huanghun"] = "<font color=\"red\"><b>限定技，</b></font>准备阶段开始时，你可以弃置你判定区所有牌，若如此做，你摸X张牌（X为你以此法弃置牌的数量+1），然后直到你下个回合开始，你不能成为延时锦囊牌的目标且“鲁莽”造成的伤害+1。",
	["@huanghun"] = "黄昏",
	["$huanghunQP"] = "黄昏",
}

--皮城女警·凯特琳
Caitlyn = sgs.General(extension, "Caitlyn", "wu", "3", false, false, false)
juji = sgs.CreateTriggerSkill{
	name = "juji",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			if not p:inMyAttackRange(player) then
				local room = player:getRoom()
				local msg = sgs.LogMessage()
				msg.type = "#juji"
				msg.from = player
				msg.to:append(p)
				room:sendLog(msg)
				room:broadcastSkillInvoke("juji", 1)
				local _data = sgs.QVariant()
				_data:setValue(p)
				jink_table[index] = 0
			end
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	end
}
jujiMod = sgs.CreateTargetModSkill{
	name = "#jujiMod",
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player:hasSkill("juji") then
			return 1
		end
	end,
}
jujiDis = sgs.CreateDistanceSkill{
	name = "#jujiDis",
	correct_func = function(self, from, to)
		if to:hasSkill("juji") then
			return to:getLostHp()
		end
	end
}
extension:insertRelatedSkills("juji", "#jujiMod")
extension:insertRelatedSkills("juji", "#jujiDis")
baotou = sgs.CreateTriggerSkill{
	name = "baotou", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DamageCaused}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		local count = damage.damage
		local reason = damage.card
		if damage.chain or damage.transfer or (not damage.by_user) then return false end
		if player:hasSkill(self:objectName()) then
			if reason then
				if reason:isKindOf("Slash") and not player:isKongcheng() then
					if room:askForCard(player, ".black", "@baotou-hur:" .. damage.to:objectName(), data, self:objectName()) then
						local msg = sgs.LogMessage()
						msg.type = "#baotouEffect"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = count
						count = count + 1
						msg.arg2 = count
						room:sendLog(msg)
						room:broadcastSkillInvoke("baotou")
						damage.damage = count
						data:setValue(damage)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
Caitlyn:addSkill(juji)
Caitlyn:addSkill(jujiMod)
Caitlyn:addSkill(jujiDis)
Caitlyn:addSkill(baotou)
sgs.LoadTranslationTable{
	["Caitlyn"] = "凯特琳",
	["&Caitlyn"] = "凯特琳",
	["#Caitlyn"] = "皮城女警",

	["juji"] = "狙击",
	["#jujiMod"] = "狙击",
	["#jujiDis"] = "狙击",
	[":juji"] = "<font color=\"blue\"><b>锁定技，</b></font>你的攻击范围+1；其他角色与你计算距离时始终+X（X为你已失去的体力值）；当你对一名角色使用【杀】时，若你不在其攻击范围内，则此【杀】不可闪避。",
	["#juji"] = "%from 的“<font color=\"yellow\"><b>狙击</b></font>”被触发，%to 不能使用【<font color=\"yellow\"><b>闪</b></font>】响应此【<font color=\"yellow\"><b>杀</b></font>】",
	
	["baotou"] = "爆头",
	[":baotou"] = "当你使用的【杀】造成伤害时，你可以弃置一张黑色手牌另此伤害+1。",
	["@baotou-hur"]	= "你可以弃置一张黑色手牌令此“杀”伤害+1。",
	["#baotouEffect"] = "%from 的技能“<font color=\"yellow\">爆头</font>”被触发， %to 受到的伤害从 %arg 点上升到 %arg2 点。",
}

--暴走萝莉·金克斯
Jinx = sgs.General(extension, "Jinx", "wu", "3", false, false, false)
qiangpao = sgs.CreateTriggerSkill{
	name = "qiangpao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			local choice = room:askForChoice(player, self:objectName(), "qiang+pao")
			if choice == "qiang" then
				room:broadcastSkillInvoke("qiangpao", 1)
				player:gainMark("@qiang")
			elseif choice == "pao" then
				room:broadcastSkillInvoke("qiangpao", 2)
				player:gainMark("@pao")
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if player:getMark("@qiang") == 0 and player:getMark("@pao") > 0 then
					room:broadcastSkillInvoke("qiangpao", 1)
					player:loseAllMarks("@pao")
					player:gainMark("@qiang")
				elseif player:getMark("@qiang") > 0 and player:getMark("@pao") == 0 then
					room:broadcastSkillInvoke("qiangpao", 2)
					player:loseAllMarks("@qiang")
					player:gainMark("@pao")	
				end
			end
		end
	end
}
qiangpaoMod = sgs.CreateTargetModSkill{
	name = "#qiangpaoMod",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill("qiangpao") and player:getMark("@qiang") > 0 then
			return 1
		else
			return 0
		end
	end,
	distance_limit_func = function(self, player, card)
		if player:hasSkill("qiangpao") and player:getMark("@pao") > 0 then
			return 1000
		end
	end,
}
extension:insertRelatedSkills("qiangpao", "#qiangpaoMod")
jiaohuo = sgs.CreateTriggerSkill{
	name = "jiaohuo" ,
	events = {sgs.DamageDone, sgs.DamageComplete} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if event == sgs.DamageDone then
			if card and card:isKindOf("Slash") then
				if damage.from and (damage.from:isAlive() and damage.from:hasSkill(self:objectName())) then
					local targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if (player:distanceTo(p) == 1) then
							targets:append(p)
						end
					end
					if targets:isEmpty() then return false end
					if damage.from:askForSkillInvoke(self:objectName(), data) then
						damage.from:drawCards(1, self:objectName())
						room:broadcastSkillInvoke("jiaohuo", math.random(1, 2))
						local target = room:askForPlayerChosen(damage.from, targets, self:objectName())
						local _data = sgs.QVariant()
						_data:setValue(target)
						damage.from:setTag("jiaohuoTarget", _data)
					end
				end
			end
			return false
		elseif event == sgs.DamageComplete then
			if damage.from == nil then return false end
			local target = damage.from:getTag("jiaohuoTarget"):toPlayer()
			damage.from:removeTag("jiaohuoTarget")
			if (not target) or (not damage.from) or (damage.from:isDead()) then return false end
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|heart"
			judge.good = false
			judge.reason = self:objectName()
			judge.who = damage.from
			room:judge(judge)
			if judge:isGood() then
				local jh_damage = sgs.DamageStruct()
				jh_damage.nature = sgs.DamageStruct_Fire
				jh_damage.from = damage.from
				jh_damage.to = target
				room:damage(jh_damage)
			end
			return false
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
Jinx:addSkill(qiangpao)
Jinx:addSkill(qiangpaoMod)
Jinx:addSkill(jiaohuo)
sgs.LoadTranslationTable{	
	["Jinx"] = "金克斯",
	["&Jinx"] = "金克斯",
	["#Jinx"] = "暴走萝莉",
	
	["qiangpao"] = "枪炮",
	["#qiangpaoMod"] = "枪炮",
	[":qiangpao"] = "<font color=\"blue\"><b>锁定技，</b></font>游戏开始时，你获得一枚“枪/炮”标记并选择一个朝向；准备阶段开始时，你须改变“枪/炮”标记的朝向。若你的标记为“枪”朝上，出牌阶段你可以额外使用一张【杀】；若你的标记为“炮”朝上，你使用的【杀】无距离限制。",
	["qiang"] = "“枪”朝上",
	["pao"] = "“炮”朝上",
	["@qiang"] = "枪",
	["@pao"] = "炮",
	["$qiangpao1"] = "",
	["$qiangpao2"] = "",

	["jiaohuo"] = "嚼火",
	[":jiaohuo"] = "当你使用【杀】对一名角色造成伤害后，你可以选择一名其距离为1的另外一名角色，你摸一张牌并进行一次判定：若判定结果不为<font color=\"red\">♥</font>，你对选择的角色造成一点火焰伤害。",
	["$jiaohuo"] = "",
}

--迅捷斥候·提莫
Teemo = sgs.General(extension, "Teemo", "wu", "3", true, false, false)
zhimang = sgs.CreateTriggerSkill{
	name = "zhimang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card:isKindOf("Slash") and damage.to:isAlive() then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke("zhimang", math.random(1, 2))
				room:setPlayerCardLimitation(damage.to, "use", "Slash", false)
				room:addPlayerMark(damage.to, "&zhimang+to+#"..player:objectName().. "-SelfClear")
			end
		end
	end,
}
zhimangClear = sgs.CreateTriggerSkill{
	name = "#zhimangClear",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			for _, m in sgs.list(player:getMarkNames()) do
				if m:startsWith("&zhimang+") and player:getMark(m) > 0 then
					room:setPlayerMark(player, m, 0)
					room:removePlayerCardLimitation(player, "use", "Slash")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}
extension:insertRelatedSkills("zhimang", "#zhimangClear")
moguCard = sgs.CreateSkillCard{
	name = "moguCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local muthroom = source:getPile("muthroom")
		local subs = self:getSubcards()
		if subs:isEmpty() then
			for _,card_id in sgs.qlist(muthroom) do
				room:obtainCard(source, card_id)
			end
		else
			for _,card_id in sgs.qlist(subs) do
				source:addToPile("muthroom", card_id)
			end
		end
	end
}
moguVS = sgs.CreateViewAsSkill{
	name = "mogu",
	n = 4,
	view_filter = function(self, selected, to_select)
		for _,card in ipairs(selected) do
			if to_select:getSuit() == card:getSuit() then return false end
		end
		for _, id in sgs.qlist(sgs.Self:getPile("muthroom")) do
			if to_select:getSuit() == sgs.Sanguosha:getCard(id):getSuit() then return false end
		end
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		local n = sgs.Self:getPile("muthroom"):length()
		if #cards > 0 and #cards <= 4 - n then
			local card = moguCard:clone()
			for _,cd in pairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng() and not player:hasUsed("#moguCard")
	end
}
mogu = sgs.CreateTriggerSkill{
	name = "mogu", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardUsed, sgs.CardResponded}, 
	view_as_skill = moguVS,
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local card
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponded then
			card = data:toCardResponse().m_card
		end
		local suit = card:getSuit()
		for _, teemo in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			for _,id in sgs.qlist(teemo:getPile("muthroom")) do
				local c = sgs.Sanguosha:getCard(id)
				if c:getSuit() == suit and player:objectName() ~= teemo:objectName() then
					local dest = sgs.QVariant()
					dest:setValue(player)
					if teemo:askForSkillInvoke("moguhit", dest) then
						room:broadcastSkillInvoke("mogu", math.random(1, 2))
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "mogu", "");
						room:throwCard(c, reason, nil);
						room:damage(sgs.DamageStruct("mogu", teemo, player))
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}
Teemo:addSkill(zhimang)
Teemo:addSkill(zhimangClear)
Teemo:addSkill(mogu)
sgs.LoadTranslationTable{	
	["Teemo"] = "提莫",
	["&Teemo"] = "提莫",
	["#Teemo"] = "迅捷斥候",

	["zhimang"] = "致盲",
	[":zhimang"] = "当你使用【杀】对一名角色造成伤害后，你可以令其不可使用【杀】直到其下个回合结束。",
	["$zhimang1"] = "",
	["$zhimang2"] = "",
	
	["mogu"] = "蘑菇",
	["moguCard"] = "蘑菇",
	[":mogu"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将任意张花色互不相同的手牌放置在你的武将牌上，称之为“蘑菇”（需与其他“蘑菇”花色均不同）。每当其他角色使用或打出一张牌时，你可以弃置与该牌相同花色的“蘑菇”视为你对该角色造成1点伤害。",
	["muthroom"] = "蘑菇",
	["moguhit"] = "蘑菇",
	["$mogu1"] = "",
	["$mogu2"] = "",
}

--机械先驱·维克托（所需大量标记，AI不完善）
Victor = sgs.General(extension, "Victor", "qun", "3", true, false, false)
Mohe = sgs.CreateTriggerSkill{
	name = "Mohe",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			local choices = {}
			for i = 0, 10000 do
				local card = sgs.Sanguosha:getEngineCard(i)
				if card == nil then break end
				if card:isKindOf("Weapon") and not table.contains(choices, card:objectName()) then
					table.insert(choices, card:objectName())
				end
			end
			table.insert(choices, "cancel")
			local choice = room:askForChoice(player, "Mohe", table.concat(choices, "+"))
			local old = player:property("Mohe"):toString()
			room:setPlayerMark(player, "&Mohe+" .. old, 0)
			if choice ~= "cancel" then
				room:setPlayerProperty(player, "Mohe", sgs.QVariant(choice))
				room:setPlayerMark(player, "&Mohe+" .. choice, 1)
			end
		end
	end,
}
Mohe_equip = sgs.CreateViewAsEquipSkill {
	name = "#Mohe_equip",
	view_as_equip = function(self, player)
		return "" .. player:property("Mohe"):toString()
	end,
}
ZhongliCard = sgs.CreateSkillCard{
	name = "ZhongliCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("Zhongli") --播放配音
		local target = targets[1]
		target:gainMark("@ZhongliTarget", 1)
		local ZhongliTargets = source:getTag("ZhongliTargets"):toString():split("+")
		table.insert(ZhongliTargets, target:objectName())
		source:setTag("ZhongliTargets", sgs.QVariant(table.concat(ZhongliTargets, "+")))
	end,
}
ZhongliVS = sgs.CreateViewAsSkill{
	name = "Zhongli",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = ZhongliCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:isNude() then
			return false
		elseif player:hasUsed("#ZhongliCard") then
			return false
		end
		return true
	end,
}
Zhongli = sgs.CreateTriggerSkill{
	name = "Zhongli",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged, sgs.EventPhaseStart},
	view_as_skill = ZhongliVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local victim = damage.to
			if victim and victim:objectName() == player:objectName() then
				if victim:getMark("@ZhongliTarget") > 0 then
					victim:gainMark("@ZhongliDist", damage.damage)
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				local ZhongliTargets = player:getTag("ZhongliTargets"):toString():split("+")
				local alives = room:getAlivePlayers()
				for _,name in ipairs(ZhongliTargets) do
					for _,p in sgs.qlist(alives) do
						if p:objectName() == name then
							p:loseMark("@ZhongliTarget", 1)
							p:loseAllMarks("@ZhongliDist")
						end
					end
				end
				player:removeTag("ZhongliTargets")
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
ZhongliDist = sgs.CreateDistanceSkill{
	name = "#ZhongliDist",
	correct_func = function(self, from, to)
		return from:getMark("@ZhongliDist")
	end,
}
extension:insertRelatedSkills("Zhongli", "#ZhongliDist")
Victor:addSkill(Mohe)
Victor:addSkill(Mohe_equip)
extension:insertRelatedSkills("Mohe", "#Mohe_equip")
Victor:addSkill(Zhongli)
Victor:addSkill(ZhongliDist)
sgs.LoadTranslationTable{
	["Victor"] = "维克托",
	["&Victor"] = "维克托",
	["#Victor"] = "机械先驱",
	
	["Mohe"] = "魔核",
	[":Mohe"] = "准备阶段开始时，你须声明一种武器牌；直到你下个回合开始阶段，你可以发动你声明的武器牌的技能。",
	["$Mohe"] = "技能 魔核 的台词",
	["@MHCrossbow"] = "诸葛连弩",
	["@MHDoubleSword"] = "雌雄双股剑",
	["@MHQinggangSword"] = "青釭剑",
	["@MHBlade"] = "青龙偃月刀",
	["@MHSpear"] = "丈八蛇矛",
	["@MHAxe"] = "贯石斧",
	["@MHHalberd"] = "方天画戟",
	["@MHKylinBow"] = "麒麟弓",
	["@MHIceSword"] = "寒冰剑",
	["@MHGudingBlade"] = "古锭刀",
	["@MHFan"] = "朱雀羽扇",
	["@MHMoonSpear"] = "银月枪",
	["@MHSPMoonSpear"] = "SP银月枪",
	["@MHInfinityEdge"] = "无尽之刃",
	["@MHBloodthirster"] = "饮血剑",
	["@MHDeathcap"] = "灭世者之帽",
	["@MHWilloftheAncients"] = "远古意志",
	["@MHZither"] = "镇魂琴",
	["@MHfeishi"] = "飞矢",
	
	["Zhongli"] = "重力",
	["ZhongliCard"] = "重力",
	[":Zhongli"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张牌并指定一名角色，直到你的下个回合开始阶段，该角色每受到1点伤害后，其与其他角色计算距离时便+1。",
	["$Zhongli"] = "技能 重力 的台词",
	["ZhongliCard"] = "重力",
	["@ZhongliTarget"] = "力",
	["@ZhongliDist"] = "重",
	["#ZhongliDist"] = "重力",
	["zhongli"] = "重力",
}

--沙漠皇帝·阿兹尔（没做AI）
Azir = sgs.General(extension, "Azir", "qun", "3", true, false, false)
shabingCard = sgs.CreateSkillCard{
	name = "shabingCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local soldier = source:getPile("soldier")
		local subs = self:getSubcards()
		if subs:isEmpty() then
			for _,card_id in sgs.qlist(soldier) do
				room:obtainCard(source, card_id)
			end
		else
			for _,card_id in sgs.qlist(subs) do
				source:addToPile("soldier", card_id)
			end
		end
	end
}
shabing = sgs.CreateViewAsSkill{
	name = "shabing",
	n = 4,
	view_filter = function(self, selected, to_select)
		for _,card in ipairs(selected) do
			if to_select:getSuit() == card:getSuit() then return false end
		end
		for _, id in sgs.qlist(sgs.Self:getPile("soldier")) do
			if to_select:getSuit() == sgs.Sanguosha:getCard(id):getSuit() then return false end
		end
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		local n = sgs.Self:getPile("soldier"):length()
		if #cards > 0 and #cards <= 4 - n then
			local card = shabingCard:clone()
			for _,cd in pairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng() and not player:hasUsed("#shabingCard")
	end
}

jinjunCard = sgs.CreateSkillCard {
	name = "jinjunCard",
	will_throw = false,

	filter = function(self, targets, to_select)
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
		return card and card:targetFilter(plist, to_select, sgs.Self) and
			not sgs.Self:isProhibited(to_select, card, plist)
	end,
	feasible = function(self, targets, from)
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
		return card and card:targetsFeasible(plist, from)
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local aocaistring = self:getUserString()
		local suits = {}
		for _, id in sgs.qlist(user:getPile("soldier")) do
			if not table.contains(suits, sgs.Sanguosha:getCard(id):getSuitString()) then
				table.insert(suits, sgs.Sanguosha:getCard(id):getSuitString())
			end
		end
		local judge = sgs.JudgeStruct()
		judge.pattern = ".|"..table.concat(suits,",")
		judge.reason = "jinjun"
		judge.play_animation = false
		judge.who = user
		room:judge(judge)
		if judge:isGood() then
			for _, id in sgs.qlist(user:getPile("soldier")) do
				if judge.card:getSuitString() ==  sgs.Sanguosha:getCard(id):getSuitString() then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE,"","jinjun","")
					room:throwCard(sgs.Sanguosha:getCard(id), reason, nil)
					break
				end
			end
			local use_card = sgs.Sanguosha:cloneCard(aocaistring, sgs.Card_NoSuit, 0)
			use_card:setSkillName("jinjun")
			user:drawCards(1, "jinjun")
			return use_card
		else
			room:setPlayerFlag(user, "Global_jinjunFailed")
		end
		return nil
	end,
	on_validate = function(self, cardUse)
		local user = cardUse.from
		local room = user:getRoom()
		local aocaistring = self:getUserString()
		local suits = {}
		for _, id in sgs.qlist(user:getPile("soldier")) do
			if not table.contains(suits, sgs.Sanguosha:getCard(id):getSuitString()) then
				table.insert(suits, sgs.Sanguosha:getCard(id):getSuitString())
			end
		end
		local judge = sgs.JudgeStruct()
		judge.pattern = ".|"..table.concat(suits,",")
		judge.reason = "jinjun"
		judge.play_animation = false
		judge.who = user
		room:judge(judge)
		if judge:isGood() then
			for _, id in sgs.qlist(user:getPile("soldier")) do
				if judge.card:getSuitString() ==  sgs.Sanguosha:getCard(id):getSuitString() then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE,"","jinjun","")
					room:throwCard(sgs.Sanguosha:getCard(id), reason, nil)
					break
				end
			end
			local use_card = sgs.Sanguosha:cloneCard(aocaistring, sgs.Card_NoSuit, 0)
			use_card:setSkillName("jinjun")
			user:drawCards(1, "jinjun")
			return use_card
		else
			room:setPlayerFlag(user, "Global_jinjunFailed")
		end
		return nil
	end
}
jinjunVS = sgs.CreateZeroCardViewAsSkill {
	name = "jinjun",
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if player:getPhase() ~= sgs.Player_NotActive or player:hasFlag("Global_jinjunFailed") then return false end
		if player:getPile("soldier"):isEmpty() then return false end
		if string.find(pattern,"slash") or string.find(pattern,"jink") then
			return true
		end
		return false
	end,
	view_as = function(self)
		local acard = jinjunCard:clone()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		local names = pattern:split("+")
        if #names ~= 1 then pattern = names[1] end
        if pattern == "Slash" then pattern = "slash" end
        if pattern == "Jink" then pattern = "jink" end
		acard:setUserString(pattern)
		return acard
	end
}
jinjun = sgs.CreateTriggerSkill{
	name = "jinjun", 
	view_as_skill = jinjunVS,
	events = {sgs.CardAsked}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local soldier = player:getPile("soldier")
		if soldier:length() > 0 then
			if event == sgs.CardAsked then
				local pattern = data:toStringList()[1]
				if player:getPhase() == sgs.Player_NotActive then
					if pattern == "jink" or pattern == "slash" then
						
						local js
						if pattern == "jink" then
							js = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
						elseif pattern == "slash" then
							js = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
							if data:toStringList()[3] == "use" then
								return false
							end
						end
						local suits = {}
						for _, id in sgs.qlist(player:getPile("soldier")) do
							if not table.contains(suits, sgs.Sanguosha:getCard(id):getSuitString()) then
								table.insert(suits, sgs.Sanguosha:getCard(id):getSuitString())
							end
						end
						if player:askForSkillInvoke(self:objectName(), data) then
							local judge = sgs.JudgeStruct()
							judge.pattern = ".|"..table.concat(suits,",")
							judge.reason = self:objectName()
							judge.play_animation = false
							judge.who = player
							room:judge(judge)
							if judge:isGood() then
								for _, id in sgs.qlist(player:getPile("soldier")) do
									if judge.card:getSuitString() ==  sgs.Sanguosha:getCard(id):getSuitString() then
										local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE,"",self:objectName(),"")
										room:throwCard(sgs.Sanguosha:getCard(id), reason, nil)
										break
									end
								end
								js:setSkillName(self:objectName())
								room:provide(js)
								player:drawCards(1, self:objectName())
								return true
							else
								room:setPlayerFlag(player, "Global_jinjunFailed")
							end
						end
					end
				end
				return false
			end
		end
	end,
}
liusha = sgs.CreateTriggerSkill{
	name = "liusha",
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish and player:getPile("soldier"):length() >= 4 then
			local other = room:getOtherPlayers(player)
			local victims = sgs.SPlayerList()
			for _,p in sgs.qlist(other) do
				if player:inMyAttackRange(p) then
					victims:append(p)
				end
			end
			local target = room:askForPlayerChosen(player, victims, self:objectName(), "liushainvoke", true, true)
			if not target then return false end
			local soldier = player:getPile("soldier")
			local to_throw = sgs.IntList()
			for i = 0,3,1 do
				local card_id = 0
				room:fillAG(soldier, player)
				if soldier:length() == 4 - i then
					card_id = soldier:first()
				else
					card_id = room:askForAG(player, soldier, false, self:objectName())
				end
				room:clearAG(player)
				soldier:removeOne(card_id)
				to_throw:append(card_id)
			end
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _,id in sgs.qlist(to_throw) do
				slash:addSubcard(id)
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE,"",self:objectName(),"")
			room:throwCard(slash, reason, nil)
			slash:deleteLater()
			room:damage(sgs.DamageStruct("liusha", player, target))
			target:turnOver()
		end
		return false
	end,
	
}
Azir:addSkill(shabing)
Azir:addSkill(jinjun)
Azir:addSkill(liusha)
sgs.LoadTranslationTable{
	["Azir"] = "阿兹尔",
	["&Azir"] = "阿兹尔",
	["#Azir"] = "沙漠皇帝",

    ["shabing"] = "沙兵",
	["shabingCard"] = "沙兵",
	[":shabing"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将任意张花色互不相同的手牌放置在你的武将牌上，称之为“兵”（需与其他“兵”花色均不同）。",
	["soldier"] = "兵",
	
	["jinjun"] = "禁军",
	["jinjunCard"] = "禁军",
	--[":jinjun"] = "每当你需要使用或打出一张【杀】或【闪】时，若你的武将牌上有“兵”，你可以进行一次判定（你的出牌阶段限2次）：你弃置一张与判定牌相同花色的“兵”，视为你使用或打出一张【杀】或【闪】，然后你摸一张牌。",
	[":jinjun"] = "每当你于回合外需要使用或打出一张【杀】或【闪】时，若你的武将牌上有“兵”，你可以进行一次判定：你弃置一张与判定牌相同花色的“兵”，视为你使用或打出一张【杀】或【闪】，然后你摸一张牌。",

	["liusha"] = "流沙",
	[":liusha"] = "回合结束阶段，你可以弃置4张“兵”并选择攻击范围内的一名角色，你对其造成1点伤害并将其武将牌翻面。",
	["liushainvoke"] = "请选择攻击范围内的一名角色",
}

--疾风剑豪·亚索
Yasuo = sgs.General(extension, "Yasuo", "qun", "3", true, false, false)
langke = sgs.CreateTriggerSkill{
	name = "langke",  
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardResponded, sgs.DamageInflicted, sgs.DamageCaused},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		if (event == sgs.CardUsed or event == sgs.CardResponded) then
			local card
			if event == sgs.CardUsed then
				local use = data:toCardUse()
				card = use.card
			elseif event == sgs.CardResponded then
				card = data:toCardResponse().m_card
			end
			if card and card:isKindOf("BasicCard") then
				player:gainMark("@lang")
			end
		elseif event == sgs.DamageInflicted then
			if player:getMark("@lang") >= 4 then
				if room:askForSkillInvoke(player, "langkea", data) then
					player:loseMark("@lang", 4)
					local msg = sgs.LogMessage()
					msg.type = "#langkemsga"
					msg.from = player
					msg.to:append(player)
					room:sendLog(msg)
					room:broadcastSkillInvoke("langke", math.random(1, 2))
					damage.prevented = true
					data:setValue(damage)
					return true
				end
			end
		elseif event == sgs.DamageCaused then
			if player:getMark("@lang") >= 4 then
				if room:askForSkillInvoke(player, "langkeb", data) then
					player:loseMark("@lang", 4)
					local count = damage.damage
					local msg = sgs.LogMessage()
					msg.from = player
					msg.type = "#langkemsgb"
					msg.arg = count
					count = count + 1
					msg.arg2 = count
					msg.to:append(damage.to)
					room:sendLog(msg)
					room:broadcastSkillInvoke("langke", math.random(3, 4))
					damage.damage = count
					data:setValue(damage)
				end
			end
		end
	end
}
fengbi = sgs.CreateTriggerSkill{
	name = "fengbi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardEffected, sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("Slash") then
				--if not player:inMyAttackRange(effect.from) then
				if player:askForSkillInvoke(self:objectName()) then
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|black"
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					if judge:isGood() then
						local msg = sgs.LogMessage()
						msg.type = "#fengbimsga"
						msg.from = player
						msg.to:append(player)
						room:sendLog(msg)
						room:broadcastSkillInvoke("fengbi", math.random(1, 2))
						player:addMark("feng")
						room:askForUseCard(player, "slash", "@askforslash", -1, sgs.Card_MethodUse, false, nil, nil, "fengbiSlash")
						player:setMark("feng", 0)
						return true
					end
				end
				--end
			return false
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("fengbiSlash") then
				local hurt = damage.damage
				local msg = sgs.LogMessage()
				msg.type = "#fengbimsgb"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = hurt
				hurt = hurt + 1
				msg.arg2 = hurt
				room:sendLog(msg)
				damage.damage = hurt
				data:setValue(damage)
			end
		end
	end,
}
Yasuo:addSkill(langke)
Yasuo:addSkill(fengbi)
sgs.LoadTranslationTable{
	["Yasuo"] = "亚索",
	["&Yasuo"] = "亚索",
	["#Yasuo"] = "疾风剑豪",

	["langke"] = "浪客",
	[":langke"] = "每当你使用或打出一张基本牌时，你获得一枚“浪”标记；当你造成（受到）伤害时，若你拥有的“浪”标记数不少于4枚，你可以弃置4枚“浪”标记，令此伤害+1（防止此伤害）。",
	["@lang"] = "浪",
	["langkea"] = "浪客（抵消伤害）",
	["langkeb"] = "浪客（伤害+1）",
	["#langkemsga"] = "%from 的“<font color=\"yellow\"><b>浪客</b></font>”被触发，%from 不会受到任何伤害",
	["#langkemsgb"] = "%from 的“<font color=\"yellow\"><b>浪客</b></font>”被触发，%to 受到的伤害从 %arg 点上升到 %arg2 点",

	["fengbi"] = "风壁",
	[":fengbi"] = "当你成为【杀】的目标时，你可以进行一次判定：若结果为黑色：此【杀】对你无效，然后你可以对攻击范围内的一名角色使用一张【杀】，且此【杀】造成的伤害+1。",
	["#fengbimsga"] = "%from 的“<font color=\"yellow\"><b>风壁</b></font>”被触发，此【<font color=\"yellow\"><b>杀</b></font>】对 %from 无效",
	["#fengbimsgb"] = "%from 的“<font color=\"yellow\"><b>风壁</b></font>”被触发，%to 受到的伤害从 %arg 点上升到 %arg2 点",
}

--齐天大圣·孙悟空
Wukong = sgs.General(extension, "Wukong", "god", "4", true, false, false)
tengyun = sgs.CreateTargetModSkill{
	name = "tengyun",
	pattern = "Slash",
	extra_target_func = function(self, from)
		if from:hasSkill(self:objectName()) and (not from:hasUsed("Slash")) then
			return 1
		end
	end,
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) and (not player:hasUsed("Slash")) then
			return 999
		end
	end,
}
jingang = sgs.CreateTriggerSkill{
	name = "jingang",
	events = {sgs.Damage} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local target = damage.to
		if damage.card and damage.card:isKindOf("Slash") and target:getArmor() and (not damage.chain) and (not damage.transfer) then
			local Armorlist = {}
			if player:canDiscard(target, target:getArmor():getEffectiveId()) or (player:getArmor() == nil) then
				table.insert(Armorlist,tostring(i))
			end
			if #Armorlist == nil then return false end
			if player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke("jingang", math.random(1, 2))
				local _data = sgs.QVariant()
				_data:setValue(target)
				local card = target:getArmor()
				local card_id = card:getEffectiveId()
				local choicelist = {}
				if player:canDiscard(target, card_id) then
					table.insert(choicelist, "throw")
				end
				if player:getArmor() == nil then
					table.insert(choicelist, "movearmor")
				end
				local choice = room:askForChoice(player, "jingang", table.concat(choicelist, "+"), data)
				if choice == "movearmor" then
					room:moveCardTo(card, player, sgs.Player_PlaceEquip)
				else
					room:throwCard(card, target, player)
				end
			end
		end
		return false
	end
}
Wukong:addSkill(tengyun)
Wukong:addSkill(jingang)
sgs.LoadTranslationTable{
	["Wukong"] = "孙悟空",
	["&Wukong"] = "孙悟空",
	["#Wukong"] = "齐天大圣",
	
	["tengyun"] = "腾云",
	[":tengyun"] = "出牌阶段，你使用的第一张【杀】无距离限制，且可以额外指定一名角色为目标。",
	
	["jingang"] = "金刚",
	[":jingang"] = "每当你使用【杀】对一名角色造成一次伤害后，你可以将其防具牌弃置或置入你的装备区。",
	["throw"] = "弃置",
	["movearmor"] = "置入装备区",
}

--审判天使·凯尔
Kayle = sgs.General(extension, "Kayle", "god", "4", false, false, false)
shenyan = sgs.CreateTriggerSkill{
	name = "shenyan",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DrawNCards, sgs.TargetConfirmed}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			if draw.num > 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					draw.num = draw.num - 1
					room:setPlayerFlag(player, "shenyantar")
					room:broadcastSkillInvoke("shenyan", 1)
					room:addPlayerMark(player, "&shenyan-Clear")
					data:setValue(draw)
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local source = use.from
			local slash = use.card
			if source and source:objectName() == player:objectName() then
				if slash and slash:isKindOf("Slash") then
					if player:hasFlag("shenyantar") then
						room:broadcastSkillInvoke("shenyan", 2) --播放配音
						local do_anim = false
						for _,p in sgs.qlist(use.to) do
							if p:getMark("Equips_of_Others_Nullified_to_You") == 0 then
								local armor = p:getArmor()
								if armor and p:hasArmorEffect(armor:objectName()) then
									do_anim = true
								elseif p:hasArmorEffect("bazhen") then
									do_anim = true
								end
								p:addQinggangTag(slash)
							end
						end
					end
				end
			end
		end
	end
}
shenyanMod = sgs.CreateTargetModSkill{
	name = "#shenyanMod",
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player:hasSkill("shenyan") and player:hasFlag("shenyantar") then
			return 1000
		end
	end,
	extra_target_func = function(self, from, card)
		if from:hasSkill("shenyan") and from:hasFlag("shenyantar") then
			return 1
		else
			return 0
		end
	end
}
extension:insertRelatedSkills("shenyan", "#shenyanMod")
bihuCard = sgs.CreateSkillCard{
	name = "bihuCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local keystr = string.format("bihuSource%d", self:getEffectiveId())
		local tag = sgs.QVariant()
		tag:setValue(source)
		room:setTag(keystr, tag)
		local cards = self:getSubcards()
		for _,id in sgs.qlist(cards) do
			target:gainMark("@bihu")
			room:broadcastSkillInvoke("bihu", math.random(1, 2))
		end
	end
}
bihuVS = sgs.CreateViewAsSkill{
	name = "bihu",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = bihuCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@bihu"
	end
}
bihu = sgs.CreateTriggerSkill{
	name = "bihu", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseChanging, sgs.DamageInflicted, sgs.EventPhaseStart, sgs.Death}, 
	view_as_skill = bihuVS, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if player:isAlive() and player:hasSkill(self:objectName()) then
				if change.to == sgs.Player_NotActive then
					room:askForUseCard(player, "@@bihu", "@bihuinvoke")
					return false
				end
			end
		elseif event == sgs.DamageInflicted then
			if player:getMark("@bihu") > 0 then
				local msg = sgs.LogMessage()
				msg.type = "#bihumsg"
				msg.from = player
				msg.to:append(player)
				room:sendLog(msg)
				local damage = data:toDamage()
				damage.prevented = true
				data:setValue(damage)
				return true
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then
				if player:hasSkill(self:objectName()) then
					for _,p in sgs.qlist(room:getAllPlayers()) do
						if p:getMark("@bihu") > 0 then
							p:loseAllMarks("@bihu")
						end
					end
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:hasSkill(self:objectName()) then
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("@bihu") > 0 then
						p:loseAllMarks("@bihu")
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}
Kayle:addSkill(shenyan)
Kayle:addSkill(shenyanMod)
Kayle:addSkill(bihu)
sgs.LoadTranslationTable{
	["Kayle"] = "凯尔",
	["&Kayle"] = "凯尔",
	["#Kayle"] = "审判天使",
	
	["shenyan"] = "圣炎",
	[":shenyan"] = "摸牌阶段摸牌时，你可以少摸1张牌，若如此做，本回合你使用的【杀】无视距离和防具，且可以额外指定一名角色为目标。",
	
	["bihu"] = "庇护",
	["bihuCard"] = "庇护",
	[":bihu"] = "回合结束时，你可以弃置一张装备牌并指定一名角色：直到你下个回合开始，其不会受到任何伤害。",
	["@bihu"] = "庇护",
	["@bihudis"] = "你可以弃置一张装备牌来发动“庇护”",
	["@bihuinvoke"] = "你可以发动“庇护”",
	["~bihu"] = "选择一张装备牌-->选择一名角色",
	["#bihumsg"] = "因“<font color=\"yellow\"><b>庇护</b></font>”的效果，%from 不会受到任何伤害",
}

--殇之木乃伊·阿木木
Amumu = sgs.General(extension, "Amumu", "god", "4", true, false, false)
juewang = sgs.CreateTriggerSkill{
	name = "juewang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|heart"
				judge.good = false
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				if judge:isGood() then
					room:broadcastSkillInvoke("juewang", math.random(1, 2))
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if room:askForCard(p, ".", "@juewangdis:", sgs.QVariant(), sgs.CardDiscarded) then
						else
							room:loseHp(p, 1)
						end
					end
				end
			end
		end
	end
}
zhouchuCard = sgs.CreateSkillCard{
	name = "zhouchuCard" ,
	filter = function(self, targets, to_select)
		return #targets == 0 and sgs.Self:canSlash(to_select,nil,false) and sgs.Self:inMyAttackRange(to_select)
	end,
	on_effect = function(self, effect)
		local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
		slash:setSkillName("zhouchu")
		local use = sgs.CardUseStruct()
		use.card = slash
		use.from = effect.from
		use.to:append(effect.to)
		effect.from:getRoom():useCard(use)
	end
}
zhouchuVS = sgs.CreateOneCardViewAsSkill{
	name = "zhouchu",
	view_filter = function(self,to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		local zhouchu = zhouchuCard:clone()
			zhouchu:addSubcard(cards)
        return zhouchu
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response=function(self, player, pattern)
		return pattern == "@@zhouchu"
	end
}
zhouchu = sgs.CreateTriggerSkill{
	name = "zhouchu",
	view_as_skill = zhouchuVS,
	events = {sgs.DamageInflicted, sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.DamageInflicted then
			if damage.damage > 1 then
				local count = damage.damage
				local msg = sgs.LogMessage()
				msg.type = "#zhouchuEffect"
				msg.from = damage.to
				msg.to:append(damage.to)
				msg.arg = count
				count = count - 1
				msg.arg2 = count
				damage.damage = count
				room:sendLog(msg)
				room:broadcastSkillInvoke("zhouchu", math.random(1, 2))
				if damage.damage < 1 then return true end
				data:setValue(damage)
			end
		elseif event == sgs.Damaged then
			for i=1, damage.damage, 1 do
				if not player:isKongcheng() then
					room:askForUseCard(player, "@@zhouchu","@zhouchu", -1,sgs.Card_MethodDiscard,false)
				end
			end
		end
	end
}
Amumu:addSkill(juewang)
Amumu:addSkill(zhouchu)
sgs.LoadTranslationTable{
	["Amumu"] = "阿木木",
	["&Amumu"] = "阿木木",
	["#Amumu"] = "殇之木乃伊",

	["juewang"] = "绝望",
	[":juewang"] = "准备阶段开始时，你可以进行一次判定：若结果为不为<font color=\"red\">♥</font>，其他所有角色需选择：弃置一张手牌或失去1点体力。",
	["@juewangdis"] = "请弃置一张手牌，否则失去一点体力",
	
	["zhouchu"] = "咒触",
	["zhouchuCard"] = "咒触",
	[":zhouchu"] = "当你受到一点伤害后，你可以弃置一张手牌并选择攻击范围内的一名其他角色，视为你对其使用一张【杀】。<font color=\"blue\"><b>锁定技，</b></font>当你受到一次大于1点的伤害时，此伤害-1。",
	["@zhouchu"] = "你可以发动“咒触”",
	["~zhouchu"] = "选择一张手牌-->选择攻击范围内的一名角色",
	["#zhouchuEffect"] = "%from 的“<font color=\"yellow\"><b>咒触</b></font>”被触发，%from 受到的伤害从 %arg 点下降到 %arg2 点",
}

--金属大师·莫德凯撒
Mordekaiser = sgs.General(extension, "Mordekaiser", "god", "4", true, false, false)
tieren = sgs.CreateTriggerSkill{
	name = "tieren", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damage, sgs.EventPhaseStart, sgs.DamageInflicted}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			local count = damage.damage
			local msg = sgs.LogMessage()
			msg.type = "#tieren_a"
			msg.from = player
			msg.to:append(damage.to)
			msg.arg = count
			room:sendLog(msg)
			room:broadcastSkillInvoke("tieren", 1)
			player:gainMark("@tie", count)			
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				local tiecou = player:getMark("@tie")
				if tiecou > 0 then
					local countx = (tiecou + 1)/2
					local msgx = sgs.LogMessage()
					msgx.type = "#tieren_a"
					msgx.from = player
					msgx.to:append(player)
					room:sendLog(msgx)
					room:broadcastSkillInvoke("tieren", 2)
					player:loseMark("@tie", countx)
					player:drawCards(countx, self:objectName())
				end
			end
		elseif event == sgs.DamageInflicted then
			local tienum = player:getMark("@tie")
			if tienum > 0 then
				local damage = data:toDamage()
				local damnum = damage.damage
				if tienum >= damnum then  --伤害小于或等于“铁”标记数，只失去相应数量的标记，不掉血
					local msg = sgs.LogMessage()
					msg.type = "#tieren_b"
					msg.from = player
					msg.to:append(player)
					msg.arg = damnum
					room:sendLog(msg)
					room:broadcastSkillInvoke("tieren", 3)
					player:loseMark("@tie", damnum)
					return true
				elseif tienum < damnum then  --伤害大于“铁”标记数，失去所有标记，受到伤害为（原伤害-失去的标记数）
					local hurt = damnum - tienum
					local msgx = sgs.LogMessage()
					msgx.type = "#tieren_b"
					msgx.from = player
					msgx.to:append(player)
					msgx.arg = tienum
					room:sendLog(msgx)
					room:broadcastSkillInvoke("tieren", 3)
					player:loseAllMarks("@tie")
					damage.damage = hurt
					data:setValue(damage)
				end
			end
		end
	end
}
kuilei = sgs.CreateTriggerSkill{
	name = "kuilei",
	frequency = sgs.Skill_Limited,
	limit_mark = "@kuilei",
	events = {sgs.EventPhaseStart, sgs.Death, sgs.EventPhaseChanging, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if player:hasSkill("kuilei") then
					room:setPlayerMark(player, "KuileiInvoked", 0)
					player:setTag("KuileiSkills", sgs.QVariant(""))
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			local victim = death.who
			if victim and victim:objectName() == player:objectName() then
				local reason = death.damage
				if reason then
					local killer = reason.from
					if killer and killer:isAlive() then
						if killer:hasSkill("kuilei") and killer:getMark("@kuilei") > 0 then
							if killer:getPhase() == sgs.Player_Play then
								room:setPlayerMark(killer, "KuileiInvoked", 1)
								local record = killer:getTag("KuileiSkills"):toString()
								local skillnames = record:split("+") or {}
								local skills = player:getVisibleSkillList()
								for _,skill in sgs.qlist(skills) do
									local can_acquire = true
									if skill:isAttachedLordSkill() then
										can_acquire = false
									elseif skill:isLordSkill() then
										can_acquire = false
									elseif skill:getFrequency() == sgs.Skill_Limited then
										can_acquire = false
									elseif skill:getFrequency() == sgs.Skill_Wake then
										can_acquire = false
									end
									if can_acquire then
										table.insert(skillnames, skill:objectName())
									end
								end
								record = table.concat(skillnames, "+")
								killer:setTag("KuileiSkills", sgs.QVariant(record))
							end
						end
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				if player:getMark("KuileiInvoked") > 0 then
					room:setPlayerMark(player, "KuileiInvoked", 0)
					if player:getMark("@kuilei") > 0 then
						if player:askForSkillInvoke("kuilei", data) then
							room:doLightbox("$kuileiQP")
							room:broadcastSkillInvoke("kuilei") --播放配音
							player:loseMark("@kuilei")
							local record = player:getTag("KuileiSkills"):toString()
							player:removeTag("KuileiSkills")
							local skillnames = record:split("+")
							if #skillnames > 0 then
								local acquired_skills = {}
								for _,skillname in ipairs(skillnames) do
									if not player:hasSkill(skillname) then
										room:acquireSkill(player, skillname)
										table.insert(acquired_skills, skillname)
									end
								end
								if #acquired_skills > 0 then
									record = table.concat(acquired_skills, "+")
									player:setTag("KuileiAcquiredSkills", sgs.QVariant(record))
								end
							end
							room:setPlayerMark(player, "KuileiExtraTurn", 1)
							room:addPlayerMark(player, "&kuilei-SelfClear")
							player:gainAnExtraTurn()
						end
					end
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				if player:getMark("KuileiExtraTurn") > 0 then
					room:setPlayerMark(player, "KuileiExtraTurn", 0)
					local record = player:getTag("KuileiAcquiredSkills"):toString()
					if record ~= "" then
						local acquired_skills = record:split("+")
						for _,skillname in ipairs(acquired_skills) do
							room:detachSkillFromPlayer(player, skillname)
							local skills = sgs.Sanguosha:getRelatedSkills(skillname)
							for _,skill in sgs.qlist(skills) do
								room:detachSkillFromPlayer(player, skill:objectName())
							end
						end
					end
					player:removeTag("KuileiAcquiredSkills")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return ( target ~= nil ) 
	end,
}
Mordekaiser:addSkill(tieren)
Mordekaiser:addSkill(kuilei)
sgs.LoadTranslationTable{
	["Mordekaiser"] = "莫德凯撒",
	["&Mordekaiser"] = "莫德凯撒",
	["#Mordekaiser"] = "金属大师",
	["@tie"] = "铁",
	["@kuilei"] = "傀儡",
	
	["tieren"] = "铁人",
	[":tieren"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你造成1点伤害后，你获得1枚“铁”标记；每当你受到伤害时，你弃置相应数量的“铁”标记以抵消相同数量的伤害（不足则全弃）；准备阶段开始时，若你有“铁”标记，你失去一半数量的“铁”标记（向上取整）并摸该数量的牌。",
	["#tieren_a"] = "%from 的“<font color=\"yellow\"><b>铁人</b></font>”被触发",
	["#tieren_b"] = "%from 的“<font color=\"yellow\"><b>铁人</b></font>”被触发，失去 %arg 枚“铁”标记以抵消 %arg 点伤害。",
	["$tieren1"] = "没有痛苦，就吸不到能量！",
	["$tieren2"] = "多么让人愉悦的痛苦啊！",
	["$tieren3"] = "你们的疾病支撑着我。",

	["kuilei"] = "傀儡",
	[":kuilei"] = "<font color=\"red\"><b>限定技，</b></font>若你于出牌阶段杀死至少一名角色，在此回合结束后你可以执行一个额外的回合，且该回合你获得你杀死角色的所有技能（主公技、限定技、觉醒技除外），直到该回合结束。",
	["$kuileiQP"] = "傀儡",
	["$kuilei"] = "痛苦恒久远！",
}

--沙漠死神·内瑟斯
Nasus = sgs.General(extension, "Nasus", "god", "4", true, false, false)
jihun = sgs.CreateTriggerSkill{
	name = "jihun" ,
	events = {sgs.DamageCaused, sgs.Death},
	frequency = sgs.Skill_Compulsory, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then return false end
			local killer = damage.from
			if death.damage then
				killer = death.damage.from
			else
				killer = nil
			end
			local current = player:getRoom():getCurrent()
			if killer and current and current:isAlive() then
				if killer:hasSkill(self:objectName()) then
					room:doLightbox("$jihunQP")
					room:broadcastSkillInvoke("jihun", 1)
					killer:gainMark("@hun")
				end
			end	
		elseif event == sgs.DamageCaused then
			local reason = damage.card
			if damage.chain or damage.transfer then return false end
			if player:getMark("@hun") > 0 then
				if player:hasSkill(self:objectName()) then
					if reason then
						if reason:isKindOf("Slash") or reason:isKindOf("Duel") then
							local count = player:getMark("@hun")
							local hurt = damage.damage
							local msg = sgs.LogMessage()
							msg.type = "#jihunEffect"
							msg.from = player
							msg.to:append(damage.to)
							msg.arg = hurt
							hurt = hurt + count
							msg.arg2 = hurt
							room:sendLog(msg)
							room:broadcastSkillInvoke("jihun", math.random(2, 3))
							damage.damage = hurt
							data:setValue(damage)
						end
					end	
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
shihun = sgs.CreateTriggerSkill{ 
	name = "shihun",
	events = {sgs.Damage},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.damage > 1 then
			if player:isWounded() then
				local recover = sgs.RecoverStruct()
				local msg = sgs.LogMessage()
				msg.type = "#shihunEffect"
				msg.from = player
				msg.to:append(player)
				room:sendLog(msg)
				room:broadcastSkillInvoke("shihun")
				recover.who = player
				room:recover(player, recover)
			end
		end
	end,
}
Nasus:addSkill(jihun)
Nasus:addSkill(shihun)
sgs.LoadTranslationTable{
	["Nasus"] = "内瑟斯",
	["&Nasus"] = "内瑟斯",
	["#Nasus"] = "沙漠死神",

	["@hun"] = "魂",
	["jihun"] = "汲魂",
	[":jihun"] = "<font color=\"blue\"><b>锁定技，</b></font>你为伤害来源的【杀】或【决斗】造成的伤害+X（X为你杀死的角色数）。",
	["#jihunEffect"] = "%from 的“<font color=\"yellow\"><b>汲魂</b></font>”被触发，%to 受到的伤害由 %arg 点上升到 %arg2 点。",
	["$jihunQP"] = "汲魂",
	["$jihun1"] = "生与死轮回不止；我们生，他们死！",
	["$jihun2"] = "你们的灵魂将会被女神称量。",
	["$jihun3"] = "他们的死亡就要降临了。",
	
	["shihun"] = "噬魂",
	[":shihun"] = "<font color=\"blue\"><b>锁定技，</b></font>当你造成一次伤害后，若此伤害大于1点，你回复1点体力。",
	["#shihunEffect"] = "%from 的“<font color=\"yellow\"><b>噬魂</b></font>”被触发",
	["$shihun"] = "为了恩赐，我愿意前往。",
}

--虚空恐惧·科’加斯
Cho_Gath = sgs.General(extension, "Cho_Gath", "god", "5", true, false, false)
shengyan = sgs.CreateTriggerSkill{
	name = "shengyan",
	events = {sgs.Death, sgs.AskForPeachesDone} ,
	frequency = sgs.Skill_Compulsory, 
	on_trigger = function(self, event, player, data)
		if event == sgs.Death then
			local room = player:getRoom()
			local death = data:toDeath()
			local damage = data:toDamage()
			if death.who:objectName() ~= player:objectName() then return false end
			local killer = damage.from
			if death.damage then
				killer = death.damage.from
			else
				killer = nil
			end
			local current = player:getRoom():getCurrent()
			if killer and current and current:isAlive() then
				if killer:hasSkill(self:objectName()) then
					local maxhp = killer:getMaxHp() + 1
					room:setPlayerProperty(killer, "maxhp", sgs.QVariant(maxhp))
					local recover = sgs.RecoverStruct()
					recover.who = killer
					room:recover(killer, recover) 
				end
			end
		elseif event == sgs.AskForPeachesDone then
			local room = player:getRoom()
			if player:hasSkill(self:objectName()) then
				if player:getHp() <= 0 then return false end
				room:loseMaxHp(player)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
roushi = sgs.CreateTriggerSkill{
	name = "roushi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.MaxHpChanged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:hasSkill(self:objectName()) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				player:drawCards(2, self:objectName())
			end
		end
	end
}
Cho_Gath:addSkill(shengyan)
Cho_Gath:addSkill(roushi)
sgs.LoadTranslationTable{
	["Cho_Gath"] = "科’加斯",
	["&Cho_Gath"] = "科’加斯",
	["#Cho_Gath"] = "虚空恐惧",

	["shengyan"] = "盛宴",
	[":shengyan"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你杀死一名角色，你增加1点体力值上限并回复1点体力；每当你于濒死状态被救活后，你失去1点体力值上限。",
	["$shengyan"] = "",

	["roushi"] = "肉食",
	[":roushi"] = "每当你的体力值上限发生变化时，你可以摸2张牌。",
	["$roushi"] = "",
}

--暗裔剑魔·亚托克斯
Aatrox = sgs.General(extension, "Aatrox", "god", "4", true, false, false)
xuechang = sgs.CreateTriggerSkill{
	name = "xuechang", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DamageCaused}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		local count = damage.damage
		local reason = damage.card
		if damage.chain or damage.transfer or (not damage.by_user) then return false end
		if player:hasSkill(self:objectName()) then
			if reason then
				if reason:isKindOf("Slash") or reason:isKindOf("Duel") then
					local choice = room:askForChoice(player, self:objectName(), "hurt+reco+cancel", data)
					if choice == "hurt" then
						room:loseHp(player, 1)
						local msg = sgs.LogMessage()
						msg.type = "#xuechang1Effect"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = count
						count = count + 1
						msg.arg2 = count
						room:sendLog(msg)
						room:broadcastSkillInvoke("xuechang", 1)
						damage.damage = count
						data:setValue(damage)
					elseif choice == "reco" then
						local msg = sgs.LogMessage()
						msg.type = "#xuechang2Effect"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = count
						count = count - 1
						msg.arg2 = count
						damage.damage = count
						room:sendLog(msg)
						room:broadcastSkillInvoke("xuechang", 2)
						if player:isWounded() then
							local recover = sgs.RecoverStruct()
							recover.who = player
							room:recover(player, recover)
						end
						if damage.damage < 1 then return true end
						data:setValue(damage)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
xuemo = sgs.CreateTriggerSkill{
	name = "xuemo", 
	frequency = sgs.Skill_Limited, 
	limit_mark = "@xuemo",
	events = {sgs.Damage, sgs.AskForPeaches}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			local count = damage.damage
			if count >= 2 then
				local msg = sgs.LogMessage()
				msg.type = "#xuemo"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = count
				room:sendLog(msg)
				room:broadcastSkillInvoke("xuemo", 1)
				player:gainMark("@moxue", 1)
			end
		elseif event == sgs.AskForPeaches then
			local xnum = player:getMark("@moxue")
			local dying_data = data:toDying()
			local source = dying_data.who
			if source:objectName() == player:objectName() and xnum > 0 then
				room:doLightbox("$xuemoQP")
				room:broadcastSkillInvoke("xuemo", 2)
				player:loseMark("@xuemo")
				for i=1 , xnum, 1 do
					player:loseMark("@moxue")
					if player:isWounded() then
						local recover = sgs.RecoverStruct()
						recover.who = player
						room:recover(player, recover)
					else
						player:drawCards(1, self:objectName())
					end
				end
			end
			return false
		end
	end,
	can_trigger = function(self, target)
		if target then
			if target:hasSkill(self:objectName()) then
				if target:isAlive() then
					return target:getMark("@xuemo") > 0
				end
			end
		end
		return false
	end
}
Aatrox:addSkill(xuechang)
Aatrox:addSkill(xuemo)
sgs.LoadTranslationTable{
	["Aatrox"] = "亚托克斯",
	["&Aatrox"] = "亚托克斯",
	["#Aatrox"] = "暗裔剑魔",

	["xuechang"] = "血偿",
	[":xuechang"] = "当你使用【杀】或【决斗】造成伤害时（你为伤害来源），你可以：\n1、自减一点体力，令此伤害+1；\n2、令此伤害-1，你回复1点体力。",
	["hurt"] = "自减一点体力，令此伤害+1",
	["reco"] = "令此伤害-1，回复1点体力",
	["#xuechang1Effect"] = "%from 的技能“<font color=\"yellow\">血偿</font>”被触发， %to 受到的伤害从 %arg 点上升到 %arg2 点。",
	["#xuechang2Effect"] = "%from 的技能“<font color=\"yellow\">血偿</font>”被触发， %to 受到的伤害从 %arg 点下降到 %arg2 点，%from 回复 <font color=\"yellow\">1</font> 点体力。",
	["$xuechang1"] = "",
	["$xuechang2"] = "",
	
	["xuemo"] = "血魔",
	[":xuemo"] = "<font color=\"red\"><b>限定技，</b></font><font color=\"blue\"><b>锁定技，</b></font>当你造成一次不小于2点的伤害时，你获得1枚“魔血”标记；当你濒死时，你依次弃置所有的“魔血”标记：每弃置一枚“魔血”标记你回复1点体力，体力回复满后每弃置一枚“魔血”你摸1张牌。",
	["@xuemo"] = "血魔",
	["@moxue"] = "魔血",
	["$xuemoQP"] = "血魔",
	["#xuemo"] = "%from 的技能“<font color=\"yellow\">血魔</font>”被触发",
	
}

--死亡颂唱者·卡尔萨斯
Karthus = sgs.General(extension, "Karthus", "god", "3", true, false, false)
huangwu = sgs.CreateViewAsSkill{
	name = "huangwu",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("Slash")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local fireattack = sgs.Sanguosha:cloneCard("FireAttack", suit, point)
			fireattack:setSkillName(self:objectName())
			fireattack:addSubcard(id)
			return fireattack
		end
	end
}
huangwuM = sgs.CreateTriggerSkill{
	name = "#huangwuM",
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if card and card:isKindOf("FireAttack") then
			room:broadcastSkillInvoke("huangwu", math.random(1, 2))
			player:drawCards(1, "huangwu")
		end
	end
}
huangwuMod = sgs.CreateTargetModSkill{
	name = "#huangwuMod",
	pattern = "TrickCard+^DelayedTrick",
	extra_target_func = function(self, from, card)
		if from:hasSkill("huangwu") then
			if card:isKindOf("FireAttack") then
				return 1
			end
		end
		return 0
	end,
}
extension:insertRelatedSkills("huangwu", "#huangwuM")
extension:insertRelatedSkills("huangwu", "#huangwuMod")
lingtiask = sgs.CreateTriggerSkill{
	name = "#lingtiask",
	events = {sgs.HpChanged, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.HpChanged then
			if player:getHp() < 1 then
				if player:hasSkill("lol_lingti") then
					if player:getMark("bsyz") > 0 then
						room:setTag("SkipGameRule",sgs.QVariant(tonumber(event)))
					elseif room:askForSkillInvoke(player, "lol_lingti", data) then
						room:doLightbox("$lingtiQP")
						local cards = player:getJudgingArea()
						local slash = sgs.Sanguosha:cloneCard("slash")
						slash:deleteLater()
						slash:addSubcards(cards)
						room:throwCard(slash, nil, nil)   --弃置判定区所有牌，和下面这段都可以用
						--[[for _, c in sgs.qlist(player:getJudgingArea()) do
							room:throwCard(c,player)
						end]]--
						if not player:faceUp() then
							player:turnOver()
						end
						room:broadcastSkillInvoke("lingti", math.random(1, 2))
						room:setTag(self:objectName(), sgs.QVariant())
						player:addMark("lol_lingti")  --获得标记以便获得额外回合
						player:addMark("bsyz")  --获得标记以便额外回合获得能力
						room:setTag("SkipGameRule",sgs.QVariant(tonumber(event)))
						room:addPlayerMark(player, "&lol_lingti-Clear")
					end
				end
			end
		elseif player:getPhase() == sgs.Player_NotActive then
			for _,p in sgs.qlist(player:getRoom():getAlivePlayers()) do
				p:setMark("lol_lingti", 0)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
lol_lingti = sgs.CreateTriggerSkill{
	name = "lol_lingti" ,
	events = {sgs.EventPhaseChanging},
	frequency = sgs.Skill_NotFrequent,
	priority = 1,
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		local karthus = player:getRoom():findPlayerBySkillName("lol_lingti")
		if (not karthus) or (karthus:getMark("lol_lingti") <= 0) then return false end
		local n = karthus:getMark("lol_lingti")
		karthus:setMark("lol_lingti",0)
		local p = karthus
		local playerdata = sgs.QVariant()
		playerdata:setValue(p)
		player:getRoom():setTag("lol_lingtiInvoke", playerdata)
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}
lingtiDo = sgs.CreateTriggerSkill{
	name = "#lingtiDo" ,
	events = {sgs.EventPhaseStart},
	priority = 1 ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("lol_lingtiInvoke") then
			local target = room:getTag("lol_lingtiInvoke"):toPlayer()
			room:removeTag("lol_lingtiInvoke")
			if target and target:isAlive() then
				target:addMark("killself")
				room:addPlayerMark(target, "&lol_lingti-Clear")
				target:gainAnExtraTurn()
			end
		end
	end,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end
}
lingtiC = sgs.CreateTriggerSkill{
	name = "#lingtiC" ,
	events = {sgs.DrawNCards, sgs.DamageInflicted, sgs.TurnedOver, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			room:broadcastSkillInvoke("lol_lingti", 3)
			draw.num = draw.num + 3
			data:setValue(draw)
		elseif event == sgs.DamageInflicted then
			room:broadcastSkillInvoke("lol_lingti", 4)
			room:sendCompulsoryTriggerLog(player, "lol_lingti", true)
			local damage = data:toDamage()
			damage.prevented = true
			data:setValue(damage)
			return true
		elseif event == sgs.TurnedOver then
			if not (player:faceUp()) then
				player:turnOver()
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				if player:getMark("killself") > 0 then
					room:killPlayer(player)
					room:sendCompulsoryTriggerLog(player, "lol_lingti", true)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill("lol_lingti") and target:getMark("bsyz") > 0
	end
}
lingtiP = sgs.CreateProhibitSkill{
	name = "#lingtiP",
	is_prohibited = function(self, from, to, card)
		if to:hasSkill("lol_lingti") and to:getMark("bsyz") > 0 then
			if to:objectName() ~= from:objectName() then
				return card:isKindOf("BasicCard") or card:isKindOf("TrickCard")
			end
		end
	end
}
extension:insertRelatedSkills("lol_lingti", "#lingtiask")
extension:insertRelatedSkills("lol_lingti", "#lingtiDo")
extension:insertRelatedSkills("lol_lingti", "#lingtiC")
extension:insertRelatedSkills("lol_lingti", "#lingtiP")
Karthus:addSkill(huangwu)
Karthus:addSkill(huangwuM)
Karthus:addSkill(huangwuMod)
Karthus:addSkill(lingtiask)
Karthus:addSkill(lol_lingti)
Karthus:addSkill(lingtiDo)
Karthus:addSkill(lingtiC)
Karthus:addSkill(lingtiP)
Karthus:addSkill("yeyan")
sgs.LoadTranslationTable{
	["Karthus"] = "卡尔萨斯",
	["&Karthus"] = "卡尔萨斯",
	["#Karthus"] = "死亡颂唱者",
	
	["huangwu"] = "荒芜",
	[":huangwu"] = "你可以将一张【杀】当【火攻】使用；<font color=\"blue\"><b>锁定技，</b></font>当你的【火攻】造成伤害时，你摸1张牌；你使用的【火攻】可以额外指定一个角色为目标。",

	["lol_lingti"] = "灵体",
	[":lol_lingti"] = "当你濒死时，你可以不死去，然后弃置判定区所有牌并将武将牌翻至正面朝上。若如此做，你不会受到任何伤害也不能成为其他角色任何牌的目标，当前角色回合结束后，你获得一个额外的回合，该回合摸牌阶段你额外摸3张牌；该回合结束后，你立即死亡。",
	["$lingtiQP"] = "灵体",
}

--深渊巨口·克格’莫
Kog_Maw = sgs.General(extension, "Kog_Maw", "god", "3", true, false, false)
shenghuaCard = sgs.CreateSkillCard{
	name = "shenghuaCard",
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		local cd = sgs.Sanguosha:getCard(self:getSubcards():first())

		local record = source:property("shenghuaRecords"):toString()
		local type = cd:getType()
		local records
		if (record) then
			records = record:split(",")
		end
		if records and not(table.contains(records, type) ) then
			table.insert(records, type)
		end
		if #records == 0 then return false end
		room:setPlayerProperty(source, "shenghuaRecords", sgs.QVariant(table.concat(records, ",")));
		for _, mark in sgs.list(source:getMarkNames()) do
			if (string.startsWith(mark, "&shenghua+#record") and source:getMark(mark) > 0) then
				room:setPlayerMark(source, mark, 0)
			end
		end
		local mark = "&shenghua+#record"
		for _, type in ipairs(records) do
			mark = mark .. "+" .. type
		end
		mark = mark .. "-Clear"
		room:setPlayerMark(source, mark, 1)
		if cd:isKindOf("BasicCard") then
			room:setPlayerFlag(source,"shenghuaBC")
			local msgA = sgs.LogMessage()
			msgA.type = "#shenghuaA"
			msgA.from = source
			room:sendLog(msgA)
		elseif cd:isKindOf("EquipCard") then
			room:setPlayerFlag(source,"shenghuaEC")
			local msgB = sgs.LogMessage()
			msgB.type = "#shenghuaB"
			msgB.from = source
			room:sendLog(msgB)
		elseif cd:isKindOf("TrickCard") then
			room:setPlayerFlag(source,"shenghuaTC")
			local msgC = sgs.LogMessage()
			msgC.type = "#shenghuaC"
			msgC.from = source
			room:sendLog(msgC)
		end
	end,
}
shenghua = sgs.CreateViewAsSkill{
	name = "shenghua",
	n = 1,
	view_filter = function(self, cards, to_select)
		if to_select:isKindOf("BasicCard") then
			return not sgs.Self:hasFlag("shenghuaBC")
		elseif to_select:isKindOf("EquipCard") then
			return not sgs.Self:hasFlag("shenghuaEC")
		elseif to_select:isKindOf("TrickCard") then
			return not sgs.Self:hasFlag("shenghuaTC")
		end
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = shenghuaCard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return true
	end
}
shenghuaTri = sgs.CreateTriggerSkill{
	name = "#shenghuaTri",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed, sgs.DamageCaused, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				if player:hasFlag("shenghuaTC") then
					local msg = sgs.LogMessage()
					msg.type = "#shenghuaEffect1"
					msg.from = player
					msg.to:append(p)
					room:sendLog(msg)
					room:broadcastSkillInvoke("shenghua", 1)
					local _data = sgs.QVariant()
					_data:setValue(p)
					jink_table[index] = 0
				end
				index = index + 1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
			return false
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			local count = damage.damage
			local reason = damage.card
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if player:hasFlag("shenghuaEC") then
				if reason and reason:isKindOf("Slash") then
					local msg = sgs.LogMessage()
					msg.type = "#shenghuaEffect2"
					msg.from = player
					msg.to:append(damage.to)
					msg.arg = count
					count = count + 1
					msg.arg2 = count
					room:sendLog(msg)
					room:broadcastSkillInvoke("shenghua", 2)
					damage.damage = count
					data:setValue(damage)
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				local records = {}
				room:setPlayerProperty(player, "shenghuaRecords", sgs.QVariant(table.concat(records, ",")))
			end
		end
	end,
}
shenghuaMod = sgs.CreateTargetModSkill{
	name = "#shenghuaMod",
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player:hasSkill("shenghua") and player:hasFlag("shenghuaBC") then
			return 1000
		end
	end,
}
extension:insertRelatedSkills("shenghua", "#shenghuaTri")
extension:insertRelatedSkills("shenghua", "#shenghuaMod")
lol_fushi = sgs.CreateTriggerSkill{
	name = "lol_fushi",
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage, sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local target
		if event == sgs.Damage then
			target = damage.to
		elseif event == sgs.Damaged then
			target = damage.from
		end
		if damage.to:objectName() ~= damage.from:objectName() then
			if damage.to:isAlive() and damage.from:isAlive() then
				for i=1, damage.damage, 1 do
					if target:getHandcardNum() > 0 then
						if player:askForSkillInvoke(self:objectName(), data) then
							room:showAllCards(target)
							room:askForCard(target, ".!", "@lol_fushidis:", sgs.QVariant(), sgs.CardDiscarded)
						end
					end
				end
			end
		end
	end
}
jingxi = sgs.CreateTriggerSkill{
	name = "jingxi" ,
	events = {sgs.Death} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		local targets = room:getAlivePlayers()
		local target = room:askForPlayerChosen(player, targets, self:objectName(), "jingxiinvoke", true, true)
		if not target then return false end
		room:loseHp(target, 3)
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}
Kog_Maw:addSkill(shenghua)
Kog_Maw:addSkill(shenghuaTri)
Kog_Maw:addSkill(shenghuaMod)
Kog_Maw:addSkill(lol_fushi)
--Kog_Maw:addSkill(jingxi)
sgs.LoadTranslationTable{
	["Kog_Maw"] = "克格’莫",
	["&Kog_Maw"] = "克格’莫",
	["#Kog_Maw"] = "深渊巨口",

	["shenghua"] = "生化",
	["shenghuaCard"] = "生化",
	[":shenghua"] = "出牌阶段，你可以弃置一张牌，依据你弃置牌的类型，你获得以下锁定技直到回合结束：基本牌：你使用的【杀】无视距离；锦囊牌：你使用的【杀】不可闪避；装备牌：你使用的【杀】造成的伤害+1。每种类型的牌每回合限一次。",
	["#shenghuaA"] = "%from 弃置了一张基本牌，本回合内 %from 使用的【<font color=\"yellow\"><b>杀</b></font>】无视距离",
	["#shenghuaB"] = "%from 弃置了一张装备牌，本回合内 %from 使用的【<font color=\"yellow\"><b>杀</b></font>】造成的伤害+1",
	["#shenghuaC"] = "%from 弃置了一张锦囊牌，本回合内 %from 使用的【<font color=\"yellow\"><b>杀</b></font>】不可闪避",
	["#shenghuaEffect1"] = "%from 的“<font color=\"yellow\"><b>生化</b></font>”被触发，%to 不能使用【<font color=\"yellow\"><b>闪</b></font>】响应此【<font color=\"yellow\"><b>杀</b></font>】",
	["#shenghuaEffect2"] = "%from 的“<font color=\"yellow\"><b>生化</b></font>”被触发，%to 受到的伤害从 %arg 点上升至 %arg2 点。",

	["lol_fushi"] = "腐蚀",
	[":lol_fushi"] = "当你对其他角色或其他角色对你造成1点伤害后，你可以令其展示所有手牌然后弃置一张手牌。",
	["@lol_fushidis"] = "请弃置一张手牌",

	["jingxi"] = "惊喜",
	[":jingxi"] = "你死亡时，你可以令一名其他角色失去3点体力。",
	["jingxiinvoke"] = "你可以选择一名角色发动“惊喜”",
}

--永恒梦魇·魔腾
Nocturne = sgs.General(extension, "Nocturne", "god", "4", true, false, false)
moyingCard = sgs.CreateSkillCard{
	name = "moyingCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:isKongcheng() then
				return false
			elseif to_select:objectName() == sgs.Self:objectName() then
				return false
			end
			return true
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:broadcastSkillInvoke("moying") --播放配音
		local success = source:pindian(target, "moying", self)
		if success then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("moying")
			local use = sgs.CardUseStruct()
			use.card = slash
			use.from = source
			use.to:append(target)
			room:useCard(use)
			slash:deleteLater()
			room:addPlayerMark(target, "&moying+to+#"..source:objectName().."-Clear")
			room:setFixedDistance(source, target, 1)
			local msg = sgs.LogMessage()
			msg.type = "#moyingSuccess"
			msg.from = source
			msg.to:append(target)
			room:sendLog(msg) --发送提示信息
		end
	end,
}
moyingVS = sgs.CreateViewAsSkill{
	name = "moying",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = moyingCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@moying"
	end,
}
moying = sgs.CreateTriggerSkill{
	name = "moying",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd},
	view_as_skill = moyingVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local others = room:getOtherPlayers(player)
		if player:getPhase() == sgs.Player_Draw then
			if player:isKongcheng() then return false end
			local can_invoke = false
			for _,p in sgs.qlist(others) do
				if not p:isKongcheng() then
					can_invoke = true
					break
				end
			end
			if can_invoke then
				room:askForUseCard(player, "@@moying", "@moyinginvoke")
			end
		elseif player:getPhase() == sgs.Player_Finish then
			for _,p in sgs.qlist(others) do
				room:removeFixedDistance(player, p, 1)
			end
		end
	end,
}
mengyanCard = sgs.CreateSkillCard{
	name = "mengyanCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:doLightbox("$mengyanQP")
		source:loseMark("@mengyan")
		local list = room:getOtherPlayers(source)
		for _,p in sgs.qlist(list) do
			-- p:setCardLimitation("use,response", ".|.|.|hand", true)
			room:setPlayerCardLimitation(p, "use,response", ".|.|.|hand", true)
		end
		room:setPlayerFlag(source, "mengyanTarget")
		local msg = sgs.LogMessage()
		msg.type = "#mengyan"
		msg.from = source
		msg.arg = "mengyan"
		room:sendLog(msg)
		room:broadcastSkillInvoke("mengyan", 1)
		room:addPlayerMark(source, "&mengyan-Clear")
	end,
}
mengyanVS = sgs.CreateZeroCardViewAsSkill{
	name = "mengyan",
	view_as = function()
		return mengyanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@mengyan") > 0
	end
}
mengyan = sgs.CreateTriggerSkill{
	name = "mengyan",
	frequency = sgs.Skill_Limited,
	limit_mark = "@mengyan",
	events = {sgs.EventPhaseEnd},
	view_as_skill = mengyanVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if player:hasFlag("mengyanTarget") then
				local alives = room:getAlivePlayers()
				for _,p in sgs.qlist(alives) do
					p:removeCardLimitation("use,response", ".|.|.|hand$1")
				end
			end
		end
	end
}
mengyanDist = sgs.CreateDistanceSkill{
	name = "#mengyanDist",
	correct_func = function(self, from, to)
		if from:hasSkill("mengyan") and from:hasFlag("mengyanTarget") then
			return -999
		end
	end
}
extension:insertRelatedSkills("mengyan", "#mengyanDist")
Nocturne:addSkill(moying)
Nocturne:addSkill(mengyan)
Nocturne:addSkill(mengyanDist)
sgs.LoadTranslationTable{
	["Nocturne"] = "魔腾",
	["&Nocturne"] = "魔腾",
	["#Nocturne"] = "永恒梦魇",
	
	["moying"] = "魔影",
	["moyingCard"] = "魔影",
	[":moying"] = "摸牌阶段摸牌后，你可以和一名角色拼点：若你赢，视为你对其使用一张【杀】且本回合你无视与该角色的距离。",
	["@moyinginvoke"] = "你可以发动“魔影”",
	["~moying"] = "选择一名有手牌的其他角色",
	["#moyingSuccess"] = "%from 对 %to 拼点赢，本回合 %from 无视与 %to 的距离",
	
	["mengyan"] = "梦魇",
	["mengyanCard"] = "梦魇",
	["mengyanDist"] = "梦魇",
	[":mengyan"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以令其他所有角色均不能使用或打出其手牌且你无视与所有角色的距离，直到回合结束。",
	["@mengyan"] = "梦魇",
	["#mengyan"] = "%from 发动了“%arg”，本回合其他所有角色均不能使用或打出手牌且 %from 与所有角色计算距离始终为1",
	["$mengyanQP"] = "梦魇",
}

--德玛西亚之翼·奎因
--[[所需标记：
	1、@Ren（“人”标记，来自技能“搭档”）
	2、@Ying（“鹰”标记，来自技能“搭档”）
	3、@Yisun（“易损”标记，来自技能“侵扰”）
]]--
Quinn = sgs.General(extension, "Quinn", "shu", "3", false, true, true)
Dadang = sgs.CreateTriggerSkill{
	name = "Dadang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.GameStart, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if event == sgs.GameStart then
			player:gainMark("@Ren", 1)
		elseif event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Start or phase == sgs.Player_Finish then
				if player:askForSkillInvoke("Dadang", data) then
					local room = player:getRoom()
					room:broadcastSkillInvoke("Dadang") --播放配音
					local ren = player:getMark("@Ren")
					local ying = player:getMark("@Ying")
					if ren == 0 then
						player:gainMark("@Ren", 1)
					else
						player:loseMark("@Ren", 1)
					end
					if ying == 0 then
						player:gainMark("@Ying", 1)
					else
						player:loseMark("@Ying", 1)
					end
				end
			end
		end
	end,
}
QinraoCard = sgs.CreateSkillCard{
	name = "QinraoCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:getMark("@Yisun") == 0
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("Qinrao", 1) --播放配音
		local target = targets[1]
		target:gainMark("@Yisun", 1) 
	end,
}
QinraoVS = sgs.CreateViewAsSkill{
	name = "Qinrao",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isBlack()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = QinraoCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:getMark("@Ying") > 0 then
			if player:isNude() then
				return false
			elseif player:getMark("@Yisun") == 0 then
				return true
			else
				local others = player:getSiblings()
				for _,p in sgs.qlist(others) do
					if p:getMark("@Yisun") == 0 then
						return true
					end
				end
			end
		end
		return false
	end,
}
Qinrao = sgs.CreateTriggerSkill{
	name = "Qinrao",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused},
	view_as_skill = QinraoVS,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local source = damage.from
		if source and source:objectName() == player:objectName() then
			if source:getMark("@Ren") > 0 then
				local victim = damage.to
				if victim and victim:getMark("@Yisun") > 0 then
					local room = player:getRoom()
					room:broadcastSkillInvoke("Qinrao", 2) --播放配音
					local count = damage.damage
					local msg = sgs.LogMessage()
					msg.type = "#QinraoDamage"
					msg.from = source
					msg.to:append(victim)
					msg.arg = count
					count = count + 1
					msg.arg2 = count
					room:sendLog(msg) --发送提示信息
					damage.damage = count
					data:setValue(damage)
					victim:loseMark("@Yisun")
				end
			end
		end
	end,
	priority = -1,
}
GanzhiDummyCard = sgs.CreateSkillCard{
	name = "GanzhiDummyCard",
}
GanzhiCard = sgs.CreateSkillCard{
	name = "GanzhiCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if to_select:isKongcheng() then
			return false
		elseif to_select:objectName() == sgs.Self:objectName() then
			return false
		end
		return true
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("Ganzhi", 1) --播放配音
		local target = targets[1]
		local hp = source:getHp()
		local mynum = source:getHandcardNum()
		local num = target:getHandcardNum()
		local x = math.min( hp, math.min(mynum, num) )
		if x == 0 then
			if num > 0 then
				room:showAllCards(target, source)
			end
		else
			local handcard_ids = target:handCards()
			local selected = sgs.IntList()
			local count = 0
			room:fillAG(handcard_ids, source)
			for i=1, x, 1 do
				local id = room:askForAG(source, handcard_ids, true, "Ganzhi")
				if id > 0 then
					handcard_ids:removeOne(id)
					room:takeAG(nil, id, false)
					selected:append(id)
					count = count + 1
				else
					break
				end
			end
			room:clearAG(source)
			if count > 0 then
				local to_exchange = room:askForExchange(source, "Ganzhi", count, false)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, source:objectName())
				local moveA = sgs.CardsMoveStruct(selected, source, sgs.Player_PlaceHand, reason)
				local moveB = sgs.CardsMoveStruct(to_exchange:getSubcards(), target, sgs.Player_PlaceHand, reason)
				local moves = sgs.CardsMoveList()
				moves:append(moveA)
				moves:append(moveB)
				room:moveCards(moves, false)
			end
		end
	end,
}
GanzhiVS = sgs.CreateViewAsSkill{
	name = "Ganzhi",
	n = 0,
	view_as = function(self, cards)
		return GanzhiCard:clone()
	end,
	enabled_at_play = function(self, player)
		if player:getMark("@Ying") > 0 then
			if player:hasUsed("#GanzhiCard") then
				return false
			else
				local others = player:getSiblings()
				for _,p in sgs.qlist(others) do
					if not p:isKongcheng() then
						return true
					end
				end
			end
		end
		return false
	end,
}
Ganzhi = sgs.CreateTriggerSkill{
	name = "Ganzhi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused},
	view_as_skill = GanzhiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local source = damage.from
		if source and source:objectName() == player:objectName() then
			if source:getMark("@Ren") > 0 then
				local victim = damage.to
				if victim and victim:getMark("@Yisun") > 0 then
					if source:askForSkillInvoke("Ganzhi", data) then
						room:broadcastSkillInvoke("Ganzhi", 2) --播放配音
						local choices = {}
						if source:canSlash(victim, false) then
							table.insert(choices, "slash")
						end
						table.insert(choices, "draw")
						if not source:isNude() then
							table.insert(choices, "discard")
						end
						table.insert(choices, "cancel")
						choices = table.concat(choices, "+")
						local choice = room:askForChoice(source, "Ganzhi", choices, data)
						if choice == "slash" then
							local prompt = string.format("@Ganzhi:%s:", victim:objectName())
							room:askForUseSlashTo(source, victim, prompt, false, false, false)
						elseif choice == "draw" then
							room:drawCards(source, 1, "Ganzhi")
						elseif choice == "discard" then
							local id = room:askForCardChosen(source, victim, "he", "Ganzhi")
						end
					end
				end
			end
		end
	end,
	priority = 3,
}
Quinn:addSkill(Dadang)
Quinn:addSkill(Qinrao)
Quinn:addSkill(Ganzhi)
sgs.LoadTranslationTable{
	["Quinn"] = "奎因",
	["&Quinn"] = "奎因",
	["#Quinn"] = "德玛西亚之翼",

	["Dadang"] = "搭档",
	[":Dadang"] = "游戏开始时，你获得一枚“人/鹰”标记（“人”朝上），回合开始或回合结束阶段，你可以改变“人/鹰”标记的朝向。",
	["$Dadang"] = "技能 搭档 的台词",
	["@Ren"] = "人",
	["@Ying"] = "鹰",

	["Qinrao"] = "侵扰",
	[":Qinrao"] = "若你的标记为“鹰”朝上，你可以弃置一张黑色牌并指定一名没有“易损”标记的角色，该角色获得一枚“易损”标记；若你的标记为“人”朝上，你对拥有“易损”标记的角色伤害+1，然后弃置该角色的“易损”标记。",
	["$Qinrao1"] = "技能 侵扰 发动技能时 的台词",
	["$Qinrao2"] = "技能 侵扰 增加伤害时 的台词",
	["#QinraoDamage"] = "由于 %from 的技能“<font color=\"yellow\">侵扰</font>”的影响，%to 受到的伤害从 %arg 点上升到 %arg2 点。",
	["QinraoCard"] = "侵扰",
	["@Yisun"] = "易损",
	["msqinrao"] = "侵扰",

	["Ganzhi"] = "感知",
	[":Ganzhi"] = "若你的标记为“鹰”朝上，出牌阶段限一次，你可以观看一名角色的手牌，并可以将你的至多X张手牌与其相同数量的手牌交换（X为你当前体力值、你的手牌数、对方手牌数三者之间的最小值）；若你的标记为“人”朝上，当你对拥有“易损”标记的角色造成伤害时，你可以选择：1、对其使用一张【杀】（无视距离且不计入限制），2、摸一张牌，3、弃置其一张牌。",
	["$Ganzhi1"] = "技能 感知 观看手牌时 的台词",
	["$Ganzhi2"] = "技能 感知 造成伤害时 的台词",
	["GanzhiCard"] = "感知",
	["Ganzhi:slash"] = "对目标使用一张杀",
	["Ganzhi:draw"] = "摸一张牌",
	["Ganzhi:discard"] = "弃置目标一张牌",
	["@Ganzhi"] = "请对 %src 使用一张【杀】",
	["msganzhi"] = "感知",
}

--装备
--饮血剑
Bloodthirster = sgs.CreateWeapon{
	name = "Bloodthirster",
	class_name = "Bloodthirster",
	suit = sgs.Card_Heart,
	number = 4,
	range = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("Bloodthirsterkeep")
		room:getThread():addTriggerSkill(skill)
	end,
}
Bloodthirsterkeep = sgs.CreateTriggerSkill{
	name = "Bloodthirsterkeep",
	events = {sgs.Damage},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local Weapon = player:getWeapon()
		local damage = data:toDamage()
		if Weapon and Weapon:isKindOf("Bloodthirster") then
			local slash = damage.card
			if slash then
				if slash:isKindOf("Slash") then
					if player:isWounded() then
						local recover = sgs.RecoverStruct()
						recover.who = player
						recover.recover = 1
						local yx = sgs.LogMessage()
						yx.from = player
						yx.type = "#Bloodthirster"
						yx.to:append(player)
						yx.arg = recover.recover
						room:sendLog(yx)
						room:recover(player, recover)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
if not sgs.Sanguosha:getSkill("Bloodthirsterkeep") then skills:append(Bloodthirsterkeep) end 
Bloodthirster:setParent(extension)
sgs.LoadTranslationTable{
	["Bloodthirster"] = "饮血剑",
	["Bloodthirsterkeep"] = "饮血剑",
	[":Bloodthirster"] = "装备牌·武器\n攻击范围：２\n武器特效：<font color=\"blue\"><b>锁定技，</b></font>每当你使用【杀】造成一次伤害，你回复1点体力。",
	["#Bloodthirster"] = "%from 的装备【<font color=\"yellow\"><b>饮血剑</b></font>】效果被触发，%from 回复了 %arg 点体力。",
}

--无尽之刃
InfinityEdge = sgs.CreateWeapon{
	name = "InfinityEdge",
	class_name = "InfinityEdge",
	suit = sgs.Card_Spade,
	number = 9,
	range = 1,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("InfinityEdgekeep")
		room:getThread():addTriggerSkill(skill)
	end,
}
InfinityEdgekeep = sgs.CreateTriggerSkill{
	name = "InfinityEdgekeep",
	events = {sgs.DamageCaused},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local Weapon = player:getWeapon()
		local damage = data:toDamage()
		if Weapon and Weapon:isKindOf("InfinityEdge") then
			local slash = damage.card
			if slash then
				if slash:isKindOf("Slash") then
					local count = damage.damage
					local wj = sgs.LogMessage()
					wj.from = player
					wj.type = "#InfinityEdge"
					wj.arg = count
					wj.arg2 = count + 1
					wj.to:append(damage.to)
					room:sendLog(wj)
					damage.damage = count + 1
					data:setValue(damage)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
if not sgs.Sanguosha:getSkill("InfinityEdgekeep") then skills:append(InfinityEdgekeep) end 
InfinityEdge:setParent(extension)
sgs.LoadTranslationTable{
	["InfinityEdge"] = "无尽之刃",
	["InfinityEdgekeep"] = "无尽之刃",
	[":InfinityEdge"] = "装备牌·武器\n攻击范围：１\n武器特效：<font color=\"blue\"><b>锁定技，</b></font>每当你使用【杀】造成伤害时，该伤害 +1。",
	["#InfinityEdge"] = "%from 的装备【<font color=\"yellow\"><b>无尽之刃</b></font>】效果被触发，对 %to 的伤害从 %arg 增加至 %arg2 点。",
}

--远古意志
WilloftheAncients = sgs.CreateWeapon{
	name = "WilloftheAncients",
	class_name = "WilloftheAncients",
	suit = sgs.Card_Heart,
	number = 8,
	range = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("WilloftheAncientskeep")
		room:getThread():addTriggerSkill(skill)
	end,
}
WilloftheAncientskeep = sgs.CreateTriggerSkill{
	name = "WilloftheAncientskeep",
	events = {sgs.Damage},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local Weapon = player:getWeapon()
		local damage = data:toDamage()
		if Weapon and Weapon:isKindOf("WilloftheAncients") then
			local TrickCard = damage.card
			if TrickCard then
				if TrickCard:isKindOf("TrickCard") then
					if player:isWounded() then
						local recover = sgs.RecoverStruct()
						recover.who = player
						recover.recover = 1
						local yg = sgs.LogMessage()
						yg.from = player
						yg.type = "#WilloftheAncients"
						yg.to:append(player)
						yg.arg = recover.recover
						room:sendLog(yg)
						room:recover(player, recover)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
if not sgs.Sanguosha:getSkill("WilloftheAncientskeep") then skills:append(WilloftheAncientskeep) end 
WilloftheAncients:setParent(extension)
sgs.LoadTranslationTable{
	["WilloftheAncients"] = "远古意志",
	["WilloftheAncientskeep"] = "远古意志",
	[":WilloftheAncients"] = "装备牌·武器\n攻击范围：２\n武器特效：<font color=\"blue\"><b>锁定技，</b></font>每当你使用锦囊牌造成一次伤害，你回复1点体力。",
	["#WilloftheAncients"] = "%from 的装备【<font color=\"yellow\"><b>远古意志</b></font>】效果被触发，%from 回复了 %arg 点体力。",
}

--灭世者之帽
Deathcap = sgs.CreateWeapon{
	name = "Deathcap",
	class_name = "Deathcap",
	suit = sgs.Card_Spade,
	number = 4,
	range = 1,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("Deathcapkeep")
		room:getThread():addTriggerSkill(skill)
	end,
}
Deathcapkeep = sgs.CreateTriggerSkill{
	name = "Deathcapkeep",
	events = {sgs.DamageCaused},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local Weapon = player:getWeapon()
		local damage = data:toDamage()
		if Weapon and Weapon:isKindOf("Deathcap") then
			local TrickCard = damage.card
			if TrickCard then
				if TrickCard:isKindOf("TrickCard") then
					local count = damage.damage
					local dc = sgs.LogMessage()
					dc.from = player
					dc.type = "#Deathcap"
					dc.arg = count
					dc.arg2 = count + 1
					dc.to:append(damage.to)
					room:sendLog(dc)
					damage.damage = count + 1
					data:setValue(damage)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
if not sgs.Sanguosha:getSkill("Deathcapkeep") then skills:append(Deathcapkeep) end 
Deathcap:setParent(extension)
sgs.LoadTranslationTable{
	["Deathcap"] = "灭世者之帽",
	["Deathcapkeep"] = "灭世者之帽",
	[":Deathcap"] = "装备牌·武器\n攻击范围：１\n武器特效：<font color=\"blue\"><b>锁定技，</b></font>每当你使用锦囊牌造成伤害时，该伤害 +1。",
	["#Deathcap"] = "%from 的装备【<font color=\"yellow\"><b>灭世者之帽</b></font>】效果被触发，对 %to 的伤害从 %arg 增加至 %arg2 点。",
}

--狂徒铠甲
WarmongArmor = sgs.CreateArmor{
	name = "WarmongArmor",
	class_name = "WarmongArmor",
	suit = sgs.Card_Heart,
	number = 13,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("WarmongArmorkeep")
		room:getThread():addTriggerSkill(skill)
	end,
}
WarmongArmorkeep = sgs.CreateTriggerSkill{
	name = "WarmongArmorkeep",
	events = {sgs.DrawNCards},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local Armor = player:getArmor()
		if Armor and Armor:isKindOf("WarmongArmor") then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			if draw.num > 0 and player:isWounded() then
				if room:askForSkillInvoke(player, "WarmongArmor", data) then
					draw.num = draw.num - 1
					data:setValue(draw)
					local recover = sgs.RecoverStruct()
					local kt = sgs.LogMessage()
					kt.from = player
					kt.type = "#WarmongArmor"
					kt.to:append(player)
					kt.arg = 1
					room:sendLog(kt)
					recover.who = player
					room:recover(player, recover) 
				end
			end
		end
	end,
	can_trigger = function(self, target)
		if target then
			if target:getMark("Armor_Nullified")==0 and not target:hasFlag("WuqianTarget") then
				if target:getMark("Equips_Nullified_to_Yourself") == 0 then
					local list = target:getTag("Qinggang"):toStringList()
					return #list == 0
				end
			end
		end
		return false
	end
}
if not sgs.Sanguosha:getSkill("WarmongArmorkeep") then skills:append(WarmongArmorkeep) end 
WarmongArmor:setParent(extension)
sgs.LoadTranslationTable{
	["WarmongArmor"] = "狂徒铠甲",
	["WarmongArmorkeep"] = "狂徒铠甲",
	[":WarmongArmor"] = "装备牌·防具\n防具特效：摸牌阶段摸牌时，你可以少摸1张牌，然后回复1点体力。",
	["#WarmongArmor"] = "%from 发动了【<font color=\"yellow\"><b>狂徒铠甲</b></font>】，%from 少摸 %arg 张牌并回复了 %arg 点体力。",
}

--振奋铠甲
SpiritVisage = sgs.CreateArmor{
	name = "SpiritVisage",
	class_name = "SpiritVisage",
	suit = sgs.Card_Diamond,
	number = 10,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("SpiritVisagekeep")
		room:getThread():addTriggerSkill(skill)
	end,
}
SpiritVisagekeep = sgs.CreateTriggerSkill{
	name = "SpiritVisagekeep",
	events = {sgs.PreHpRecover},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local Armor = player:getArmor()
		if Armor and Armor:isKindOf("SpiritVisage") then
			local recover = data:toRecover()
			local zf = sgs.LogMessage()
			zf.from = player
			zf.type = "#SpiritVisage"
			zf.to:append(player)
			zf.arg = "SpiritVisage"
			room:sendLog(zf)
			recover.recover = recover.recover + 1
			data:setValue(recover)
		end
	end,
	can_trigger = function(self, target)
		if target then
			if target:getMark("Armor_Nullified")==0 and not target:hasFlag("WuqianTarget") then
				if target:getMark("Equips_Nullified_to_Yourself") == 0 then
					local list = target:getTag("Qinggang"):toStringList()
					return #list == 0
				end
			end
		end
		return false
	end
}
if not sgs.Sanguosha:getSkill("SpiritVisagekeep") then skills:append(SpiritVisagekeep) end 
SpiritVisage:setParent(extension)
sgs.LoadTranslationTable{
	["SpiritVisage"] = "振奋铠甲",
	["SpiritVisagekeep"] = "振奋铠甲",
	[":SpiritVisage"] = "装备牌·防具\n防具特效：<font color=\"blue\"><b>锁定技，</b></font>每当你回复体力时，你额外回复1点体力。",
	["#SpiritVisage"] = "%from 的【<font color=\"yellow\"><b>振奋铠甲</b></font>】效果被触发，%from 额外回复了 %arg 点体力。",
}

--荆棘之甲
Thornmail = sgs.CreateArmor{
	name = "Thornmail",
	class_name = "Thornmail",
	suit = sgs.Card_Spade,
	number = 13,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("Thornmailkeep")
		room:getThread():addTriggerSkill(skill)
	end,
}
Thornmailkeep = sgs.CreateTriggerSkill{
	name = "Thornmailkeep",  
	events = {sgs.Damaged}, 
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local from = damage.from
		local Armor = player:getArmor()
		if Armor and Armor:isKindOf("Thornmail") then
			if damage.card and damage.card:isKindOf("Slash") then
				for a = 1, damage.damage, 1 do
					if (not from) or from:isDead() then return end
					if room:askForSkillInvoke(player, "Thornmail", data) then
						if from:getHandcardNum() < 2 then
							room:damage(sgs.DamageStruct(self:objectName(), player, from))
						else
							if not room:askForDiscard(from, self:objectName(), 2, 2, true) then
								room:damage(sgs.DamageStruct(self:objectName(), player, from))
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		if target then
			if target:getMark("Armor_Nullified")==0 and not target:hasFlag("WuqianTarget") then
				if target:getMark("Equips_Nullified_to_Yourself") == 0 then
					local list = target:getTag("Qinggang"):toStringList()
					return #list == 0
				end
			end
		end
		return false
	end
}
if not sgs.Sanguosha:getSkill("Thornmailkeep") then skills:append(Thornmailkeep) end 
Thornmail:setParent(extension)
sgs.LoadTranslationTable{
	["Thornmail"] = "荆棘之甲",
	["Thornmailkeep"] = "荆棘之甲",
	[":Thornmail"] = "装备牌·防具\n防具特效：每当你受到1点【杀】造成的伤害后，你可以令伤害来源选择一项：弃置两张手牌，或受到你对其造成的1点伤害。",
}

--中娅沙漏
ZhonyaHourglass = sgs.CreateArmor{
	name = "ZhonyaHourglass",
	class_name = "ZhonyaHourglass",
	suit = sgs.Card_Club,
	number = 7,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("ZhonyaHourglasskeep")
		room:getThread():addTriggerSkill(skill)
	end,
}
ZhonyaHourglasskeep = sgs.CreateProhibitSkill{
	name = "ZhonyaHourglasskeep",
	is_prohibited = function(self, from, to, card)
		local Armor = to:getArmor()
		if Armor and Armor:isKindOf("ZhonyaHourglass") then
			if to:getMark("Armor_Nullified")==0 and not to:hasFlag("WuqianTarget") then
				if to:getMark("Equips_Nullified_to_Yourself") == 0 then
					if to:objectName() ~= from:objectName() and not (faceup or to:faceUp()) then
						return card:isKindOf("BasicCard") or card:isKindOf("TrickCard")
					end
				end
			end
		end
	end
}
if not sgs.Sanguosha:getSkill("ZhonyaHourglasskeep") then skills:append(ZhonyaHourglasskeep) end 
ZhonyaHourglass:setParent(extension)
sgs.LoadTranslationTable{
	["ZhonyaHourglass"] = "中娅沙漏",
	["ZhonyaHourglasskeep"] = "中娅沙漏",
	[":ZhonyaHourglass"] = "装备牌·防具\n防具特效：<font color=\"blue\"><b>锁定技，</b></font>当你的武将牌背面向上时，你不能成为其他角色任何牌的目标。",
	["#SpiritVisage"] = "%from 的【%arg】效果被触发，%from 摸一张牌",
}


sgs.Sanguosha:addSkills(skills)  --非列表技能添加列表。放在最后