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
				player:peiyin(self)
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
		return 0
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
					for i,p in sgs.qlist(room:getAllPlayers())do
						if p:inMyAttackRange(tp) or player==p then
							p:drawCards(2,self:objectName())
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
				for _,p in sgs.qlist(room:getAllPlayers())do
					local ids = p:getTag("yijuguIds"):toIntList()
					if ids:isEmpty() then continue end
					local dc = dummyCard()
					for _,id in sgs.qlist(room:getDrawPile())do
						if ids:contains(id) then dc:addSubcard(id) end
					end
					p:obtainCard(dc,true)
				end
				for _,p in sgs.qlist(room:getAllPlayers())do
					local ids = p:getTag("yijuguIds"):toIntList()
					if ids:isEmpty() then continue end
					p:removeTag("yijuguIds")
					p:drawCards(1,self:objectName())
				end
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
							player:drawCards(2,self:objectName())
							damage.from:drawCards(2,self:objectName())
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
					for _,p in sgs.list(tps)do
						local id = room:drawCardsList(p,1,self:objectName()):first()
						room:showCard(p,id)
						p:setMark("yimituId",id)
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
				player:obtainCard(c1)
				for _,id in sgs.list(InsertList({},ids))do
					local c2 = sgs.Sanguosha:getCard(id)
					if c1:getType()~=c2:getType() and c1:getNumber()~=c2:getNumber() and c1:getSuit()~=c2:getSuit()
					or room:getCardOwner(id)==room:getCardOwner(cid) or not player:canDiscard(room:getCardOwner(id),id) then
						room:takeAG(player,id,false,tps2)
						ids:removeOne(id)
					end
				end
				local dc = dummyCard()
				for i=1,3 do
					if ids:isEmpty() then break end
					cid = room:askForAG(player,ids,true,self:objectName(),"yizongheng2")
					if cid<0 then break end
					dc:addSubcard(cid)
					for _,id in sgs.list(InsertList({},ids))do
						local c2 = sgs.Sanguosha:getCard(id)
						if i==1 then
							if c1:getType()~=c2:getType()
							then continue end
						elseif i==2 then
							if c1:getSuit()~=c2:getSuit()
							then continue end
						elseif i==3 then
							if c1:getNumber()~=c2:getNumber()
							then continue end
						end
						room:takeAG(player,id,false,tps2)
						ids:removeOne(id)
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
			and player:canPindian(damage.from) and player:askForSkillInvoke(self) then
				local pd = delayedPingdian(self,player,damage.from)
				player:damageRevises(data,damage.damage)
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
	["&yi_jiangguan"] = "蒋干",
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
	["&yi_liubei"] = "刘备",
	["#yi_liubei"] = "潜隐波涛",
	["illustrator:yi_liubei"] = "鬼画府",
	["yichengbian"] = "乘变",
	[":yichengbian"] = "准备阶段和结束阶段，你可以进行延时拼点并视为对对方使用一张【决斗】，结算中双方可以将至少半数手牌当做【杀】打出；结算后公开拼点结果，赢的角色摸牌至体力上限。",
	["yichengbian0"] = "你可以与一名角色延时拼点",
	["yichengbian1"] = "乘变：你可以将半数手牌当做【杀】打出",

	["yi_fuhuanghou"] = "疑伏寿",
	["&yi_fuhuanghou"] = "伏寿",
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
	["&yi_xunyu"] = "荀彧",
	["#yi_xunyu"] = "末路见疑",
	["illustrator:yi_xunyu"] = "鬼画府",
	["yihuice"] = "迴策",
	[":yihuice"] = "出牌阶段限一次，你可以依次与两名其他角色拼点，然后每次赢的角色对另一次没赢的角色造成1点伤害。",
	["yiyihe"] = "异合",
	[":yiyihe"] = "锁定技，回合内各限一次，当一名角色受到伤害时，若其与伤害来源体力值和手牌数：不同，此伤害+1；相同，双方各摸两张牌。",
	["yijizhi"] = "赍志",
	[":yijizhi"] = "锁定技，其他角色不能对你使用【桃】；当你每回合首次陷入濒死时，你回复1点体力。",

	["yi_caopi"] = "疑曹丕",
	["&yi_caopi"] = "曹丕",
	["#yi_caopi"] = "兄友弟恭",
	["illustrator:yi_caopi"] = "鬼画府",
	["yizhengsi"] = "争嗣",
	[":yizhengsi"] = "出牌阶段，你可以选择包含你在内3名有手牌的角色，令第一名角色先展示一张手牌，其余角色再同时展示一张手牌；点数最大的角色弃置两张手牌，点数最小的角色失去1点体力。",
	["yichengming"] = "承命",
	[":yichengming"] = "出牌阶段结束时，若你在此阶段“争嗣”角色中；手牌数最大，你可以回复2点体力；体力值最大，你可以获得其他“争嗣”角色各一张牌。",
	["yichengming:yichengming1"] = "你可以发动“承命”回复2点体力",
	["yichengming:yichengming2"] = "你可以发动“承命”获得其他“争嗣”角色各一张牌",

	["yi_wanghou"] = "疑王垕",
	["&yi_wanghou"] = "王垕",
	["#yi_wanghou"] = "一刀斩讫",
	["illustrator:yi_wanghou"] = "鬼画府",
	["yijugu"] = "聚谷",
	[":yijugu"] = "准备阶段，你可以依次将任意角色共计5张牌正面朝上置于牌堆顶，此回合结束时，这些角色获得牌堆顶各自被放置的牌，然后各摸一张牌。",
	["yijugu0"] = "聚谷：请选择角色放置至多X张牌",

	["yi_lvboshe"] = "疑吕伯奢",
	["&yi_lvboshe"] = "吕伯奢",
	["#yi_lvboshe"] = "碧血东流",
	["illustrator:yi_lvboshe"] = "鬼画府",
	["yiqingjun"] = "请君",
	[":yiqingjun"] = "每轮结束时，你可以令一名其他角色执行一个额外回合，你和攻击范围内有其的角色各摸两张牌并发动“设伏”，此额外回合结束时，移去所有“伏兵”，本回合未受到伤害的“设伏”角色视为对其使用一张【杀】。",
	["yiqingjun0"] = "你可以发动“请君”选择一名角色",
	["yiqingjun1"] = "请选择一张手牌设伏【%src】",

	["yi_huatuo"] = "疑华佗",
	["&yi_huatuo"] = "华佗",
	["#yi_huatuo"] = "上医医国",
	["illustrator:yi_huatuo"] = "鬼画府",
	["yimiehai"] = "灭害",
	[":yimiehai"] = "你可以将两张牌当做无距离与次数限制的刺【杀】使用。此【杀】结算过程中正面朝上失去♠牌的已受伤角色摸两张牌并回复1点体力。",

	["yi_caocao"] = "疑曹操",
	["&yi_caocao"] = "曹操",
	["#yi_caocao"] = "一目窥九州",
	["illustrator:yi_caocao"] = "鬼画府",
	["yikuxin"] = "枯心",
	[":yikuxin"] = "当你受到伤害后，你可以令所有其他角色依次展示任意张手牌，你选择获得所有角色展示的牌或一名其他角色未展示的牌所有手牌并展示之。若你没有因此获得♥牌，你弃置获得的牌并翻面。",
	["yisigu"] = "似故",
	[":yisigu"] = "出牌阶段限一次，你可以令一名其他角色进行一次判定并对其造成两次1点伤害，期间其根据判定结果视为拥有对应的“受到伤害后”的技能。",
	["yikuxin0"] = "枯心：请选择任意张手牌展示",
	["yikuxin1"] = "枯心：你可以点击取消获得这些牌或选择一名角色获得其未展示的牌",

}
return{shixinrumo_yi}