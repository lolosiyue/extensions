module("extensions.ck", package.seeall)
extension = sgs.Package("ck")

ckmisaka = sgs.General(extension, "ckmisaka", "science", 3, false)

ckleiti = sgs.CreateTriggerSkill{
	name = "ckleiti", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damage, sgs.DamageInflicted}, 
	
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.nature==sgs.DamageStruct_Thunder then
			if damage.to==player then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())				
				local msg = sgs.LogMessage()
				msg.type = "#ckleiti"
				msg.from = player
				room:sendLog(msg)
				local theRecover = sgs.RecoverStruct()
				theRecover.recover = damage.damage
				theRecover.who = damage.from
				room:recover(player, theRecover)--恢复体力
				room:setEmotion(player, "skill_nullify")
				return true		--免疫雷属性伤害
			elseif player:isWounded()==true then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local theRecover = sgs.RecoverStruct()
				theRecover.recover = damage.damage
				theRecover.who = damage.from
				room:recover(player, theRecover)--恢复体力
				return false				
			end					
		end
	end, 
}

ckdianjicard = sgs.CreateSkillCard{
	name = "ckdianjicard", 
	filter = function(self, targets, to_select) 
		return #targets==0
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		room:broadcastSkillInvoke("CkDianji")
		room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to, 1, sgs.DamageStruct_Thunder))
		return false
	end
}

ckdianji = sgs.CreateViewAsSkill{
	name = "ckdianji", 
	n = 1, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#ckdianjicard")
	end,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		if #cards == 0 then
			return nil
		else
			local card = ckdianjicard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end
}

ckluoleicard = sgs.CreateSkillCard{
	name = "ckluoleicard" ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		room:doSuperLightbox("ck_misaka", "ckluolei")
		--room:broadcastSkillInvoke("ckluolei")
		source:loseMark("@thunder")
		source:throwAllHandCards()
		local players = room:getOtherPlayers(source)
		for _, player in sgs.qlist(players) do
			room:damage(sgs.DamageStruct("ckluolei", source, player,2,sgs.DamageStruct_Thunder))
		end
		room:detachSkillFromPlayer(source, "ckdianji")
	end
}

ckluoleiVS = sgs.CreateViewAsSkill{
	name = "ckluolei" ,
	n = 0,
	view_as = function()
		local card = ckluoleicard:clone()
		card:setSkillName("ckluolei")
		return card
	end ,
	enabled_at_play = function(self, player)
		return player:getMark("@thunder") >= 1
	end
}

ckluolei = sgs.CreateTriggerSkill{
	name = "ckluolei" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@thunder",
	events = {},
	view_as_skill = ckluoleiVS,
	
	on_trigger = function()
	end
}

ckmisaka:addSkill(ckleiti)
ckmisaka:addSkill(ckdianji)
ckmisaka:addSkill(ckluolei)

sgs.LoadTranslationTable{
	["ck"]="魔禁",
	["ckmisaka"]="御坂美琴",
	["&ckmisaka"]="御坂美琴",
	["#ckmisaka"]="超电磁炮",
	["designer:ckmisaka"]="CK",
	["cv:ckmisaka"]="官方",
	["illustrator:ckmisaka"]="官方",
	["ckleiti"]="雷体",
	[":ckleiti"]="<font color=\"blue\"><b>锁定技，</b></font>免疫雷属性伤害并且在造成或受到雷属性伤害时回复等量体力。",
	["$ckleiti"]="雷体音效。",
	["#ckleiti"]="免疫雷属性伤害。",
	["ckdianji"]="电击",
	[":ckdianji"]="<font color=\"green\"><b>出牌阶段限一次，</b></font>弃置一张牌，对任意目标造成1点雷属性伤害。",
	["$ckdianji"]="电击音效。",
	["ckluolei"]="落雷",
	[":ckluolei"]="<font color=\"red\"><b>限定技，</b></font>弃置所有手牌，对所有其他角色造成2点雷属性伤害，并失去技能【电击】。",
	["$ckluolei"]="落雷音效。",
	["@luolei"]="落雷",
	["$luolei"]="见识下真正的落雷吧！",
	}
	
ckkuroko = sgs.General(extension, "ckkuroko", "science", 3, false)

cksunyi = sgs.CreateDistanceSkill{
	name = "cksunyi",
	correct_func = function(self, from ,to)
		if from:hasSkill(self:objectName()) then
			return -1000
		end
		if to:hasSkill(self:objectName()) then
			return 2
		end
	end,
}

cksiliecard = sgs.CreateSkillCard{
	name = "cksiliecard" ,
	will_throw = false,
	filter = function(self, targets, to_select, source)
		return #targets == 0 and to_select:objectName() ~= source:objectName()
	end ,
	on_effect = function(self, effect)
		local n = 0
		local room = effect.to:getRoom()
		local subid = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(subid)
		local target_suit = card:getSuit()
		room:broadcastSkillInvoke("cksilie")
		room:obtainCard(effect.to, subid, true)
		if not effect.to:isKongcheng() then
			local ids = sgs.IntList()
			for _, cardtmp in sgs.qlist(effect.to:getHandcards()) do
				if cardtmp:getSuit() == target_suit then
					n = n + 1
				end
			end
			room:showAllCards(effect.to)
			if (n == 0) then return end
			room:damage(sgs.DamageStruct("cksilie", effect.from, effect.to,n))
		end
	end
}	

cksilie = sgs.CreateViewAsSkill{
	name = "cksilie", 
	n = 1, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#cksiliecard")
	end,
	view_filter = function(self, selected, to_select)
		return true
	end, 
	view_as = function(self, cards) 
		if #cards == 0 then
			return nil
		else
			local card = cksiliecard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end
}

ckbaihecard = sgs.CreateSkillCard{
	name = "ckbaihecard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:hasEquip() and to_select:isFemale()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		if effect.to:hasEquip() then
			local id = room:askForCardChosen(effect.from, effect.to, "e", "ckbaihe")
			--room:broadcastSkillInvoke("ckbaihe")
			room:throwCard(id, effect.to, effect.from)
			if effect.to:isWounded() then
				room:recover(effect.to, sgs.RecoverStruct(effect.from))
			end
			effect.to:drawCards(2)
		end
	end
}

ckbaiheVS = sgs.CreateViewAsSkill{
	name = "ckbaihe",
	n = 0,
	view_as = function(self, cards)
			return ckbaihecard:clone()
	end,
	response_pattern = "@@ckbaihe",
}

ckbaihe = sgs.CreateTriggerSkill{
	name = "ckbaihe",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = ckbaiheVS,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			player:getRoom():askForUseCard(player, "@@ckbaihe", "@baihe-card")
		end
	end,
}

ckkuroko:addSkill(cksunyi)
ckkuroko:addSkill(cksilie)
ckkuroko:addSkill(ckbaihe)

sgs.LoadTranslationTable{
	["ckkuroko"]="白井黑子",
	["&ckkuroko"]="白井黑子",
	["#ckkuroko"]="空间移动",
	["designer:ckkuroko"]="CK",
	["cv:ckkuroko"]="官方",
	["illustrator:ckkuroko"]="官方",
	["cksunyi"]="瞬移",
	[":cksunyi"]="<font color=\"blue\"><b>锁定技，</b></font>你与其他角色的距离为1，其他角色与你的距离+2。",
	["cksilie"]="撕裂",
	[":cksilie"]="<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以展示一张手牌以确认此牌的花色并将之交给一名角色，展示其所有手牌，对其造成X点伤害(X为其拥有该花色手牌数)。",
	["$cksilie"]="撕裂音效。",
	["ckbaihe"]="百合",
	[":ckbaihe"]="回合结束阶段，你可以指定一名女性角色，弃置其装备区一张牌，令其回复一点体力并摸两张牌。",
	["$ckbaihe"]="百合音效。",
	["@baihe-card"]="发动【百合】吗？",
	["~ckbaihe"]="选择一名有装备的女性角色，弃置其装备区一张牌，令其回复一点体力并摸两张牌。",
}

cktouma = sgs.General(extension, "cktouma", "science")

ckhuansha = sgs.CreateTriggerSkill {
	name = "ckhuansha",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected,sgs.TargetSpecifying},
	
	on_trigger = function(self, event, player, data)
		
		local room = player:getRoom()
		local current = room:getCurrent()
		local msg = sgs.LogMessage()
		if event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.from == player or effect.to ~= player or not effect.card then return false end
			if effect.card:getTypeId()==sgs.Card_TypeSkill or effect.card:getSkillName()~="" or effect.card:isVirtualCard()then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				if effect.card:isKindOf("DelayedTrick") then
					msg.type = "#huanshaDelayedTrick"
					msg.arg = effect.card:objectName()
					msg.to:append(effect.to)
					room:sendLog(msg)
					return true
				end
				local p = effect.from
				if p:hasFlag("ckhuanshaTarget") then return true end
				room:setPlayerFlag(p, "ckhuanshaTarget")
				room:addPlayerMark(p, "@skill_invalidity", 1)
				room:setPlayerMark(p, "&ckhuansha+to+#"..player:objectName().."-Clear", 1)
				
				room:setPlayerMark(current, "ckhuansha", 1)
				local lose_skills = p:getTag("ckhuanshaSkills"):toString():split("+")
				local skills = p:getVisibleSkillList()
				for _, skill in sgs.qlist(skills) do
					room:addPlayerMark(p, "Qingcheng"..skill:objectName())
					table.insert(lose_skills, skill:objectName())	
					for _, sk in sgs.qlist(sgs.Sanguosha:getRelatedSkills(skill:objectName())) do
						room:addPlayerMark(p, "Qingcheng"..sk:objectName())
					end
				end
				p:setTag("ckhuanshaSkills", sgs.QVariant(table.concat(lose_skills, "+")))
				
				if effect.card:getTypeId() == sgs.Card_TypeSkill then
					msg.type = "#huanshaSkill"
					msg.arg = effect.card:getSkillName()
				else
					msg.type = "#huanshaCard"
					msg.arg = effect.card:objectName()
				end
				if effect.from then
					msg.from = effect.from
				end
				msg.to:append(effect.to)
				room:sendLog(msg)
				return true
			end
			return false
		else
			local use = data:toCardUse()
			if not current or current:isDead() then return end
			if use.from == player then
				local music=false
				for _, p in sgs.qlist(use.to) do
					if p~=player then
						if not p:hasFlag("ckhuanshaTarget") then
							music=true
							room:sendCompulsoryTriggerLog(player, self:objectName())
							room:setPlayerFlag(p, "ckhuanshaTarget")
							room:addPlayerMark(p, "@skill_invalidity", 1)
							room:setPlayerMark(current, "ckhuansha", 1)
							room:setPlayerMark(p, "&ckhuansha+to+#"..player:objectName().."-Clear", 1)
							local lose_skills = p:getTag("ckhuanshaSkills"):toString():split("+")
							local skills = p:getVisibleSkillList()
							for _, skill in sgs.qlist(skills) do
								room:addPlayerMark(p, "Qingcheng"..skill:objectName())
								table.insert(lose_skills, skill:objectName())
						
								for _, sk in sgs.qlist(sgs.Sanguosha:getRelatedSkills(skill:objectName())) do
									room:addPlayerMark(p, "Qingcheng"..sk:objectName())
								end
							end
							p:setTag("ckhuanshaSkills", sgs.QVariant(table.concat(lose_skills, "+")))
						end
					end
				end
				if music then
					room:broadcastSkillInvoke(self:objectName())
					music=false
				end
			end
		end
	return false
	end,
}

ckhuansha_clear = sgs.CreateTriggerSkill{
	name = "#ckhuansha",
	events = {sgs.EventPhaseEnd, sgs.Death},
	
	can_trigger = function(self, target)
		return target and target:getMark("ckhuansha") > 0
	end,
	
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseEnd then
			if player:getPhase() ~= sgs.Player_Finish then return false end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if not death.who:hasSkill("ckhuansha") then return false end
		end
		
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("ckhuansha") > 0 then
				room:setPlayerMark(p,"ckhuansha",0)
			end
			if p:hasFlag("ckhuanshaTarget") then
				room:setPlayerFlag(p, "-ckhuanshaTarget")
				room:removePlayerMark(p, "@skill_invalidity", 1)
				local lose_skills = p:getTag("ckhuanshaSkills"):toString():split("+")
				for _, skill_name in ipairs(lose_skills) do
					room:removePlayerMark(p, "Qingcheng"..skill_name)
					for _, sk in sgs.qlist(sgs.Sanguosha:getRelatedSkills(skill_name)) do
						room:removePlayerMark(p, "Qingcheng"..sk:objectName())
					end
				end
				p:setTag("ckhuanshaSkills", sgs.QVariant())
			end
		end
		return false
	end,
}

ckdalian = sgs.CreateTriggerSkill{
	name = "ckdalian",
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from==player and (damage.from:distanceTo(damage.to)<=1) then
		local to_data = sgs.QVariant()
			to_data:setValue(damage.to)
			if room:askForSkillInvoke(player, "ckdalian", to_data) then
				local msg = sgs.LogMessage()
				msg.type = "#dalian"
				msg.from = damage.from
				msg.to:append(damage.to)
				msg.arg = damage.damage
				damage.damage = damage.damage + 1
				msg.arg2 = damage.damage
				data:setValue(damage)
				room:sendLog(msg)
				player:broadcastSkillInvoke("ckdalian")
			end
		end
	end, 
}

cktouma:addSkill(ckhuansha)
cktouma:addSkill(ckhuansha_clear)
extension:insertRelatedSkills("ckhuansha", "#ckhuansha")
cktouma:addSkill(ckdalian)

sgs.LoadTranslationTable {
	["cktouma"] = "上条当麻",
	["&cktouma"] = "上条当麻",
	["#cktouma"]="幻想杀手",
	["designer:cktouma"]="CK",
	["cv:cktouma"]="官方",
	["illustrator:cktouma"]="官方",
	["ckhuansha"] = "幻杀",
	[":ckhuansha"] = "<font color=\"blue\"><b>锁定技，</b></font>当你指定一名角色为目标或成为一名角色技能的目标后，该角色的技能失效直到回合结束，你免疫大多数技能效果。",
	["$ckhuansha"] = "幻杀音效",
	["ckdalian"] = "打脸",
	[":ckdalian"] =  "你对距离为1的目标造成伤害时，可以令此伤害+1。",
	["$ckdalian"] = "打脸音效",
	["#dalian"] = "%from 对 %to 造成的伤害从 %arg 点增加为 %arg2 点。",
}



ckaccelerator = sgs.General(extension, "ckaccelerator", "science", 3)

ckshiliangcard = sgs.CreateSkillCard{
	name = "ckshiliangcard",
	target_fixed = false,
	will_throw = true,
	on_effect = function(self, effect)
		effect.to:getRoom():setPlayerFlag(effect.to, "ckshiliangtarget")
		return false
	end
}

ckshiliangVS = sgs.CreateViewAsSkill{
	name = "ckshiliang",
	n = 0,
	view_as = function(self, cards)
		local card = ckshiliangcard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function()
		return false
	end,
	response_pattern = "@@ckshiliang",
}

ckshiliang = sgs.CreateTriggerSkill{
	name = "ckshiliang",
	view_as_skill = ckshiliangVS,
	events = {sgs.TargetConfirming},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local players = room:getOtherPlayers(player)
		local use = data:toCardUse()
		if use.card and player:getMark("ckshiliang-Clear") == 0 and use.to:contains(player) then
			local prompt = ""
			if use.card:getTypeId() == sgs.Card_TypeSkill then
				prompt = "@ckshiliangSkill:"..use.from:objectName().."::"..use.card:getSkillName()
			else
				prompt = "@ckshiliangCard:"..use.from:objectName().."::"..use.card:objectName()
			end
			room:setTag("ckshiliang", data)
			if room:askForUseCard(player, "@@ckshiliang", prompt) then
				for _,p in sgs.qlist(players) do
					if p:hasFlag("ckshiliangtarget") then 
						room:setPlayerFlag(p,"-ckshiliangtarget")
						if use.card:isKindOf("DelayedTrick") then
							room:moveCardTo(sgs.Sanguosha:getCard(use.card:getEffectiveId()), p, sgs.Player_PlaceDelayedTrick)
							room:addPlayerMark(player,"ckshiliang-Clear")
							room:addPlayerMark(player,"&ckshiliang-Clear")
							return true
						else
							local i = use.to:indexOf(player)
							use.to:replace(i, p)
							-- if use.card:isKindOf("Slash") then
							-- 	player:slashSettlementFinished(use.card)
							-- end
							room:addPlayerMark(player,"&ckshiliang-Clear")
							room:addPlayerMark(player,"ckshiliang-Clear")
							room:sortByActionOrder(use.to)
							data:setValue(use)
							room:getThread():trigger(sgs.TargetConfirming, room, p, data)
							return false
						end
					end
				end	
			end
			room:removeTag("ckshiliang")
		end
	return false
	end,
}

ckxueni = sgs.CreateTriggerSkill{
	name = "ckxueni",
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if not dying.damage or dying.damage.from~=player then 
			return false 
		end
		local victim = dying.who
		local to_data = sgs.QVariant()
		to_data:setValue(victim)
		if room:askForSkillInvoke(player, "ckxueni", to_data) then
			player:broadcastSkillInvoke("ckxueni")
			room:killPlayer(victim,dying.damage)
		end
		return true
	end,
}

ckaccelerator:addSkill(ckshiliang)
ckaccelerator:addSkill(ckxueni)

sgs.LoadTranslationTable {
	["ckaccelerator"] = "一方通行",
	["&ckaccelerator"] = "一方通行",
	["#ckaccelerator"]="矢量操控",
	["designer:ckaccelerator"]="CK",
	["cv:ckaccelerator"]="官方",
	["illustrator:ckaccelerator"]="官方",
	["ckshiliang"] = "矢量",
	[":ckshiliang"] = "每名角色的回合限一次,当你成为目标时,你可以将其转移给除你以外的任意一名角色。",
	["$ckshiliang"] = "矢量音效",
	["@ckshiliang"] = "发动【矢量】吗？",
	["~ckshiliang"] = "选择一个目标。",
	["ckxueni"] = "血逆",
	[":ckxueni"] = "你对一名角色造成伤害使其进入濒死阶段时，你可以令其立即死亡。",
	["$ckxueni"] = "血逆音效",
}


ck_index = sgs.General(extension, "ck_index", "magic", 3, false)
indexWaked = sgs.General(extension, "indexWaked", "magic", 3, false, true, true )

ckyongchang=sgs.CreateTriggerSkill{

name="ckyongchang",

--view_as_skill=ckshiliangVS,

events={sgs.CardEffected},
--events = {sgs.TargetConfirmed, sgs.FinishJudge},

on_trigger=function(self,event,player,data)
	local room=player:getRoom()
	local players=room:getOtherPlayers(player)
	local current=room:getCurrent()
	if event == sgs.CardEffected then
		for _, ck_index in sgs.qlist(room:getAllPlayers()) do
			if not ck_index or ck_index:isDead() or not ck_index:hasSkill(self:objectName()) then continue end
			local effect = data:toCardEffect()
			if effect.card and effect.card:isKindOf("Slash") and effect.from ~= ck_index then
			 local to_data = sgs.QVariant()
				to_data:setValue(effect.to)
				room:setTag("ckyongchang", data)
				if room:askForSkillInvoke(ck_index,"ckyongchang",to_data) then
					room:removeTag("ckyongchang")
					room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|black"
					judge.good = false
					judge.play_animation = false
					judge.who = ck_index
					judge.reason = self:objectName()
					room:judge(judge)
					if judge:isGood() then
						effect.nullified = true
							data:setValue(effect)
							room:setEmotion(effect.to, "skill_nullify")
							return false
					else
						effect.to:drawCards(1, self:objectName())
						return false
					end
				end
				room:removeTag("ckyongchang")
			end	
		end
	end
end,

can_trigger = function(self, target)
		return target ~= nil
end,
}

ckshengyu=sgs.CreateTriggerSkill{

name="ckshengyu",
frequency = sgs.Skill_Compulsory, 

events={sgs.DamageInflicted},

on_trigger=function(self,event,player,data)
	local room=player:getRoom()
	if event == sgs.DamageInflicted then
		if player:getMark("ckshengyu-Clear") == 0 then
			room:setPlayerMark(player,"&ckshengyu-Clear", 1)
			room:setPlayerMark(player,"ckshengyu-Clear", 1)
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			local msg = sgs.LogMessage()
			msg.type = "#ckshengyu"
			msg.from = player
			room:sendLog(msg)
			room:setEmotion(player, "skill_nullify")
			return true
		end
	end
end,
}

cklongxicard = sgs.CreateSkillCard{
	name = "cklongxicard" ,
	will_throw = true,
	filter = function(self, targets, to_select, source)
		return #targets == 0 and to_select:objectName() ~= source:objectName()
	end ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		room:broadcastSkillInvoke(self:objectName())
		room:doSuperLightbox("ck_indexWaked", "#longxi")
		if effect.to:hasEquip() then
			effect.to:throwAllEquips()
		end
		
		if not effect.to:isKongcheng() then
			effect.to:throwAllHandCards()
		end
		
		room:damage(sgs.DamageStruct("cklongxi", effect.from, effect.to,3))
		effect.from:loseMark("@longxi")
		room:detachSkillFromPlayer(effect.from, "ckshengyu")
	end
}	

cklongxiVS = sgs.CreateViewAsSkill{
	name = "cklongxi", 
	n = 0, 
	enabled_at_play = function(self, player)
		return player:getMark("@longxi") >= 1
	end,
	
	view_as = function(self, cards) 
		return cklongxicard:clone()
	end,
}

cklongxi = sgs.CreateTriggerSkill{
	name = "cklongxi" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@longxi",
	events = {},
	view_as_skill = cklongxiVS,
	on_trigger = function(self, event, player, data)
	end,
}

ckjinshu = sgs.CreateTriggerSkill{
	name = "ckjinshu",
	events = {sgs.Dying },
	frequency = sgs.Skill_Wake,
	waked_skills = "ckshengyu,cklongxi",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.who~=player or player:getMark("ckjinshuWaked")>0 then return end
		room:broadcastSkillInvoke(self:objectName())
		room:doSuperLightbox("ck_indexWaked", "#jinshu")
		room:changeMaxHpForAwakenSkill(player, 0, self:objectName())
		room:addPlayerMark(player, "ckjinshuWaked")
		room:addPlayerMark(player, "ckjinshu")
		local theRecover = sgs.RecoverStruct()
		theRecover.recover = 1 - player:getHp()
		theRecover.who = player
		room:recover(player, theRecover)
		if player:getGeneralName() == "ck_index" then
				room:changeHero(player,"indexWaked",false, false, false, false)
			elseif player:getGeneral2Name() == "ck_index" then
				room:changeHero(player,"indexWaked",false, false, true, false)
				else
				player:getRoom():handleAcquireDetachSkills(player, "ckshengyu")
				player:getRoom():handleAcquireDetachSkills(player, "cklongxi")
				end
	end,
}
local Skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("ckshengyu") then
	Skills:append(ckshengyu)
end
if not sgs.Sanguosha:getSkill("cklongxi") then
	Skills:append(cklongxi)
end
sgs.Sanguosha:addSkills(Skills)

ck_index:addSkill(ckyongchang)
ck_index:addSkill(ckjinshu)
indexWaked:addSkill(ckyongchang)
indexWaked:addSkill(ckjinshu)
indexWaked:addSkill("ckshengyu")
indexWaked:addSkill("cklongxi")

sgs.LoadTranslationTable {
	["ck_index"] = "茵蒂克丝",
	["&ck_index"] = "茵蒂克丝",
	["#ck_index"]="魔道书图书馆",
	["designer:ck_index"]="CK",
	["cv:ck_index"]="官方",
	["illustrator:ck_index"]="官方",
	["indexWaked"] = "茵蒂克丝",
	["&indexWaked"] = "茵蒂克丝",
	["#indexWaked"]="魔道书图书馆",
	["designer:indexWaked"]="CK",
	["cv:indexWaked"]="官方",
	["illustrator:indexWaked"]="官方",
	["ckyongchang"] = "咏唱",
	[":ckyongchang"] = "每当一名角色成为【杀】的目标后，你可以进行一次判定，若结果为黑色，该角色摸一张牌，若结果为红色，此杀无效。",
	["$ckyongchang"] = "咏唱音效",
	["#ckyongchangGood"] = "此杀无效。",
	["ckshengyu"] = "圣域",
	[":ckshengyu"] = "<font color=\"blue\"><b>锁定技，</b></font>每名其他角色的回合限一次，你免疫即将受到的伤害。",
	["$ckshengyu"] = "圣域音效",
	["#ckshengyu"] = "免疫本次伤害",
	["cklongxi"] = "龙息",
	[":cklongxi"] = "<font color=\"red\"><b>限定技，</b></font>指定一名角色，弃置其所有装备和手牌，对其造成3点伤害，然后你失去技能【圣域】",
	["$cklongxi"] = "龙息音效",
	["@longxi"] = "龙息",
	["#longxi"] = "龙王的叹息",
	["ckjinshu"] = "禁书",
	[":ckjinshu"] = "<font color=\"purple\"><b>觉醒技，</b></font>当你进入濒死阶段时，立即回复至1点体力，并获得技能【圣域】和【龙息】。",
	["$ckjinshu"] = "禁书音效",
	["#jinshu"] = "禁书",
}

kanzaki = sgs.General(extension, "kanzaki", "magic", 4, false)

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
ckqishan = sgs.CreateTriggerSkill{
	name = "ckqishan",
	events = {sgs.TargetConfirmed},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if not use.card or not use.from or not use.from:hasSkill(self:objectName()) or not use.card:isKindOf("Slash") then return false end
		room:sendCompulsoryTriggerLog(player, self:objectName(), true)
		room:broadcastSkillInvoke(self:objectName())
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local msg = sgs.LogMessage()
		msg.type = "#NoJink"
		local index = 1
		for _, p in sgs.qlist(use.to) do
			jink_table[index] = 0
			index = index + 1
			msg.from = p
			room:sendLog(msg)
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	end,
}

ckqishan2 = sgs.CreateTargetModSkill{
	name = "#ckqishan",
	pattern = "Slash",
	extra_target_func = function(self, from, card)
        if from:hasSkill("ckqishan") then
            return 1000
        else
            return 0
		end
	end,
}

ckweishancard = sgs.CreateSkillCard{
	name = "ckweishancard" ,
	will_throw = true,
	filter = function(self, selected, to_select, source)
		return #selected == 0 and to_select:objectName() ~= source:objectName()
	end ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		effect.from:loseMark("@weishan")
		room:doSuperLightbox("ck_kanzaki", "ckweishan")
		room:broadcastSkillInvoke("ckweishan")
		room:damage(sgs.DamageStruct("ckweishan", effect.from, effect.to, effect.to:getMaxHp()))
		room:loseHp(effect.from, 1, true, effect.from, self:objectName())
		effect.from:turnOver()
		return false
	end
}	

ckweishanVS = sgs.CreateViewAsSkill{
	name = "ckweishan",
	n = 3,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then return true end
		local i = 1
		for i=1,#selected do
			if selected[i]:getType() == to_select:getType() then return false end
		end
		if #selected == 3 then return false end
		return true
	end,
	view_as = function(self, cards) 
		if #cards ~= 3 then return nil end
		local card = ckweishancard:clone()
		card:addSubcard(cards[1])
		card:addSubcard(cards[2])
		card:addSubcard(cards[3])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@weishan") > 0
	end,
}

ckweishan = sgs.CreateTriggerSkill{
	name = "ckweishan",
	frequency = sgs.Skill_Limited,
	limit_mark = "@weishan",
	view_as_skill = ckweishanVS,
	on_trigger = function(self, event, player, data)
		return false
	end,
}

ckjinjieCard = sgs.CreateSkillCard{
	name = "ckjinjieCard" ,
	will_throw = true,
	filter = function(self, selected, to_select)
		if #selected >= 3 then return false end
		return true
	end ,
	on_use = function(self, room, player, targets)
		for _, p in ipairs(targets) do
			room:addPlayerMark(p, "@jinjie", 1)
		end
		return false
	end
}	

ckjinjieVS = sgs.CreateViewAsSkill{
	name = "ckjinjie" ,
	n = 0,
	response_pattern = "@@ckjinjie",
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self, cards)
		local card = ckjinjieCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
}

ckjinjie = sgs.CreateTriggerSkill {
	name = "ckjinjie",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = ckjinjieVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Play then return false end
		if room:askForUseCard(player, "@@ckjinjie", "@ckjinjie") then
			room:broadcastSkillInvoke(self:objectName())
		end
		return false
	end,
}

ckjinjie_clear = sgs.CreateTriggerSkill{
	name = "#ckjinjie",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Start then return false end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then return false end
		end
		
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("@jinjie") > 0 then
				room:removePlayerMark(p, "@jinjie", 1)
			end
		end
		return false
	end,
}

ckjinjieDS = sgs.CreateDistanceSkill{
	name = "#ckjinjieDS",
	correct_func = function(self, from, to)
		if from:getMark("@jinjie") > 0 and to:getMark("@jinjie") > 0 then
			return -1000
		elseif from:getMark("@jinjie") > 0 or to:getMark("@jinjie") > 0 then
			return 1
		end
	end,
}

kanzaki:addSkill(ckqishan)
kanzaki:addSkill(ckqishan2)
extension:insertRelatedSkills("ckqishan", "#ckqishan")
kanzaki:addSkill(ckweishan)
kanzaki:addSkill(ckjinjie)
kanzaki:addSkill(ckjinjie_clear)
kanzaki:addSkill(ckjinjieDS)
extension:insertRelatedSkills("ckjinjie", "#ckjinjie")
extension:insertRelatedSkills("ckjinjie", "#ckjinjieDS")

sgs.LoadTranslationTable {
	["kanzaki"] = "神裂火织",
	["&kanzaki"] = "神裂火织",
	["#kanzaki"] = "圣人",
	["designer:kanzaki"]="CK",
	["cv:kanzaki"] = "官方",
	["illustrator:kanzaki"]="官方",
	["ckqishan"] = "七闪",
	["#ckqishan"] = "七闪",
	[":ckqishan"] = "锁定技，你的【杀】可以指定攻击范围内的任意名角色为目标且不可被【闪】响应",
	["$ckqishan"] = "七闪音效",
	["ckweishan"] = "唯闪",
	[":ckweishan"] = "限定技，弃置三张不同类型的牌并指定一名其他角色，对其造成X点伤害(X为其体力上限)，然后你流失一点体力并翻面",
	["$ckweishan"] = "唯闪音效",
	["@weishan"] = "唯闪",
	["ckjinjie"] = "禁界",
	["#ckjinjie"] = "禁界",
	["#ckjinjieDS"] = "禁界",
	[":ckjinjie"] = "出牌阶段开始时，你可以指定至多3名角色，直到你的下一个回合开始，其处于结界内，结界内角色之间距离为1，结界内外角色之间距离+1",
	["$ckjinjie"] = "禁界音效",
	["@jinjie"] = "禁界",
	["@ckjinjie"] = "发动 “禁界” 吗？",
	["~ckjinjie"] = "指定至多3名角色→点击确定",
}



