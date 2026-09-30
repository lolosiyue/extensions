local shixinrumo_yi = sgs.Package("shixinrumo_yi",sgs.Package_GeneralPack)


require("lua.config")
table.insert(config.kingdoms,"demon")
config.kingdom_colors.demon = "#e396aa"

-- 舊版觸發技每個事件目標只觸發一次（即使多人持有同一技能）；
-- V2 以單一 ctx（第一位持有者）對應，避免效果被持有者數量放大。
local function firstSkillOwner(room, skill_name)
	for _, p in sgs.qlist(room:findPlayersBySkillName(skill_name)) do
		return skill_name, p:objectName()
	end
	return false
end

yi_caocao = sgs.General(shixinrumo_yi,"yi_caocao","demon",3)
yikuxin = sgs.CreateTriggerSkillV2{
	name = "yikuxin",
	events = {sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		if event==sgs.Damaged then
			if player:askForSkillInvoke(skill) then
				for i,p in sgs.qlist(room:getOtherPlayers(player))do
					room:doAnimate(1,player:objectName(),p:objectName())
				end
				local dc = dummyCard()
				for i,p in sgs.qlist(room:getOtherPlayers(player))do
					local sc = room:askForExchange(p,skill:objectName(),p:getHandcardNum(),1,false,"yikuxin0",true)
					if sc then
						room:showCard(p,sc:getSubcards())
						dc:addSubcards(sc:getSubcards())
					end
				end
				if player:isDead() then return end
				room:fillAG(dc:getSubcards(),player)
				player:setTag("yikuxinIds",ToData(dc:getSubcards()))
				local tp = room:askForPlayerChosen(player,room:getOtherPlayers(player),skill:objectName(),"yikuxin1",true)
				room:clearAG(player)
				if tp then
					local dc2 = dummyCard()
					for i,id in sgs.qlist(tp:handCards())do
						if dc:getSubcards():contains(id) then continue end
						dc2:addSubcard(id)
					end
					dc = dc2
				end
				player:obtainCard(dc,false)
				if player:isDead() then return end
				if tp then
					room:showCard(player,dc:getSubcards())
					if player:isDead() then return end
				end
				local dc2 = dummyCard()
				for i,id in sgs.qlist(dc:getSubcards())do
					if sgs.Sanguosha:getCard(id):getSuit()==2 then return end
					if player:handCards():contains(id) and player:canDiscard(player,id)
					then dc2:addSubcard(id) end
				end
				room:throwCard(dc2,skill:objectName(),player)
				player:turnOver()
			end
		end
		return false
	end
}
yi_caocao:addSkill(yikuxin)
yisiguCard = sgs.CreateSkillCard{
	name = "yisiguCard",
	filter = function(self,targets,to_select,from)
		return #targets<1 and to_select~=from
	end,
	on_use = function(self,room,source,targets)
		for _,to in sgs.list(targets)do
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|.|1~13"
			judge.reason = "yisigu"
			judge.who = to
			room:judge(judge)
			local skill = "zhichi"
			if judge.card:getNumber()==2 then
				skill = "ganglie"
			elseif judge.card:getNumber()==3 then
				skill = "fankui"
			elseif judge.card:getNumber()==4 then
				skill = "yiji"
			elseif judge.card:getNumber()==5 then
				skill = "oljieming"
			elseif judge.card:getNumber()==6 then
				skill = "fangzhu"
			elseif judge.card:getNumber()==7 then
				skill = "sibei"
			elseif judge.card:getNumber()==8 then
				skill = "chengxiang"
			elseif judge.card:getNumber()==9 then
				skill = "zhiyu"
			elseif judge.card:getNumber()==10 then
				skill = "jilei"
			elseif judge.card:getNumber()==11 then
				skill = "benyu"
			elseif judge.card:getNumber()==12 then
				skill = "chouce"
			elseif judge.card:getNumber()==13 then
				skill = "wuhun"
			end
			if to:hasSkill(skill,true) then skill = ""
			else room:acquireSkill(to,skill,true,true,false) end
			for i=1,2 do
				room:damage(sgs.DamageStruct("yisigu",source,to))
				room:getThread():delay()
			end
			if skill~="" then
				room:detachSkillFromPlayer(to,skill,true,true,false)
			end
		end
	end
}
yisigu = sgs.CreateViewAsSkillV2{
	name = "yisigu",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:usedTimes("#yisiguCard") < 1
	end,
	create_card = function(skill, request)
		return yisiguCard:clone()
	end,
}
yi_caocao:addSkill(yisigu)

yi_huatuo = sgs.General(shixinrumo_yi,"yi_huatuo","qun",4)
yimiehaivs = sgs.CreateViewAsSkillV2{
	name = "yimiehai",
	n = 2,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not (player and player:isAlive()) then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return player:getCardCount() > 1
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern() == "slash"
		end
		return false
	end,
	create_card = function(skill, request)
		local sc = sgs.Sanguosha:cloneCard("yj_stabs_slash")
		sc:setSkillName("yimiehai")
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			sc:addSubcard(id)
		end
		return sc
	end,
}
yimiehai = sgs.CreateTriggerSkillV2{
	name = "yimiehai",
	view_as_skill = yimiehaivs,
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		-- 「滅害」用牌結算中嘅移牌：以 historyParent 取外層 use_card，
		-- 取代舊版 PreCardUsed/CardFinished 之間嘅 yimiehaibf 標記。
		local move = data:toMoveOneTime()
		if not invoker:hasSkill(skill)
		or not (move.from_places:contains(sgs.Player_PlaceHand)
			or move.from_places:contains(sgs.Player_PlaceEquip)) then
			return false
		end
		-- 走訪所有 use_card 祖先（舊標記於整個 PreCardUsed~CardFinished 窗口有效，
		-- 巢狀用牌不會清除它）
		local eid = room:currentHistoryEventId()
		local in_yimiehai_use = false
		while eid do
			local use_ev = room:historyParent(eid,"use_card",true)
			if not (use_ev and use_ev.id) then break end
			local ud = use_ev.data or {}
			if tostring(ud.from or "")==invoker:objectName()
			and string.find(tostring((ud.card or {}).skill_name or ""),"yimiehai",1,true) then
				in_yimiehai_use = true
				break
			end
			eid = use_ev.parent_id
		end
		if not in_yimiehai_use then return false end
		for i,id in sgs.qlist(move.card_ids)do
			local c = sgs.Sanguosha:getCard(id)
			if c:getSuit()==0 and c:hasFlag("visible") and move.from:isWounded() then
				local to = BeMan(room,move.from)
				to:drawCards(2,skill:objectName())
				room:recover(to,sgs.RecoverStruct(skill:objectName(),invoker))
			end
		end
		return false
	end
}
yi_huatuo:addSkill(yimiehai)
yimiehaibf = sgs.CreateTargetModSkillV2{
    name = "#yimiehaibf",
	holder_selector = sgs.CorrectSkill_System,
	correct_func = function(skill, ctx)
		local modType = ctx:getModType()
		local card = ctx:getCard()
		local from = ctx:getPrimary()
		if not (card and from) then return nil end
		if table.contains(card:getSkillNames(), "yimiehai") then
			if modType == sgs.TargetModSkill_DistanceLimit
			or modType == sgs.TargetModSkill_Residue then
				return 999
			end
			return nil
		end
		if modType == sgs.TargetModSkill_Residue then
			local n = 0
			if from:getPhase()==sgs.Player_Play then
				local x = 0
				for _,m in ipairs(from:getMarkNames())do
					if m:startsWith("&manhuaibing+:+") and from:getMark(m)>0 then
						x = tonumber(m:split("+")[3])-1
					end
				end
				n = n+x
			end
			return n
		end
		return nil
	end,
}
yi_huatuo:addSkill(yimiehaibf)

yi_lvboshe = sgs.General(shixinrumo_yi,"yi_lvboshe","qun",4)
yiqingjun = sgs.CreateTriggerSkillV2{
	name = "yiqingjun",
	waked_skills = "shefu",
	events = {sgs.RoundEnd,sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.RoundEnd then
			if invoker:hasSkill(skill) then
				local tp = room:askForPlayerChosen(invoker,room:getOtherPlayers(invoker),skill:objectName(),"yiqingjun0",true,true)
				if tp then
					room:setPlayerMark(tp,"&yiqingjun",1)
					room:getThread():addTriggerSkill(sgs.Sanguosha:getTriggerSkill("shefu"))
					local aps = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getAllPlayers())do
						if p:inMyAttackRange(tp) or invoker==p
						then aps:append(p) end
					end
					room:drawCards(aps,2,skill:objectName())
					for _,p in sgs.qlist(aps)do
						if p:isDead() then continue end
						local cns = {}
						for _,cn in sgs.list(sgs.Sanguosha:getCardNames("BasicCard,TrickCard"))do
							if p:getMark("Shefu_"..cn)<1 then table.insert(cns,cn) end
						end
						local cn = room:askForChoice(p,"shefu",table.concat(cns,"+"))
						local dc = room:askForExchange(p,skill:objectName(),1,1,false,"yiqingjun1:"..cn)
						if dc then
							cns = sgs.Sanguosha:cloneSkillCard("ShefuCard")
							cns:setUserString(cn)
							cns:addSubcard(dc)
							room:useCard(sgs.CardUseStruct(cns,p))
							cns:deleteLater()
							p:acquireSkill("shefu")
						end
						p:addMark("yiqingjunbf")
					end
					tp:gainAnExtraTurn()
					room:setPlayerMark(tp,"&yiqingjun",0)
				end
			end
		elseif event==sgs.EventPhaseChanging then
	     	local change = data:toPhaseChange()
			if change.to==sgs.Player_NotActive and invoker:getMark("&yiqingjun")>0 then
				room:setPlayerMark(invoker,"&yiqingjun",0)
				for i,p in sgs.qlist(room:getAllPlayers())do
					if p:getMark("yiqingjunbf")>0 then
						p:detachSkill("shefu")
						p:clearOnePrivatePile("ambush")
						for _,m in sgs.list(p:getMarkNames())do
							if m:contains("Shefu_") then
								room:setPlayerMark(p,m,0)
							end
						end
					end
				end
				-- 「未受傷害」以本 turn 域嘅 damage 事件取代 yiqingjunDamage-Clear 標記
				local turn = room:historyScopes().turn_id
				local damaged = {}
				if turn and tostring(turn)~="0" then
					local dfilter = {kind="damage",turn_id=turn,limit=64}
					local dpage = room:queryHistoryEvents(dfilter)
					if not (dpage.error or not dpage.complete or not dpage.attribution_complete) then
						local dwatermark = dpage.watermark
						while true do
							for _,ev in ipairs(dpage.items or {})do
								local dd = ev.data or {}
								if dd.prevented~=true and dd.to and tostring(dd.to)~="" then
									damaged[tostring(dd.to)] = true
								end
							end
							if not dpage.has_more then break end
							dfilter.after = dpage.next_after
							dfilter.watermark = dwatermark
							dpage = room:queryHistoryEvents(dfilter)
							if dpage.error or not dpage.complete or not dpage.attribution_complete then break end
						end
					end
				end
				for i,p in sgs.qlist(room:getAllPlayers())do
					if p:getMark("yiqingjunbf")>0 then
						p:setMark("yiqingjunbf",0)
						if not damaged[p:objectName()] then
							local tp = invoker
							if p:canSlash(tp,false) then
								tp = BeMan(room,tp)
								local dc = dummyCard("slash","_yiqingjun")
								room:useCard(sgs.CardUseStruct(dc,p,tp))
							end
						end
					end
				end
			end
		end
	end
}
yi_lvboshe:addSkill(yiqingjun)

yi_wanghou = sgs.General(shixinrumo_yi,"yi_wanghou","wei",3)
yijugu = sgs.CreateTriggerSkillV2{
	name = "yijugu",
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.EventPhaseChanging then
	     	local change = data:toPhaseChange()
			if change.to==sgs.Player_NotActive then
				local aps = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAllPlayers())do
					local ids = p:getTag("yijuguIds"):toIntList()
					if ids:isEmpty() then continue end
					p:removeTag("yijuguIds")
					local dc = dummyCard()
					for _,id in sgs.qlist(room:getDrawPile())do
						if ids:contains(id) then dc:addSubcard(id) end
					end
					p:obtainCard(dc,true)
					aps:append(p)
				end
				room:drawCards(aps,1,skill:objectName())
			end
		else
			if invoker:getPhase()==sgs.Player_Start and invoker:hasSkill(skill) then
				local x = 5
				for i=1,5 do
					local tps = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getAlivePlayers())do
						if p:getCardCount()>0 then tps:append(p) end
					end
					if i==1 then
						if tps:isEmpty() or not invoker:askForSkillInvoke(skill) then break end
					end
					local tp = room:askForPlayerChosen(invoker,tps,skill:objectName(),"yijugu0:"..x,i>1)
					if tp then
						room:doAnimate(1,invoker:objectName(),tp:objectName())
						local dc = dummyCard()
						for n=1,x do
							local id = room:askForCardChosen(invoker,tp,"he",skill:objectName(),false,sgs.Card_MethodNone,dc:getSubcards(),n>1)
							if id<0 then break end
							dc:addSubcard(id)
							if dc:subcardsLength()>=tp:getCardCount() then break end
						end
						x = x-dc:subcardsLength()
						tp:setTag("yijuguIds",ToData(dc:getSubcards()))
						room:moveCardTo(dc,nil,sgs.Player_DrawPile,true)
						if x<1 or invoker:isDead() then break end
					else
						break
					end
				end
			end
		end
	end
}
yi_wanghou:addSkill(yijugu)

yi_caopi = sgs.General(shixinrumo_yi,"yi_caopi","wei",3)
yizhengsiCard = sgs.CreateSkillCard{
	name = "yizhengsiCard",
	filter = function(self,targets,to_select,from)
		if #targets<2 then return to_select:getHandcardNum()>0 end
		return #targets<3 and to_select:getHandcardNum()>0
		and (to_select==from or table.contains(targets,from))
	end,
	feasible = function(self,targets,source)
		return #targets>2 and table.contains(targets,source)
	end,
	about_to_use = function(self,room,use)
		-- 保留選擇順序：cardOnUse 內 use.to 會被 sortByActionOrder 重排
		self:setTag("yizhengsiUse",ToData(use))
		self:cardOnUse(room,use)
	end,
	on_use = function(self,room,source,targets)
		local use = self:getTag("yizhengsiUse"):toCardUse()
		local nums,ids = {},{}
		local dc = room:askForCardShow(use.to:first(),source,"yizhengsi")
		local max,min = dc:getNumber(),dc:getNumber()
		nums[use.to:first():objectName()] = dc:getNumber()
		room:showCard(use.to:first(),dc:getEffectiveId())
		for i,p in sgs.qlist(use.to)do
			p:addMark("yizhengsiUse-PlayClear")
			if i>0 then
				local dc2 = room:askForCardShow(p,source,"yizhengsi")
				if dc2:getNumber()>max then max = dc2:getNumber() end
				if dc2:getNumber()<min then min = dc2:getNumber() end
				ids[p:objectName()] = dc2:getEffectiveId()
				nums[p:objectName()] = dc2:getNumber()
			end
		end
		for i,p in sgs.qlist(use.to)do
			if i>0 then
				room:showCard(p,ids[p:objectName()])
			end
		end
		for i,p in sgs.qlist(use.to)do
			local n = nums[p:objectName()] or 0
			if n>=max then
				room:askForDiscard(p,"yizhengsi",2,2)
			end
			if n<=min then
				room:loseHp(p,1,true,source,"yizhengsi")
			end
		end
	end
}
yizhengsi = sgs.CreateViewAsSkillV2{
	name = "yizhengsi",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:getHandcardNum() > 0
	end,
	create_card = function(skill, request)
		return yizhengsiCard:clone()
	end,
}
yi_caopi:addSkill(yizhengsi)
yichengming = sgs.CreateTriggerSkillV2{
	name = "yichengming",
	events = {sgs.EventPhaseEnd},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		if event==sgs.EventPhaseEnd then
			if player:getPhase()==sgs.Player_Play
			and player:usedTimes("#yizhengsiCard")>0 then
				local hp,hn = player:getHp(),player:getHandcardNum()
				for i,p in sgs.qlist(room:getAlivePlayers())do
					if p:getMark("yizhengsiUse-PlayClear")>0 then
						if p:getHandcardNum()>hn then hn = p:getHandcardNum() end
						if p:getHp()>hp then hp = p:getHp() end
					end
				end
				local hp2 = player:getHp()
				if player:getHandcardNum()>hn and player:isWounded()
				and player:askForSkillInvoke(skill,ToData("yichengming1")) then
					room:recover(player,sgs.RecoverStruct(skill:objectName(),player))
				end
				if hp2>hp and player:askForSkillInvoke(skill,ToData("yichengming2")) then
					for i,p in sgs.qlist(room:getOtherPlayers(player))do
						if p:getMark("yizhengsiUse-PlayClear")>0 and p:getCardCount()>0 and player:isAlive() then
							local id = room:askForCardChosen(player,p,"he",skill:objectName())
							if id>-1 then room:obtainCard(player,id,false) end
						end
					end
				end
			end
		end
	end
}
yi_caopi:addSkill(yichengming)

yi_xunyu = sgs.General(shixinrumo_yi,"yi_xunyu","wei",3)
yihuiceCard = sgs.CreateSkillCard{
	name = "yihuiceCard",
	filter = function(self,targets,to_select,from)
		return #targets<2 and to_select~=from
		and from:canPindian(to_select)
	end,
	feasible = function(self,targets,source)
		return #targets>1
	end,
	on_use = function(self,room,source,targets)
		local success = nil
		for i,tp in sgs.list(targets)do
			if source:canPindian(tp) then
				local n = source:pindianInt(tp,"yihuice")
				if i==1 then
					if n==1 then success = source
					elseif n==-1 then success = tp end
				else
					if n==1 then
						if success then
							if success==source then
								room:damage(sgs.DamageStruct("yihuice",source,targets[1]))
							else
								room:damage(sgs.DamageStruct("yihuice",source,source))
							end
							room:getThread():delay()
							room:damage(sgs.DamageStruct("yihuice",success,tp))
						else
							room:damage(sgs.DamageStruct("yihuice",source,source))
							room:getThread():delay()
							room:damage(sgs.DamageStruct("yihuice",source,targets[1]))
						end
					elseif n==-1 then
						if success then
							if success==source then
								room:damage(sgs.DamageStruct("yihuice",tp,targets[1]))
							else
								room:damage(sgs.DamageStruct("yihuice",tp,source))
							end
							room:getThread():delay()
							room:damage(sgs.DamageStruct("yihuice",success,source))
						else
							room:damage(sgs.DamageStruct("yihuice",tp,source))
							room:getThread():delay()
							room:damage(sgs.DamageStruct("yihuice",tp,targets[1]))
						end
					elseif n==0 then
						if success then
							room:damage(sgs.DamageStruct("yihuice",success,source))
							room:getThread():delay()
							room:damage(sgs.DamageStruct("yihuice",success,tp))
						end
					end
				end
			end
		end
	end
}
yihuice = sgs.CreateViewAsSkillV2{
	name = "yihuice",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:usedTimes("#yihuiceCard") < 1
			and player:getHandcardNum() > 0
	end,
	create_card = function(skill, request)
		return yihuiceCard:clone()
	end,
}
yi_xunyu:addSkill(yihuice)
yiyihe = sgs.CreateTriggerSkillV2{
	name = "yiyihe",
	events = {sgs.DamageInflicted},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.from then
				local fromNum = damage.from:getHandcardNum()-damage.from:getHp()
				if fromNum>0 then fromNum = 1 elseif fromNum<0 then fromNum = -1 end
				local toNum = invoker:getHandcardNum()-invoker:getHp()
				if toNum>0 then toNum = 1 elseif toNum<0 then toNum = -1 end
				for i,p in sgs.list(room:getAllPlayers())do
					if p:hasFlag("CurrentPlayer") and p:hasSkill(skill) then
						if fromNum==toNum then
							if p:getMark("yiyihe2-Clear")<1 then
								p:addMark("yiyihe2-Clear")
								room:sendCompulsoryTriggerLog(p,skill)
								local aps = SPlayerList(invoker,damage.from)
								room:sortByActionOrder(aps)
								room:drawCards(aps,2,skill:objectName())
							end
						else
							if p:getMark("yiyihe1-Clear")<1 then
								p:addMark("yiyihe1-Clear")
								room:sendCompulsoryTriggerLog(p,skill)
								invoker:damageRevises(data,1)
							end
						end
					end
				end
			end
		end
	end
}
yi_xunyu:addSkill(yiyihe)
yijizhi = sgs.CreateTriggerSkillV2{
	name = "yijizhi",
	events = {sgs.Dying},
	frequency = sgs.Skill_Compulsory,
	-- 「每回合首次陷入濒死」由 SkillV2 usage 計量（回合域）；觸發技需手動 isUsable/addUsage
	limit_scope = sgs.Skill_Limit_Turn,
	max_usage_limit = 1,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then
			return false
		end
		if data:toDying().who~=player then return false end
		for _, iid in sgs.list(player:getSkillInstanceIds(skill:objectName())) do
			local uctx = sgs.SkillContext()
			uctx.owner = player
			uctx.invoker = player
			uctx.instanceID = iid
			uctx.current_event = event
			if skill:isUsable(uctx) then return skill:objectName() end
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		if not skill:isUsable(ctx) then return false end
		skill:addUsage(ctx)
		room:sendCompulsoryTriggerLog(player,skill)
		room:recover(player,sgs.RecoverStruct(skill:objectName(),player))
		return false
	end
}
yi_xunyu:addSkill(yijizhi)
-- DEFER:yijizhibf:sgs.CreateProhibitSkill has no SkillV2 equivalent
yijizhibf = sgs.CreateProhibitSkill{
	name = "#yijizhibf",
	is_prohibited = function(self,from,to,card)
		if card:isKindOf("Peach") then
			return from~=to and to and to:hasSkill("yijizhi")
		end
	end
}
yi_xunyu:addSkill(yijizhibf)

yi_fuhuanghou = sgs.General(shixinrumo_yi,"yi_fuhuanghou","qun",4,false,false,false,3)
yimitu = sgs.CreateTriggerSkillV2{
    name = "yimitu",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Start then
				local tps = sgs.SPlayerList()
				for _,p in sgs.list(room:getAlivePlayers())do
					if p:isWounded() then tps:append(p) end
				end
				tps = room:askForPlayersChosen(player,tps,skill:objectName(),0,3,"yimitu0",true,true)
				if tps:length()>0 then
					local shown = {}
					for _,p in sgs.qlist(tps)do
						local id = room:drawCardsList(p,1,skill:objectName()):first()
						shown[p:objectName()] = id
						room:showCard(p,id)
					end
					local tps2 = sgs.SPlayerList()
					for _,p in sgs.list(room:getAlivePlayers())do
						if p:isKongcheng() or tps:contains(p) then continue end
						tps2:append(p)
					end
					local tp = room:askForPlayerChosen(player,tps2,skill:objectName(),"yimitu1")
					if tp then
						room:doAnimate(1,player:objectName(),tp:objectName())
						for _,p in sgs.list(tps)do
							if p:canPindian(tp) and p:askForSkillInvoke(skill,ToData("yimitu2:"..tp:objectName()),false) then
								local pd = p:PinDian(tp,skill:objectName())
								if pd.success then
									local dc = dummyCard(nil,"_yimitu")
									if p:canSlash(tp,dc,false) then
										room:useCard(sgs.CardUseStruct(dc,p,tp))
									end
								elseif pd.to_number>pd.from_number then
									local dc = dummyCard(nil,"_yimitu")
									if tp:canSlash(p,dc,false) then
										room:useCard(sgs.CardUseStruct(dc,tp,p))
									end
								end
								if pd.from_card:getEffectiveId()==shown[p:objectName()]
								then continue end
							end
							shown[p:objectName()] = -1
						end
						for _,p in sgs.list(tps)do
							if (shown[p:objectName()] or 0)<0 then
								room:loseMaxHp(player,1,skill:objectName())
							end
						end
					end
				end
			end
		end
	end,
}
yi_fuhuanghou:addSkill(yimitu)
yiqianliu = sgs.CreateTriggerSkillV2{
	name = "yiqianliu",
	events = {sgs.TargetConfirmed},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		if event==sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				for i,p in sgs.list(use.to)do
					if p:distanceTo(player)<=1 then
						if player:askForSkillInvoke(skill) then
							local ids = room:getNCards(4,true,false)
							room:askForGuanxing(player,ids)
							local suits = sgs.IntList()
							for _,id in sgs.qlist(ids)do
								local c = sgs.Sanguosha:getCard(id)
								if suits:contains(c:getSuit()) then continue end
								suits:append(c:getSuit())
							end
							if suits:length()==4 and player:askForSkillInvoke("yiqianliu0",ToData("yiqianliu"),false) then
								local move = sgs.CardsMoveStruct()
								move.card_ids = ids
								move.to = player
								move.to_place = sgs.Player_PlaceTable
								move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER,player:objectName(),skill:objectName(),nil)
								room:moveCardsAtomic(move,true)
								room:getThread():delay()
								move.to_place = sgs.Player_PlaceHand
								move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTBACK,player:objectName(),skill:objectName(),nil)
								room:moveCardsAtomic(move,true)
							end
						end
						break
					end
				end
			end
		end
		return false
	end
}
yi_fuhuanghou:addSkill(yiqianliu)

yi_liubei = sgs.General(shixinrumo_yi,"yi_liubei","qun",4)
yichengbian = sgs.CreateTriggerSkillV2{
	name = "yichengbian",
	events = {sgs.EventPhaseStart,sgs.CardAsked},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.CardAsked then
    		local pattern = data:toStringList()
			if pattern[#pattern]:contains("_yichengbian")
			and pattern[1]:contains("slash") and invoker:getHandcardNum()>0 then
				local h = invoker:getHandcardNum()+1
				local sc = room:askForExchange(invoker,skill:objectName(),h,h/2,false,"yichengbian1",true)
				if sc then
					local dc = dummyCard("slash","_yichengbian")
					dc:addSubcards(sc:getSubcards())
					room:provide(dc)
					return true
				end
			end
		else
			if (invoker:getPhase()==sgs.Player_Start or invoker:getPhase()==sgs.Player_Finish)
			and invoker:hasSkill(skill) then
				local tps = sgs.SPlayerList()
				local dc = dummyCard("duel","_yichengbian")
				for i,p in sgs.list(room:getOtherPlayers(invoker))do
					if invoker:canPindian(p) and invoker:canUse(dc,p)
					then tps:append(p) end
				end
				local tp = room:askForPlayerChosen(invoker,tps,skill:objectName(),"yichengbian0",true,true)
				if tp then
					local pd = delayedPingdian(skill,invoker,tp)
					room:useCard(sgs.CardUseStruct(dc,invoker,tp))
					pd = verifyPindian(pd)
					if pd.success then
						invoker:drawCards(invoker:getMaxHp()-invoker:getHandcardNum(),skill:objectName())
					elseif pd.from_number<pd.to_number then
						tp:drawCards(tp:getMaxHp()-tp:getHandcardNum(),skill:objectName())
					end
				end
			end
		end
		return false
	end
}
yi_liubei:addSkill(yichengbian)

yi_jiangguan = sgs.General(shixinrumo_yi,"yi_jiangguan","wei",3)
yizongheng = sgs.CreateTriggerSkillV2{
	name = "yizongheng",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Start then
				local tps = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if p:getHandcardNum()>0 then tps:append(p) end
				end
				if tps:length()<2 then return end
				tps = room:askForPlayersChosen(player,tps,skill:objectName(),-1,2,"yizongheng0",true,true)
				if tps:length()<2 then return end
				local ids = tps:first():handCards()
				for _,id in sgs.qlist(tps:last():handCards())do
					ids:append(id)
				end
				for _,p in sgs.qlist(tps)do
					room:doGongxin(player,p,sgs.IntList(),skill:objectName())
				end
				room:fillAG(ids,player)
				local cid = room:askForAG(player,ids,false,skill:objectName(),"yizongheng1")
				local tps2 = sgs.SPlayerList()
				tps2:append(player)
				room:showCard(room:getCardOwner(cid),cid)
				local c1 = sgs.Sanguosha:getCard(cid)
				room:takeAG(player,cid,false,tps2)
				for _,id in sgs.list(InsertList({},ids))do
					local c2 = sgs.Sanguosha:getCard(id)
					if c1:getType()~=c2:getType() and c1:getNumber()~=c2:getNumber() and c1:getSuit()~=c2:getSuit()
					or room:getCardOwner(id)==room:getCardOwner(cid) or not player:canDiscard(room:getCardOwner(id),id) then
						room:takeAG(nil,id,false,tps2)
						ids:removeOne(id)
					end
				end
				player:obtainCard(c1)
				local dc = dummyCard()
				for i=1,3 do
					if ids:isEmpty() then break end
					cid = room:askForAG(player,ids,true,skill:objectName(),"yizongheng2")
					if cid<0 then break end
					room:takeAG(player,cid,false,tps2)
					dc:addSubcard(cid)
					ids:removeOne(cid)
					local c2 = sgs.Sanguosha:getCard(cid)
					for _,id in sgs.list(InsertList({},ids))do
						local c3 = sgs.Sanguosha:getCard(id)
						if c1:getType()==c2:getType() and c3:getType()==c2:getType()
						or c1:getSuit()==c2:getSuit() and c3:getSuit()==c2:getSuit()
						or c1:getNumber()==c2:getNumber() and c3:getNumber()==c2:getNumber() then
							room:takeAG(nil,id,false,tps2)
							ids:removeOne(id)
						end
					end
				end
				room:clearAG(player)
				room:throwCard(dc,skill:objectName(),room:getCardOwner(dc:getEffectiveId()),player)
			end
		end
	end
}
yi_jiangguan:addSkill(yizongheng)
yiduibian = sgs.CreateTriggerSkillV2{
	name = "yiduibian",
	events = {sgs.DamageInflicted},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		if event==sgs.DamageInflicted then
			local damage = data:toDamage()
			player:addMark("yiduibianDamage-Clear")
			if damage.from and player:getMark("yiduibianDamage-Clear")==1
			and player:canPindian(damage.from) and player:askForSkillInvoke(skill,data) then
				local pd = delayedPingdian(skill,player,damage.from)
				player:damageRevises(data,-damage.damage)
				if player:canDiscard(damage.from,"he")
				and damage.from:askForSkillInvoke("yiduibian0",ToData("yiduibian:"..player:objectName()),false) then
					local id = room:askForCardChosen(player,damage.from,"he",skill:objectName(),false,sgs.Card_MethodDiscard)
					if id>-1 then
						room:throwCard(id,skill:objectName(),damage.from,player)
						pd = verifyPindian(pd)
						if pd.to_number>pd.from_number then
							room:loseHp(player,1,true,player,skill:objectName())
						end
					end
				end
				return true
			end
		end
		return false
	end
}
yi_jiangguan:addSkill(yiduibian)


sgs.LoadTranslationTable {
	["shixinrumo_yi"] = "蚀心入魔·疑",
	["demon"] = "魔",

	["yi_jiangguan"] = "疑蒋干",
	["#yi_jiangguan"] = "舌锁千帆",
	["illustrator:yi_jiangguan"] = "鬼画府",
	["yizongheng"] = "纵横",
	[":yizongheng"] = "准备阶段，你可以观看两名其他角色的手牌，展示并获得其中一名角色的一张牌，然后弃置另一名角色与展示牌类别、花色、点数相同的至多各一张牌。",
	["yiduibian"] = "对辩",
	[":yiduibian"] = "当你每回合首次受到伤害时，你可以与伤害来源延时拼点并防止此伤害，然后其可以令你弃置其一张牌并公开结果：若其赢，你失去1点体力。",
	["yizongheng0"] = "你可以发动“纵横”选择观看两名其他角色手牌",
	["yizongheng1"] = "纵横：请选择要获得的牌",
	["yizongheng2"] = "纵横：请选择要弃置的牌",
	["yiduibian0:yiduibian"] = "对辩：你可以令%src弃置你一张牌来公开拼点结果",

	["yi_liubei"] = "疑刘备",
	["#yi_liubei"] = "潜隐波涛",
	["illustrator:yi_liubei"] = "鬼画府",
	["yichengbian"] = "乘变",
	[":yichengbian"] = "准备阶段和结束阶段，你可以进行延时拼点并视为对对方使用一张【决斗】，结算中双方可以将至少半数手牌当做【杀】打出；结算后公开拼点结果，赢的角色摸牌至体力上限。",
	["yichengbian0"] = "你可以与一名角色延时拼点",
	["yichengbian1"] = "乘变：你可以将半数手牌当做【杀】打出",

	["yi_fuhuanghou"] = "疑伏寿",
	["#yi_fuhuanghou"] = "白绫蔽月",
	["illustrator:yi_fuhuanghou"] = "鬼画府",
	["yimitu"] = "密图",
	[":yimitu"] = "准备阶段，你可以令至多3名已受伤角色各摸一张牌并展示之，这些角色可以与你指定的另一名角色拼点：赢的角色视为对没赢的角色使用一张【杀】；然后每有一名未以展示牌拼点的角色，你扣减1点体力上限。",
	["yiqianliu"] = "潜流",
	[":yiqianliu"] = "与你距离为1的角色成为【杀】的目标后，你可以观看牌堆底4张牌并以任意顺序置于牌堆顶或底，若这些牌花色各不同，你可以展示并获得之。",
	["yimitu0"] = "你可以发动“密图”选择至多3名受伤角色摸牌",
	["yimitu1"] = "密图：请选择这些角色拼点目标",
	["yimitu:yimitu2"] = "密图：你可以与%src拼点",
	["yiqianliu0:yiqianliu"] = "潜流：你可以获得观看的牌",

	["yi_xunyu"] = "疑荀彧",
	["#yi_xunyu"] = "末路见疑",
	["illustrator:yi_xunyu"] = "鬼画府",
	["yihuice"] = "迴策",
	[":yihuice"] = "出牌阶段限一次，你可以依次与两名其他角色拼点，然后每次赢的角色对另一次没赢的角色造成1点伤害。",
	["yiyihe"] = "异合",
	[":yiyihe"] = "锁定技，回合内各限一次，当一名角色受到伤害时，若其与伤害来源体力值和手牌数：不同，此伤害+1；相同，双方各摸两张牌。",
	["yijizhi"] = "赍志",
	[":yijizhi"] = "锁定技，其他角色不能对你使用【桃】；当你每回合首次陷入濒死时，你回复1点体力。",

	["yi_caopi"] = "疑曹丕",
	["#yi_caopi"] = "兄友弟恭",
	["illustrator:yi_caopi"] = "鬼画府",
	["yizhengsi"] = "争嗣",
	[":yizhengsi"] = "出牌阶段，你可以选择包含你在内3名有手牌的角色，令第一名角色先展示一张手牌，其余角色再同时展示一张手牌；点数最大的角色弃置两张手牌，点数最小的角色失去1点体力。",
	["yichengming"] = "承命",
	[":yichengming"] = "出牌阶段结束时，若你在此阶段“争嗣”角色中；手牌数最大，你可以回复2点体力；体力值最大，你可以获得其他“争嗣”角色各一张牌。",
	["yichengming:yichengming1"] = "你可以发动“承命”回复2点体力",
	["yichengming:yichengming2"] = "你可以发动“承命”获得其他“争嗣”角色各一张牌",

	["yi_wanghou"] = "疑王垕",
	["#yi_wanghou"] = "一刀斩讫",
	["illustrator:yi_wanghou"] = "鬼画府",
	["yijugu"] = "聚谷",
	[":yijugu"] = "准备阶段，你可以依次将任意角色共计5张牌正面朝上置于牌堆顶，此回合结束时，这些角色获得牌堆顶各自被放置的牌，然后各摸一张牌。",
	["yijugu0"] = "聚谷：请选择角色放置至多X张牌",

	["yi_lvboshe"] = "疑吕伯奢",
	["#yi_lvboshe"] = "碧血东流",
	["illustrator:yi_lvboshe"] = "鬼画府",
	["yiqingjun"] = "请君",
	[":yiqingjun"] = "每轮结束时，你可以令一名其他角色执行一个额外回合，你和攻击范围内有其的角色各摸两张牌并发动“设伏”，此额外回合结束时，移去所有“伏兵”，本回合未受到伤害的“设伏”角色视为对其使用一张【杀】。",
	["yiqingjun0"] = "你可以发动“请君”选择一名角色",
	["yiqingjun1"] = "请选择一张手牌设伏【%src】",

	["yi_huatuo"] = "疑华佗",
	["#yi_huatuo"] = "上医医国",
	["illustrator:yi_huatuo"] = "鬼画府",
	["yimiehai"] = "灭害",
	[":yimiehai"] = "你可以将两张牌当做无距离与次数限制的刺【杀】使用。此【杀】结算过程中正面朝上失去♠牌的已受伤角色摸两张牌并回复1点体力。",

	["yi_caocao"] = "疑曹操",
	["#yi_caocao"] = "一目窥九州",
	["illustrator:yi_caocao"] = "鬼画府",
	["yikuxin"] = "枯心",
	[":yikuxin"] = "当你受到伤害后，你可以令所有其他角色依次展示任意张手牌，你选择获得所有角色展示的牌或一名其他角色未展示的牌所有手牌并展示之。若你没有因此获得♥牌，你弃置获得的牌并翻面。",
	["yisigu"] = "似故",
	[":yisigu"] = "出牌阶段限一次，你可以令一名其他角色进行一次判定并对其造成两次1点伤害，期间其根据判定结果视为拥有对应的“受到伤害后”的技能。",
	["yikuxin0"] = "枯心：请选择任意张手牌展示",
	["yikuxin1"] = "枯心：你可以点击取消获得这些牌或选择一名角色获得其未展示的牌",

}





local shixinrumo_man = sgs.Package("shixinrumo_man",sgs.Package_GeneralPack)

man_guanyu = sgs.General(shixinrumo_man,"man_guanyu","demon",5)
manhanguo = sgs.CreateTriggerSkillV2{
	name = "manhanguo",
	events = {sgs.Damage,sgs.RoundStart,sgs.RoundEnd,sgs.CardAsked},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.RoundStart then
			if invoker:hasSkill(skill) then
				local tps = sgs.SPlayerList()
				local x = room:getTag("TurnLengthCount"):toInt()
				for _,p in sgs.qlist(room:getOtherPlayers(invoker))do
					if p:getMark(invoker:objectName().."manhanguoT"..x-1)<1
					then tps:append(p) end
				end
				local tp = room:askForPlayerChosen(invoker,tps,skill:objectName(),"manhanguo0:",true,true)
				if tp then
					tp:addMark(invoker:objectName().."manhanguoT"..x)
					local ids = tp:handCards()
					for _,id in sgs.qlist(tp:getEquipsId())do
						ids:append(id)
					end
					tp:addToPile(skill:objectName(),ids,false)
				end
			end
		elseif event==sgs.RoundEnd then
			local ids = invoker:getPile(skill:objectName())
			if ids:length()>0 then
				local dc = dummyCard()
				dc:addSubcards(ids)
				invoker:obtainCard(dc,false)
			end
		elseif event==sgs.CardAsked then
    		local pattern = data:toStringList()
			if #pattern>3 and pattern[1]:contains("jink") then
				local c = sgs.Card_Parse(pattern[4])
				if c and c:isKindOf("Slash") then
					local use = room:getUseStruct(c)
					local x = room:getTag("TurnLengthCount"):toInt()
					if use.from and invoker:getMark(use.from:objectName().."manhanguoT"..x)>0
					and invoker:askForSkillInvoke("hujia",data,false) then
						invoker:skillInvoked("hujia")
						for _,p in sgs.qlist(room:getOtherPlayers(invoker))do
							c = room:askForCard(p,"jink","@hujia-jink:"..invoker:objectName(),ToData(invoker),sgs.Card_MethodResponse,invoker,false,"",true)
							if c then
								room:provide(c)
								if use.from:getCardCount()>0 then
									x = room:askForCardChosen(p,use.from,"he",skill:objectName())
									if x>=0 then room:obtainCard(p,x,false) end
								end
								return true
							end
						end
					end
				end
			end
		elseif event==sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				local x = room:getTag("TurnLengthCount"):toInt()
				if damage.to:getMark(invoker:objectName().."manhanguoT"..x)>0 then
					room:sendCompulsoryTriggerLog(invoker,skill:objectName())
					room:killPlayer(damage.to,damage)
				end
			end
		end
		return false
	end
}
man_guanyu:addSkill(manhanguo)
manweiwo = sgs.CreateTriggerSkillV2{
	name = "manweiwo",
	limit_mark = "@manweiwo",
	waked_skills = "nosrende,qingnang,longyin,wushen",
	frequency = sgs.Skill_Limited,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Finish and player:getMark("@manweiwo")>0 then
				local tps = room:askForPlayersChosen(player,room:getOtherPlayers(player),skill:objectName(),0,3,"manweiwo0",true,false)
				if tps:length()>0 then
					room:removePlayerMark(player,"@manweiwo")
					room:doSuperLightbox(player,skill:objectName())
					local sks = {"nosrende","qingnang","longyin"}
					for _,p in sgs.qlist(tps)do
						local sk = room:askForChoice(player,skill:objectName(),table.concat(sks,"+"),ToData(p),"",p:getGeneralName())
						table.removeOne(sks,sk)
						if p:hasSkill(sk,true) then continue end
						room:setPlayerProperty(p,"manweiwoFrom",ToData(player:objectName()))
						room:acquireSkill(p,sk)
					end
					room:acquireSkill(player,"wushen")
				end
			end
		end
		return false
	end
}
man_guanyu:addSkill(manweiwo)

man_yanliangwenchou = sgs.General(shixinrumo_man,"man_yanliangwenchou","qun",5)
manhaibianvs = sgs.CreateViewAsSkillV2{
	name = "manhaibian",
	can_activate = function(skill, request)
		return request:getPattern() == "@@manhaibian"
	end,
	create_card = function(skill, request)
		local dc = sgs.Sanguosha:cloneCard("duel")
		dc:setSkillName("_manhaibian")
		return dc
	end,
}
manhaibian = sgs.CreateTriggerSkillV2{
	name = "manhaibian",
	view_as_skill = manhaibianvs,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local invoker = ctx.invoker
		if invoker:getPhase()~=sgs.Player_RoundStart then return false end
		-- 以 Resolution History 取代 manhaibianUse/manhaibianColor* 標記：
		-- 舊版窗界為「上一次 RoundStart 階段事件」之後嘅所有非技能用牌。
		local cur = room:historyParent(room:currentHistoryEventId(),"phase",true)
		local curid = tonumber(tostring((cur or {}).id)) or 0
		local boundary = 0
		local efilter = {kind="phase",limit=64}
		local epage = room:queryHistoryEvents(efilter)
		if not (epage.error or not epage.complete or not epage.attribution_complete) then
			local ewatermark = epage.watermark
			while true do
				for _,ev in ipairs(epage.items or {})do
					local ed = ev.data or {}
					local id = tonumber(tostring(ev.id)) or 0
					if ed.phase==sgs.Player_RoundStart and ed.entered==true
					and id>boundary and id<curid then
						boundary = id
					end
				end
				if not epage.has_more then break end
				efilter.after = epage.next_after
				efilter.watermark = ewatermark
				epage = room:queryHistoryEvents(efilter)
				if epage.error or not epage.complete or not epage.attribution_complete then break end
			end
		end
		local users = {}
		local lastUser = {}
		local ufilter = {kind="use_card",after=boundary,limit=64}
		local upage = room:queryHistoryEvents(ufilter)
		if not (upage.error or not upage.complete or not upage.attribution_complete) then
			local uwatermark = upage.watermark
			while true do
				for _,ev in ipairs(upage.items or {})do
					local ud = ev.data or {}
					local card = ud.card or {}
					local f = tostring(ud.from or "")
					if (tonumber(tostring(card.type)) or 0)>0 and f~="" then
						users[f] = true
						if card.red==true then lastUser["red"] = f
						elseif card.black==true then lastUser["black"] = f end
					end
				end
				if not upage.has_more then break end
				ufilter.after = upage.next_after
				ufilter.watermark = uwatermark
				upage = room:queryHistoryEvents(ufilter)
				if upage.error or not upage.complete or not upage.attribution_complete then break end
			end
		end
		local rp = lastUser["red"] and room:findPlayerByObjectName(lastUser["red"],true) or nil
		local bp = lastUser["black"] and room:findPlayerByObjectName(lastUser["black"],true) or nil
		for _,p in sgs.qlist(room:getAllPlayers())do
			if users[p:objectName()] and p:hasSkill(skill) then
				if rp and rp:isAlive() then
					room:askForUseCard(rp,"@@manhaibian","manhaibian0")
				end
				if bp and bp:isAlive() then
					room:askForUseCard(bp,"@@manhaibian","manhaibian0")
				end
			end
		end
		return false
	end
}
man_yanliangwenchou:addSkill(manhaibian)
manqiewang = sgs.CreateTriggerSkillV2{
	name = "manqiewang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged,sgs.EventPhaseChanging,sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.EventPhaseChanging then
	     	local change = data:toPhaseChange()
			if change.to==sgs.Player_NotActive then
				for _,p in sgs.qlist(room:getAlivePlayers())do
					if p:getMark("manqiewangBf-Clear")<1 then continue end
					local cs = sgs.CardList()
					for _,c in sgs.qlist(p:getHandcards())do
						if c:getSkillName()=="manqiewang"
						then cs:append(c) end
					end
					room:filterCards(p,cs,true)
				end
			end
		elseif event==sgs.CardsMoveOneTime then
	     	local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_PlaceHand and move.to:objectName()==invoker:objectName()
			and invoker:getMark("manqiewangBf-Clear")>0 then
				for _,h in sgs.qlist(invoker:getHandcards())do
					if h:getSkillName()=="manqiewang" then continue end
					local toc = sgs.Sanguosha:cloneCard("nullification",h:getSuit(),h:getNumber())
					toc:setSkillName("manqiewang")
					local wrap = sgs.Sanguosha:getWrappedCard(h:getId())
					wrap:takeOver(toc)
					room:notifyUpdateCard(invoker,h:getId(),wrap)
				end
			end
		elseif event==sgs.Damaged then
			local damage = data:toDamage()
			for _,p in sgs.qlist(room:getAllPlayers())do
				if damage.to:distanceTo(p)<=1 and p:hasSkill(skill) then
					room:sendCompulsoryTriggerLog(p,skill)
					p:drawCards(1,skill:objectName())
					p:addMark("manqiewangBf-Clear")
					for _,h in sgs.qlist(p:getHandcards())do
						local toc = sgs.Sanguosha:cloneCard("nullification",h:getSuit(),h:getNumber())
						toc:setSkillName("manqiewang")
						local wrap = sgs.Sanguosha:getWrappedCard(h:getEffectiveId())
						wrap:takeOver(toc)
						room:notifyUpdateCard(p,h:getEffectiveId(),wrap)
					end
				end
			end
		end
		return false
	end
}
man_yanliangwenchou:addSkill(manqiewang)

man_luxun = sgs.General(shixinrumo_man,"man_luxun","wu",3)
manchanyuCard = sgs.CreateSkillCard{
	name = "manchanyuCard",
	filter = function(self,targets,to_select,from)
		return #targets<1 and to_select~=from
	end,
	on_use = function(self,room,source,targets)
		for _,to in sgs.list(targets)do
			to:drawCards(to:getHp(),"manchanyu")
			if source:canPindian(to) then
				local x = 99
				for _,h in sgs.qlist(source:getHandcards())do
					x = math.min(x,h:getNumber())
				end
				local c = room:askForCard(source,".|.|"..x.."!","manchanyu0:"..x,ToData(to),sgs.Card_MethodPindian)
				x = source:pindianInt(to,"manchanyu",c)
				room:showAllCards(source)
				room:showAllCards(to)
				if x==0 then continue end
				local sts = {}
				for _,h in sgs.qlist(source:getHandcards())do
					if not table.contains(sts,h:getColorString()) then
						table.insert(sts,h:getColorString())
					end
					if not table.contains(sts,h:getType()) then
						table.insert(sts,h:getType())
					end
				end
				for _,h in sgs.qlist(to:getHandcards())do
					if not table.contains(sts,h:getColorString()) then
						table.insert(sts,h:getColorString())
					end
					if not table.contains(sts,h:getType()) then
						table.insert(sts,h:getType())
					end
				end
				if #sts<1 then continue end
				local tp,fp = source,to
				if x<0 then
					tp = to
					fp = source
				end
				local st = room:askForChoice(tp,"manchanyu",table.concat(sts,"+"),ToData(fp))
				local tids = sgs.IntList()
				for _,h in sgs.qlist(tp:getHandcards())do
					if h:getColorString()==st or h:getType()==st then
						tids:append(h:getId())
					end
				end
				local fids = sgs.IntList()
				for _,h in sgs.qlist(fp:getHandcards())do
					if h:getColorString()==st or h:getType()==st then
						fids:append(h:getId())
					end
				end
				room:swapCards(tp,fp,tids,fids,"manchanyu")
			end
		end
	end
}
manchanyuvs = sgs.CreateViewAsSkillV2{
	name = "manchanyu",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:usedTimes("#manchanyuCard") < 1
	end,
	create_card = function(skill, request)
		return manchanyuCard:clone()
	end,
}
manchanyu = sgs.CreateTriggerSkillV2{
	name = "manchanyu",
	view_as_skill = manchanyuvs,
	events = {sgs.AskforPindianCard},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.AskforPindianCard then
    		local pd = data:toPindian()
			if pd.reason==skill:objectName() and pd.to_card==nil then
				local x = 99
				for _,h in sgs.qlist(pd.to:getHandcards())do
					x = math.min(x,h:getNumber())
				end
				pd.to_card = room:askForCard(pd.to,".|.|"..x.."!","manchanyu0:"..x,ToData(invoker),sgs.Card_MethodPindian)
				data:setValue(pd)
			end
		end
		return false
	end
}
man_luxun:addSkill(manchanyu)
mancongfeng = sgs.CreateTriggerSkillV2{
	name = "mancongfeng",
	change_skill = true,
	events = {sgs.TargetSpecified,sgs.TargetConfirmed},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		if event==sgs.TargetSpecified then
	     	local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				if player:getChangeSkillState(skill:objectName())==1 then
					if player:askForSkillInvoke(skill,use.from) then
						room:setChangeSkillState(player,skill:objectName(),2)
						local sps = SPlayerList(player,use.from)
						room:sortByActionOrder(sps)
						room:drawCards(sps,1,skill:objectName())
					end
				elseif player:canDiscard(use.from,"he") and player:askForSkillInvoke(skill,use.from) then
					room:setChangeSkillState(player,skill:objectName(),1)
					local ids = sgs.IntList()
					for i=1,2 do
						local id = room:askForCardChosen(player,use.from,"he",skill:objectName(),false,sgs.Card_MethodDiscard,ids)
						if id>=0 then
							ids:append(id)
							if ids:length()>=use.from:getCardCount() then break end
						end
					end
					room:throwCard(ids,skill:objectName(),use.from,player)
				end
			end
		elseif event==sgs.TargetConfirmed then
	     	local use = data:toCardUse()
			if use.card:getTypeId()>0 and use.to:contains(player) then
				if player:getChangeSkillState(skill:objectName())==1 then
					if player:askForSkillInvoke(skill,use.from) then
						room:setChangeSkillState(player,skill:objectName(),2)
						local sps = SPlayerList(player,use.from)
						room:sortByActionOrder(sps)
						room:drawCards(sps,1,skill:objectName())
					end
				elseif player:canDiscard(use.from,"he") and player:askForSkillInvoke(skill,use.from) then
					room:setChangeSkillState(player,skill:objectName(),1)
					local ids = sgs.IntList()
					for i=1,2 do
						local id = room:askForCardChosen(player,use.from,"he",skill:objectName(),false,sgs.Card_MethodDiscard,ids)
						if id>=0 then
							ids:append(id)
							if ids:length()>=use.from:getCardCount() then break end
						end
					end
					room:throwCard(ids,skill:objectName(),use.from,player)
				end
			end
		end
		return false
	end
}
man_luxun:addSkill(mancongfeng)

man_lvmeng = sgs.General(shixinrumo_man,"man_lvmeng","wu",4,true,false,false,3)
mankongzhi = sgs.CreateTriggerSkillV2{
	name = "mankongzhi",
	waked_skills = "#mankongzhibf",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified,sgs.CardEffect,sgs.HpChanged,sgs.MaxHpChanged},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		if event==sgs.TargetSpecified then
	     	local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.to:length()==1 and use.to:last():getCardCount()>0 then
				room:sendCompulsoryTriggerLog(player,skill)
				local dc = dummyCard()
				for i=1,math.min(3,use.to:last():getCardCount()) do
					local id = room:askForCardChosen(player,use.to:last(),"he",skill:objectName(),false,sgs.Card_MethodNone,dc:getSubcards(),true)
					if id<0 then break end
					dc:addSubcard(id)
				end
				player:obtainCard(dc,false)
			end
		elseif event==sgs.CardEffect then
	     	local effect = data:toCardEffect()
			if effect.card:isNDTrick() and player:isWounded() then
				room:sendCompulsoryTriggerLog(player,skill)
				effect.nullified = true
				data:setValue(effect)
			end
		else
			if player:isWounded() then
				room:filterCards(player,player:getHandcards(),false)
			else
				local cs = sgs.CardList()
				for _,h in sgs.qlist(player:getHandcards())do
					if h:getSkillName()==skill:objectName()
					then cs:append(h) end
				end
				room:filterCards(player,cs,true)
			end
		end
		return false
	end
}
man_lvmeng:addSkill(mankongzhi)
-- DEFER:mankongzhibf:sgs.CreateFilterSkill has no SkillV2 equivalent
mankongzhibf = sgs.CreateFilterSkill{
	name = "#mankongzhibf",
	view_filter = function(self,card)
		if card:isKindOf("BasicCard") then
			local tp = sgs.Sanguosha:currentRoom():getCardOwner(card:getId())
			return tp and tp:isWounded()
		end
	end,
	view_as = function(self,card)
		local ex = sgs.Sanguosha:cloneCard("jink",card:getSuit(),card:getNumber())
    	ex:setSkillName("mankongzhi")
	    --local wrap = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
	    --wrap:takeOver(ex)
	    return ex
	end
}
man_lvmeng:addSkill(mankongzhibf)
manbizhavs = sgs.CreateViewAsSkillV2{
	name = "manbizha",
	expand_pile = "#manbizha",
	n = 1,
	can_activate = function(skill, request)
		return request:getPattern() == "@@manbizha"
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		return player and candidate
			and request:getSelectedCardIds():isEmpty()
			and player:getPile("#manbizha"):contains(candidate:getId())
			and player:getMark("manbizhaNum")>candidate:getNumber()
			and candidate:isAvailable(player)
	end,
	create_card = function(skill, request)
		return sgs.Sanguosha:getCard(request:getSelectedCardIds():first())
	end,
}
manbizha = sgs.CreateTriggerSkillV2{
	name = "manbizha",
	view_as_skill = manbizhavs,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Finish and player:askForSkillInvoke(skill) then
				player:drawCards(1,skill:objectName())
				local tps = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if player:canPindian(p) then tps:append(p) end
				end
				local tp = room:askForPlayerChosen(player,tps,skill:objectName(),"manbizha0")
				if tp then
					local pd = player:PinDian(tp,skill:objectName())
					if pd.from_number>=pd.to_number and tp:isAlive() then
						room:loseHp(tp,2,true,player,skill:objectName())
						room:setPlayerMark(player,"manbizhaNum",pd.to_number)
						tps = tp:handCards()
						room:doGongxin(player,tp,tps,skill:objectName())
						for i=1,2 do
							if tps:isEmpty() then break end
							room:notifyMoveToPile(player,tps,skill:objectName())
							room:askForUseCard(player,"@@manbizha","manbizha1:"..pd.to_number)
							tps = tp:handCards()
						end
					end
					if pd.from_number<=pd.to_number and player:isAlive() then
						room:loseMaxHp(player,1,skill:objectName())
					end
				end
			end
		end
		return false
	end
}
man_lvmeng:addSkill(manbizha)


man_pangde = sgs.General(shixinrumo_man,"man_pangde","wei",4)
mannuozhan = sgs.CreateTriggerSkillV2{
	name = "mannuozhan",
	events = {sgs.EventPhaseStart,sgs.ConfirmDamage,sgs.CardFinished},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.EventPhaseStart then
			if invoker:getPhase()==sgs.Player_Start and invoker:hasSkill(skill) then
				local tp = room:askForPlayerChosen(invoker,room:getOtherPlayers(invoker),skill:objectName(),"mannuozhan0",true,true)
				while tp do
					invoker:drawCards(1,skill:objectName())
					local cns = {}
					for _,cn in ipairs(patterns())do
						local dc = dummyCard(cn,skill:objectName())
						if dc:isDamageCard() and not dc:isKindOf("DelayedTrick") then
							if invoker:canUse(dc,tp) or tp:canUse(dc,invoker)
							then table.insert(cns,cn) end
						end
					end
					if #cns<1 then break end
					local cn = room:askForChoice(tp,skill:objectName(),table.concat(cns,"+"),ToData(invoker))
					local log = sgs.LogMessage()
					log.type = "#mannuozhanLog"
					log.from = tp
					log.arg = cn
					room:sendLog(log)
					cns = {}
					local dc = dummyCard(cn,"_"..skill:objectName())
					if invoker:canUse(dc,tp) then table.insert(cns,"mannuozhan1") end
					if tp:canUse(dc,invoker) then table.insert(cns,"mannuozhan2") end
					if room:askForChoice(invoker,"mannuozhan3",table.concat(cns,"+"),ToData(cn))=="mannuozhan1" then
						room:useCard(sgs.CardUseStruct(dc,invoker,tp))
					else
						room:useCard(sgs.CardUseStruct(dc,tp,invoker))
					end
					if invoker:isAlive() and tp:isAlive() and invoker:askForSkillInvoke(skill,tp)
					then else break end
				end
			end
		elseif event==sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and table.contains(damage.card:getSkillNames(),skill:objectName()) then
				invoker:damageRevises(data,1)
			end
		elseif event==sgs.CardFinished then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),skill:objectName()) then
				for _,p in sgs.qlist(use.to)do
					if use.card:hasFlag("DamageDone_"..p:objectName()) then return end
				end
				room:loseHp(invoker,1,true,nil,skill:objectName())
			end
		end
		return false
	end
}
man_pangde:addSkill(mannuozhan)

man_koufeng = sgs.General(shixinrumo_man,"man_koufeng","shu",4)
manhuaibing = sgs.CreateTriggerSkillV2{
	name = "manhuaibing",
	events = {sgs.EventPhaseStart,sgs.DrawNCards},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.EventPhaseStart then
			if invoker:getPhase()==sgs.Player_Start and invoker:hasSkill(skill) then
				local tps = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers())do
					if p:getHandcardNum()>0 then tps:append(p) end
				end
				local tps = room:askForPlayersChosen(invoker,tps,skill:objectName(),-1,2,"manhuaibing0",true,true)
				if tps:length()>0 then
					local dc = dummyCard()
					for _,p in sgs.qlist(tps)do
						if p==invoker then continue end
						local id = room:askForCardChosen(invoker,p,"h",skill:objectName())
						dc:addSubcard(id)
					end
					invoker:obtainCard(dc,false)
					room:showAllCards(invoker)
					local n = 0
					for _,h in sgs.qlist(invoker:getHandcards())do
						if h:isRed() then n = n+1 end
					end
					local x = 99
					for _,p in sgs.qlist(tps)do
						x = math.min(x,p:getHp())
					end
					for _,p in sgs.qlist(tps)do
						if p:getHp()<=x then
							room:setPlayerMark(p,"&manhuaibing+:+"..n.."+-SelfClear",1)
						end
					end
				end
			end
		elseif event==sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason~="draw_phase" then return end
			for _,m in ipairs(invoker:getMarkNames())do
				if m:startsWith("&manhuaibing+:+") then
					draw.num = tonumber(m:split("+")[3])
					data:setValue(draw)
				end
			end
		end
		return false
	end
}
man_koufeng:addSkill(manhuaibing)
manhuaibingbf = sgs.CreateMaxCardsSkillV2{
    name = "#manhuaibingbf",
	holder_selector = sgs.CorrectSkill_System,
	fixed_func = function(skill, ctx)
		local player = ctx:getPrimary()
		if not player then return nil end
		if player:getPhase()==sgs.Player_Discard then
			local x = -1
			for _,m in ipairs(player:getMarkNames())do
				if m:startsWith("&manhuaibing+:+") and player:getMark(m)>0 then
					x = math.max(tonumber(m:split("+")[3]),x)
				end
			end
			return x
		end
		return -1
	end
}
man_koufeng:addSkill(manhuaibingbf)

man_mifang = sgs.General(shixinrumo_man,"man_mifang","shu",4)
manhuoe = sgs.CreateTriggerSkillV2{
	name = "manhuoe",
	events = {sgs.EventPhaseStart,sgs.CardEffected,sgs.CardFinished},
	priority = {2,0},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.EventPhaseStart then
			if invoker:getPhase()==sgs.Player_Finish and invoker:hasSkill(skill) then
				local tps = sgs.SPlayerList()
				local dc = dummyCard("fire_attack",skill:objectName())
				for _,p in sgs.qlist(room:getOtherPlayers(invoker))do
					if invoker:canUse(dc,p) then tps:append(p) end
				end
				local tps = room:askForPlayersChosen(invoker,tps,skill:objectName(),0,4,"manhuoe0")
				if tps:length()>0 then room:useCard(sgs.CardUseStruct(dc,invoker,tps)) end
			end
		elseif event==sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("FireAttack") and table.contains(use.card:getSkillNames(),skill:objectName()) then
				local dc = dummyCard()
				local n = 0
				for _,p in sgs.qlist(use.to)do
					local sc = use.card:getTag("manhuoeSC-"..p:objectName()):toCard()
					if sc then
						n = n+sc:getNumber()
						dc:addSubcard(sc)
					end
				end
				if dc:subcardsLength()>0 then
					room:fillAG(dc:getSubcards(),invoker)
					local tp = room:askForPlayerChosen(invoker,room:getAlivePlayers(),skill:objectName(),"manhuoe1")
					if tp then tp:obtainCard(dc) end
					room:clearAG(invoker)
				end
				if n<13 then
					room:loseHp(invoker,1,true,invoker,skill:objectName())
				end
			end
		elseif event==sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("FireAttack") and table.contains(effect.card:getSkillNames(),skill:objectName()) then
				if effect.to:getHandcardNum()>0 and effect.from:getMark("manhuoeBanTo-Clear")<1 then
					local sc = room:askForCardShow(effect.to,effect.from,"fire_attack")
					room:showCard(effect.to,sc:getEffectiveId())
					effect.card:setTag("manhuoeSC-"..effect.to:objectName(),ToData(sc))
					local suit = sc:getSuitString()
					local suit_png = suit
					if sc:hasSuit() then
						suit_png = "<img src='image/system/cardsuit/"..suit..".png' height=17/>"
					end
					if effect.from:isAlive() then
						for _,h in sgs.qlist(effect.from:getHandcards())do
							if h:getSuitString()==suit and effect.from:canDiscard(effect.from,h:getId()) then
								if room:askForCard(effect.from,".|"..suit.."!","@fire-attack:"..effect.to:objectName().."::"..suit_png,data) then
									room:damage(sgs.DamageStruct(effect.card,effect.from,effect.to,1,sgs.DamageStruct_Fire))
									effect.from:addMark("manhuoeBanTo-Clear")
								else
									effect.from:setFlags("FireAttackFailed_"..effect.to:objectName())
								end
								break
							end
						end
						if effect.from:getMark("manhuoeBanTo-Clear")<1 and effect.from:isAlive() and effect.to:isAlive() then
							room:doGongxin(effect.to,effect.from,sgs.IntList(),skill:objectName())
						end
					end
				end
				effect.to:setFlags("Global_NonSkillNullify")
				return true
			end
		end
		return false
	end
}
man_mifang:addSkill(manhuoe)
mantanduo = sgs.CreateTriggerSkillV2{
	name = "mantanduo",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		if event==sgs.EventPhaseChanging then
	     	local change = data:toPhaseChange()
			if change.to==sgs.Player_Discard and player:getHandcardNum()>player:getMaxCards() then
				room:sendCompulsoryTriggerLog(player,skill)
				change.to = sgs.Player_Draw
				data:setValue(change)
			end
		end
		return false
	end
}
man_mifang:addSkill(mantanduo)

man_yujin = sgs.General(shixinrumo_man,"man_yujin","shu",4)
mansuwu = sgs.CreateTriggerSkillV2{
	name = "mansuwu",
	events = {sgs.EventPhaseStart,sgs.CardUsed,sgs.PreCardUsed,sgs.CardFinished},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.EventPhaseStart then
			if invoker:getPhase()==sgs.Player_Start and invoker:hasSkill(skill) then
				local tps = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers())do
					if p:getHandcardNum()>0 then tps:append(p) end
				end
				tps = room:askForPlayersChosen(invoker,tps,skill:objectName(),0,4,"mansuwu0",true,true)
				for _,p in sgs.qlist(tps)do
					linkCard(room,room:askForCardChosen(invoker,p,"h",skill:objectName()))
				end
			end
		elseif event==sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:isDamageCard() and invoker:getMark("mansuwuUse-Clear")<1 then
				for _,h in sgs.qlist(invoker:getHandcards())do
					if h:hasFlag("link_card") then
						room:setCardFlag(use.card,"mansuwuBf")
						invoker:addMark("mansuwuUse-Clear")
						break
					end
				end
			end
		elseif event==sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:hasFlag("mansuwuBf") then
				for _,p in sgs.qlist(room:getAllPlayers())do
					if p:hasSkill(skill) then
						for _,h in sgs.qlist(p:getHandcards())do
							if h:hasFlag("link_card") then
								room:sendCompulsoryTriggerLog(p,skill:objectName())
								room:setCardFlag(use.card,"mansuwuUse")
								local list = use.no_respond_list
								table.insert(list,"_ALL_TARGETS")
								use.no_respond_list = list
								data:setValue(use)
								break
							end
						end
					end
				end
			end
		elseif event==sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:hasFlag("mansuwuUse") then
				invoker:drawCards(2,skill:objectName())
			end
		end
		return false
	end
}
man_yujin:addSkill(mansuwu)
manrenwangvs = sgs.CreateViewAsSkillV2{
	name = "manrenwang",
	n = 1,
	response_or_use = true,
	-- 「每回合限一次」由 SkillV2 usage 計量（回合域）
	limit_scope = sgs.Skill_Limit_Turn,
	max_usage_limit = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not (player and player:isAlive()) then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return dummyCard("peach"):isAvailable(player)
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern() or ""
			return string.find(pattern,"peach") and player:hasTurn()
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		return candidate and candidate:hasFlag("link_card")
			and request:getSelectedCardIds():isEmpty()
	end,
	create_card = function(skill, request)
		local dc = sgs.Sanguosha:cloneCard("peach")
		dc:setSkillName("manrenwang")
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			dc:addSubcard(id)
		end
		return dc
	end,
}
manrenwang = sgs.CreateTriggerSkillV2{
	name = "manrenwang",
	view_as_skill = manrenwangvs,
}
man_yujin:addSkill(manrenwang)

man_guanyinping = sgs.General(shixinrumo_man,"man_guanyinping","shu",4,false)
manyinmou = sgs.CreateTriggerSkillV2{
	name = "manyinmou",
	events = {sgs.EventPhaseStart,sgs.EventForDiy},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.EventPhaseStart then
			if invoker:getPhase()==sgs.Player_Finish and invoker:isMale() then
				for _,p in sgs.qlist(room:getAllPlayers())do
					if p:hasSkill(skill) then
						local pids = {}
						for _,h in sgs.qlist(invoker:getHandcards())do
							if h:hasFlag("link_card") then continue end
							table.insert(pids,h:getId())
						end
						local tids = sgs.IntList()
						for _,h in sgs.qlist(p:getHandcards())do
							if h:hasFlag("link_card") then tids:append(h:getId()) end
						end
						if #pids>0 and p:getHandcardNum()>tids:length() then
							local c = room:askForCard(invoker,table.concat(pids,","),"manyinmou0:"..p:objectName(),ToData(p),sgs.Card_MethodNone)
							if c then
								invoker:skillInvoked(skill,-1,p)
								local id = room:askForCardChosen(invoker,p,"h",skill:objectName(),false,sgs.Card_MethodNone,ids)
								linkCard(room,c:getId())
								linkCard(room,id)
							end
						end
					end
				end
			end
		elseif event==sgs.EventForDiy then
			local str = data:toString()
			if str:startsWith("link_card_dis:") then
				local strs = str:split(":")
				for _,p in sgs.qlist(room:getAllPlayers())do
					if string.find(str,p:objectName().."=") and p:getMark("manyinmouUse-Clear")<1 and p:hasSkill(skill) then
						room:sendCompulsoryTriggerLog(p,skill)
						p:addMark("manyinmouUse-Clear")
						local aps = sgs.SPlayerList()
						for _,q in sgs.qlist(room:getAllPlayers())do
							if string.find(str,q:objectName().."=")
							then aps:append(q) end
						end
						room:drawCards(aps,math.min(#strs-1,5),skill:objectName())
					end
				end
			end
		end
		return false
	end
}
man_guanyinping:addSkill(manyinmou)
manquchiCard = sgs.CreateSkillCard{
	name = "manquchiCard",
	filter = function(self,targets,to_select,from)
		return #targets<1
	end,
	on_use = function(self,room,source,targets)
		for _,to in sgs.list(targets)do
			local x = 1
			for _,h in sgs.qlist(to:getHandcards())do
				if h:hasFlag("link_card") then
					linkCard(room,h:getId())
					x = 2
				end
			end
			room:damage(sgs.DamageStruct("manquchi",source,to,x,sgs.DamageStruct_Fire))
		end
	end
}
manquchi = sgs.CreateViewAsSkillV2{
	name = "manquchi",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:usedTimes("#manquchiCard") < 1
	end,
	create_card = function(skill, request)
		return manquchiCard:clone()
	end,
}
man_guanyinping:addSkill(manquchi)




-- DEFER-ADJACENT: 全局联动弃牌规则技。V2 需要持有者实例，故改名隐藏技能并挂到所有武将。
shixinrumo_global = sgs.CreateTriggerSkillV2{
	name = "#shixinrumo_global",
	global = true,
	events = {sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if event~=sgs.CardsMoveOneTime then return false end
     	local move = data:toMoveOneTime()
		if move.from_places:contains(sgs.Player_PlaceHand) and move.from then
			return skill:objectName(), move.from:objectName()
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		-- V2 觸發需要持有者實例：為缺少實例的角色補掛（晚於本擴展載入的武將/換將）
		for _,p in sgs.qlist(room:getAllPlayers())do
			if p:getSkillInstanceIds(skill:objectName()):isEmpty() then
				room:attachSkillToPlayer(p,skill:objectName())
			end
		end
		local data = ctx.original_data
		if event==sgs.CardsMoveOneTime then
	     	local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceHand)
			and move.from:objectName()==player:objectName() and move.reason.m_skillName~="link_card" then
				if bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_DISCARD
				or move.reason.m_reason==sgs.CardMoveReason_S_REASON_RESPONSE or move.reason.m_reason==sgs.CardMoveReason_S_REASON_USE then
					local lids = {}
					for _,id in sgs.qlist(move.card_ids)do
						if sgs.Sanguosha:getCard(id):hasFlag("link_card")
						then table.insert(lids,id) end
					end
					if #lids<1 then return end
					local plc = {"link_card_dis"}
					table.insert(plc,player:objectName().."="..table.concat(lids,"+"))
					local moves = sgs.CardsMoveList()
					local log = sgs.LogMessage()
					log.type = "$link_card_dis"
					for _,p in sgs.qlist(room:getAllPlayers())do
						local ids = sgs.IntList()
						for _,h in sgs.qlist(p:getHandcards())do
							if h:hasFlag("link_card") and p:canDiscard(p,h:getId())
							then ids:append(h:getId()) end
						end
						if ids:isEmpty() then continue end
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD,p:objectName(),"link_card","")
						moves:append(sgs.CardsMoveStruct(ids,nil,sgs.Player_Discard,reason))
						log.card_str = table.concat(sgs.QList2Table(ids),"+")
						table.insert(plc,p:objectName().."="..log.card_str)
						log.from = p
						room:sendLog(log)
					end
					room:moveCardsAtomic(moves,true)
					plc = ToData(table.concat(plc,":"))
					room:getThread():trigger(sgs.EventForDiy,room,player,plc)
				end
			end
		end
		return false
	end,
}
addToSkills(shixinrumo_global)
-- V2 全局規則技：挂到所有武將作 bootstrap（隱藏 # 名不顯示）
for _,gen in sgs.qlist(sgs.Sanguosha:getAllGenerals())do
	gen:addSkill("#shixinrumo_global")
end

function linkCard(room,id)
	if sgs.Sanguosha:getCard(id):hasFlag("link_card") then
		room:setCardFlag(id,"-link_card")
		room:setCardFlag(id,"-visible")
		room:setCardTip(id,"-link_card")
	else
		room:setCardFlag(id,"link_card")
		room:setCardFlag(id,"visible")
		room:setCardTip(id,"link_card")
	end
end

sgs.LoadTranslationTable {
	["shixinrumo_man"] = "蚀心入魔·慢",
	
	["man_guanyu"] = "慢关羽",
	["#man_guanyu"] = "四海仰鼻息",
    ["illustrator:man_guanyu"] = "小罗没想好",
	["manhanguo"] = "撼国",
	[":manhanguo"] = "每轮开始时，你可以选择一名上轮未选择的其他角色，将其所有牌扣置于其武将牌旁，直到本轮结束，本轮内：当你使用【杀】对其造成伤害后，其死亡；其可以发动无势力限制的“护驾”，且响应的角色获得你一张牌。",
	["manhanguo0"] = "你可以发动“撼国”选择角色扣置其的牌",
	["manweiwo"] = "唯我",
	[":manweiwo"] = "限定技，结束阶段，你可以选择至多3名其他角色，这些角色个获得“仁德”、“青囊”、“龙吟”中的一个不同技能，这些技能仅能对你发动，然后你获得“武神”。",
	["manweiwo0"] = "你可以发动“唯我”选择至多3名其他角色获得技能",

	["man_yanliangwenchou"] = "慢颜良文丑",
	["#man_yanliangwenchou"] = "土鸡瓦犬",
    ["illustrator:man_yanliangwenchou"] = "城与橙与程",
	["manhaibian"] = "骇变",
	[":manhaibian"] = "每回合开始时，若你上回合使用过手牌，则上回合最后一张黑色牌和最后一张红色牌的使用者依次可以视为使用一张【决斗】。",
	["manhaibian0"] = "骇变：你可以视为使用【决斗】",
	["manqiewang"] = "怯亡",
	[":manqiewang"] = "锁定技，当与你距离1以内的角色受到伤害后，你摸一张牌，本回合你的手牌均视为【无懈可击】。",

	["man_luxun"] = "慢陆逊",
	["#man_luxun"] = "孺子为将",
    ["illustrator:man_luxun"] = "小罗没想好",
	["manchanyu"] = "谄谀",
	[":manchanyu"] = "出牌阶段限一次，你可以令一名其他角色摸等同其体力值的牌，然后你与其各自用点数最小的手牌进行拼点：双方展示手牌，赢的角色可以交换双方一种颜色或类别的所有手牌。",
	["manchanyu0"] = "请选择一张点数最小的手牌拼点",
	["mancongfeng"] = "从风",
	[":mancongfeng"] = "转换技，当你指定或成为牌的目标后，你可以①与使用者各摸一张牌②弃置使用者两张牌。",
	[":mancongfeng1"] = "转换技，当你指定或成为牌的目标后，你可以①与使用者各摸一张牌<font color=\"#01A5AF\"><s>②弃置使用者两张牌</s></font>。",
	[":mancongfeng2"] = "转换技，当你指定或成为牌的目标后，你可以<font color=\"#01A5AF\"><s>①与使用者各摸一张牌</s></font>②弃置使用者两张牌。",

	["man_lvmeng"] = "慢吕蒙",
	["#man_lvmeng"] = "病入膏肓",
    ["illustrator:man_lvmeng"] = "小罗没想好",
	["mankongzhi"] = "空志",
	[":mankongzhi"] = "锁定技，当你使用【杀】指定唯一目标后，你获得其至多3张牌；若你已受伤，普通锦囊牌对你无效且你的基本牌视为【闪】。",
	["manbizha"] = "鄙诈",
	[":manbizha"] = "结束阶段，你可以摸一张牌，然后进行拼点：若对方没赢，其失去2点体力，你观看其所有手牌且可以使用其中至多两张点数小于其拼点牌的牌；若你没赢，你扣减1点体力上限。",
	["manbizha0"] = "鄙诈：请选择与一名角色拼点",
	["manbizha1"] = "鄙诈：你可以使用其手牌中点数小于%src的牌",

	["man_pangde"] = "慢庞德",
	["#man_pangde"] = "狂徒",
    ["illustrator:man_pangde"] = "城与橙与程",
	["mannuozhan"] = "搦战",
	[":mannuozhan"] = "准备阶段，你可以摸一张牌并令一名其他角色声明一种伤害牌，然后你选择视为你对其使用或其对你使用此牌且伤害+1，若此牌未对目标造成伤害，使用者失去1点体力，你可以再对相同角色发动此技能。",
	["mannuozhan0"] = "你可以发动“搦战”选择一名其他角色",
	["#mannuozhanLog"] = "%from 选择声明 %arg",
	["mannuozhan1"] = "视为你对其使用",
	["mannuozhan2"] = "视为其对你使用",
	["mannuozhan3"] = "搦战选择",

	["man_koufeng"] = "慢寇封",
	["#man_koufeng"] = "不动如山",
    ["illustrator:man_koufeng"] = "城与橙与程",
	["manhuaibing"] = "怀兵",
	[":manhuaibing"] = "准备阶段，你可以获得两名角色各一张手牌，然后展示所有手牌，令其中体力较小的角色下个摸牌阶段摸牌数、出牌阶段使用【杀】次数、弃牌阶段手牌上限改为其中红色牌数。",
	["manhuaibian0"] = "你可以发动“怀兵”选择2名角色获得手牌",

	["man_mifang"] = "慢糜芳",
	["#man_mifang"] = "负荆之臣",
    ["illustrator:man_mifang"] = "城与橙与程",
	["manhuoe"] = "火厄",
	[":manhuoe"] = "结束阶段，你可以视为对至多4名其他角色使用【火攻】（若你可以弃置同花色的牌，则弃置之并取消其余目标，否则当前目标观看你的手牌），结算后将因此展示的牌交给任意角色，若这些牌点数之和小于13，你失去1点体力。",
	["manhuoe0"] = "你可以发动“火厄”选择对至多4名其他角色使用【火攻】",
	["manhuoe1"] = "火厄：请将这些牌交给一名角色",
	["mantanduo"] = "贪惰",
	[":mantanduo"] = "锁定技，你需要弃置牌的弃牌阶段改为摸牌阶段。",

	["man_yujin"] = "慢于禁",
	["#man_yujin"] = "立地成佛",
    ["illustrator:man_yujin"] = "城与橙与程",
	["mansuwu"] = "肃伍",
	[":mansuwu"] = "准备阶段，你可以连接至多4名角色各一张手牌；若你有连接牌，有连接牌的角色每回合首次使用的伤害牌不能被响应，且结算后其摸两张牌。",
	["mansuwu0"] = "你可以发动“肃伍”选择至多4名角色",
	["manrenwang"] = "仁王",
	[":manrenwang"] = "每回合限一次，你可以将你的一张连接牌当做【桃】使用。",

	["link_card"] = "连接",
	["$link_card_dis"] = "%from 弃置连接牌 %card",

	["man_guanyinping"] = "慢关银屏",
	["#man_guanyinping"] = "天骄虎女",
    ["illustrator:man_guanyinping"] = "小罗没想好",
	["manyinmou"] = "姻谋",
	[":manyinmou"] = "男性角色的结束阶段，其可以连接你与其各一张未连接的手牌；当你每回合首次失去连接牌后，本次一同失去连接牌的角色依次摸X张牌（X为这些角色数，至多为5）。",
	["manquchi"] = "驱斥",
	[":manquchi"] = "出牌阶段限一次，你可以对一名角色造成1点火焰伤害，若其有连接牌，重置之并令此伤害+1。",



}




local function getShimingRef(p, skill)
	return sgs.SkillInstanceRef(p:objectName(), sgs.SkillInstanceKey(skill:objectName(), p:getSkillInstanceId(skill:objectName())))
end

local shixinrumo_chen = sgs.Package("shixinrumo_chen",sgs.Package_GeneralPack)
chen_zhouyu = sgs.General(shixinrumo_chen,"chen_zhouyu","demon",4)
chenjiehuo = sgs.CreateTriggerSkillV2{
	name = "chenjiehuo",
	shiming_skill = true,
	events = {sgs.EventPhaseStart,sgs.ConfirmDamage},
	can_trigger = function(skill, event, room, player, data)
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.ConfirmDamage then
			local damage = data:toDamage()
			for i,p in sgs.qlist(room:getAllPlayers())do
				if p:getMark("&chenjiehuo+#use")>0 then
					room:setPlayerMark(p,"&chenjiehuo+#use",0)
					room:sendCompulsoryTriggerLog(p,skill)
					damage.damage = 3
					damage.nature = sgs.DamageStruct_Fire
					data:setValue(damage)
					if damage.from~=p then
						room:sendShimingLog(getShimingRef(p, skill), false)
						room:loseMaxHp(p,1,skill:objectName())
					end
				end
			end
		else
			if invoker:isAlive() and invoker:getPhase()==sgs.Player_RoundStart and invoker:getMark("chenjiehuo")<1
			and invoker:hasSkill(skill:objectName()) and invoker:askForSkillInvoke(skill:objectName()) then
				room:setPlayerMark(invoker,"&chenjiehuo+#use",1)
			end
		end
		return false
	end
}
chen_zhouyu:addSkill(chenjiehuo)
chenxiangerCard = sgs.CreateSkillCard{
	name = "chenxiangerCard",
	filter = function(self,targets,to_selec,source)
		return #targets<1
	end,
	on_use = function(self,room,source,targets)
		for i,p in sgs.list(targets)do
			room:setPlayerMark(p,"&chenxianger+#"..source:objectName(),1)
			room:setPlayerCardLimitation(p,"use",".|.|7~13",false)
			p:setMark("chenxiangerNum",0)
		end
	end,
}
chenxiangervs = sgs.CreateViewAsSkillV2{
	name = "chenxianger",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:usedTimes("#chenxiangerCard") < 1
			and player:getMark("chenxianger") < 1
	end,
	create_card = function(skill, request)
		return chenxiangerCard:clone()
	end,
}
chenxianger = sgs.CreateTriggerSkillV2{
	name = "chenxianger",
	view_as_skill = chenxiangervs,
	events = {sgs.EventPhaseProceeding,sgs.DamageDone},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.EventPhaseProceeding then
	     	if(invoker:getPhase()==sgs.Player_Finish)then
				for i,p in sgs.list(room:getAllPlayers())do
					if(invoker:getMark("&chenxianger+#"..p:objectName())>0)then
						room:setPlayerMark(invoker,"&chenxianger+#"..p:objectName(),0)
						room:recover(invoker,sgs.RecoverStruct(skill:objectName(),p,2))
						room:removePlayerCardLimitation(invoker,"use",".|.|7~13")
						if(invoker:getMark("chenxiangerNum")<2)then
							room:sendShimingLog(getShimingRef(p, skill), false)
							room:loseMaxHp(p,1,skill:objectName())
						end
					end
				end
			end
		elseif event==sgs.DamageDone then
			local damage = data:toDamage()
			invoker:addMark("chenxiangerNum",damage.damage)
		end
		return false
	end
}
chen_zhouyu:addSkill(chenxianger)
chenmieguo = sgs.CreateTriggerSkillV2{
	name = "chenmieguo",
	waked_skills = "#chenmieguobf",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.EventPhaseStart then
			if invoker:getPhase()==sgs.Player_NotActive then
				if invoker:getTag("Global_ExtraTurn"):toBool() then
					for i,p in sgs.qlist(room:getAlivePlayers())do
						room:setPlayerMark(p,"&chenmieguo_ban+#"..invoker:objectName(),0)
					end
					if invoker:getMark("chenmieguoBf")>0 then
						invoker:setMark("chenmieguoBf",0)
						-- 「此額外回合未使用牌」：以本 turn 域嘅 use_card 事件取代 chenmieguoUse 標記
						local used = false
						local turn = room:historyScopes().turn_id
						if turn and tostring(turn)~="0" then
							local ufilter = {kind="use_card",turn_id=turn,
								from=invoker:objectName(),limit=8}
							local upage = room:queryHistoryEvents(ufilter)
							if not (upage.error or not upage.complete or not upage.attribution_complete) then
								local uwatermark = upage.watermark
								while not used do
									for _,ev in ipairs(upage.items or {})do
										local ud = ev.data or {}
										if (tonumber(tostring((ud.card or {}).type)) or 0)>0 then
											used = true
											break
										end
									end
									if used or not upage.has_more then break end
									ufilter.after = upage.next_after
									ufilter.watermark = uwatermark
									upage = room:queryHistoryEvents(ufilter)
									if upage.error or not upage.complete or not upage.attribution_complete then break end
								end
							end
						end
						if not used then
							room:sendShimingLog(getShimingRef(invoker, skill), false)
							room:loseMaxHp(invoker,1,skill:objectName())
						end
					end
				else
					if invoker:getMark("chenmieguo")<1 and invoker:hasSkill(skill) then
						local tps = sgs.SPlayerList()
						for i,p in sgs.qlist(room:getOtherPlayers(invoker))do
							if p:getCardCount()>0 then tps:append(p) end
						end
						local tp = room:askForPlayerChosen(invoker,tps,skill:objectName(),"chenmieguo0",true,true)
						if tp then
							local dc = dummyCard()
							for i=1,3 do
								local id = room:askForCardChosen(invoker,tp,"he",skill:objectName(),false,sgs.Card_MethodNone,dc:getSubcards(),true)
								if id<0 then break end
								dc:addSubcard(id)
								if dc:subcardsLength()>=tp:getCardCount()
								then break end
							end
							invoker:obtainCard(dc,false)
							local x = dc:subcardsLength()
							local tps = room:askForPlayersChosen(tp,room:getAlivePlayers(),skill:objectName(),x,x,"chenmieguo1:"..x)
							for i,p in sgs.qlist(tps)do
								room:doAnimate(1,tp:objectName(),p:objectName())
								room:setPlayerMark(p,"&chenmieguo_ban+#"..invoker:objectName(),1)
							end
							invoker:setMark("chenmieguoBf",1)
							invoker:gainAnExtraTurn()
						end
					end
				end
			end
		end
		return false
	end
}
chen_zhouyu:addSkill(chenmieguo)
-- DEFER:chenmieguobf:sgs.CreateProhibitSkill has no SkillV2 equivalent
chenmieguobf = sgs.CreateProhibitSkill{
	name = "#chenmieguobf",
	is_prohibited = function(self,from,to,card)
		if card:getTypeId()>0 then
			return to and to:getMark("&chenmieguo_ban+#"..from:objectName())>0
		end
	end
}
chen_zhouyu:addSkill(chenmieguobf)

chen_zhugeliang = sgs.General(shixinrumo_chen,"chen_zhugeliang","shu",3)
chenbingquvs = sgs.CreateViewAsSkillV2{
	name = "chenbingqu",
	n = 999,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
			and request:getPattern() == "@@chenbingqu!"
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		return candidate and player
			and request:getSelectedCardIds():length() < player:getHandcardNum()/2
			and not candidate:isEquipped()
	end,
	card_selection_feasible = function(skill, request)
		local player = request:getInitiator()
		return player and request:getSelectedCardIds():length() >= player:getHandcardNum()/2
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		local dc = sgs.Sanguosha:cloneCard(player:property("chenbingquCn"):toString())
		dc:setSkillName("_chenbingqu")
		for _,id in sgs.qlist(request:getSelectedCardIds())do
			dc:addSubcard(id)
		end
		return dc
	end,
}
chenbingqu = sgs.CreateTriggerSkillV2{
	name = "chenbingqu",
	events = {sgs.EventPhaseStart},
	view_as_skill = chenbingquvs,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		local invoker = ctx.invoker
		if event==sgs.EventPhaseStart then
			if invoker:getPhase()==sgs.Player_Start then
				local tp = room:askForPlayerChosen(invoker,room:getOtherPlayers(invoker),skill:objectName(),"chenbingqu0",true,true)
				if tp then
					local p2cn = {}
					local msg = sgs.LogMessage()
					msg.type = "#ShouxiChoice"
					local cns = sgs.Sanguosha:getCardNames("TrickCard+^DelayedTrick")
					for i,p in sgs.qlist(SPlayerList(invoker,tp))do
						local choices = {}
						for i,cn in sgs.list(cns)do
							if cn==msg.arg then continue end
							local dc = dummyCard(cn,"chenbingqu")
							if dc:isAvailable(p) then
								table.insert(choices,cn)
							end
						end
						if #choices<1 then continue end
						msg.from = p
						msg.arg = room:askForChoice(p,skill:objectName(),table.concat(choices,"+"),ToData((i<1 and tp or invoker)))
						p2cn[p:objectName()] = msg.arg
						room:sendLog(msg)
					end
					for i,p in sgs.qlist(SPlayerList(invoker,tp))do
						local cn = p2cn[(i<1 and tp:objectName() or invoker:objectName())]
						room:setPlayerProperty(p,"chenbingquCn",ToData(cn))
						room:askForUseCard(p,"@@chenbingqu!","chenbingqu1:"..cn)
					end
				end
			end
		end
		return false
	end
}
chen_zhugeliang:addSkill(chenbingqu)
chenfanxin = sgs.CreateTriggerSkillV2{
	name = "chenfanxin",
	events = {sgs.GameStart,sgs.Death,sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.EventPhaseStart then
			if invoker:getPhase()==sgs.Player_RoundStart and invoker:getMark("&wrath")>0 then
				for i,p in sgs.qlist(room:getOtherPlayers(invoker))do
					if invoker:getMark("&chenfanxin+#"..p:objectName())>0 and p:askForSkillInvoke(skill,invoker) then
						local choices = {}
						for i=1,math.min(5,invoker:getMark("&wrath")) do
							table.insert(choices,"1="..i)
						end
						local choice = room:askForChoice(p,skill:objectName(),table.concat(choices,"+"),ToData(invoker))
						local x = tonumber(choice:split("=")[2])
						invoker:loseMark("&wrath",x)
						p:drawCards(x,skill:objectName())
						if invoker:getMark("&wrath")<1 then break end
					end
				end
			end
		else
			if event==sgs.Death then
				local death = data:toDeath()
				if death.who==invoker or death.who:getMark("&chenfanxin+#"..invoker:objectName())<1 then
					return false
				end
			end
			if invoker:isAlive() and invoker:hasSkill(skill) then
				local tp = room:askForPlayerChosen(invoker,room:getOtherPlayers(invoker),skill:objectName(),"chenfanxin0",true,true)
				if tp then
					room:setPlayerMark(tp,"&chenfanxin+#"..invoker:objectName(),1)
					room:handleAcquireDetachSkills(tp,"kuangbao|wumou")
				end
			end
		end
		return false
	end
}
chen_zhugeliang:addSkill(chenfanxin)

chen_zhaoyun = sgs.General(shixinrumo_chen,"chen_zhaoyun","shu",4)
chenzhaduo = sgs.CreateTriggerSkillV2{
	name = "chenzhaduo",
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		local invoker = ctx.invoker
		if event==sgs.EventPhaseStart then
			if invoker:getPhase()==sgs.Player_Finish then
				local tps = sgs.SPlayerList()
				for i,p in sgs.list(room:getOtherPlayers(invoker))do
					if p:getCardCount()>0 then tps:append(p) end
				end
				tps = room:askForPlayersChosen(invoker,tps,skill:objectName(),-1,2,"chenzhaduo0",true,false)
				if tps:length()<2 then return false end
				for i,p in sgs.list(tps)do
					local id = room:askForCardChosen(invoker,p,"he",skill:objectName())
					room:obtainCard(invoker,id,false)
				end
				local dc = dummyCard(nil,"_chenzhaduo")
				if invoker:canSlash(tps:first(),dc,false) then
					local skills = {}
					for i,s in sgs.qlist(tps:last():getVisibleSkillList())do
						if s:isAttachedLordSkill() or invoker:hasSkill(s,true) then continue end
						table.insert(skills,s:objectName())
					end
					room:handleAcquireDetachSkills(invoker,table.concat(skills,"|"))
					room:useCard(sgs.CardUseStruct(dc,invoker,tps:first()))
					local skills2 = {}
					for i,s in sgs.list(skills)do
						table.insert(skills2,"-"..s)
					end
					room:handleAcquireDetachSkills(invoker,table.concat(skills2,"|"))
				end
				dc = dummyCard("duel","_chenzhaduo")
				if tps:last():canUse(dc,invoker) then
					local skills = {}
					for i,s in sgs.list(tps:first():getVisibleSkillList())do
						if s:isAttachedLordSkill() or invoker:hasSkill(s,true) then continue end
						table.insert(skills,s:objectName())
					end
					room:handleAcquireDetachSkills(invoker,table.concat(skills,"|"))
					room:useCard(sgs.CardUseStruct(dc,tps:last(),invoker))
					local skills2 = {}
					for i,s in sgs.list(skills)do
						table.insert(skills2,"-"..s)
					end
					room:handleAcquireDetachSkills(invoker,table.concat(skills2,"|"))
				end
			end
		end
		return false
	end
}
chen_zhaoyun:addSkill(chenzhaduo)

chen_zhangzhao = sgs.General(shixinrumo_chen,"chen_zhangzhao","wu",3)
chenxiezhongvs = sgs.CreateViewAsSkillV2{
	name = "chenxiezhong",
	n = 2,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not (player and player:isAlive()) then return false end
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local pattern = request:getPattern()
		return pattern and string.find(pattern,"chenxiezhong")
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 2
	end,
	create_card = function(skill, request)
		local dc = sgs.Sanguosha:cloneCard("slash")
		dc:setSkillName("_chenxiezhong")
		for _,id in sgs.qlist(request:getSelectedCardIds())do
			dc:addSubcard(id)
		end
		return dc
	end,
}
chenxiezhong = sgs.CreateTriggerSkillV2{
	name = "chenxiezhong",
	events = {sgs.EventPhaseStart},
	view_as_skill = chenxiezhongvs,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		local invoker = ctx.invoker
		if event==sgs.EventPhaseStart then
			if invoker:getPhase()==sgs.Player_Start then
				local x = (invoker:aliveCount()+1)/2
				local tps = room:askForPlayersChosen(invoker,room:getAlivePlayers(),skill:objectName(),-1,x,"chenxiezhong0",true)
				if tps:length()<x then return false end
				local slash = 0
				local draw = 0
				local aps = sgs.SPlayerList()
				for i,p in sgs.list(room:getAllPlayers())do
					if tps:contains(p) then
						if p:getCardCount()>1 and room:askForUseCard(p,"@@chenxiezhong","chenxiezhongy1")
						then slash = slash+1 continue end
						p:drawCards(2,skill:objectName())
						room:loseHp(p,1,true,invoker,skill:objectName())
						draw = draw+1
					else
						aps:append(p)
					end
				end
				if invoker:isDead() then return false end
				local choices = {}
				if slash>=draw then
					table.insert(choices,"xz_slash")
				end
				if draw>=slash then
					table.insert(choices,"xz_draw")
				end
				local choice = room:askForChoice(invoker,skill:objectName(),table.concat(choices,"+"))
				local tp = room:askForPlayerChosen(invoker,aps,skill:objectName(),"chenxiezhong2:"..choice,true)
				if tp then
					room:doAnimate(1,invoker:objectName(),tp:objectName())
					for i=0,1 do
						if choice=="xz_slash" then
							if tp:getCardCount()>1 and sgs.Slash_IsAvailable(tp) then
								room:askForUseCard(tp,"@@chenxiezhong!","chenxiezhong3")
							end
						else
							tp:drawCards(2,skill:objectName())
							room:loseHp(tp,1,true,invoker,skill:objectName())
						end
					end
				end
			end
		end
		return false
	end
}
chen_zhangzhao:addSkill(chenxiezhong)
chenqishi = sgs.CreateTriggerSkillV2{
	name = "chenqishi",
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	dynamic_frequency = function(skill,target)
		if target:getMark("chenqishiCompulsory")>0 then
			return sgs.Skill_Compulsory
		end
		return sgs.Skill_NotFrequent
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.EventPhaseStart then
			if invoker:getPhase()==sgs.Player_Finish and invoker:hasSkill(skill) then
				-- 以 Resolution History 查本回合由其他角色置入棄牌堆嘅牌，
				-- 取代舊版 id.."chenqishiId-Clear" 標記。
				local others = {}
				for _,p in sgs.list(room:getAlivePlayers())do
					if p~=invoker then others[p:objectName()] = true end
				end
				local put = {}
				local turn = room:historyScopes().turn_id
				if turn and tostring(turn)~="0" then
					local mfilter = {turn_id = turn, limit = 64}
					local mpage = room:queryHistoryMoves(mfilter)
					if not (mpage.error or not mpage.complete or not mpage.attribution_complete) then
						local mwatermark = mpage.watermark
						while true do
							for _,fact in ipairs(mpage.items or {})do
								local d = fact.data or {}
								if d.to_place==sgs.Player_DiscardPile and d.card_id then
									if (d.from_place==sgs.Player_PlaceHand
										or d.from_place==sgs.Player_PlaceEquip)
									and others[tostring(d.from or "")] then
										put[d.card_id] = true
									elseif d.from_place==sgs.Player_PlaceTable
									and others[tostring(d.reason_player or "")] then
										put[d.card_id] = true
									end
								end
							end
							if not mpage.has_more then break end
							mfilter.after = mpage.next_after
							mfilter.watermark = mwatermark
							mpage = room:queryHistoryMoves(mfilter)
							if mpage.error or not mpage.complete
							or not mpage.attribution_complete then break end
						end
					end
				end
				local ids = sgs.IntList()
				for i,id in sgs.qlist(room:getDiscardPile())do
					if put[id] then ids:append(id) end
				end
				if ids:isEmpty() then return end
				if skill:getFrequency(invoker)==sgs.Skill_Compulsory then
					room:sendCompulsoryTriggerLog(invoker,skill)
				elseif not invoker:askForSkillInvoke(skill,ToData(ids)) then return end
				room:setPlayerMark(invoker,"chenqishiCompulsory",1)
				room:changeTranslation(invoker,skill:objectName(),1)
				local dc = dummyCard()
				room:fillAG(ids,invoker)
				local x = math.min(5,ids:length())
				for i=1,x do
					local id = room:askForAG(invoker,ids,i>1,skill:objectName())
					if id<0 then break end
					ids:removeOne(id)
					dc:addSubcard(id)
					room:takeAG(invoker,id,false,SPlayerList(invoker))
				end
				room:clearAG(invoker)
				room:setPlayerMark(invoker,"&chenqishi+#bf",1)
				invoker:obtainCard(dc)
			end
		elseif event==sgs.EventPhaseChanging then
	     	local change = data:toPhaseChange()
			if change.to==sgs.Player_Draw and invoker:getMark("&chenqishi+#bf")>0 then
				room:setPlayerMark(invoker,"&chenqishi+#bf",0)
				room:sendCompulsoryTriggerLog(invoker,skill:objectName())
				invoker:skip(sgs.Player_Draw)
			end
		end
		return false
	end
}
chen_zhangzhao:addSkill(chenqishi)

chen_lusu = sgs.General(shixinrumo_chen,"chen_lusu","wu",3)
chenwanliCard = sgs.CreateSkillCard{
	name = "chenwanliCard",
	filter = function(self,targets,to_selec,source)
		return #targets<1 and to_selec~=source
	end,
	on_use = function(self,room,source,targets)
		for i,p in sgs.list(targets)do
			room:setPlayerMark(p,"&chenwanli+:+"..self:subcardsLength().."+#"..source:objectName(),4)
			room:giveCard(source,p,self,"chenwanli")
		end
	end,
}
chenwanlivs = sgs.CreateViewAsSkillV2{
	name = "chenwanli",
	n = 999,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
			and request:getPattern() == "@@chenwanli"
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() >= 1
	end,
	create_card = function(skill, request)
		local dc = chenwanliCard:clone()
		for _,id in sgs.qlist(request:getSelectedCardIds())do
			dc:addSubcard(id)
		end
		return dc
	end,
}
chenwanli = sgs.CreateTriggerSkillV2{
	name = "chenwanli",
	view_as_skill = chenwanlivs,
	events = {sgs.RoundStart,sgs.RoundEnd,sgs.DrawNCards,sgs.Death},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.RoundStart then
			if data:toInt()==1 and invoker:hasSkill(skill) then
				room:askForUseCard(invoker,"@@chenwanli","chenwanli0")
			end
		elseif event==sgs.Death then
			local death = data:toDeath()
			for _,m in sgs.list(death.who:getMarkNames())do
				if m:contains("&chenwanli+:+") and m:endsWith(invoker:objectName()) then
					invoker:addMark("chenwanli_3")
				end
			end
		elseif event==sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason~="draw_phase" then return end
			if invoker:getMark("chenwanli_3")>0 and invoker:hasSkill(skill) then
				room:sendCompulsoryTriggerLog(invoker,skill)
				draw.num = draw.num+3
				data:setValue(draw)
			end
		else
			local x = data:toInt()
			for _,m in sgs.list(invoker:getMarkNames())do
				if m:contains("&chenwanli+:+") and invoker:getMark(m)==x then
					for _,p in sgs.qlist(room:getAlivePlayers())do
						if m:endsWith(p:objectName()) then
							local n = tonumber(m:split("+")[3])*3
							local dc = room:askForExchange(invoker,skill:objectName(),n,n,true,"chenwanli0:"..p:objectName()..":"..n)
							if dc then
								invoker:addMark("chenwanli_3")
								room:giveCard(invoker,p,dc,skill:objectName())
								if dc:subcardsLength()>=n then continue end
							end
							local skills = {}
							for _,s in sgs.qlist(invoker:getVisibleSkillList())do
								if s:isAttachedLordSkill() then continue end
								table.insert(skills,"-"..s:objectName())
							end
							room:handleAcquireDetachSkills(invoker,table.concat(skills,"|"))
						end
					end
					room:setPlayerMark(invoker,m,0)
				end
			end
		end
		return false
	end
}
chen_lusu:addSkill(chenwanli)
chenlishuo = sgs.CreateTriggerSkillV2{
	name = "chenlishuo",
	events = {sgs.TargetConfirmed},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and use.card:isBlack()
			and use.to:contains(invoker) and invoker:askForSkillInvoke(skill) then
				invoker:drawCards(1,skill:objectName())
				local tps = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(invoker))do
					for _,m in sgs.list(p:getMarkNames())do
						if m:contains("&chenwanli+:+") and m:endsWith(invoker:objectName()) then
							if invoker:canPindian(p) then tps:append(p) end
							break
						end
					end
				end
				local tp = room:askForPlayerChosen(invoker,tps,skill:objectName(),"chenlishuo0")
				if tp then
					if invoker:pindian(tp,skill:objectName()) then
						for _,m in sgs.list(tp:getMarkNames())do
							if m:contains("&chenwanli+:+") and m:endsWith(invoker:objectName()) then
								room:removePlayerMark(tp,m)
								break
							end
						end
					end
				end
			end
		end
		return false
	end
}
chen_lusu:addSkill(chenlishuo)

chen_jiahua = sgs.General(shixinrumo_chen,"chen_jiahua","wu",5)
chenfubeiCard = sgs.CreateSkillCard{
	name = "chenfubeiCard",
	target_fixed = true,
	on_use = function(self,room,source,targets)
		local x = source:getMaxHp()-source:getHandcardNum()
		source:drawCardsList(x,"chenfubei")
		local dc = room:askForExchange(source,"chenfubei",2,2,true,"chenfubei0")
		if dc then
			local id2n = {}
			x = math.min(10,room:getDrawPile():length())
			for i=1,dc:subcardsLength() do
				local choices = {}
				for n=1,x do
					table.insert(choices,"1="..i.."="..n)
				end
				local choice = room:askForChoice(source,"chenfubei",table.concat(choices,"+"))
				id2n[dc:getSubcards():at(i-1)] = tonumber(choice:split("=")[3])
			end
			for _,id in sgs.qlist(dc:getSubcards())do
				room:moveCardsInToDrawpile(source,id,"chenfubei",id2n[id],true)
			end
		end
	end
}
chenfubeivs = sgs.CreateViewAsSkillV2{
	name = "chenfubei",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:usedTimes("#chenfubeiCard") < 1
			and player:getHandcardNum() < player:getMaxHp()
	end,
	create_card = function(skill, request)
		return chenfubeiCard:clone()
	end,
}
chenfubei = sgs.CreateTriggerSkillV2{
	name = "chenfubei",
	view_as_skill = chenfubeivs,
	events = {sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.EventPhaseChanging then
	     	local change = data:toPhaseChange()
			if change.to==sgs.Player_NotActive then
				local ids = room:getDrawPile()
				if ids:isEmpty() or not sgs.Sanguosha:getCard(ids:first()):hasFlag("visible")
				then return end
				for _,p in sgs.qlist(room:getAllPlayers())do
					if p:hasSkill(skill) then
						room:sendCompulsoryTriggerLog(p,skill)
						room:damage(sgs.DamageStruct(skill:objectName(),p,invoker))
					end
				end
			end
		end
		return false
	end
}
chen_jiahua:addSkill(chenfubei)
chendancui = sgs.CreateTriggerSkillV2{
	name = "chendancui",
	events = {sgs.DamageCaused},
	dynamic_frequency = function(skill,target)
		if target:getMark("chendancuiCompulsory")>0 then
			return sgs.Skill_Compulsory
		end
		return sgs.Skill_NotFrequent
	end,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.DamageCaused then
			if skill:getFrequency(invoker)==sgs.Skill_Compulsory then
				room:sendCompulsoryTriggerLog(invoker,skill)
				room:askForDiscard(invoker,skill:objectName(),2,2,false,true)
			else
				invoker:setTag("chendancuiData",data)
				if invoker:getCardCount()>0 then
					if invoker:canDiscard("he") and room:askForDiscard(invoker,skill:objectName(),2,2,true,true,"",".",skill:objectName()) then
					else return end
				else
					if invoker:askForSkillInvoke(skill) then
					else return end
				end
			end
			room:setPlayerMark(invoker,"chendancuiCompulsory",1)
			room:changeTranslation(invoker,skill:objectName(),1)
			return invoker:damageRevises(data,1)
		end
		return false
	end
}
chen_jiahua:addSkill(chendancui)

chen_caocao = sgs.General(shixinrumo_chen,"chen_caocao","wei",4)
chenlanjiaoCard = sgs.CreateSkillCard{
	name = "chenlanjiaoCard",
	filter = function(self,targets,to_selec,source)
		return #targets<1 and to_selec~=source and to_selec:getHandcardNum()>0
		and source:getMark(to_selec:objectName().."chenlanjiaoBan-Clear")<1
	end,
	on_use = function(self,room,source,targets)
		for i,p in sgs.list(targets)do
			room:addPlayerMark(source,p:objectName().."chenlanjiaoBan-Clear")
			local dc = dummyCard()
			for i=1,math.min(2,p:getHandcardNum()) do
				local id = room:askForCardChosen(source,p,"h","chenlanjiao",false,sgs.Card_MethodNone,dc:getSubcards())
				if id<0 then break end
				dc:addSubcard(id)
			end
			if dc:subcardsLength()<1 then continue end
			room:showCard(p,dc:getSubcards())
			p:setTag("chenlanjiaoIds",ToData(dc:getSubcards()))
			while p:askForSkillInvoke("chenlanjiao",ToData("0:"..source:objectName()),false) do
				room:loseHp(p,1,true,p,"chenlanjiao")
				if p:isDead() then break end
				dc:clearSubcards()
				p:drawCards(1,"chenlanjiao")
				for i=1,math.min(2,p:getHandcardNum()) do
					local id = room:askForCardChosen(source,p,"h","chenlanjiao",false,sgs.Card_MethodNone,dc:getSubcards())
					if id<0 then break end
					dc:addSubcard(id)
				end
				room:showCard(p,dc:getSubcards())
				p:setTag("chenlanjiaoIds",ToData(dc:getSubcards()))
			end
			if p:isDead() or dc:subcardsLength()<1 then continue end
			for i,id in sgs.qlist(dc:getSubcards())do
				source:addMark(sgs.Sanguosha:getCard(id):getSuitString().."chenlanjiaoSuit-Clear")
			end
			source:obtainCard(dc)
			if source:getMark("heartchenlanjiaoSuit-Clear")>0 and source:getMark("diamondchenlanjiaoSuit-Clear")>0 then
				room:addPlayerMark(source,"chenlanjiaoBan-Clear")
			end
		end
	end,
}
chenlanjiao = sgs.CreateViewAsSkillV2{
	name = "chenlanjiao",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:usedTimes("#chenlanjiaoCard") < 1
			and player:getMark("chenlanjiaoBan-Clear") < 1
	end,
	create_card = function(skill, request)
		return chenlanjiaoCard:clone()
	end,
}
chen_caocao:addSkill(chenlanjiao)

chen_caoren = sgs.General(shixinrumo_chen,"chen_caoren","wei",4)
chenyangbei = sgs.CreateTriggerSkillV2{
	name = "chenyangbei",
	events = {sgs.EventPhaseStart,sgs.TargetSpecified},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.EventPhaseStart then
			if invoker:getPhase()==sgs.Player_Finish or invoker:getPhase()==sgs.Player_Start then
				if invoker:getMark("&chenyangbeiBan")<1 and invoker:askForSkillInvoke(skill) then
					invoker:turnOver()
					invoker:drawCards(3,skill:objectName())
				end
			end
		else
			local use = data:toCardUse()
			if use.to:length()==1 and (use.card:isKindOf("Slash") or use.card:isNDTrick())
			and use.to:last():canDiscard("h") and use.to:last():askForSkillInvoke(skill,ToData("0:"..invoker:objectName()),false) then
				use.to:last():throwAllHandCards(skill:objectName())
				room:setPlayerMark(invoker,"&chenyangbeiBan",1)
			end
		end
		return false
	end
}
chen_caoren:addSkill(chenyangbei)
chenyinfeng = sgs.CreateTriggerSkillV2{
	name = "chenyinfeng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage,sgs.Predamage,sgs.DamageForseen,sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.Damage then
			local damage = data:toDamage()
			invoker:addMark("chenyinfengDamage-Clear")
			if invoker:getMark("chenyinfengDamage-Clear")==1 and damage.to:isAlive() and invoker:hasSkill(skill) then
				room:sendCompulsoryTriggerLog(invoker,skill)
				room:addPlayerMark(damage.to,"&chenyinfeng+#"..invoker:objectName(),damage.to:getLostHp())
				room:loseMaxHp(damage.to,damage.to:getLostHp(),skill:objectName())
			end
		elseif event==sgs.Predamage or event==sgs.DamageForseen then
			local damage = data:toDamage()
			for i,p in sgs.qlist(room:getAlivePlayers())do
				if invoker:getMark("&chenyinfeng+#"..p:objectName())>0 then
					room:loseHp(damage.to,damage.damage,true,invoker,damage.reason)
					return true
				end
			end
		else
	     	local change = data:toPhaseChange()
			if change.from==sgs.Player_NotActive then
				for i,p in sgs.qlist(room:getAllPlayers())do
					local x = p:getMark("&chenyinfeng+#"..invoker:objectName())
					if x<1 then continue end
					room:setPlayerMark(p,"&chenyinfeng+#"..invoker:objectName(),0)
					room:gainMaxHp(p,x,skill:objectName())
				end
			end
		end
		return false
	end
}
chen_caoren:addSkill(chenyinfeng)

chen_sunshangxiang = sgs.General(shixinrumo_chen,"chen_sunshangxiang","wu",3,false)
chenjiaozong = sgs.CreateTriggerSkillV2{
	name = "chenjiaozong",
	events = {sgs.EventPhaseStart,sgs.TargetConfirmed,sgs.EventPhaseChanging,sgs.DamageForseen},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.EventPhaseChanging then
	     	local change = data:toPhaseChange()
			if change.to==sgs.Player_NotActive then
				for i,p in sgs.qlist(room:getPlayers())do
					if invoker:getMark("chenjiaozongbf-Keep")>0 then
						invoker:setMark("chenjiaozongbf-Keep",0)
						for _,m in sgs.list(p:getMarkNames())do
							if m:contains("&chenjiaozong+:+") then
								local ms = m:split("+")
								room:removePlayerCardLimitation(p,"use",".|"..ms[3])
								room:setPlayerMark(p,m,0)
							end
						end
					end
				end
			end
		elseif event==sgs.DamageForseen then
			if invoker:getMark("chenjiaozongbf-Keep")>0 then
				return invoker:damageRevises(data,1)
			end
		else
			if event==sgs.EventPhaseStart then
				if invoker:getPhase()==sgs.Player_Start then
				else return end
			else
				local use = data:toCardUse()
				if use.card:isKindOf("Slash") and use.to:contains(invoker) then
				else return end
			end
			if invoker:isAlive() and invoker:hasSkill(skill) then
				local tps = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers())do
					for _,e in sgs.qlist(p:getCards("ej"))do
						if e:getTypeId()~=3 then continue end
						local n = e:getRealCard():toEquipCard():location()
						for _,q in sgs.qlist(room:getAlivePlayers())do
							if q:getEquip(n) or invoker:isProhibited(q,e) then continue end
							tps:append(p)
							break
						end
					end
				end
				local tp = room:askForPlayerChosen(invoker,tps,skill:objectName(),"chenjiaozong0",true)
				if tp then
					invoker:skillInvoked(skill)
					local ids = sgs.IntList()
					for _,e in sgs.qlist(tp:getCards("ej"))do
						if e:getTypeId()~=3 then
							ids:append(e:getId())
							continue
						end
						local n = e:getRealCard():toEquipCard():location()
						for _,q in sgs.qlist(room:getAlivePlayers())do
							if q:getEquip(n) or invoker:isProhibited(q,e)
							then continue end
							n = 9
							break
						end
						if n~=9 then
							ids:append(e:getId())
						end
					end
					room:doAnimate(1,invoker:objectName(),tp:objectName())
					local id = room:askForCardChosen(invoker,tp,"ej",skill:objectName(),false,sgs.Card_MethodNone,ids)
					if id>=0 then
						tps:clear()
						local e = sgs.Sanguosha:getCard(id)
						local n = e:getRealCard():toEquipCard():location()
						for _,q in sgs.qlist(room:getAlivePlayers())do
							if q:getEquip(n) or tp:isProhibited(q,e)
							then continue end
							tps:append(q)
						end
						local tp2 = room:askForPlayerChosen(invoker,tps,"chenjiaozong1","chenjiaozong1:"..e:objectName())
						if tp2 then
							room:doAnimate(1,invoker:objectName(),tp2:objectName())
							tp2:addMark("chenjiaozongbf-Keep")
							local cs = e:getColorString()
							if tp2:getMark("&chenjiaozong+:+"..cs.."-Keep")<1 then
								room:setPlayerMark(tp2,"&chenjiaozong+:+"..cs.."-Keep",1)
								room:setPlayerCardLimitation(tp2,"use",".|"..cs,false)
							end
							room:moveCardTo(e,tp2,sgs.Player_PlaceEquip,true)
						end
					end
				end
			end
		end
		return false
	end
}
chen_sunshangxiang:addSkill(chenjiaozong)
chenfusuiCard = sgs.CreateSkillCard{
	name = "chenfusuiCard",
	filter = function(self,targets,to_selec,source)
		return #targets<1 and to_selec:isMale()
	end,
	on_use = function(self,room,source,targets)
		room:removePlayerMark(source,"@chenfusui")
		room:doSuperLightbox(source,"chenfusui")
		for i,p in sgs.list(targets)do
			local skills = {}
			for _,s in sgs.qlist(p:getVisibleSkillList())do
				if s:isAttachedLordSkill() then continue end
				local pt = s:getDescription(p)
				if pt:contains("技，") then continue end
				table.insert(skills,"1="..s:objectName())
			end
			if #skills<1 then continue end
			local skill = room:askForChoice(source,"chenfusui",table.concat(skills,"+"),ToData(p))
			skill = skill:split("=")[2]
			room:detachSkillFromPlayer(p,skill)
			room:setPlayerProperty(source,"chenbiyi_skill",ToData(skill))
			room:setPlayerProperty(p,"chenbiyi_skill",ToData(skill))
			skills = sgs.Sanguosha:getSkill(skill):getDescription(p)
			source:setSkillDescriptionSwap("chenbiyi","%arg",skills)
			room:acquireSkill(source,"chenbiyi")
			p:setSkillDescriptionSwap("chenbiyi","%arg",skills)
			room:acquireSkill(p,"chenbiyi")
			room:setPlayerMark(source,"&chenfusui+#bf_lun",1)
			room:setPlayerMark(p,"&chenfusui+#bf_lun",1)
		end
	end,
}
chenfusuivs = sgs.CreateViewAsSkillV2{
	name = "chenfusui",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and player:isAlive()
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:getMark("@chenfusui") > 0
	end,
	create_card = function(skill, request)
		return chenfusuiCard:clone()
	end,
}
chenfusui = sgs.CreateTriggerSkillV2{
	name = "chenfusui",
	frequency = sgs.Skill_Limited,
	limit_mark = "@chenfusui",
	waked_skills = "chenbiyi",
	view_as_skill = chenfusuivs,
	events = {sgs.DamageInflicted},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.DamageInflicted then
			if invoker:getMark("&chenfusui+#bf_lun")>0 then
				return invoker:damageRevises(data,-99)
			end
		end
		return false
	end
}
chen_sunshangxiang:addSkill(chenfusui)
-- chenbiyi 代理 chenbiyi_skill 所指嘅（舊版）ViewAsSkill；V2 以 request 模型橋接：
-- can_activate 對應 enabled_at_*，can_select_card 對應 viewFilter，create_card 對應 viewAs。
local function chenbiyiCards(request)
	local cards = sgs.CardList()
	for _,id in sgs.qlist(request:getSelectedCardIds())do
		cards:append(sgs.Sanguosha:getCard(id))
	end
	return cards
end
chenbiyivs = sgs.CreateViewAsSkillV2{
	name = "chenbiyi",
	n = 999,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local vs = sgs.Sanguosha:getViewAsSkill(player:property("chenbiyi_skill"):toString())
		if not vs then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return vs:isEnabledAtPlay(player)
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
		or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return vs:isEnabledAtResponse(player,request:getPattern())
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not (player and candidate) then return false end
		local vs = sgs.Sanguosha:getViewAsSkill(player:property("chenbiyi_skill"):toString())
		if not vs then return false end
		return vs:viewFilter(chenbiyiCards(request),candidate)
	end,
	card_selection_feasible = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local vs = sgs.Sanguosha:getViewAsSkill(player:property("chenbiyi_skill"):toString())
		return vs ~= nil and vs:viewAs(chenbiyiCards(request)) ~= nil
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		if not player then return nil end
		local vs = sgs.Sanguosha:getViewAsSkill(player:property("chenbiyi_skill"):toString())
		if not vs then return nil end
		return vs:viewAs(chenbiyiCards(request))
	end,
}
local events = {}
for i=sgs.GameStart,sgs.EventForDiy do
	table.insert(events,i)
end
chenbiyi = sgs.CreateTriggerSkillV2{
	name = "chenbiyi",
	events = events,
	change_skill = true,
	view_as_skill = chenbiyivs,
	can_trigger = function(skill, event, room, player, data)
		return firstSkillOwner(room, skill:objectName())
	end,
	on_effect = function(skill,event,room,player,ctx)
		local data = ctx.original_data
		local invoker = ctx.invoker
		if event==sgs.ChoiceMade then
			local cm = data:toString()
			if cm:startsWith("notifyInvoked:") then
				local pt = invoker:property("chenbiyi_skill"):toString()
				if pt~="" then
					local sname = cm:split(":")[2]
					if sname=="xiaoji" then
						room:setChangeSkillState(invoker,skill:objectName(),1)
					elseif sname==pt then
						room:setChangeSkillState(invoker,skill:objectName(),2)
					end
				end
			end
		end
		for _,owner in sgs.qlist(room:findPlayersBySkillName(skill:objectName()))do
			local pt = "xiaoji"
			if owner:getChangeSkillState(skill:objectName())==1 then
				pt = owner:property("chenbiyi_skill"):toString()
				if pt=="" then continue end
			end
			if owner:hasSkill(pt,true) then continue end
			local ts = sgs.Sanguosha:getTriggerSkill(pt)
			if ts and ts:hasEvent(event) then
				local has = false
				room:setPlayerProperty(owner,"pingjian_triggerskill",ToData(pt))
				if ts:triggerable(invoker,room,event) then has = ts:trigger(event,room,invoker,data) end
				room:setPlayerProperty(owner,"pingjian_triggerskill",ToData())
				if has then return true end
			end
		end
		return false
	end
}
shixinrumo_chen:addSkills(chenbiyi)

sgs.LoadTranslationTable {
	["shixinrumo_chen"] = "蚀心入魔·嗔",

	["chen_sunshangxiang"] = "嗔孙尚香",
	["#chen_sunshangxiang"] = "生死相随",
    ["illustrator:chen_sunshangxiang"] = "ShapByAI",
	["chenjiaozong"] = "娇纵",
	[":chenjiaozong"] = "准备阶段或当你成为【杀】的目标后，你可以移动场上一张装备牌至一名角色装备区，其本回合不能使用与之颜色相同的牌且受到的伤害+1。",
	["chenfusui"] = "妇随",
	[":chenfusui"] = "限定技，出牌阶段，你可以令一名男性角色失去一个无标签技能，然后你与其获得“比翼”并防止你与其本轮此后受到的伤害。",
	["chenbiyi"] = "比翼",
	[":chenbiyi"] = "转换技，此技能视为①因“妇随”失去的技能②“枭姬”。",
	[":chenbiyi1"] = "转换技，此技能视为①因“妇随”失去的技能<font color=\"#01A5AF\"><s>②“枭姬”</s></font>。（%arg）",
	[":chenbiyi2"] = "转换技，此技能视为<font color=\"#01A5AF\"><s>①因“妇随”失去的技能</s></font>②“枭姬”。（%arg）",
	["chenjiaozong0"] = "你可以发动“娇纵”选择角色移动装备",
	["chenjiaozong1"] = "娇纵：请选择【%src】移动目标",
	["chenfusui:1"] = "失去“%src”",

	["chen_caoren"] = "嗔曹仁",
	["#chen_caoren"] = "坚壳之蚌",
    ["illustrator:chen_caoren"] = "张油菜",
	["chenyangbei"] = "佯北",
	[":chenyangbei"] = "准备阶段和结束阶段，你可以翻面并摸三张牌。当你使用【杀】或普通锦囊牌指定唯一目标后，其可以弃置所有手牌令此技能失效。",
	["chenyinfeng"] = "阴锋",
	[":chenyinfeng"] = "锁定技，当你每回合首次造成伤害后，你令受伤角色将体力上限扣减至体力值，且其造成和受到的伤害均视为失去体力，直到你下回合开始。",
	["chenyangbeiBan"] = "佯北失效",
	["chenyangbei:0"] = "你可以弃置所有手牌令%src的“佯北”失效",

	["chen_caocao"] = "嗔曹操",
	["#chen_caocao"] = "铜雀囚凰",
    ["illustrator:chen_caocao"] = "丝葱",
	["chenlanjiao"] = "揽娇",
	[":chenlanjiao"] = "出牌阶段每名角色限一次，你可以展示一名其他角色两张手牌，然后你获得展示牌；其可以于展示牌时失去1点体力并摸一张牌，令你重新展示。若你一回合内因此获得过红桃和方块，本回合此技能失效。",
	["chenlanjiao:0"] = "揽娇：你可以失去1点体力摸一张牌，令%src重新展示",

	["chen_jiahua"] = "嗔贾华",
	["#chen_jiahua"] = "拔剑四顾",
    ["illustrator:chen_jiahua"] = "城与橙与程",
	["chenfubei"] = "伏备",
	[":chenfubei"] = "出牌阶段限一次，你可以将手牌摸至体力上限，然后将两张牌正面朝上置于牌堆顶前十张牌的任意位置。一名角色回合角色时，若牌堆顶的牌正面朝上，你对其造成1点伤害。",
	["chendancui"] = "殚瘁",
	[":chendancui"] = "契定技，当你造成伤害时，你可以弃置两张牌（无牌则不弃），令此伤害+1。",
	[":chendancui1"] = "锁定技，当你造成伤害时，你弃置两张牌（无牌则不弃），令此伤害+1。",
	["chenfubei:1"] = "将选择的第%src张牌置为牌堆顶第%dest张牌",

	["chen_lusu"] = "嗔鲁肃",
	["#chen_lusu"] = "养虺为蛇",
    ["illustrator:chen_lusu"] = "城与橙与程",
	["chenwanli"] = "万利",
	[":chenwanli"] = "首轮开始时，你可以交给一名其他角色任意张牌，第四轮结束时，若你存活，其交给你3倍的牌（不足则全给并失去所有技能）；若其以此法交给过你牌或已死亡，你于摸牌阶段多摸3张牌。",
	["chenlishuo"] = "理说",
	[":chenlishuo"] = "当你成为黑色牌的目标后，你可以摸一张牌并与“万利”角色拼点：若你赢，其提前一轮交给你牌。",
	["chenwanli0"] = "你可以发动“万利”选择任意牌交给其他角色",
	["chenwanli1"] = "万利：请选择%dest张牌交给%src",

	["chen_zhangzhao"] = "嗔张昭",
	["#chen_zhangzhao"] = "迂儒",
    ["illustrator:chen_zhangzhao"] = "曲夜雀",
	["chenxiezhong"] = "挟众",
	[":chenxiezhong"] = "准备阶段，你可以令X名角色选择一项（X为角色数的一半，向上取整）：摸两张牌，失去1点体力；将两张牌当做【杀】使用。然后你可以令另一名角色执行两次选择次数最多的一项。",
	["chenqishi"] = "乞施",
	[":chenqishi"] = "契定技，结束阶段，你可以从本回合置入弃牌堆的牌中获得至多5张其他角色置入的牌，然后跳过你的下一个弃牌阶段。",
	[":chenqishi1"] = "锁定技，结束阶段，你从本回合置入弃牌堆的牌中获得至多5张其他角色置入的牌，然后跳过你的下一个摸牌阶段。",
	["chenxiezhong0"] = "你可以发动“挟众”选择半数角色",
	["chenxiezhong1"] = "挟众：你可以将两张牌当【杀】使用，或者摸两张牌并失去1点体力",
	["xz_draw"] = "令另一名角色摸两张牌并失去1点体力",
	["xz_slash"] = "令另一名角色将两张牌当【杀】使用",
	["chenxiezhong2"] = "挟众：%src",
	["chenxiezhong3"] = "挟众：请将两张牌当【杀】使用",

	["chen_zhaoyun"] = "嗔赵云",
	["#chen_zhaoyun"] = "坐收渔利",
    ["illustrator:chen_zhaoyun"] = "曲夜雀",
	["chenzhaduo"] = "诈夺",
	[":chenzhaduo"] = "结束阶段，你可以获得里面其他角色各一张牌，视为对其中一名角色使用【杀】，然后另一名角色视为对你使用【决斗】；在和其中一名角色的结算过程中，你视为拥有另一名角色的所有技能。",
	["chenzhaduo0"] = "你可以发动“诈夺”选择两名角色获得牌，你对第一名【杀】，第二名对你【决斗】",

	["chen_zhouyu"] = "嗔周瑜",
	["#chen_zhouyu"] = "哀弦万耳惊",
    ["illustrator:chen_zhouyu"] = "小罗没想好",
	["chenjiehuo"] = "劫火",
	[":chenjiehuo"] = "使命技，回合开始时，你可以令场上下次出现的伤害改为3点火焰伤害。失败：若造成伤害的角色不为你，你扣减1点体力上限。",
	["chenxianger"] = "香饵",
	[":chenxianger"] = "使命技，出牌阶段限一次，你可以令一名角色于其下个结束阶段回复2点体力，期间其不能使用点数大于6的牌。失败：期间其受到的伤害小于2点，你扣减1点体力上限。",
	["chenmieguo"] = "灭虢",
	[":chenmieguo"] = "使命技，额定回合结束后，你可以获得一名其他角色至多3张牌并令其指定等量角色，然后你执行一个不能对其指定角色使用牌的额外回合。失败：此额外回合你未使用牌，你扣减1点体力上限。",
	["chenmieguo0"] = "你可以发动“灭虢”选择角色",
	["chenmieguo1"] = "灭虢：请选择%src名角色",
	["chenmieguo_ban"] = "灭虢禁止",

	["chen_zhugeliang"] = "嗔诸葛亮",
	["#chen_zhugeliang"] = "人也神也",
    ["illustrator:chen_zhugeliang"] = "城与橙与程",
	["chenbingqu"] = "并驱",
	[":chenbingqu"] = "准备阶段，你可以与一名其他角色各声明一种普通锦囊牌，然后你与其依次将半数手牌（向上取整）当做对方声明的牌使用。",
	["chenfanxin"] = "燔心",
	[":chenfanxin"] = "游戏开始时或“燔心”角色死亡后，你可以令一名其他角色获得“狂暴”和“无谋”；其回合开始时，你可以移去其至多5枚“暴怒”标记并摸等量的牌。",
	["chenbingqu0"] = "你可以发动“并驱”选择角色声明牌",
	["chenbingqu1"] = "并驱：请选择半数手牌当做【%src】使用",
	["chenfanxin0"] = "你可以发动“燔心”选择角色获得“狂暴”和“无谋”",
	["chenfanxin:1"] = "移去%src枚“暴怒”摸%src张牌",







}


return{shixinrumo_yi,shixinrumo_man,shixinrumo_chen}