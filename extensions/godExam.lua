extension_exam = sgs.Package("godexam")


sgs.Sanguosha:setAudioType("simayi","fankui","1,2")
sgs.Sanguosha:setAudioType("jiaxu","weimu","1,2")
sgs.Sanguosha:setAudioType("yl_chujiang","weimu","3")
sgs.Sanguosha:setAudioType("yl_chujiang","fankui","3")
sgs.Sanguosha:setAudioType("nos_fazheng","nosenyuan","1,2,3,4")
sgs.Sanguosha:setAudioType("yl_songdi","nosenyuan","5")

ge_zhuque = sgs.General(extension_exam, "ge_zhuque", "god", 4, false, true)
ge_shenyi = sgs.CreateTriggerSkill{
	name = "ge_shenyi",
	events = {sgs.TurnOver, sgs.StartJudge, sgs.EventPhaseProceeding},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TurnOver and player:faceUp() then
			room:sendCompulsoryTriggerLog(player, self)
			return true
		elseif event == sgs.EventPhaseProceeding then
			player:removeTag("ge_shenyiJudge")
			if player:getPhase()==sgs.Player_Judge then
				player:setTag("ge_shenyiJudge",ToData(player:getJudgingAreaID()))
			end
		elseif event == sgs.StartJudge then
			local judge = data:toJudge()
			for _,id in sgs.qlist(player:getTag("ge_shenyiJudge"):toIntList()) do
				if sgs.Sanguosha:getCard(id):objectName()==judge.reason then
					room:sendCompulsoryTriggerLog(player, self)
					judge.good = not judge.good
					data:setValue(judge)
					break
				end
			end
		end
		return false
	end
}
ge_fentian = sgs.CreateTriggerSkill{
	name = "ge_fentian",
	events = {sgs.ConfirmDamage, sgs.TrickCardCanceling, sgs.SlashProceed},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			damage.nature = sgs.DamageStruct_Fire
			data:setValue(damage)
			room:sendCompulsoryTriggerLog(poi, self)
		elseif event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isRed() then
				return true
			end
		else
			local effect = data:toSlashEffect()
			if effect.from:objectName() == poi:objectName() and effect.slash:isRed() then
				room:sendCompulsoryTriggerLog(poi, self)
				room:slashResult(effect, nil)
				return true
			end
		end
	end
}
ge_zhuque:addSkill(ge_shenyi)
ol_fentiaCard = sgs.CreateSkillCard{
	name = "ol_fentiaCard",
	target_fixed = false,
	filter = function(self, targets, to_select, from)
		return to_select:objectName()~=from:objectName()
		and #targets < 1
	end,
	on_use = function(self, room, source, targets)
		for _, p in sgs.list(targets) do
			room:damage(sgs.DamageStruct("ol_fentia", source, p, 1, sgs.DamageStruct_Fire))
		end
		return false
	end
}
ge_fentianvs = sgs.CreateZeroCardViewAsSkill{
	name = "ge_fentian",
	view_as = function()
		return ol_fentiaCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#ol_fentiaCard") <= player:getMark("ol_fentian-PlayClear")
	end
}
ge_fentian = sgs.CreateTriggerSkill{
	name = "ge_fentian",
	events = {sgs.Death},
	view_as = ge_fentianvs,
	on_trigger = function(self, event, player, data, room)
		local death = data:toDeath()
		if death.damage and death.damage.reason==self:objectName() then
			room:addPlayerMark(player,"ol_fentian-PlayClear")
		end
	end,
}
ge_zhuque:addSkill(ge_fentian)

ge_zhurong = sgs.General(extension_exam, "ge_zhurong", "god", 5, true, true)
ge_zhurong:addSkill("ge_shenyi")
ge_xingxiaCard = sgs.CreateSkillCard{
	name = "ge_xingxia",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(source, "ge_xingxia_turn_count", 2)
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getGeneralName() == "ge_yanling" or p:getGeneral2Name() == "ge_yanling" then
				room:damage(sgs.DamageStruct(self:objectName(), source, p, 2, sgs.DamageStruct_Fire))
			end
		end
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if not p:isYourFriend(source) and not room:askForCard(p, ".|red", "@ge_xingxia-discard:" .. p:objectName(), sgs.QVariant(), sgs.Card_MethodDiscard) then
				room:damage(sgs.DamageStruct(self:objectName(), source, p, 1, sgs.DamageStruct_Fire))
			end
		end
	end
}
ge_xingxia = sgs.CreateZeroCardViewAsSkill{
	name = "ge_xingxia",
	view_as = function()
		return ge_xingxiaCard:clone()
	end,
	enabled_at_play = function(self, target)
		return target:getMark("ge_xingxia_turn_count") == 0
	end
}
ge_zhurong:addSkill(ge_xingxia)

ge_yanling = sgs.General(extension_exam, "ge_yanling", "god", 4, true, true)
ge_huihuo = sgs.CreateTriggerSkill{
	name = "ge_huihuo",
	events = {sgs.Death},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
			room:sendCompulsoryTriggerLog(player, self)
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not player:isYourFriend(p) then
					room:damage(sgs.DamageStruct(self:objectName(), player, p, 3, sgs.DamageStruct_Fire))
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}
ge_yanling:addSkill(ge_huihuo)
ge_furan = sgs.CreateTriggerSkill{
	name = "ge_furan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EnterDying, sgs.QuitDying},
	can_trigger = function(self,target)
		return target
	end,
	on_trigger = function(self, event, player, data, room)
		if event==sgs.EnterDying then
			if player:hasSkill(self) then
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if not p:hasSkill("ge_furan_use",true) then
					room:attachSkillToPlayer(p, "ge_furan_use")
				end
			end
		end
		else
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasSkill("ge_furan_use",true) then
					room:detachSkillFromPlayer(p, "ge_furan_use",true)
				end
			end
		end
		return false
	end
}
ge_yanling:addSkill(ge_furan)
ge_furan_use = sgs.CreateOneCardViewAsSkill{
	name = "ge_furan_use&",
	response_or_use = true,
	filter_pattern = ".|red",
	view_as = function(self, card)
		local peach = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
		peach:setSkillName(self:objectName())
		peach:addSubcard(card:getId())
		return peach
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if string.find(pattern, "peach") then
			for _,p in sgs.qlist(player:getAliveSiblings()) do
				if p:hasFlag("Global_Dying") and p:hasSkill("ge_furan") and not player:isYourFriend(p)
				then return true end
			end
		end
		return false
	end
}
addToSkills(ge_furan_use)

ge_yandi = sgs.General(extension_exam, "ge_yandi", "god", 6, true, true)
ge_yandi:addSkill("ge_shenyi")
ge_shenen = sgs.CreateTriggerSkill{
	name = "ge_shenen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards},
	can_trigger = function(self,target)
		return target
	end,
	on_trigger = function(self, event, player, data, room)
		local draw = data:toDraw()
		if draw.reason~="draw_phase" then return end
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if not p:isYourFriend(player) then
				room:sendCompulsoryTriggerLog(p, self)
				draw.num = draw.num+1
				data:setValue(draw)
			end
		end
	end
}
ge_shenenbf1 = sgs.CreateMaxCardsSkill{
    name = "#ge_shenenbf1",
	extra_func = function(self,target)
		for _,p in sgs.list(target:getAliveSiblings())do
			if not p:isYourFriend(target) and p:hasSkill("ge_shenen")
			then return 1 end
		end
		return 0
	end 
}
ge_yandi:addSkill(ge_shenen)
ge_yandi:addSkill(ge_shenenbf1)
ge_shenenbf2 = sgs.CreateTargetModSkill{
	name = "#ge_shenenbf2",
	pattern = ".",
	residue_func = function(self,from,card)-- 额外使用
		return 0
	end,
	distance_limit_func = function(self,from,card,to)-- 使用距离
		for _,p in sgs.list(from:getAliveSiblings())do
			if p:isYourFriend(from) and p:hasSkill("ge_shenen")
			then return 999 end
		end
		if from:hasSkill("ge_shenen")
		then return 999 end
		return 0
	end,
	extra_target_func = function(self,from,card)--目标数
		return 0
	end
}
ge_yandi:addSkill(ge_shenenbf2)
ge_chiyi = sgs.CreateTriggerSkill{
	name = "ge_chiyi",
	events = {sgs.DamageInflicted, sgs.RoundStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local count = room:getTag("TurnLengthCount"):toInt()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if not p:isYourFriend(damage.to) and count >= 4 then
					room:sendCompulsoryTriggerLog(p, self)
					room:doAnimate(1,p:objectName(),damage.to:objectName())
					player:damageRevises(data,1)
				end
			end
		elseif player:hasSkill(self:objectName()) then
			if count == 7 then
				room:sendCompulsoryTriggerLog(player, self)
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					room:doAnimate(1,player:objectName(),p:objectName())
				end
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					room:damage(sgs.DamageStruct(self:objectName(), player, p, 1, sgs.DamageStruct_Fire))
				end
			elseif count == 10 then
				room:sendCompulsoryTriggerLog(player, self)
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getGeneralName() == "ge_yanling" or p:getGeneral2Name() == "ge_yanling" then
						room:doAnimate(1,player:objectName(),p:objectName())
						sgs.DamageStruct(self:objectName(), player, p, 0)
						room:killPlayer(p)
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target
	end
}
ge_yandi:addSkill(ge_chiyi)
extension_exam:insertRelatedSkills("ge_shenen", "#ge_shenenbf1")
extension_exam:insertRelatedSkills("ge_shenen", "#ge_shenenbf2")

ge_qinglong = sgs.General(extension_exam, "ge_qinglong", "god", 4, true, true)
ge_qinglong:addSkill("ge_shenyi")
--ge_qinglong:addSkill("olleiji")
ge_tengyun = sgs.CreateTriggerSkill{
	name = "ge_tengyun",
	events = {sgs.Damaged,sgs.TargetConfirming},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			room:sendCompulsoryTriggerLog(player, self)
			room:addPlayerMark(player, "&ge_tengyun-Clear")
		else
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and use.from~=player
			and player:getMark("&ge_tengyun-Clear")
			then
				room:sendCompulsoryTriggerLog(player, self)
				local list = use.nullified_list
				table.insert(list,player:objectName())
				use.nullified_list = list
				data:setValue(use)
			end
		end
	end
}
ge_qinglong:addSkill(ge_tengyun)

ge_goumang = sgs.General(extension_exam, "ge_goumang", "god", 5, true, true)
ge_goumang:addSkill("ge_shenyi")
ge_buchunCard = sgs.CreateSkillCard{
	name = "ge_buchun",
	target_fixed = false,
	filter = function(self, targets, to_select, from)
		for _, p in sgs.qlist(from:getSiblings()) do
			if from:isYourFriend(p) and p:isDead()
			and p:getMaxHp() > 0
			then return false end
		end
		return not from:isYourFriend(to_select)
		and #targets < 1
	end,
	feasible = function(self, targets,from)
		for _, p in sgs.qlist(from:getSiblings()) do
			if from:isYourFriend(p) and p:isDead()
			and p:getMaxHp() > 0
			then return true end
		end
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(source, "ge_buchun_turn_count", 2)
		if #targets>0 then
			for _, p in sgs.list(targets) do
				room:damage(sgs.DamageStruct(self:objectName(), source, p, 2))
			end
		else
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:isDead() and p:getMaxHp() > 0 and source:isYourFriend(p)
				then
					room:doAnimate(1,source:objectName(),p:objectName())
					local hp = p:getHp()
					room:revivePlayer(p)
					room:setPlayerProperty(p, "hp", sgs.QVariant(hp))
					room:recover(p, sgs.RecoverStruct(source, nil, 1 - hp))
					p:drawCards(2 - p:getHandcardNum(), self:objectName())
				end
			end
		end
		return false
	end
}
ge_buchunvs = sgs.CreateZeroCardViewAsSkill{
	name = "ge_buchun",
	view_as = function()
		return ge_buchun_card:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("ge_buchun_turn_count") < 1
	end
}
ge_buchun = sgs.CreateTriggerSkill{
	name = "ge_buchun",
	events = {sgs.RoundStart},
	view_as = ge_buchunvs,
	on_trigger = function(self, event, player, data, room)
		room:removePlayerMark(player, "ge_buchun_turn_count")
	end,
}
ge_goumang:addSkill(ge_buchun)

ge_shujing = sgs.General(extension_exam, "ge_shujing", "god", 2, false, true)
ge_cuidu = sgs.CreateTriggerSkill{
	name = "ge_cuidu",
	events = {sgs.Damage},
	frequency = sgs.Skill_Compulsory,
	waked_skills = "ge_zhongdu",
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.to:isAlive() and not damage.to:hasSkill("ge_zhongdu") then
			room:sendCompulsoryTriggerLog(player, self)
			room:doAnimate(1,player:objectName(),damage.to:objectName())
			room:acquireSkill(damage.to, "ge_zhongdu")
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getGeneralName() == "ge_goumang" then
					room:drawCards(p, 1, self:objectName())
				end
			end
		end
	end
}
ge_shujing:addSkill(ge_cuidu)
ge_zhongdu = sgs.CreateTriggerSkill{
	name = "ge_zhongdu",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Start then
			room:sendCompulsoryTriggerLog(player, self)
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|diamond"
			judge.who = player
			judge.reason = self:objectName()
			judge.good = false
			room:judge(judge)
			if judge:isBad() then
				room:damage(sgs.DamageStruct(self:objectName(), nil, player))
			else
				room:detachSkillFromPlayer(player, self:objectName())
			end
		end
	end
}
addToSkills(ge_zhongdu)

ge_taihao = sgs.General(extension_exam, "ge_taihao", "god", 6, true, true)
ge_taihao:addSkill("ge_shenyi")
ge_taihao:addSkill("ge_shenen")
ge_qingyi = sgs.CreateTriggerSkill{
	name = "ge_qingyi",
	events = {sgs.RoundStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local count = room:getTag("TurnLengthCount"):toInt()
		if count == 3 then
			room:sendCompulsoryTriggerLog(player, self)
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if player:isYourFriend(p) and p:isWounded() then
					room:doAnimate(1,player:objectName(),p:objectName())
					room:recover(p, sgs.RecoverStruct(player))
				end
			end
		elseif count == 6 then
			room:sendCompulsoryTriggerLog(player, self)
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if not player:isYourFriend(p) then
					room:doAnimate(1,player:objectName(),p:objectName())
					room:loseHp(p,1,true,player,self:objectName())
				end
			end
		elseif count == 9 then
			room:sendCompulsoryTriggerLog(player, self)
			for _,p in sgs.qlist(room:getPlayers()) do
				if player:isYourFriend(p) and p:isDead() and p:getMaxHp() > 0 then
					room:doAnimate(1,player:objectName(),p:objectName())
					room:revivePlayer(p)
					room:recover(p, sgs.RecoverStruct(player, nil, p:getMaxHp()-p:getHp()))
					room:drawCards(p, 4, self:objectName())
				end
			end
			for _,p in sgs.qlist(room:getPlayers()) do
				if player:isYourFriend(p) and p:isAlive() then
					room:acquireSkill(p,"qingnang")
				end
			end
		end
		return false
	end
}
ge_taihao:addSkill(ge_qingyi)

ge_baihu = sgs.General(extension_exam, "ge_baihu", "god", 4, true, true)
ge_baihu:addSkill("ge_shenyi")
ge_kuangxiao = sgs.CreateTriggerSkill{
	name = "ge_kuangxiao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreCardUsed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not player:isYourFriend(p) and not use.to:contains(p) then
					use.to:append(p)
				end
			end
			room:sortByActionOrder(use.to)
			data:setValue(use)
			room:sendCompulsoryTriggerLog(player, self)
		end
	end
}
ge_baihu:addSkill(ge_kuangxiao)

ge_rushou = sgs.General(extension_exam, "ge_rushou", "god", 5, true, true)
ge_rushou:addSkill("ge_shenyi")
xingqiu = sgs.CreateTriggerSkill{
	name = "xingqiu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.RoundStart,sgs.EventPhaseStart},
	waked_skills = "jiding",
	on_trigger = function(self, event, player, data, room)
		if event == sgs.RoundStart then
			room:removePlayerMark(player, "xingqiu_turn_count")
		elseif player:getPhase()==sgs.Player_Play
		and player:getMark("xingqiu_turn_count")<1 then
			room:sendCompulsoryTriggerLog(player, self)
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not player:isYourFriend(p) then
					room:doAnimate(1,player:objectName(),p:objectName())
				end
			end
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not player:isYourFriend(p) then
					room:setPlayerChained(p,true)
				end
				if p:getGeneralName()=="ge_zhu" or p:getGeneral2Name()=="ge_zhu"
				then room:acquireSkill(p,"jiding") end
			end
		end
	end,
}
ge_rushou:addSkill(xingqiu)
jiding = sgs.CreateTriggerSkill{
	name = "jiding",
	events = {sgs.Damage},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self,target)
		return target
	end,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.from then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p~=damage.to and p:isYourFriend(damage.to) and not p:isYourFriend(damage.from) then
					room:sendCompulsoryTriggerLog(player, self)
					local dc = dummyCard("thunder_slash")
					dc:setSkillName("_"..self:objectName())
					if p:canUse(dc,damage.from,true) then
						dc:setFlags("jiding"..p:objectName())
						room:useCard(sgs.CardUseStruct(dc,p,damage.from))
					end
				end
				if damage.card and damage.card:hasFlag("jiding"..p:objectName()) then
					room:sendCompulsoryTriggerLog(player, self)
					for _, pt in sgs.qlist(room:getAlivePlayers()) do
						if pt:getGeneralName()=="ge_rushou" or pt:getGeneral2Name()=="ge_rushou"
						then room:recover(pt, sgs.RecoverStruct(p)) end
					end
					room:detachSkillFromPlayer(p, self:objectName())
				end
			end
		end
	end
}
addToSkills(jiding)

ge_zhu = sgs.General(extension_exam, "ge_zhu", "god", 3, false, true)
ge_qingzhu = sgs.CreateTriggerSkill{
	name = "ge_qingzhu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseChanging then
    		local change = data:toPhaseChange()
            if change.to==sgs.Player_Discard then
				room:sendCompulsoryTriggerLog(player, self)
				player:skip(change.to)
			end
		end
		return false
	end,
}
ge_qingzhubf = sgs.CreateCardLimitSkill{
	name = "#ge_qingzhubf" ,
	limit_list = function(self,player)
		return "use"
	end,
	limit_pattern = function(self,player)
		if player:getPhase()==sgs.Player_Play and player:hasSkill("ge_qingzhu")
		and not player:hasSkill("jiding") then return "Slash" end
	end
}
ge_zhu:addSkill(ge_qingzhu)
ge_zhu:addSkill(ge_qingzhubf)
extension_exam:insertRelatedSkills("ge_qingzhu", "#ge_qingzhubf")
ge_jiazu = sgs.CreateTriggerSkill{
	name = "ge_jiazu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseProceeding},
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()==sgs.Player_Start then
			room:sendCompulsoryTriggerLog(player, self)
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:isYourFriend(p) then continue end
				if player:getNextAlive()==p then
					local dc = dummyCard()
					for _, e in sgs.qlist(p:getEquips()) do
						if e:isKindOf("Horse")
						then dc:addSubcard(e) end
					end
					if dc:subcardsLength()>0 then
						room:throwCard(dc,self:objectName(),p,player)
					end
				end
				if p:getNextAlive()==player then
					local dc = dummyCard()
					for _, e in sgs.qlist(p:getEquips()) do
						if e:isKindOf("Horse")
						then dc:addSubcard(e) end
					end
					if dc:subcardsLength()>0 then
						room:throwCard(dc,self:objectName(),p,player)
					end
				end
			end
		end
		return false
	end,
}
ge_zhu:addSkill(ge_jiazu)

ge_shaohao = sgs.General(extension_exam, "ge_shaohao", "god", 6, true, true)
ge_shaohao:addSkill("ge_shenyi")
ge_shaohao:addSkill("ge_shenen")
ge_baiyi = sgs.CreateTriggerSkill{
	name = "ge_baiyi",
	events = {sgs.DamageForseen, sgs.DrawNCards, sgs.RoundStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local count = room:getTag("TurnLengthCount"):toInt()
		if event == sgs.DamageForseen then
			local damage = data:toDamage()
			if count >= 7 or damage.nature~=sgs.DamageStruct_Thunder then return end
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:isYourFriend(damage.to) then
					room:sendCompulsoryTriggerLog(p, self)
					room:doAnimate(1,p:objectName(),damage.to:objectName())
					return p:damageRevises(data,-damage.damage)
				end
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason~="draw_phase" then return end
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if not p:isYourFriend(player) then
					room:sendCompulsoryTriggerLog(p, self)
					room:doAnimate(1,p:objectName(),player:objectName())
					draw.num = draw.num-1
					data:setValue(draw)
				end
			end
		elseif player:hasSkill(self:objectName()) then
			if count == 5 then
				room:sendCompulsoryTriggerLog(player, self)
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:isYourFriend(p) then continue end
					room:doAnimate(1,player:objectName(),p:objectName())
				end
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:isYourFriend(p) then continue end
					room:askForDiscard(p,self:objectName(),2,2,false,true)
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target
	end
}
ge_shaohao:addSkill(ge_baiyi)

ge_xuanwu = sgs.General(extension_exam, "ge_xuanwu", "god", 4, false, true)
ge_xuanwu:addSkill("ge_shenyi")
ge_lingqu = sgs.CreateTriggerSkill{
	name = "ge_lingqu",
	events = {sgs.DamageInflicted, sgs.Damaged},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.damage<2 then return end
			room:sendCompulsoryTriggerLog(player, self)
			return player:damageRevises(data,-damage.damage)
		else
			room:sendCompulsoryTriggerLog(player, self)
			player:drawCards(1,self:objectName())
		end
	end,
}
ge_xuanwu:addSkill(ge_lingqu)

ge_gonggong = sgs.General(extension_exam, "ge_gonggong", "god", 6, true, true)
ge_gonggong:addSkill("ge_shenyi")
ge_juehong = sgs.CreateTriggerSkill{
	name = "ge_juehong",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()==sgs.Player_Start then
			room:sendCompulsoryTriggerLog(player, self)
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:isYourFriend(p) or p:isNude() then continue end
				room:doAnimate(1,player:objectName(),p:objectName())
				if p:hasEquip() then p:throwAllEquips(self:objectName())
				else
					local id = room:askForCardChosen(player,p,"h",self:objectName(),false,sgs.Card_MethodDiscard)
					room:throwCard(id,self:objectName(),p,player)
				end
			end
		end
		return false
	end,
}
ge_gonggong:addSkill(ge_juehong)

ge_xuanming = sgs.General(extension_exam, "ge_xuanming", "god", 6, false, true)
ge_xuanming:addSkill("ge_shenyi")
ge_zirun = sgs.CreateTriggerSkill{
	name = "ge_zirun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()==sgs.Player_Start then
			room:sendCompulsoryTriggerLog(player, self)
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:doAnimate(1,player:objectName(),p:objectName())
				if p:hasEquip() then p:drawCards(2,self:objectName())
				else p:drawCards(1,self:objectName()) end
			end
		end
		return false
	end,
}
ge_xuanming:addSkill(ge_zirun)

ge_chuanxi = sgs.General(extension_exam, "ge_chuanxi", "god", 4, true, true)
ge_chuanxi:addSkill("ge_shenyi")
ge_chuanxi:addSkill("ge_shenen")
ge_zaoyi = sgs.CreateProhibitSkill{
	name = "ge_zaoyi",
	is_prohibited = function(self,from,to,card)
		if not to:isYourFriend(from) and to:hasSkill(self) then
			if card:getTypeId()==1 then
				for _, p in sgs.qlist(to:getAliveSiblings()) do
					if p:getGeneralName()=="ge_gonggong"
					or p:getGeneral2Name()=="ge_gonggong"
					then return true end
				end
			elseif card:getTypeId()==1 then
				for _, p in sgs.qlist(to:getAliveSiblings()) do
					if p:getGeneralName()=="ge_xuanming"
					or p:getGeneral2Name()=="ge_xuanming"
					then return true end
				end
			end
		end
	end
}
ge_zaoyibf = sgs.CreateTriggerSkill{
	name = "#ge_zaoyibf",
	events = {sgs.Death,sgs.EventPhaseChanging},
	can_trigger = function(self,target)
		return target and target:isAlive()
		and target:hasSkill("ge_zaoyi")
	end,
	on_trigger = function(self, event, player, data, room)
		if event==sgs.EventPhaseChanging then
    		local change = data:toPhaseChange()
            if change.from==sgs.Player_NotActive
			and player:getMark("ge_zaoyibf")>0 then
				local n = 999
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					n = math.min(n,p:getHp())
				end
				local tos = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:isYourFriend(p) then continue end
					if p:getHp()<=n then tos:append(p) end
				end
				if tos:isEmpty() then return end
				room:sendCompulsoryTriggerLog(player, self)
				tos = PlayerChosen("ge_zaoyi",player,tos,"ge_zaoyi0:")
				room:loseHp(tos,tos:getHp(),true,player,"ge_zaoyi")
			end
			return false
		end
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if p:getGeneralName()=="ge_gonggong"
			or p:getGeneral2Name()=="ge_gonggong"
			or p:getGeneral2Name()=="ge_xuanming"
			or p:getGeneral2Name()=="ge_xuanming"
			then return end
		end
		room:sendCompulsoryTriggerLog(player, self)
		room:addPlayerMark(player,"ge_zaoyibf")
	end,
}
ge_chuanxi:addSkill(ge_zaoyi)
ge_chuanxi:addSkill(ge_zaoyibf)
extension_exam:insertRelatedSkills("ge_zaoyi", "#ge_zaoyibf")


ge_honghuang = sgs.CreateTrickCard{
	name = "ge_honghuang",
	class_name = "Honghuang",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = false,
	can_recast = false,
	is_cancelable = true,
	--damage_card = true,
    available = function(self,player)
    	for _,to in sgs.list(player:getAliveSiblings())do
			if CanToCard(self,player,to) then
				return self:cardIsAvailable(player)
			end
		end
    end,
	filter = function(self,targets,to_select,source)
	    if source:isProhibited(to_select,self) then return end
		return to_select:objectName()~=source:objectName()
		and #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self,to_select)
	end,
	on_effect = function(self,effect)
		local room = effect.to:getRoom()
	   	if effect.to:getKingdom()=="god"
		then
			if effect.to:getCardCount()>0
			and effect.from:isAlive()
			then
				local id = room:askForCardChosen(effect.from,effect.to,"he",self:objectName())
				room:obtainCard(effect.from,id,false)
			end
			room:addPlayerMark(effect.to,"Qingchengge_shenyi")
			room:addPlayerMark(effect.to,"&ge_honghuangbf")
		else
			effect.to:turnOver()
		end
		return false
	end,
}
ge_honghuang:clone(0,1):setParent(extension_exam)
ge_honghuang:clone(2,12):setParent(extension_exam)

local god_examWinner = 1

GodExamOnTrigger = sgs.CreateTriggerSkill{
	name = "#GodExamOnTrigger",
	events = {sgs.EventPhaseChanging,sgs.GameOver},
	frequency = sgs.Skill_Compulsory,
	global = true,
	can_trigger = function(self,target)
		return target and target:isAlive()
		and not table.contains(sgs.Sanguosha:getBanPackages(),"godexam")
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseChanging then
    		local change = data:toPhaseChange()
            if change.from==sgs.Player_NotActive then
				local to = player:getNextAlive(player:aliveCount()-1)
				local n = to:getMark("&ge_honghuangbf")
				if n>0 then
					room:removePlayerMark(to,"Qingchengge_shenyi",n)
				end
			end
		elseif event==sgs.GameOver then
			if room:getMode()~="04_ge" then return end
			local winner = data:toString():split("+")
			local owner = room:getOwner()
			if table.contains(winner,owner:objectName())
			or table.contains(winner,owner:getRole()) then
				god_examWinner = god_examWinner+1
				if god_examWinner>1 then
					--sgs.Sanguosha:addModes("04_ge","4 人局 神之试炼","ZCCFFF")
				end
			end
		end
		return false
	end,
}
addToSkills(GodExamOnTrigger)
--sgs.Sanguosha:addModes("04_ge","4 人局 神之试炼","ZFFF")--添加游戏模式

local god_examRandom = 0
local god_examBoss = {
	b = {a = {"ge_goumang","ge_shujing","ge_shujing"},
		b = {"ge_zhurong","ge_yanling","ge_yanling"},
		c = {"ge_rushou","ge_zhu","ge_zhu"},
		d = {"ge_gonggong","ge_xuanming"}
		},
	c = {a = {"ge_taihao","ge_shujing","ge_goumang"},
		b = {"ge_yandi","ge_yanling","ge_zhurong"},
		c = {"ge_shaohao","ge_zhu","ge_zhu","ge_rushou"},
		d = {"ge_chuanxi","ge_gonggong","ge_xuanming"}
		}
}

god_examScenario = sgs.CreateScenario{--创建剧情模式
	name = "godexam",--剧情名称
	expose = true,--身份是否可见
	roles = {--身份数（-1代表不指定武将，默认为素将，可以将-1改为特定武将名，例如樊城之战["lord"] = "guanyu"）
		["lord"] = -1,
		["rebel1"] = -1,
		["rebel2"] = -1,
		["rebel3"] = -1,
	},
	on_assign = function(self,generals,roles)
		local generals2 = generals
		local roles2 = roles
		table.insert(roles,"rebel")
		table.insert(roles,"rebel")
		table.insert(roles,"rebel")
		if god_examWinner==1 then
			table.insert(generals2,"sujiaog")
			table.insert(generals2,"sujiaog")
			table.insert(generals2,"sujiaog")
			table.insert(generals2,"sujiaog")
			table.insert(roles,"lord")
		else
			local tn = {"a","b","c","d"}
			local boss = god_examBoss[tn[god_examWinner]][tn[god_examRandom]]
			if #boss>2 then table.insert(roles,"loyalist") end
			table.insert(roles,"lord")
			table.insert(roles,"loyalist")
		end
		generals = generals2
		roles = roles2
	end
}
god_examScenarioRule = sgs.CreateScenarioRule{--创建剧情规则（就是创建一个特殊的全局触发技，但这个全局触发技只有进入剧情才启用）
	events = {sgs.GameReady,sgs.GameOver},--触发时机
	global = true,--默认全局触发
	scenario = god_examScenario,--设定触发技的剧情模式
	on_trigger = function(self,event,player,data,room)--触发函数
		if event==sgs.GameReady then
			if room:getTag("god_exam"):toBool() or player then return end
			local lord = room:getLord()
			if not lord then return end
			room:setTag("god_exam",ToData(true))
			local ops = room:getOtherPlayers(lord)
			
			local lgs = {"ge_qinglong","ge_zhuque","ge_baihu","ge_xuanwu"}
			local lgn = math.random(1,#lgs)
			local lg = lgs[lgn]
			local heros = {}
			if god_examWinner==1 then
				god_examRandom = lgn
			else
				local boss = god_examBoss[god_examWinner][god_examRandom]
				for i,b in sgs.list(boss)do
					if i<2 then
						ig = b
					else
						for _,p in sgs.list(ops)do
							if p:getRole()=="loyalist" then
								heros[p:objectName()] = b
								ops:removeOne(p)
								break
							end
						end
					end
				end
			end
			room:changeHero(lord,lg,true,false,false,false)
			local rgs = {}
			local total = sgs.GetConfig("MaxChoice",5)
			local lords = sgs.Sanguosha:getRandomGenerals(total*ops:length())
           	for _,p in sgs.list(ops)do
				rgs = {}
				for i=1,total do
					table.insert(rgs,lords[#lords])
					table.remove(lords,#lords)
				end
				heros[p:objectName()] = room:askForGeneral(p,table.concat(rgs,"+"))
			end
           	for _,p in sgs.list(ops)do
				room:changeHero(p,heros[p:objectName()],true,false,false,false)
			end
		elseif event==sgs.GameOver
		and room:getTag("god_exam"):toBool() then
			local winner = data:toString():split("+")
			local owner = room:getOwner()
			if table.contains(winner,owner:objectName())
			or table.contains(winner,owner:getRole()) then
				god_examWinner = god_examWinner+1
			end
		end
		return false
	end,
}
-- god_examScenario:setRule(god_examScenarioRule)--将触发技设置给剧情
-- sgs.Sanguosha:addScenario(god_examScenario)


sgs.LoadTranslationTable{
    ["godexam"] = "神之试炼",

    ["ge_zhuque"] = "朱雀",
    ["#ge_zhuque"] = "陵光神君",
    ["ge_shenyi"] = "神裔",
    [":ge_shenyi"] = "锁定技，若你的武将牌正面朝上，你不能翻面；你的判定区里的牌判定结果反转。",
    ["$ge_shenyi1"] = "",
    ["$ge_shenyi2"] = "",
    ["ge_fentian"] = "焚天",
    [":ge_fentian"] = "出牌阶段限一次，你可以选择一名其他角色，对其造成1点火焰伤害，然后若其以此法死亡，你此阶段可以再发动此技能。",
    [":ge_fentian_sp"] = "出牌阶段限一次，你可以选择距离1以内的一名其他角色，对其造成1点火焰伤害，然后若其以此法死亡，你此阶段可以再发动此技能。",
    ["$ge_fentian1"] = "",
    ["$ge_fentian2"] = "",
    ["~ge_zhuque"] = "",

    ["ge_zhurong"] = "火神祝融",
    ["#ge_zhurong"] = "祈光夏官",
    ["ge_xingxia"] = "行夏",
    [":ge_xingxia"] = "锁定技，每两轮限一次，出牌阶段开始时，你选择一名己方其他角色，对其造成2点火焰伤害，然后令所有敌方角色各选择一项：1.弃置一张红色手牌；2.受到由你造成的1点火焰伤害。",
    [":ge_xingxia_sp"] = "每两轮限一次，出牌阶段开始时，你可以选择一名其他角色，对其造成2点火焰伤害，然后其以外的所有其他角色各选择一项：1.弃置一张红色手牌；2.受到由你造成的1点火焰伤害。",
    ["$ge_xingxia1"] = "",
    ["$ge_xingxia2"] = "",
    ["~ge_zhurong"] = "",

    ["ge_yanling"] = "焰灵",
    ["#ge_yanling"] = "亘古业火",
    ["ge_huihuo"] = "回火",
    [":ge_huihuo"] = "锁定技，当你死亡后，你对所有敌方角色各造成3点火焰伤害；你使用【杀】的次数上限+1。",
    [":ge_huihuo_sp"] = "当你死亡后，你选择一名角色，对其造成3点火焰伤害；你使用【杀】的次数上限+1。",
    ["$ge_huihuo1"] = "",
    ["$ge_huihuo2"] = "",
    ["ge_furan"] = "复燃",
    [":ge_furan"] = "锁定技，敌方角色在你处于濒死状态时选择是否将一张红色牌当【桃】使用。",
    [":ge_furan_sp"] = "其他角色在你处于濒死状态时可以将一张牌当【桃】使用",
    ["ge_furan_use"] = "复燃",
    [":ge_furan_use"] = "若敌方“焰灵”处于濒死状态，你可以将一张红色牌当【桃】使用。",
    ["$ge_furan1"] = "",
    ["$ge_furan2"] = "",
    ["~ge_yanling"] = "",

    ["ge_yandi"] = "炎帝",
    ["#ge_yandi"] = "南方天帝",
    ["ge_shenen"] = "神恩",
    [":ge_shenen"] = "锁定技，己方角色使用牌无距离限制；敌方角色的额定摸牌数和手牌上限+1。",
    ["$ge_shenen1"] = "",
    ["$ge_shenen2"] = "",
    ["ge_chiyi"] = "赤仪",
    [":ge_chiyi"] = "锁定技，当敌方角色受到伤害时，若轮数不小于4，伤害值+1；第七轮开始时，你对所有其他角色各造成1点火焰伤害；第十轮开始时，焰灵死亡。",
    [":ge_chiyi_sp"] = "锁定技，当你造成伤害时，若轮数不小于3，伤害值+1；第六轮开始时，你对所有其他角色各造成1点火焰伤害；第九轮开始时，你死亡。",
    ["$ge_chiyi1"] = "",
    ["$ge_chiyi2"] = "",
    ["~ge_yandi"] = "",

    ["ge_qinglong"] = "青龙",
    ["#ge_qinglong"] = "孟章神君",
    ["ge_tengyun"] = "腾云",
    [":ge_tengyun"] = "锁定技，当你受到伤害后，其他角色于此回合内对你使用牌无效。",
    ["$ge_tengyun1"] = "",
    ["$ge_tengyun2"] = "",
    ["~ge_qinglong"] = "",

    ["ge_goumang"] = "木神勾芒",
    ["#ge_goumang"] = "执柳春官",
    ["ge_buchun"] = "布春",
    [":ge_buchun"] = "锁定技，每两轮限一次，准备阶段开始时，若：有已阵亡的己方角色，你令这些角色复活，各将体力值回复至1点，将手牌补至体力上限；没有已阵亡的己方角色，你选择一名敌方角色，其失去2点体力。",
    [":ge_buchun_sp"] = "每两轮限一次，准备阶段开始时，你可以失去1点体力并选择一名角色，若其：存活，其失去2点体力；阵亡，其复活，将体力值回复至1点，将手牌补至两张。",
    ["$ge_buchun1"] = "",
    ["$ge_buchun2"] = "",
    ["~ge_goumang"] = "",

    ["ge_shujing"] = "树精",
    ["#ge_shujing"] = "惑心甜毒",
    ["ge_cuidu"] = "淬毒",
    [":ge_cuidu"] = "锁定技，当你对敌方角色造成伤害后，其获得“中毒”，然后木神勾芒摸一张牌。",
    [":ge_cuidu_sp"] = "锁定技，当你对其他角色造成伤害后，你选择一名角色，其摸一张牌，然后其获得“中毒”。",
    ["$ge_cuidu1"] = "",
    ["$ge_cuidu2"] = "",
    ["ge_zhongdu"] = "中毒",
    [":ge_zhongdu"] = "锁定技，准备阶段开始时，你判定，若结果：为♦，你失去1点体力；不为♦，你失去此技能。",
    ["$ge_zhongdu1"] = "",
    ["$ge_zhongdu2"] = "",
    ["~ge_shujing"] = "",

    ["ge_taihao"] = "太昊",
    ["#ge_taihao"] = "东方天帝",
    ["ge_qingyi"] = "青仪",
    [":ge_qingyi"] = "锁定技，第三轮开始时，所有己方角色各加1点体力上限，回复1点体力；第六轮开始时，所有敌方角色各失去1点体力；第九轮开始时，己方阵亡角色复活，然后各将体力值回复至上限，摸四张牌，然后所有己方角色获得“青囊”。",
    [":ge_qingyi_sp"] = "锁定技，第三轮开始时，你加1点体力上限，回复1点体力；第六轮开始时，所有其他角色各失去1点体力；第九轮开始时，若你已死亡，你复活，然后将体力值回复至上限，摸四张牌，获得“青囊”。",
    ["$ge_qingyi1"] = "",
    ["$ge_qingyi2"] = "",
    ["~ge_taihao"] = "",

    ["ge_baihu"] = "白虎",
    ["#ge_baihu"] = "监兵神君",
    ["ge_kuangxiao"] = "狂啸",
    [":ge_kuangxiao"] = "锁定技，你于回合内使用的【杀】无距离限制且指定所有敌方角色为目标。",

    ["ge_rushou"] = "金神蓐收",
    ["#ge_rushou"] = "挥旌秋官",
    ["xingqiu"] = "刑秋",
    [":xingqiu"] = "锁定技，每两轮限一次，出牌阶段开始时，你横置所有敌方角色的武将牌，然后令【明刑柱】获得技能“殛顶”。",
    ["jiding"] = "殛顶",
    [":jiding"] = "锁定技，当敌方角色对其他己方角色造成伤害后，你视为对来源使用一张雷【杀】；此【杀】造成伤害后你令【金神蓐收】回复1点体力，然后你失去此技能。",

    ["ge_zhu"] = "明刑柱",
    ["#ge_zhu"] = "执矩一樑",
    ["ge_qingzhu"] = "擎柱",
    [":ge_qingzhu"] = "锁定技，若你没有“殛顶”，你不能于出牌阶段使用【杀】；你跳过弃牌阶段。",
    ["ge_jiazu"] = "枷足",
    [":ge_jiazu"] = "锁定技，准备阶段，若你上家或下家为敌方，你弃置其装备区里的坐骑牌。",

    ["ge_shaohao"] = "少昊",
    ["#ge_shaohao"] = "西方天帝",
    ["ge_baiyi"] = "白仪",
    [":ge_baiyi"] = "锁定技，若游戏轮次小于3，敌方角色摸牌阶段摸牌数-1；第五轮开始时，你令所有敌方角色弃置两张牌；若游戏轮数小于7，防止己方角色受到的雷电伤害。",

    ["ge_xuanwu"] = "玄武",
    ["#ge_xuanwu"] = "执明神君",
    ["ge_lingqu"] = "灵躯",
    [":ge_lingqu"] = "锁定技，当你受到伤害后，你摸一张牌；防止你受到大于1点的伤害。",

    ["ge_gonggong"] = "水神共工",
    ["#ge_gonggong"] = "振涛冬官",
    ["ge_juehong"] = "决洪",
    [":ge_juehong"] = "锁定技，准备阶段开始时，你令敌方各弃置其装备区里所有牌，若其装备区没有牌，则改为你弃置其一张手牌。",

    ["ge_xuanming"] = "水神玄冥",
    ["#ge_xuanming"] = "卜兆冬官",
    ["ge_zirun"] = "滋润",
    [":ge_zirun"] = "锁定技，准备阶段开始时，你令所有角色各摸一张牌，若其装备区有牌，则改为其摸两张牌。",

    ["ge_chuanxi"] = "歂顼",
    ["#ge_chuanxi"] = "北方天帝",
    ["ge_zaoyi"] = "皂仪",
    [":ge_zaoyi"] = "锁定技，若【水神玄冥】存活，则你不能成为敌方角色使用锦囊牌的目标；若【水神共工】存活，则你不能成为敌方角色使用基本牌的目标；当这两名角色均死亡后，你摸4张牌，然后从你下回合开始的回合开始时，你令体力值最小的其中一名敌方角色失去所有体力。",
    ["ge_zaoyi0"] = "皂仪：请选择一名体力值最小的敌方角色令其失去所有体力",

	["ge_honghuang"] = "洪荒之力",
	[":ge_honghuang"] = "锦囊牌·单目标锦囊<br/><b>时机</b>：出牌阶段，对一名其他角色使用<br/><b>效果</b>：若目标势力为神，则你获得其一张牌且其技能“神裔”无效直到其下家回合开始；否则目标将武将牌翻面。",
	["ge_honghuangbf"] = "神裔无效",
}

extension_yanluo = sgs.Package("~BossYanluo")

yl_qinguang = sgs.General(extension_yanluo, "yl_qinguang", "qun", 3, true, true)
yl_panguan = sgs.CreateProhibitSkill{
	name = "yl_panguan",
	is_prohibited = function(self,from,to,card)
		return card:isKindOf("DelayedTrick")
		and to:hasSkill(self)
	end
}
yl_qinguang:addSkill(yl_panguan)
yl_juhun = sgs.CreateTriggerSkill{
	name = "yl_juhun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseProceeding},
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()==sgs.Player_Finish then
			room:sendCompulsoryTriggerLog(player, self)
			local tos = room:getOtherPlayers(player)
			tos = tos:at(math.random(0,tos:length()-1))
			room:doAnimate(1,player:objectName(),tos:objectName())
			if math.random(0,1)<1 then tos:turnOver()
			else room:setPlayerChained(tos,true) end
		end
		return false
	end,
}
yl_qinguang:addSkill(yl_juhun)
yl_wangxiang = sgs.CreateTriggerSkill{
	name = "yl_wangxiang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	can_trigger = function(self, target)
		return target and target:hasSkill(self)
	end,
	on_trigger = function(self,event,player,data,room)
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
			room:sendCompulsoryTriggerLog(player, self)
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				room:doAnimate(1,player:objectName(),p:objectName())
			end
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				p:throwAllEquips(self:objectName())
			end
		end
		return false
	end
}
yl_qinguang:addSkill(yl_wangxiang)

yl_chujiang = sgs.General(extension_yanluo, "yl_chujiang", "qun", 4, true, true)
yl_chujiang:addSkill("weimu")
yl_chujiang:addSkill("fankui")
yl_bingfeng = sgs.CreateTriggerSkill{
	name = "yl_bingfeng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	can_trigger = function(self, target)
		return target and target:hasSkill(self)
	end,
	on_trigger = function(self,event,player,data,room)
		local death = data:toDeath()
		if death.who == player and death.damage and death.damage.from 
		and death.damage.from ~= player and death.damage.from:faceUp() then
			room:sendCompulsoryTriggerLog(player, self)
			room:doAnimate(1,player:objectName(),death.damage.from:objectName())
			death.damage.from:turnOver()
		end
		return false
	end
}
yl_chujiang:addSkill(yl_bingfeng)

yl_songdi = sgs.General(extension_yanluo, "yl_songdi", "qun", 4, true, true)
yl_heisheng = sgs.CreateTriggerSkill{
	name = "yl_heisheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	can_trigger = function(self, target)
		return target and target:hasSkill(self)
	end,
	on_trigger = function(self,event,player,data,room)
		local death = data:toDeath()
		if death.who == player then
			room:sendCompulsoryTriggerLog(player, self)
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				room:doAnimate(1,player:objectName(),p:objectName())
			end
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerChained(p,true)
			end
		end
		return false
	end
}
yl_songdi:addSkill(yl_heisheng)
yl_shengfu = sgs.CreateTriggerSkill{
	name = "yl_shengfu",
	events = {sgs.EventPhaseChanging},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event==sgs.EventPhaseChanging
		then
    		local change = data:toPhaseChange()
            if change.to==sgs.Player_NotActive then
				local hs = {}
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					for _, e in sgs.qlist(p:getEquips()) do
						if e:isKindOf("Horse")
						and player:canDiscard(p,e:getId())
						then table.insert(hs,e) end
					end
				end
				if #hs<1 then return end
				hs = hs[math.random(1,#hs)]
				local to = room:getCardOwner(hs:getId())
				room:sendCompulsoryTriggerLog(player, self)
				room:doAnimate(1,player:objectName(),to:objectName())
				room:throwCard(hs,to,player)
			end
			return false
		end
	end,
}
yl_songdi:addSkill(yl_shengfu)
yl_songdi:addSkill("nosenyuan")

yl_wuguan = sgs.General(extension_yanluo, "yl_wuguan", "qun", 4, true, true)
yl_zhiwang = sgs.CreateTriggerSkill{
	name = "yl_zhiwang",
	events = {sgs.CardsMoveOneTime}, 
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data,room)
		if room:getTag("FirstRound"):toBool() then return end
		local move = data:toMoveOneTime()
		if move.to_place==sgs.Player_PlaceHand
		and move.to:objectName()~=player:objectName()
		and move.to:getPhase()~=sgs.Player_Draw
		and player:canDiscard(move.to,"h") then
			room:sendCompulsoryTriggerLog(player, self)
			room:doAnimate(1,player:objectName(),move.to:objectName())
			local to = BeMan(room,move.to)
			local id = to:getRandomHandCardId()
			room:throwCard(id,to,player)
		end
		return false
	end
}
yl_wuguan:addSkill(yl_zhiwang)
yl_gongzheng = sgs.CreateTriggerSkill{
	name = "yl_gongzheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseProceeding},
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()==sgs.Player_Start
		and player:canDiscard(player,"j") then
			room:sendCompulsoryTriggerLog(player, self)
			local tos = player:getJudgingArea()
			tos = tos:at(math.random(0,tos:length()-1))
			room:throwCard(tos,player)
		end
		return false
	end,
}
yl_wuguan:addSkill(yl_gongzheng)
yl_xuechi = sgs.CreateTriggerSkill{
	name = "yl_xuechi",
	events = {sgs.EventPhaseChanging},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event==sgs.EventPhaseChanging then
    		local change = data:toPhaseChange()
            if change.to==sgs.Player_NotActive then
				room:sendCompulsoryTriggerLog(player, self)
				local tos = room:getOtherPlayers(player)
				tos = tos:at(math.random(0,tos:length()-1))
				room:doAnimate(1,player:objectName(),tos:objectName())
				room:loseHp(tos,2,true,player,self:objectName())
			end
			return false
		end
	end,
}
yl_wuguan:addSkill(yl_xuechi)

yl_yanluo = sgs.General(extension_yanluo, "yl_yanluo", "qun", 4, true, true)
yl_tiemian = sgs.CreateViewAsEquipSkill{
    name = "yl_tiemian",
	view_as_equip = function(self,target)
		if target:getArmor()==nil then
	    	return "renwang_shield"
		end
	end 
}
yl_yanluo:addSkill(yl_tiemian)
yl_zhadao = sgs.CreateTriggerSkill{
	name = "yl_zhadao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self,event,player,data,room)
   		if event==sgs.TargetConfirmed then
	       	local use,can = data:toCardUse(),true
	       	if use.card:isKindOf("Slash")
			and use.from==player then
	           	for _,to in sgs.list(use.to)do
			   		to:addQinggangTag(use.card)
    	           	if to:hasArmorEffect(nil)
					and can then
						can = false
						room:sendCompulsoryTriggerLog(player,self)
					end
	           	end
	       	end
		end
	end
}
yl_yanluo:addSkill(yl_zhadao)
yl_zhuxin = sgs.CreateTriggerSkill{
	name = "yl_zhuxin",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	can_trigger = function(self, target)
		return target and target:hasSkill(self)
	end,
	on_trigger = function(self,event,player,data,room)
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
			room:sendCompulsoryTriggerLog(player, self)
			local tos = sgs.SPlayerList()
			local n = 999
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHp()<=n then n = p:getHp() end
			end
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHp()<=n then tos:append(p) end
			end
			tos = PlayerChosen(self,player,tos)
			room:damage(sgs.DamageStruct(self:objectName(), nil, tos, 2))
		end
		return false
	end
}
yl_yanluo:addSkill(yl_zhuxin)

yl_biancheng = sgs.General(extension_yanluo, "yl_biancheng", "qun", 5, true, true)
yl_leizhou = sgs.CreateTriggerSkill{
	name = "yl_leizhou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseProceeding},
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()==sgs.Player_Start
		then
			room:sendCompulsoryTriggerLog(player, self)
			local tos = room:getOtherPlayers(player)
			tos = tos:at(math.random(0,tos:length()-1))
			room:doAnimate(1,player:objectName(),tos:objectName())
			room:damage(sgs.DamageStruct(self:objectName(), player, tos, 1, sgs.DamageStruct_Thunder))
		end
		return false
	end,
}
yl_biancheng:addSkill(yl_leizhou)
yl_leifu = sgs.CreateTriggerSkill{
	name = "yl_leifu",
	events = {sgs.EventPhaseChanging},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event==sgs.EventPhaseChanging then
    		local change = data:toPhaseChange()
            if change.to==sgs.Player_NotActive then
				room:sendCompulsoryTriggerLog(player, self)
				local tos = room:getOtherPlayers(player)
				tos = tos:at(math.random(0,tos:length()-1))
				room:doAnimate(1,player:objectName(),tos:objectName())
				room:setPlayerChained(tos,true)
			end
		end
		return false
	end,
}
yl_biancheng:addSkill(yl_leifu)
yl_leizhu = sgs.CreateTriggerSkill{
	name = "yl_leizhu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	can_trigger = function(self, target)
		return target and target:hasSkill(self)
	end,
	on_trigger = function(self,event,player,data,room)
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
			room:sendCompulsoryTriggerLog(player, self)
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				room:doAnimate(1,player:objectName(),p:objectName())
			end
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:damage(sgs.DamageStruct(self:objectName(), player, p, 1, sgs.DamageStruct_Thunder))
			end
		end
		return false
	end
}
yl_biancheng:addSkill(yl_leizhu)

yl_taishan = sgs.General(extension_yanluo, "yl_taishan", "qun", 5, true, true)
yl_fudu = sgs.CreateTriggerSkill{
	name = "yl_fudu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		local use = data:toCardUse()
		if use.card:isKindOf("Peach") then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:isAlive() and p~=use.from then
					local tos = room:getOtherPlayers(p)
					tos:removeOne(use.from)
					if tos:isEmpty() then continue end
					room:sendCompulsoryTriggerLog(player, self)
					tos = tos:at(math.random(0,tos:length()-1))
					room:doAnimate(1,p:objectName(),tos:objectName())
					room:loseHp(tos,1,true,p,self:objectName())
				end
			end
		end
		return false
	end
}
yl_taishan:addSkill(yl_fudu)
yl_kujiu = sgs.CreateTriggerSkill{
	name = "yl_kujiu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseProceeding},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()==sgs.Player_Start
		then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:isAlive() and p~=player then
					room:sendCompulsoryTriggerLog(player, self)
					room:doAnimate(1,p:objectName(),player:objectName())
					room:loseHp(player,1,true,p,self:objectName())
					local dc = dummyCard("analeptic")
					dc:setSkillName("_"..self:objectName())
					if player:isAlive() and player:canUse(dc) then
						room:useCard(sgs.CardUseStruct(dc,player))
					end
				end
			end
		end
		return false
	end,
}
yl_taishan:addSkill(yl_kujiu)
yl_renao = sgs.CreateTriggerSkill{
	name = "yl_renao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	can_trigger = function(self, target)
		return target and target:hasSkill(self)
	end,
	on_trigger = function(self,event,player,data,room)
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
			local tos = room:getOtherPlayers(player)
			room:sendCompulsoryTriggerLog(player, self)
			tos = tos:at(math.random(0,tos:length()-1))
			room:doAnimate(1,player:objectName(),tos:objectName())
			room:damage(sgs.DamageStruct(self:objectName(), nil, tos, 3, sgs.DamageStruct_Fire))
		end
		return false
	end
}
yl_taishan:addSkill(yl_renao)

yl_dushi = sgs.General(extension_yanluo, "yl_dushi", "qun", 5, true, true)
yl_remen = sgs.CreateTriggerSkill{
	name = "yl_remen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected},
	on_trigger = function(self,event,player,data,room)
		if player:hasEquipArea() and player:getArmor()==nil then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("SavageAssault")
			or effect.card:isKindOf("ArcheryAttack")
			or effect.card:objectName()=="slash" then
				room:sendCompulsoryTriggerLog(player, self)
				effect.nullified = true
				data:setValue(effect)
			end
		end
		return false
	end,
}
yl_dushi:addSkill(yl_remen)
yl_zhifen = sgs.CreateTriggerSkill{
	name = "yl_zhifen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseProceeding},
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()==sgs.Player_Start then
			room:sendCompulsoryTriggerLog(player, self)
			local tos = room:getOtherPlayers(player)
			tos = tos:at(math.random(0,tos:length()-1))
			room:doAnimate(1,player:objectName(),tos:objectName())
			if tos:getHandcardNum()>0 then
				local id = room:askForCardChosen(player,tos,"h",self:objectName())
				room:obtainCard(player,id,false)
			end
			room:damage(sgs.DamageStruct(self:objectName(), player, tos, 1, sgs.DamageStruct_Fire))
		end
		return false
	end,
}
yl_dushi:addSkill(yl_zhifen)
yl_huoxing = sgs.CreateTriggerSkill{
	name = "yl_huoxing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	can_trigger = function(self, target)
		return target and target:hasSkill(self)
	end,
	on_trigger = function(self,event,player,data,room)
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
			room:sendCompulsoryTriggerLog(player, self)
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				room:doAnimate(1,player:objectName(),p:objectName())
			end
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:damage(sgs.DamageStruct(self:objectName(), player, p, 1, sgs.DamageStruct_Fire))
			end
		end
		return false
	end
}
yl_dushi:addSkill(yl_huoxing)

yl_pingdeng = sgs.General(extension_yanluo, "yl_pingdeng", "qun", 5, true, true)
yl_suozu = sgs.CreateTriggerSkill{
	name = "yl_suozu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseProceeding},
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()==sgs.Player_Start then
			room:sendCompulsoryTriggerLog(player, self)
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				room:doAnimate(1,player:objectName(),p:objectName())
			end
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				room:setPlayerChained(p,true)
			end
		end
		return false
	end
}
yl_pingdeng:addSkill(yl_suozu)
yl_erbi = sgs.CreateTriggerSkill{
	name = "yl_erbi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self,event,player,data,room)
		local damage = data:toDamage()
		if damage.from and damage.from ~= player then
			room:sendCompulsoryTriggerLog(player, self)
			room:doAnimate(1,player:objectName(),damage.from:objectName())
			local ds = {sgs.DamageStruct_Fire,sgs.DamageStruct_Thunder,sgs.DamageStruct_Ice,sgs.DamageStruct_God}
			room:damage(sgs.DamageStruct(self:objectName(), player, damage.from, 1, ds[math.random(1,#ds)]))
		end
		return false
	end
}
yl_pingdeng:addSkill(yl_erbi)
yl_pingdengSkill = sgs.CreateTriggerSkill{
	name = "yl_pingdengSkill",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	can_trigger = function(self, target)
		return target and target:hasSkill(self)
	end,
	on_trigger = function(self,event,player,data,room)
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
			room:sendCompulsoryTriggerLog(player, self)
			for i=2,1,-1 do
				local n = 0
				local tos = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getHp()>n then n = p:getHp() end
				end
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getHp()>=n then tos:append(p) end
				end
				tos = PlayerChosen(self,player,tos)
				local ds = {sgs.DamageStruct_Fire,sgs.DamageStruct_Thunder,sgs.DamageStruct_Ice,sgs.DamageStruct_God}
				room:damage(sgs.DamageStruct(self:objectName(), player, tos, i, ds[math.random(1,#ds)]))
			end
		end
		return false
	end
}
yl_pingdeng:addSkill(yl_pingdengSkill)

yl_zhuanlun = sgs.General(extension_yanluo, "yl_zhuanlun", "qun", 5, true, true)
yl_zhuanlun:addSkill("bossmodao")
yl_lunhui = sgs.CreateTriggerSkill{
	name = "yl_lunhui",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseProceeding},
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()==sgs.Player_Start
		and player:getHp()<=2 then
			local n = 0
			local tos = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHp()>n then n = p:getHp() end
			end
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHp()>2 and p:getHp()>=n then tos:append(p) end
			end
			if tos:isEmpty() then return end
			room:sendCompulsoryTriggerLog(player, self)
			tos = PlayerChosen(self,player,tos)
			local m = player:getHp()
			n = tos:getHp()
			room:setPlayerProperty(player,"hp",ToData(n))
			room:setPlayerProperty(tos,"hp",ToData(m))
		end
		return false
	end
}
yl_zhuanlun:addSkill(yl_lunhui)
yl_wangsheng = sgs.CreateTriggerSkill{
	name = "yl_wangsheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()==sgs.Player_Play then
			local dcs = {}
			local dc = dummyCard("savage_assault")
			dc:setSkillName("_"..self:objectName())
			if player:canUse(dc) then table.insert(dcs,dc) end
			dc = dummyCard("archery_attack")
			dc:setSkillName("_"..self:objectName())
			if player:canUse(dc) then table.insert(dcs,dc) end
			if #dcs<1 then return end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:useCard(sgs.CardUseStruct(dcs[math.random(1,#dcs)],player))
		end
		return false
	end
}
yl_zhuanlun:addSkill(yl_wangsheng)
yl_fanshi = sgs.CreateTriggerSkill{
	name = "yl_fanshi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged},
	on_trigger = function(self,event,player,data,room)
		local damage = data:toDamage()
		player:addMark("yl_fanshi-Clear")
		if player:getMark("yl_fanshi-Clear")>1 then
			room:sendCompulsoryTriggerLog(player, self)
			local tos = room:getOtherPlayers(player)
			tos = tos:at(math.random(0,tos:length()-1))
			room:doAnimate(1,player:objectName(),tos:objectName())
			room:damage(sgs.DamageStruct(self:objectName(), player, tos))
		end
		return false
	end
}
yl_zhuanlun:addSkill(yl_fanshi)

yl_mengpo = sgs.General(extension_yanluo, "yl_mengpo", "qun", 3, false, true)

yl_shiyou = sgs.CreateTriggerSkill{
	name = "yl_shiyou",
	events = {sgs.BeforeCardsMove}, 
	--frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data,room)
		local move = data:toMoveOneTime()
		if move.to_place==sgs.Player_DiscardPile and move.from
		and move.from:objectName()~=player:objectName() and move.from:getPhase()==sgs.Player_Discard
		and bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_DISCARD
		and player:askForSkillInvoke(self,data) then
			local ids = sgs.IntList()
			for _,id in sgs.list(move.card_ids)do
				ids:append(id)
			end
			local dummy = dummyCard()
			room:fillAG(move.card_ids,player)
			while ids:length()>0 do
				local cid = room:askForAG(player,ids,true,self:objectName())
				if cid==-1 then break end
				dummy:addSubcard(cid)
				room:takeAG(player,cid,false)
				cid = sgs.Sanguosha:getCard(cid)
				for _,id in sgs.list(move.card_ids)do
					local c = sgs.Sanguosha:getCard(id)
					if c:getSuit()==cid:getSuit() then
						if c~=cid then
							room:takeAG(nil,id,false)
						end
						ids:removeOne(id)
					end
				end
			end
			room:clearAG(player)
			move:removeCardIds(dummy:getSubcards())
			data:setValue(move)
			player:obtainCard(dummy)
		end
		return false
	end
}
yl_mengpo:addSkill(yl_shiyou)
yl_wanghun = sgs.CreateTriggerSkill{
	name = "yl_wanghun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	can_trigger = function(self, target)
		return target and target:hasSkill(self)
	end,
	on_trigger = function(self,event,player,data,room)
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
			room:sendCompulsoryTriggerLog(player, self)
			local tos = sgs.SPlayerList()
			for _,p in sgs.qlist(RandomList(room:getOtherPlayers(player))) do
				if tos:length()<2 and not player:isYourFriend(p) then tos:append(p) end
			end
			for _,p in sgs.qlist(tos) do
				room:doAnimate(1,player:objectName(),p:objectName())
				for _,s in sgs.qlist(RandomList(p:getVisibleSkillList())) do
					if s:isAttachedLordSkill() or s:getFrequency(p)==sgs.Skill_Wake then continue end
					p:setTag("yl_wanghunSkill",sgs.QVariant(s:objectName()))
					room:setPlayerMark(p,"&yl_wanghun+:+"..s:objectName(),1)
					room:detachSkillFromPlayer(p,s:objectName())
					break
				end
			end
			local dc = dummyCard()
			for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
				if dc:subcardsLength()<2 and sgs.Sanguosha:getCard(id):isKindOf("Huihun")
				then dc:addSubcard(id) end
			end
			room:shuffleIntoDrawPile(player,dc:getSubcards(),self:objectName(),true)
		end
		return false
	end
}
yl_mengpo:addSkill(yl_wanghun)
yl_wangshi = sgs.CreateTriggerSkill{
	name = "yl_wangshi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseChanging then
    		local change = data:toPhaseChange()
            if change.from==sgs.Player_NotActive then
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if not p:isYourFriend(player) and p:hasSkill(self) then
						room:sendCompulsoryTriggerLog(p, self)
						local str = {"BasicCard","TrickCard","EquipCard"}
						str = str[math.random(1,3)]
						room:setPlayerCardLimitation(player,"use,response",str,true)
						room:setPlayerMark(player,"&yl_wangshi+:+"..str.."-Clear",1)
					end
				end
			end
		end
		return false
	end
}
yl_mengpo:addSkill(yl_wangshi)

yl_dizang = sgs.General(extension_yanluo, "yl_dizang", "qun", 8, true, true)
yl_bufo = sgs.CreateTriggerSkill{
	name = "yl_bufo",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging,sgs.DamageInflicted},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseChanging then
    		local change = data:toPhaseChange()
            if change.from==sgs.Player_NotActive then
				local tos = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:distanceTo(p)==1 then
						room:doAnimate(1,player:objectName(),p:objectName())
						tos:append(p)
					end
				end
				if tos:length()>0 then
					room:sendCompulsoryTriggerLog(player, self)
					for _,p in sgs.qlist(tos) do
						room:damage(sgs.DamageStruct(self:objectName(),player,p,1,sgs.DamageStruct_Fire))
					end
				end
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.damage >= 2 then
				room:sendCompulsoryTriggerLog(player, self)
				return player:damageRevises(data,-1)
			end
		end
		return false
	end
}
yl_dizang:addSkill(yl_bufo)
yl_wuliang = sgs.CreateTriggerSkill{
	name = "yl_wuliang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging,sgs.EventPhaseStart,sgs.DrawNCards},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseChanging then
    		local change = data:toPhaseChange()
            if change.from==sgs.Player_NotActive and player:getHp()<3 then
				room:sendCompulsoryTriggerLog(player, self)
				room:recover(player,sgs.RecoverStruct(self:objectName(),player,3-player:getHp()))
			end
		elseif event==sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason~="InitialHandCards" or player:getTag("yl_wuliangIHC"):toBool() then return end
			player:setTag("yl_wuliangIHC",sgs.QVariant(true))
			room:sendCompulsoryTriggerLog(player, self)
			draw.num = draw.num+3
			data:setValue(draw)
		elseif event == sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Finish then
				room:sendCompulsoryTriggerLog(player, self)
				player:drawCards(2,self:objectName())
			end
		end
		return false
	end
}
yl_dizang:addSkill(yl_wuliang)
yl_dayuan = sgs.CreateTriggerSkill{
	name = "yl_dayuan",
	events = {sgs.AskForRetrial},
	priority = {0},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.AskForRetrial then
    		local judge = data:toJudge()
            if player:askForSkillInvoke(self,data) then
				local suit = room:askForSuit(player,self:objectName())
				local n = room:askForChoice(player,self:objectName(),"1+2+3+4+5+6+7+8+9+10+11+12+13",data)
				local wc = sgs.Sanguosha:getWrappedCard(judge.card:getEffectiveId())
				wc:setSuit(suit)
				wc:setNumber(n)
				room:broadcastUpdateCard(room:getPlayers(),wc:getEffectiveId(),wc)
                judge:updateResult()
			end
		end
		return false
	end
}
yl_dizang:addSkill(yl_dayuan)
yl_ditingCard = sgs.CreateSkillCard{
	name = "yl_ditingCard",
--	will_throw = false,
	target_fixed = true,
	about_to_use = function(self,room,use)
		UseCardRecast(use.from,self,self:getSkillName())
	end,
}
yl_ditingvs = sgs.CreateViewAsSkill{
	name = "yl_diting",
	n = 1,
	view_filter = function(self,selected,to_select)
		return to_select:isKindOf("Horse")
		and not sgs.Self:isCardLimited(to_select,sgs.Card_MethodRecast)
	end,
	view_as = function(self,cards)
		if #cards<1 then return end
		local new_card = yl_ditingCard:clone()
		for _,c in ipairs(cards) do
			new_card:addSubcard(c)
		end
		return new_card
	end,
	enabled_at_play = function(self,player)
		return player:getCardCount()>0
	end,
}
yl_diting = sgs.CreateTriggerSkill{
	name = "yl_diting",
	frequency = sgs.Skill_Compulsory,
	view_as_skill = yl_ditingvs,
	waked_skills = "#yl_ditingbf",
	events = {sgs.EventAcquireSkill,sgs.GameStart,sgs.BeforeCardsMove},
	on_trigger = function(self,event,player,data,room)
		local ids = sgs.IntList()
		if player:hasDefensiveHorseArea() then
			ids:append(2)
		end
		if player:hasOffensiveHorseArea() then
			ids:append(3)
		end
		if ids:length()>0 then
			player:throwEquipArea(ids)
		end
		return false
	end
}
yl_dizang:addSkill(yl_diting)
yl_ditingbf = sgs.CreateDistanceSkill{
	name = "#yl_ditingbf",
	correct_func = function(self,from,to)
		local n = 0
		if from:hasSkill("yl_diting")
		then n = n-1 end
		if to:hasSkill("yl_diting")
		then n = n+1 end
		return n
	end
}
yl_dizang:addSkill(yl_ditingbf)

yl_huihun = sgs.CreateTrickCard{
	name = "_yl_huihun",
	class_name = "Huihun",
	subclass = sgs.LuaTrickCard_TypeGlobalEffect,
	target_fixed = true,
	can_recast = false,
	is_cancelable = true,
	--damage_card = true,
    available = function(self,player)
    	for _,to in sgs.list(player:getAliveSiblings(true))do
			if CanToCard(self,player,to) then
				return self:cardIsAvailable(player)
			end
		end
    end,
	on_use = function(self,room,source,targets)
		local use = room:getTag("UseHistory"..self:toString()):toCardUse()
		for _,to in sgs.list(targets)do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = #targets>1
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
			if to:getTag("yl_wanghunSkill"):toString()~="" then room:cardEffect(effect)
			else room:setEmotion(to,"skill_nullify") end
        end
	end,
	on_effect = function(self,effect)
		local room = effect.to:getRoom()
		local sk = effect.to:getTag("yl_wanghunSkill"):toString()
		room:acquireSkill(effect.to,sk)
		room:setPlayerMark(effect.to,"&yl_wanghun+:+"..sk,0)
		effect.to:setTag("yl_wanghunSkill",sgs.QVariant())
		return false
	end,
}
yl_huihun:clone(2,3):setParent(extension_yanluo)
yl_huihun:clone(3,3):setParent(extension_yanluo)

YanluoOnTrigger = sgs.CreateTriggerSkill{
	name = "#YanluoOnTrigger",
	events = {sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Compulsory,
	global = true,
	can_trigger = function(self,target)
		return target and target:isAlive()
		and not table.contains(sgs.Sanguosha:getBanPackages(),"BossYanluo")
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
            if move.to_place==sgs.Player_DiscardPile and move.reason.m_reason==sgs.CardMoveReason_S_REASON_USE then
				for _,id in sgs.list(move.card_ids)do
					if sgs.Sanguosha:getCard(id):isKindOf("Huihun") and room:getCardPlace(id)==move.to_place then
						room:breakCard(id)
					end
				end
			end
		end
		return false
	end,
}
addToSkills(YanluoOnTrigger)



sgs.LoadTranslationTable{
	["BossYanluo"] = "十殿阎罗",
	["  "] = "  ",
	["  "] = "  ",
	["yl_qinguang"] = "秦广王",
	["#yl_qinguang"] = "一殿阎王",
	["yl_panguan"] = "判官",
	[":yl_panguan"] = "锁定技，你不能成为延时锦囊牌的目标。",
	["yl_juhun"] = "拘魂",
	[":yl_juhun"] = "锁定技，结束阶段，你令随机一名其他角色武将牌翻面或横置。",
	["yl_wangxiang"] = "望乡",
	[":yl_wangxiang"] = "锁定技，当你死亡时，你令所有其他角色弃置其装备区内所的牌。",
	["$yl_panguan1"] = "世俗杂事，吾皆可判。",
	["$yl_juhun1"] = "勾魂索命，拘魄入狱。",
	["$yl_wangxiang1"] = "还是别望他乡了。",
	
	["yl_chujiang"] = "楚江王",
	["#yl_chujiang"] = "二殿阎王",
	["yl_bingfeng"] = "冰封",
	[":yl_bingfeng"] = "锁定技，当你死亡时，若杀死你的角色武将牌正面朝上，你令其翻面。",
	["$weimu3"] = "暗涌掩身，查无踪迹。",
	["$fankui3"] = "伤我，可是要有付出的！",
	["$yl_bingfeng1"] = "接受这寒冰的封冻吧。",

	["yl_songdi"] = "宋帝王",
	["#yl_songdi"] = "三殿阎王",
	["yl_heisheng"] = "黑绳",
	[":yl_heisheng"] = "锁定技，当你死亡时，横置所有场上角色。",
	["yl_shengfu"] = "绳缚",
	[":yl_shengfu"] = "锁定技，回合结束时，随机弃置一张场上其他角色的坐骑牌。",
	["$yl_heisheng1"] = "此绳索，是你无法逃脱的噩梦。",
	["$yl_shengfu1"] = "想跑？痴人说梦！",
	["$nosenyuan5"] = "有恩有惠，有伤有报。",

	["yl_wuguan"] = "五官王",
	["#yl_wuguan"] = "四殿阎王",
	["yl_zhiwang"] = "治妄",
	[":yl_zhiwang"] = "锁定技，其他角色于非摸牌阶段获得手牌时，你随机弃置其一张手牌。",
	["yl_gongzheng"] = "公正",
	[":yl_gongzheng"] = "锁定技，准备阶段，若你的判定区有牌，你随机弃置一张你判定区的牌。",
	["yl_xuechi"] = "血池",
	[":yl_xuechi"] = "锁定技，回合结束时，你令随机一名其他角色失去2点体力。",
	["$yl_zhiwang1"] = "罔顾伦常，必受其害。",
	["$yl_gongzheng1"] = "公正以待，显其威法。",
	["$yl_xuechi1"] = "炼狱血池，需要你的奉献。",
	["~yl_wuguan"] = "我的法阵，居然被破？！",

	["yl_yanluo"] = "阎罗王",
	["#yl_yanluo"] = "五殿阎王",
	["yl_tiemian"] = "铁面",
	[":yl_tiemian"] = "锁定技，若你的防具栏没有牌，你视为装备着【仁王盾】。",
	["yl_zhadao"] = "铡刀",
	[":yl_zhadao"] = "锁定技，你使用【杀】指定目标后，你令其防具无效。",
	["yl_zhuxin"] = "诛心",
	[":yl_zhuxin"] = "锁定技，当你死亡时，你令场上体力值最少的其他角色受到2点伤害。",
	["$yl_tiemian1"] = "铁面无私，刚正不阿。",
	["$yl_zhadao1"] = "铡刀之下，皆是恶徒。",
	["$yl_zhuxin1"] = "诛人心魄，灭人心智。",

	["yl_biancheng"] = "卞城王",
	["#yl_biancheng"] = "六殿阎王",
	["yl_leizhou"] = "雷咒",
	[":yl_leizhou"] = "锁定技，准备阶段，你对随机一名其他角色造成1点雷电伤害。",
	["yl_leifu"] = "雷缚",
	[":yl_leifu"] = "锁定技，回合结束时，随机横置一名其他角色。",
	["yl_leizhu"] = "雷诛",
	[":yl_leizhu"] = "锁定技，当你死亡时，对所有其他角色造成1点雷电伤害。",
	["$yl_leizhou1"] = "想出此阵？不要妄想。",
	["$yl_leifu1"] = "术法诅咒，显灵加威。",
	["$yl_leizhu1"] = "你们皆要受到株连罪行。",

	["yl_taishan"] = "泰山王",
	["#yl_taishan"] = "七殿阎王",
	["yl_fudu"] = "服毒",
	[":yl_fudu"] = "锁定技，其他角色使用【桃】时，你令随机另一名其他角色失去1点体力。",
	["yl_kujiu"] = "苦酒",
	[":yl_kujiu"] = "锁定技，其他角色准备阶段，你令其失去1点体力，然后其视为使用一张【酒】。",
	["yl_renao"] = "热恼",
	[":yl_renao"] = "锁定技，当你死亡时，你令随机一名其他角色受到3点火焰伤害。",
	["$yl_fudu1"] = "服药止血，反被毒伤。",
	["$yl_kujiu1"] = "此酒虽苦，酒效不减。",
	["$yl_renao1"] = "惹恼我的代价，你可承受不起！",

	["yl_dushi"] = "都市王",
	["#yl_dushi"] = "八殿阎王",
	["yl_remen"] = "热闷",
	[":yl_remen"] = "锁定技，若你的装备区没有防具牌，则【南蛮入侵】、【万箭齐发】和普通【杀】对你无效。",
	["yl_zhifen"] = "炙焚",
	[":yl_zhifen"] = "锁定技，准备阶段，你随机选择一名其他角色，获得其一张手牌（没有则不获得），然后对其造成1点火焰伤害。",
	["yl_huoxing"] = "火刑",
	[":yl_huoxing"] = "锁定技，当你死亡时，你对所有其他角色造成1点火焰伤害。",
	["$yl_remen1"] = "这燥热，真让人烦闷！",
	["$yl_zhifen1"] = "焚身燃躯，日炙火烧。",
	["$yl_huoxing1"] = "火海炼狱，普世之刑！",

	["yl_pingdeng"] = "平等王",
	["#yl_pingdeng"] = "九殿阎王",
	["yl_suozu"] = "锁足",
	[":yl_suozu"] = "锁定技，准备阶段，你令所有其他角色横置。",
	["yl_erbi"] = "阿鼻",
	[":yl_erbi"] = "锁定技，当你受到其他角色的伤害时，你对伤害来源造成1点随机属性伤害。",
	["yl_pingdengSkill"] = "平等",
	[":yl_pingdengSkill"] = "锁定技，当你死亡时，你对体力最多的一名其他角色造成2点随机属性伤害，然后再对一名体力值最多的其他角色造成1点随机属性伤害。",
	["$yl_suozu1"] = "困其身，锁其足。",
	["$yl_erbi1"] = "阿鼻地狱，雷火皆来。",
	["$yl_pingdengSkill1"] = "众生平等，你也难逃此法！",

	["yl_zhuanlun"] = "转轮王",
	["#yl_zhuanlun"] = "十殿阎王",
	["yl_lunhui"] = "轮回",
	[":yl_lunhui"] = "锁定技，准备阶段，若你的体力值小于等于2，则你与场上除你以外体力值最高且大于2的角色交换体力值。",
	["yl_wangsheng"] = "往生",
	[":yl_wangsheng"] = "锁定技，出牌阶段开始时，视为你随机使用一张【南蛮入侵】或【万箭齐发】。",
	["yl_fanshi"] = "反噬",
	[":yl_fanshi"] = "锁定技，每个回合你受到第一次伤害后，若你再次受到伤害，则你随机对一名其他角色造成1点伤害。",
	["$yl_lunhui1"] = "轮回反复，此法无解。",
	["$yl_wangsheng1"] = "前生今世，不过皆苦。",
	["$yl_fanshi1"] = "敢忤逆我，你是不知道真正的代价。",
	["$bossmodao1"] = "魔道影阵，助我法力。",
	["~yl_zhuanlun"] = "你居然走到了最后……",

	["yl_mengpo"] = "孟婆",
	["#yl_mengpo"] = "忘川离断",
	["yl_shiyou"] = "拾忧",
	[":yl_shiyou"] = "其他角色于弃牌阶段弃置的牌进入弃牌堆前，你可以选择其中任意张花色各不同的牌获得之",
	["yl_wanghun"] = "忘魂",
	[":yl_wanghun"] = "锁定技，你死亡时，令两名敌方角色各随机失去一个技能（觉醒技除外），并在牌堆中加入2张【回魂】。",
	["yl_wangshi"] = "往事",
	[":yl_wangshi"] = "锁定技，你存活时，敌方角色的回合开始时，令其于本回合内不能使用和打出随机一种类型的牌。",

	["yl_dizang"] = "地藏王",
	["#yl_dizang"] = "度脱六道",
	["yl_bufo"] = "不佛",
	[":yl_bufo"] = "锁定技，你的回合开始时，你对所有距离为1的角色各造成1点火焰伤害；你受到大于1点的伤害时，令此伤害-1。",
	["yl_wuliang"] = "无量",
	[":yl_wuliang"] = "锁定技，你登场时额外摸3张牌；结束阶段开始时，你摸两张牌；你的回合开始时，若你的体力值小于3，则回复至3点。",
	["yl_dayuan"] = "大愿",
	[":yl_dayuan"] = "当一名角色判定牌最终生效前，你可以指定该判定牌的花色和点数。",
	["yl_diting"] = "谛听",
	[":yl_diting"] = "锁定技，你的坐骑区被废除；你计算与其他角色的距离-1，其他角色计算与你的距离+1；你的坐骑牌均用于重铸。<br/>◆<font color=\"red\">点击技能图标进行选择重铸</font>",

	["_yl_huihun"] = "回魂",
	[":_yl_huihun"] = "锦囊牌·全局锦囊<br/><b>时机</b>：出牌阶段，对所有角色使用<br/><b>效果</b>：若目标有因“忘魂”而失去了技能，其获得该技能。<br/><b>额外效果</b>：此牌因使用而进入弃牌堆后销毁之。",
	["  "] = "  ",
	["  "] = "  ",
	["  "] = "  ",
	["  "] = "  ",
	["  "] = "  ",
	["  "] = "  ",
	["  "] = "  ",
	["  "] = "  ",
	["  "] = "  ",
}


return {extension_exam,extension_yanluo}