local shixinrumo_yi = sgs.Package("shixinrumo_yi",sgs.Package_GeneralPack)


require("lua.config")
table.insert(config.kingdoms,"demon")
config.kingdom_colors.demon = "#e396aa"

yi_caocao = sgs.General(shixinrumo_yi,"yi_caocao","demon",3)
yikuxin = sgs.CreateTriggerSkill{
	name = "yikuxin",
	events = {sgs.Damaged},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.Damaged then
			if player:askForSkillInvoke(self) then
				for i,p in sgs.qlist(room:getOtherPlayers(player))do
					room:doAnimate(1,player:objectName(),p:objectName())
				end
				local dc = dummyCard()
				for i,p in sgs.qlist(room:getOtherPlayers(player))do
					local sc = room:askForExchange(p,self:objectName(),p:getHandcardNum(),1,false,"yikuxin0",true)
					if sc then
						room:showCard(p,sc:getSubcards())
						dc:addSubcards(sc:getSubcards())
					end
				end
				if player:isDead() then return end
				room:fillAG(dc:getSubcards(),player)
				player:setTag("yikuxinIds",ToData(dc:getSubcards()))
				local tp = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"yikuxin1",true)
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
				room:throwCard(dc2,self:objectName(),player)
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
yisigu = sgs.CreateViewAsSkill{
	name = "yisigu",
	view_as = function(self,cards)
		return yisiguCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#yisiguCard")<1
	end,
}
yi_caocao:addSkill(yisigu)

yi_huatuo = sgs.General(shixinrumo_yi,"yi_huatuo","qun",4)
yimiehaivs = sgs.CreateViewAsSkill{
	name = "yimiehai",
	n = 2,
	response_or_use = true,
	view_filter = function(self,selected,to_select)
		return true
	end,
	view_as = function(self,cards)
		if #cards<2 then return end
		local sc = sgs.Sanguosha:cloneCard("yj_stabs_slash")
		sc:setSkillName("yimiehai")
		for _,c in ipairs(cards)do
			sc:addSubcard(c)
		end
		return sc
	end,
	enabled_at_response = function(self,player,pattern)
		if sgs.Sanguosha:getCurrentCardUseReason()~=sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return pattern=="slash"
		end
	end,
	enabled_at_play = function(self,player)
		return player:getCardCount()>1
	end,
}
yimiehai = sgs.CreateTriggerSkill{
	name = "yimiehai",
	view_as_skill = yimiehaivs,
	events = {sgs.PreCardUsed,sgs.CardFinished,sgs.CardsMoveOneTime},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.PreCardUsed then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),self:objectName()) then
				player:setMark("yimiehaibf",1)
			end
		elseif event==sgs.CardFinished then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),self:objectName()) then
				player:setMark("yimiehaibf",0)
			end
		elseif event==sgs.CardsMoveOneTime then
	     	local move = data:toMoveOneTime()
			if player:getMark("yimiehaibf")>0 and player:hasSkill(self)
			and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then
				for i,id in sgs.qlist(move.card_ids)do
					local c = sgs.Sanguosha:getCard(id)
					if c:getSuit()==0 and c:hasFlag("visible") and move.from:isWounded() then
						local to = BeMan(room,move.from)
						to:drawCards(2,self:objectName())
						room:recover(to,sgs.RecoverStruct(self:objectName(),player))
					end
				end
			end
		end
		return false
	end
}
yi_huatuo:addSkill(yimiehai)
yimiehaibf = sgs.CreateTargetModSkill{
    name = "#yimiehaibf",
	distance_limit_func = function(self, from, card, to)
		if table.contains(card:getSkillNames(), "yimiehai")
		then return 999 end
		return 0
	end,
	residue_func = function(self, from, card, to)
		if table.contains(card:getSkillNames(), "yimiehai")
		then return 999 end
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
	end,
}
yi_huatuo:addSkill(yimiehaibf)

yi_lvboshe = sgs.General(shixinrumo_yi,"yi_lvboshe","qun",4)
yiqingjun = sgs.CreateTriggerSkill{
	name = "yiqingjun",
	waked_skills = "shefu",
	events = {sgs.RoundEnd,sgs.EventPhaseChanging,sgs.DamageDone},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.RoundEnd then
			if player:hasSkill(self) then
				local tp = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"yiqingjun0",true,true)
				if tp then
					room:setPlayerMark(tp,"&yiqingjun",1)
					room:getThread():addTriggerSkill(sgs.Sanguosha:getTriggerSkill("shefu"))
					local aps = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getAllPlayers())do
						if p:inMyAttackRange(tp) or player==p
						then aps:append(p) end
					end
					room:drawCards(aps,2,self:objectName())
					for _,p in sgs.qlist(aps)do
						if p:isDead() then continue end
						local cns = {}
						for _,cn in sgs.list(sgs.Sanguosha:getCardNames("BasicCard,TrickCard"))do
							if p:getMark("Shefu_"..cn)<1 then table.insert(cns,cn) end
						end
						local cn = room:askForChoice(p,"shefu",table.concat(cns,"+"))
						local dc = room:askForExchange(p,self:objectName(),1,1,false,"yiqingjun1:"..cn)
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
					room:setTag("yiqingjunTo",ToData(tp))
					tp:gainAnExtraTurn()
					room:setPlayerMark(tp,"&yiqingjun",0)
				end
			end
		elseif event==sgs.DamageDone then
	     	if player:getMark("yiqingjunbf")>0 then
				player:addMark("yiqingjunDamage-Clear")
			end
		elseif event==sgs.EventPhaseChanging then
	     	local change = data:toPhaseChange()
			if change.to==sgs.Player_NotActive and player:getMark("&yiqingjun")>0 then
				room:setPlayerMark(player,"&yiqingjun",0)
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
				for i,p in sgs.qlist(room:getAllPlayers())do
					if p:getMark("yiqingjunbf")>0 then
						p:setMark("yiqingjunbf",0)
						if p:getMark("yiqingjunDamage-Clear")<1 then
							local tp = room:getTag("yiqingjunTo"):toPlayer()
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
yijugu = sgs.CreateTriggerSkill{
	name = "yijugu",
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
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
				room:drawCards(aps,1,self:objectName())
			end
		else
			if player:getPhase()==sgs.Player_Start and player:hasSkill(self) then
				local x = 5
				for i=1,5 do
					local tps = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getAlivePlayers())do
						if p:getCardCount()>0 then tps:append(p) end
					end
					if i==1 then
						if tps:isEmpty() or not player:askForSkillInvoke(self) then break end
					end
					local tp = room:askForPlayerChosen(player,tps,self:objectName(),"yijugu0:"..x,i>1)
					if tp then
						room:doAnimate(1,player:objectName(),tp:objectName())
						local dc = dummyCard()
						for n=1,x do
							local id = room:askForCardChosen(player,tp,"he",self:objectName(),false,sgs.Card_MethodNone,dc:getSubcards(),n>1)
							if id<0 then break end
							dc:addSubcard(id)
							if dc:subcardsLength()>=tp:getCardCount() then break end
						end
						x = x-dc:subcardsLength()
						tp:setTag("yijuguIds",ToData(dc:getSubcards()))
						room:moveCardTo(dc,nil,sgs.Player_DrawPile,true)
						if x<1 or player:isDead() then break end
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
		room:setTag("yizhengsiUse",ToData(use))
		self:cardOnUse(room,use)
	end,
	on_use = function(self,room,source,targets)
		local use = room:getTag("yizhengsiUse"):toCardUse()
		local dc = room:askForCardShow(use.to:first(),source,"yizhengsi")
		local max,min = dc:getNumber(),dc:getNumber()
		use.to:first():setMark("yizhengsiNumber",dc:getNumber())
		room:showCard(use.to:first(),dc:getEffectiveId())
		for i,p in sgs.qlist(use.to)do
			p:addMark("yizhengsiUse-PlayClear")
			if i>0 then
				local dc2 = room:askForCardShow(p,source,"yizhengsi")
				if dc2:getNumber()>max then max = dc2:getNumber() end
				if dc2:getNumber()<min then min = dc2:getNumber() end
				p:setMark("yizhengsiId",dc2:getEffectiveId())
				p:setMark("yizhengsiNumber",dc2:getNumber())
			end
		end
		for i,p in sgs.qlist(use.to)do
			if i>0 then
				room:showCard(p,p:getMark("yizhengsiId"))
			end
		end
		for i,p in sgs.qlist(use.to)do
			if p:getMark("yizhengsiNumber")>=max then
				room:askForDiscard(p,"yizhengsi",2,2)
			end
			if p:getMark("yizhengsiNumber")<=min then
				room:loseHp(p,1,true,source,"yizhengsi")
			end
		end
	end
}
yizhengsi = sgs.CreateViewAsSkill{
	name = "yizhengsi",
	view_as = function(self,cards)
		return yizhengsiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:getHandcardNum()>0
	end,
}
yi_caopi:addSkill(yizhengsi)
yichengming = sgs.CreateTriggerSkill{
	name = "yichengming",
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self,event,player,data,room)
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
				and player:askForSkillInvoke(self,ToData("yichengming1")) then
					room:recover(player,sgs.RecoverStruct(self:objectName(),player))
				end
				if hp2>hp and player:askForSkillInvoke(self,ToData("yichengming2")) then
					for i,p in sgs.qlist(room:getOtherPlayers(player))do
						if p:getMark("yizhengsiUse-PlayClear")>0 and p:getCardCount()>0 and player:isAlive() then
							local id = room:askForCardChosen(player,p,"he",self:objectName())
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
yihuice = sgs.CreateViewAsSkill{
	name = "yihuice",
	view_as = function(self,cards)
		return yihuiceCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#yihuiceCard")<1
		and player:getHandcardNum()>0
	end,
}
yi_xunyu:addSkill(yihuice)
yiyihe = sgs.CreateTriggerSkill{
	name = "yiyihe",
	events = {sgs.DamageInflicted},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.from then
				local fromNum = damage.from:getHandcardNum()-damage.from:getHp()
				if fromNum>0 then fromNum = 1 elseif fromNum<0 then fromNum = -1 end
				local toNum = player:getHandcardNum()-player:getHp()
				if toNum>0 then toNum = 1 elseif toNum<0 then toNum = -1 end
				for i,p in sgs.list(room:getAllPlayers())do
					if p:hasFlag("CurrentPlayer") and p:hasSkill(self) then
						if fromNum==toNum then
							if p:getMark("yiyihe2-Clear")<1 then
								p:addMark("yiyihe2-Clear")
								room:sendCompulsoryTriggerLog(p,self)
								local aps = SPlayerList(player,damage.from)
								room:sortByActionOrder(aps)
								room:drawCards(aps,2,self:objectName())
							end
						else
							if p:getMark("yiyihe1-Clear")<1 then
								p:addMark("yiyihe1-Clear")
								room:sendCompulsoryTriggerLog(p,self)
								player:damageRevises(data,1)
							end
						end
					end
				end
			end
		end
	end
}
yi_xunyu:addSkill(yiyihe)
yijizhi = sgs.CreateTriggerSkill{
	name = "yijizhi",
	events = {sgs.Dying},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.Dying then
			local dy = data:toDying()
			if dy.who==player and player:getMark("yijizhiUse-Clear")<1 then
				room:sendCompulsoryTriggerLog(player,self)
				player:addMark("yijizhiUse-Clear")
				room:recover(player,sgs.RecoverStruct(self:objectName(),player))
			end
		end
	end
}
yi_xunyu:addSkill(yijizhi)
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
yimitu = sgs.CreateTriggerSkill{
    name = "yimitu",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Start then
				local tps = sgs.SPlayerList()
				for _,p in sgs.list(room:getAlivePlayers())do
					if p:isWounded() then tps:append(p) end
				end
				tps = room:askForPlayersChosen(player,tps,self:objectName(),0,3,"yimitu0",true,true)
				if tps:length()>0 then
					for _,p in sgs.qlist(tps)do
						local id = room:drawCardsList(p,1,self:objectName()):first()
						p:setMark("yimituId",id)
						room:showCard(p,id)
					end
					local tps2 = sgs.SPlayerList()
					for _,p in sgs.list(room:getAlivePlayers())do
						if p:isKongcheng() or tps:contains(p) then continue end
						tps2:append(p)
					end
					local tp = room:askForPlayerChosen(player,tps2,self:objectName(),"yimitu1")
					if tp then
						room:doAnimate(1,player:objectName(),tp:objectName())
						for _,p in sgs.list(tps)do
							if p:canPindian(tp) and p:askForSkillInvoke(self,ToData("yimitu2:"..tp:objectName()),false) then
								local pd = p:PinDian(tp,self:objectName())
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
								if pd.from_card:getEffectiveId()==p:getMark("yimituId")
								then continue end
							end
							p:setMark("yimituId",-1)
						end
						for _,p in sgs.list(tps)do
							if p:getMark("yimituId")<0 then
								room:loseMaxHp(player,1,self:objectName())
							end
						end
					end
				end
			end
		end
	end,
}
yi_fuhuanghou:addSkill(yimitu)
yiqianliu = sgs.CreateTriggerSkill{
	name = "yiqianliu",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				for i,p in sgs.list(use.to)do
					if p:distanceTo(player)<=1 then
						if player:askForSkillInvoke(self) then
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
								move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER,player:objectName(),self:objectName(),nil)
								room:moveCardsAtomic(move,true)
								room:getThread():delay()
								move.to_place = sgs.Player_PlaceHand
								move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTBACK,player:objectName(),self:objectName(),nil)
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
yichengbian = sgs.CreateTriggerSkill{
	name = "yichengbian",
	events = {sgs.EventPhaseStart,sgs.CardAsked},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.CardAsked then
    		local pattern = data:toStringList()
			if pattern[#pattern]:contains("_yichengbian")
			and pattern[1]:contains("slash") and player:getHandcardNum()>0 then
				local h = player:getHandcardNum()+1
				local sc = room:askForExchange(player,self:objectName(),h,h/2,false,"yichengbian1",true)
				if sc then
					local dc = dummyCard("slash","_yichengbian")
					dc:addSubcards(sc:getSubcards())
					room:provide(dc)
					return true
				end
			end
		else
			if (player:getPhase()==sgs.Player_Start or player:getPhase()==sgs.Player_Finish)
			and player:hasSkill(self) then
				local tps = sgs.SPlayerList()
				local dc = dummyCard("duel","_yichengbian")
				for i,p in sgs.list(room:getOtherPlayers(player))do
					if player:canPindian(p) and player:canUse(dc,p)
					then tps:append(p) end
				end
				local tp = room:askForPlayerChosen(player,tps,self:objectName(),"yichengbian0",true,true)
				if tp then
					local pd = delayedPingdian(self,player,tp)
					room:useCard(sgs.CardUseStruct(dc,player,tp))
					pd = verifyPindian(pd)
					if pd.success then
						player:drawCards(player:getMaxHp()-player:getHandcardNum(),self:objectName())
					elseif pd.from_number<pd.to_number then
						tp:drawCards(tp:getMaxHp()-tp:getHandcardNum(),self:objectName())
					end
				end
			end
		end
		return false
	end
}
yi_liubei:addSkill(yichengbian)

yi_jiangguan = sgs.General(shixinrumo_yi,"yi_jiangguan","wei",3)
yizongheng = sgs.CreateTriggerSkill{
	name = "yizongheng",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Start then
				local tps = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if p:getHandcardNum()>0 then tps:append(p) end
				end
				if tps:length()<2 then return end
				tps = room:askForPlayersChosen(player,tps,self:objectName(),-1,2,"yizongheng0",true,true)
				if tps:length()<2 then return end
				local ids = tps:first():handCards()
				for _,id in sgs.qlist(tps:last():handCards())do
					ids:append(id)
				end
				for _,p in sgs.qlist(tps)do
					room:doGongxin(player,p,sgs.IntList(),self:objectName())
				end
				room:fillAG(ids,player)
				local cid = room:askForAG(player,ids,false,self:objectName(),"yizongheng1")
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
					cid = room:askForAG(player,ids,true,self:objectName(),"yizongheng2")
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
				room:throwCard(dc,self:objectName(),room:getCardOwner(dc:getEffectiveId()),player)
			end
		end
	end
}
yi_jiangguan:addSkill(yizongheng)
yiduibian = sgs.CreateTriggerSkill{
	name = "yiduibian",
	events = {sgs.DamageInflicted},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.DamageInflicted then
			local damage = data:toDamage()
			player:addMark("yiduibianDamage-Clear")
			if damage.from and player:getMark("yiduibianDamage-Clear")==1
			and player:canPindian(damage.from) and player:askForSkillInvoke(self,data) then
				local pd = delayedPingdian(self,player,damage.from)
				player:damageRevises(data,-damage.damage)
				if player:canDiscard(damage.from,"he")
				and damage.from:askForSkillInvoke("yiduibian0",ToData("yiduibian:"..player:objectName()),false) then
					local id = room:askForCardChosen(player,damage.from,"he",self:objectName(),false,sgs.Card_MethodDiscard)
					if id>-1 then
						room:throwCard(id,self:objectName(),damage.from,player)
						pd = verifyPindian(pd)
						if pd.to_number>pd.from_number then
							room:loseHp(player,1,true,player,self:objectName())
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
manhanguo = sgs.CreateTriggerSkill{
	name = "manhanguo",
	events = {sgs.Damage,sgs.RoundStart,sgs.RoundEnd,sgs.CardAsked},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.RoundStart then
			if player:hasSkill(self) then
				local tps = sgs.SPlayerList()
				local x = room:getTag("TurnLengthCount"):toInt()
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if p:getMark(player:objectName().."manhanguoT"..x-1)<1
					then tps:append(p) end
				end
				local tp = room:askForPlayerChosen(player,tps,self:objectName(),"manhanguo0:",true,true)
				if tp then
					tp:addMark(player:objectName().."manhanguoT"..x)
					local ids = tp:handCards()
					for _,id in sgs.qlist(tp:getEquipsId())do
						ids:append(id)
					end
					tp:addToPile(self:objectName(),ids,false)
				end
			end
		elseif event==sgs.RoundEnd then
			local ids = player:getPile(self:objectName())
			if ids:length()>0 then
				local dc = dummyCard()
				dc:addSubcards(ids)
				player:obtainCard(dc,false)
			end
		elseif event==sgs.CardAsked then
    		local pattern = data:toStringList()
			if #pattern>3 and pattern[1]:contains("jink") then
				local c = sgs.Card_Parse(pattern[4])
				if c and c:isKindOf("Slash") then
					local use = room:getUseStruct(c)
					local x = room:getTag("TurnLengthCount"):toInt()
					if use.from and player:getMark(use.from:objectName().."manhanguoT"..x)>0
					and player:askForSkillInvoke("hujia",data,false) then
						player:skillInvoked("hujia")
						for _,p in sgs.qlist(room:getOtherPlayers(player))do
							c = room:askForCard(p,"jink","@hujia-jink:"..player:objectName(),ToData(player),sgs.Card_MethodResponse,player,false,"",true)
							if c then
								room:provide(c)
								if use.from:getCardCount()>0 then
									x = room:askForCardChosen(p,use.from,"he",self:objectName())
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
				if damage.to:getMark(player:objectName().."manhanguoT"..x)>0 then
					room:sendCompulsoryTriggerLog(player,self:objectName())
					room:killPlayer(damage.to,damage)
				end
			end
		end
		return false
	end
}
man_guanyu:addSkill(manhanguo)
manweiwo = sgs.CreateTriggerSkill{
	name = "manweiwo",
	limit_mark = "@manweiwo",
	waked_skills = "nosrende,qingnang,longyin,wushen",
	frequency = sgs.Skill_Limited,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Finish and player:getMark("@manweiwo")>0 then
				local tps = room:askForPlayersChosen(player,room:getOtherPlayers(player),self:objectName(),0,3,"manweiwo0",true,false)
				if tps:length()>0 then
					room:removePlayerMark(player,"@manweiwo")
					room:doSuperLightbox(player,self:objectName())
					local sks = {"nosrende","qingnang","longyin"}
					for _,p in sgs.qlist(tps)do
						local sk = room:askForChoice(player,self:objectName(),table.concat(sks,"+"),ToData(p),"",p:getGeneralName())
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
manhaibianvs = sgs.CreateViewAsSkill{
	name = "manhaibian",
	response_pattern = "@@manhaibian",
	view_as = function(self,cards)
		local dc = sgs.Sanguosha:cloneCard("duel")
		dc:setSkillName("_manhaibian")
		return dc
	end,
}
manhaibian = sgs.CreateTriggerSkill{
	name = "manhaibian",
	view_as_skill = manhaibianvs,
	events = {sgs.EventPhaseStart,sgs.CardUsed},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.CardUsed then
    		local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				player:addMark("manhaibianUse")
				room:setTag("manhaibianColor"..use.card:getColorString(),ToData(player))
			end
		else
			if player:getPhase()==sgs.Player_RoundStart then
				local rp = room:getTag("manhaibianColorred"):toPlayer()
				local bp = room:getTag("manhaibianColorblack"):toPlayer()
				for _,p in sgs.qlist(room:getAllPlayers())do
					if p:getMark("manhaibianUse")>0 and p:hasSkill(self) then
						if rp and rp:isAlive() then
							room:askForUseCard(rp,"@@manhaibian","manhaibian0")
						end
						if bp and bp:isAlive() then
							room:askForUseCard(bp,"@@manhaibian","manhaibian0")
						end
					end
					p:setMark("manhaibianUse",0)
				end
				room:removeTag("manhaibianColorred")
				room:removeTag("manhaibianColorblack")
			end
		end
		return false
	end
}
man_yanliangwenchou:addSkill(manhaibian)
manqiewang = sgs.CreateTriggerSkill{
	name = "manqiewang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged,sgs.EventPhaseChanging,sgs.CardsMoveOneTime},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
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
			if move.to_place==sgs.Player_PlaceHand and move.to:objectName()==player:objectName()
			and player:getMark("manqiewangBf-Clear")>0 then
				for _,h in sgs.qlist(player:getHandcards())do
					if h:getSkillName()=="manqiewang" then continue end
					local toc = sgs.Sanguosha:cloneCard("nullification",h:getSuit(),h:getNumber())
					toc:setSkillName("manqiewang")
					local wrap = sgs.Sanguosha:getWrappedCard(h:getId())
					wrap:takeOver(toc)
					room:notifyUpdateCard(player,h:getId(),wrap)
				end
			end
		elseif event==sgs.Damaged then
			local damage = data:toDamage()
			for _,p in sgs.qlist(room:getAllPlayers())do
				if damage.to:distanceTo(p)<=1 and p:hasSkill(self) then
					room:sendCompulsoryTriggerLog(p,self)
					p:drawCards(1,self:objectName())
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
manchanyuvs = sgs.CreateViewAsSkill{
	name = "manchanyu",
	view_as = function(self,cards)
		return manchanyuCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#manchanyuCard")<1
	end,
}
manchanyu = sgs.CreateTriggerSkill{
	name = "manchanyu",
	view_as_skill = manchanyuvs,
	events = {sgs.AskforPindianCard},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.AskforPindianCard then
    		local pd = data:toPindian()
			if pd.reason==self:objectName() and pd.to_card==nil then
				local x = 99
				for _,h in sgs.qlist(pd.to:getHandcards())do
					x = math.min(x,h:getNumber())
				end
				pd.to_card = room:askForCard(pd.to,".|.|"..x.."!","manchanyu0:"..x,ToData(player),sgs.Card_MethodPindian)
				data:setValue(pd)
			end
		end
		return false
	end
}
man_luxun:addSkill(manchanyu)
mancongfeng = sgs.CreateTriggerSkill{
	name = "mancongfeng",
	change_skill = true,
	events = {sgs.TargetSpecified,sgs.TargetConfirmed},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.TargetSpecified then
	     	local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				if player:getChangeSkillState(self:objectName())==1 then
					if player:askForSkillInvoke(self,use.from) then
						room:setChangeSkillState(player,self:objectName(),2)
						local sps = SPlayerList(player,use.from)
						room:sortByActionOrder(sps)
						room:drawCards(sps,1,self:objectName())
					end
				elseif player:canDiscard(use.from,"he") and player:askForSkillInvoke(self,use.from) then
					room:setChangeSkillState(player,self:objectName(),1)
					local ids = sgs.IntList()
					for i=1,2 do
						local id = room:askForCardChosen(player,use.from,"he",self:objectName(),false,sgs.Card_MethodDiscard,ids)
						if id>=0 then
							ids:append(id)
							if ids:length()>=use.from:getCardCount() then break end
						end
					end
					room:throwCard(ids,self:objectName(),use.from,player)
				end
			end
		elseif event==sgs.TargetConfirmed then
	     	local use = data:toCardUse()
			if use.card:getTypeId()>0 and use.to:contains(player) then
				if player:getChangeSkillState(self:objectName())==1 then
					if player:askForSkillInvoke(self,use.from) then
						room:setChangeSkillState(player,self:objectName(),2)
						local sps = SPlayerList(player,use.from)
						room:sortByActionOrder(sps)
						room:drawCards(sps,1,self:objectName())
					end
				elseif player:canDiscard(use.from,"he") and player:askForSkillInvoke(self,use.from) then
					room:setChangeSkillState(player,self:objectName(),1)
					local ids = sgs.IntList()
					for i=1,2 do
						local id = room:askForCardChosen(player,use.from,"he",self:objectName(),false,sgs.Card_MethodDiscard,ids)
						if id>=0 then
							ids:append(id)
							if ids:length()>=use.from:getCardCount() then break end
						end
					end
					room:throwCard(ids,self:objectName(),use.from,player)
				end
			end
		end
		return false
	end
}
man_luxun:addSkill(mancongfeng)

man_lvmeng = sgs.General(shixinrumo_man,"man_lvmeng","wu",4,true,false,false,3)
mankongzhi = sgs.CreateTriggerSkill{
	name = "mankongzhi",
	waked_skills = "#mankongzhibf",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified,sgs.CardEffect,sgs.HpChanged,sgs.MaxHpChanged},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.TargetSpecified then
	     	local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.to:length()==1 and use.to:last():getCardCount()>0 then
				room:sendCompulsoryTriggerLog(player,self)
				local dc = dummyCard()
				for i=1,math.min(3,use.to:last():getCardCount()) do
					local id = room:askForCardChosen(player,use.to:last(),"he",self:objectName(),false,sgs.Card_MethodNone,dc:getSubcards(),true)
					if id<0 then break end
					dc:addSubcard(id)
				end
				player:obtainCard(dc,false)
			end
		elseif event==sgs.CardEffect then
	     	local effect = data:toCardEffect()
			if effect.card:isNDTrick() and player:isWounded() then
				room:sendCompulsoryTriggerLog(player,self)
				effect.nullified = true
				data:setValue(effect)
			end
		else
			if player:isWounded() then
				room:filterCards(player,player:getHandcards(),false)
			else
				local cs = sgs.CardList()
				for _,h in sgs.qlist(player:getHandcards())do
					if h:getSkillName()==self:objectName()
					then cs:append(h) end
				end
				room:filterCards(player,cs,true)
			end
		end
		return false
	end
}
man_lvmeng:addSkill(mankongzhi)
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
manbizhavs = sgs.CreateViewAsSkill{
	name = "manbizha",
	expand_pile = "#manbizha",
	response_pattern = "@@manbizha",
	n = 1,
	view_filter = function(self,selected,to_select)
		return sgs.Self:getPile("#manbizha"):contains(to_select:getId())
		and sgs.Self:getMark("manbizhaNum")>to_select:getNumber()
		and to_select:isAvailable(sgs.Self)
	end,
	view_as = function(self,cards)
		return cards[1]
	end,
}
manbizha = sgs.CreateTriggerSkill{
	name = "manbizha",
	view_as_skill = manbizhavs,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Finish and player:askForSkillInvoke(self) then
				player:drawCards(1,self:objectName())
				local tps = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if player:canPindian(p) then tps:append(p) end
				end
				local tp = room:askForPlayerChosen(player,tps,self:objectName(),"manbizha0")
				if tp then
					local pd = player:PinDian(tp,self:objectName())
					if pd.from_number>=pd.to_number and tp:isAlive() then
						room:loseHp(tp,2,true,player,self:objectName())
						room:setPlayerMark(player,"manbizhaNum",pd.to_number)
						tps = tp:handCards()
						room:doGongxin(player,tp,tps,self:objectName())
						for i=1,2 do
							if tps:isEmpty() then break end
							room:notifyMoveToPile(player,tps,self:objectName())
							room:askForUseCard(player,"@@manbizha","manbizha1:"..pd.to_number)
							tps = tp:handCards()
						end
					end
					if pd.from_number<=pd.to_number and player:isAlive() then
						room:loseMaxHp(player,1,self:objectName())
					end
				end
			end
		end
		return false
	end
}
man_lvmeng:addSkill(manbizha)


man_pangde = sgs.General(shixinrumo_man,"man_pangde","wei",4)
mannuozhan = sgs.CreateTriggerSkill{
	name = "mannuozhan",
	events = {sgs.EventPhaseStart,sgs.ConfirmDamage,sgs.CardFinished},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Start and player:hasSkill(self) then
				local tp = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"mannuozhan0",true,true)
				while tp do
					player:drawCards(1,self:objectName())
					local cns = {}
					for _,cn in ipairs(patterns())do
						local dc = dummyCard(cn,self:objectName())
						if dc:isDamageCard() and not dc:isKindOf("DelayedTrick") then
							if player:canUse(dc,tp) or tp:canUse(dc,player)
							then table.insert(cns,cn) end
						end
					end
					if #cns<1 then break end
					local cn = room:askForChoice(tp,self:objectName(),table.concat(cns,"+"),ToData(player))
					local log = sgs.LogMessage()
					log.type = "#mannuozhanLog"
					log.from = tp
					log.arg = cn
					room:sendLog(log)
					cns = {}
					local dc = dummyCard(cn,"_"..self:objectName())
					if player:canUse(dc,tp) then table.insert(cns,"mannuozhan1") end
					if tp:canUse(dc,player) then table.insert(cns,"mannuozhan2") end
					if room:askForChoice(player,"mannuozhan3",table.concat(cns,"+"),ToData(cn))=="mannuozhan1" then
						room:useCard(sgs.CardUseStruct(dc,player,tp))
					else
						room:useCard(sgs.CardUseStruct(dc,tp,player))
					end
					if player:isAlive() and tp:isAlive() and player:askForSkillInvoke(self,tp)
					then else break end
				end
			end
		elseif event==sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and table.contains(damage.card:getSkillNames(),self:objectName()) then
				player:damageRevises(data,1)
			end
		elseif event==sgs.CardFinished then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),self:objectName()) then
				for _,p in sgs.qlist(use.to)do
					if use.card:hasFlag("DamageDone_"..p:objectName()) then return end
				end
				room:loseHp(player,1,true,nil,self:objectName())
			end
		end
		return false
	end
}
man_pangde:addSkill(mannuozhan)

man_koufeng = sgs.General(shixinrumo_man,"man_koufeng","shu",4)
manhuaibing = sgs.CreateTriggerSkill{
	name = "manhuaibing",
	events = {sgs.EventPhaseStart,sgs.DrawNCards},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Start and player:hasSkill(self) then
				local tps = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers())do
					if p:getHandcardNum()>0 then tps:append(p) end
				end
				local tps = room:askForPlayersChosen(player,tps,self:objectName(),-1,2,"manhuaibing0",true,true)
				if tps:length()>0 then
					local dc = dummyCard()
					for _,p in sgs.qlist(tps)do
						if p==player then continue end
						local id = room:askForCardChosen(player,p,"h",self:objectName())
						dc:addSubcard(id)
					end
					player:obtainCard(dc,false)
					room:showAllCards(player)
					local n = 0
					for _,h in sgs.qlist(player:getHandcards())do
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
			for _,m in ipairs(player:getMarkNames())do
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
manhuaibingbf = sgs.CreateMaxCardsSkill{
    name = "#manhuaibingbf",
	extra_func = function(self,target)
		return 0
	end,
	fixed_func = function(self,player)
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
manhuoe = sgs.CreateTriggerSkill{
	name = "manhuoe",
	events = {sgs.EventPhaseStart,sgs.CardEffected,sgs.CardFinished},
	priority = {2,0},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Finish and player:hasSkill(self) then
				local tps = sgs.SPlayerList()
				local dc = dummyCard("fire_attack",self:objectName())
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if player:canUse(dc,p) then tps:append(p) end
				end
				local tps = room:askForPlayersChosen(player,tps,self:objectName(),0,4,"manhuoe0")
				if tps:length()>0 then room:useCard(sgs.CardUseStruct(dc,player,tps)) end
			end
		elseif event==sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("FireAttack") and table.contains(use.card:getSkillNames(),self:objectName()) then
				local dc = dummyCard()
				local n = 0
				for _,p in sgs.qlist(use.to)do
					local sc = p:getTag("manhuoeSC"):toCard()
					if sc then
						n = n+sc:getNumber()
						dc:addSubcard(sc)
					end
				end
				if dc:subcardsLength()>0 then
					room:fillAG(dc:getSubcards(),player)
					local tp = room:askForPlayerChosen(player,room:getAlivePlayers(),self:objectName(),"manhuoe1")
					if tp then tp:obtainCard(dc) end
					room:clearAG(player)
				end
				if n<13 then
					room:loseHp(player,1,true,player,self:objectName())
				end
			end
		elseif event==sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("FireAttack") and table.contains(effect.card:getSkillNames(),self:objectName()) then
				effect.to:removeTag("manhuoeSC")
				if effect.to:getHandcardNum()>0 and effect.from:getMark("manhuoeBanTo-Clear")<1 then
					local sc = room:askForCardShow(effect.to,effect.from,"fire_attack")
					room:showCard(effect.to,sc:getEffectiveId())
					effect.to:setTag("manhuoeSC",ToData(sc))
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
							room:doGongxin(effect.to,effect.from,sgs.IntList(),self:objectName())
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
mantanduo = sgs.CreateTriggerSkill{
	name = "mantanduo",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseChanging then
	     	local change = data:toPhaseChange()
			if change.to==sgs.Player_Discard and player:getHandcardNum()>player:getMaxCards() then
				room:sendCompulsoryTriggerLog(player,self)
				change.to = sgs.Player_Draw
				data:setValue(change)
			end
		end
		return false
	end
}
man_mifang:addSkill(mantanduo)

man_yujin = sgs.General(shixinrumo_man,"man_yujin","shu",4)
mansuwu = sgs.CreateTriggerSkill{
	name = "mansuwu",
	events = {sgs.EventPhaseStart,sgs.CardUsed,sgs.PreCardUsed,sgs.CardFinished},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Start and player:hasSkill(self) then
				local tps = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers())do
					if p:getHandcardNum()>0 then tps:append(p) end
				end
				tps = room:askForPlayersChosen(player,tps,self:objectName(),0,4,"mansuwu0",true,true)
				for _,p in sgs.qlist(tps)do
					linkCard(room,room:askForCardChosen(player,p,"h",self:objectName()))
				end
			end
		elseif event==sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:isDamageCard() and player:getMark("mansuwuUse-Clear")<1 then
				for _,h in sgs.qlist(player:getHandcards())do
					if h:hasFlag("link_card") then
						room:setCardFlag(use.card,"mansuwuBf")
						player:addMark("mansuwuUse-Clear")
						break
					end
				end
			end
		elseif event==sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:hasFlag("mansuwuBf") then
				for _,p in sgs.qlist(room:getAllPlayers())do
					if p:hasSkill(self) then
						for _,h in sgs.qlist(p:getHandcards())do
							if h:hasFlag("link_card") then
								room:sendCompulsoryTriggerLog(p,self:objectName())
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
				player:drawCards(2,self:objectName())
			end
		end
		return false
	end
}
man_yujin:addSkill(mansuwu)
manrenwangvs = sgs.CreateViewAsSkill{
	name = "manrenwang",
	n = 1,
	response_or_use = true,
	view_filter = function(self,selected,to_select)
		return to_select:hasFlag("link_card")
	end,
	view_as = function(self,cards)
		if #cards<1 then return end
		local dc = sgs.Sanguosha:cloneCard("peach")
		dc:setSkillName("manrenwang")
		dc:addSubcard(cards[1])
		return dc
	end,
	enabled_at_response = function(self,player,pattern)
		return string.find(pattern,"peach") and player:hasTurn()
		and player:getMark("manrenwangUse-Clear")<1
	end,
	enabled_at_play = function(self,player)
		return player:getMark("manrenwangUse-Clear")<1
		and dummyCard("peach"):isAvailable(player)
	end,
}
manrenwang = sgs.CreateTriggerSkill{
	name = "manrenwang",
	view_as_skill = manrenwangvs,
	events = {sgs.PreCardUsed},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Peach") and table.contains(use.card:getSkillNames(),self:objectName()) then
				room:addPlayerMark(player,"manrenwangUse-Clear")
			end
		end
		return false
	end
}
man_yujin:addSkill(manrenwang)

man_guanyinping = sgs.General(shixinrumo_man,"man_guanyinping","shu",4,false)
manyinmou = sgs.CreateTriggerSkill{
	name = "manyinmou",
	events = {sgs.EventPhaseStart,sgs.EventForDiy},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Finish and player:isMale() then
				for _,p in sgs.qlist(room:getAllPlayers())do
					if p:hasSkill(self) then
						local pids = {}
						for _,h in sgs.qlist(player:getHandcards())do
							if h:hasFlag("link_card") then continue end
							table.insert(pids,h:getId())
						end
						local tids = sgs.IntList()
						for _,h in sgs.qlist(p:getHandcards())do
							if h:hasFlag("link_card") then tids:append(h:getId()) end
						end
						if #pids>0 and p:getHandcardNum()>tids:length() then
							local c = room:askForCard(player,table.concat(pids,","),"manyinmou0:"..p:objectName(),ToData(p),sgs.Card_MethodNone)
							if c then
								player:skillInvoked(self,-1,p)
								local id = room:askForCardChosen(player,p,"h",self:objectName(),false,sgs.Card_MethodNone,ids)
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
					if string.find(str,p:objectName().."=") and p:getMark("manyinmouUse-Clear")<1 and p:hasSkill(self) then
						room:sendCompulsoryTriggerLog(p,self)
						p:addMark("manyinmouUse-Clear")
						local aps = sgs.SPlayerList()
						for _,q in sgs.qlist(room:getAllPlayers())do
							if string.find(str,q:objectName().."=")
							then aps:append(q) end
						end
						room:drawCards(aps,math.min(#strs-1,5),self:objectName())
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
manquchi = sgs.CreateViewAsSkill{
	name = "manquchi",
	view_as = function(self,cards)
		return manquchiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#manquchiCard")<1
	end,
}
man_guanyinping:addSkill(manquchi)




shixinrumo_global = sgs.CreateTriggerSkill{
	name = "shixinrumo_global",
	global = true,
	events = {sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data,room)
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



return{shixinrumo_yi,shixinrumo_man}