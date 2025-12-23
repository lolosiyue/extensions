--==《新武将》==--
extension_qi = sgs.Package("kearjsrgqi", sgs.Package_GeneralPack)

--buff集中
keslashmore = sgs.CreateTargetModSkill{
	name = "keslashmore",
	pattern = ".",
	residue_func = function(self, from, card, to)
		if to and (to:getMark("&keqilue") > 0) and from:hasSkill("keqizhenglue") then
			return 999
		end
		if from:getJudgingArea():length()>0 and to and from:inMyAttackRange(to) and from:hasSkill("keqilimu") then
			return 999
		end
		if to and from:getMark("&kechengbiaozhaofrom+#"..to:objectName())>0 then
			return 999
		end
		if (table.contains(card:getSkillNames(), "kechengxianzhu")) and from:hasSkill("kechengxianzhu") then
			return 999
		end
		if (table.contains(card:getSkillNames(), "kezhuanzhenfeng"))and from:hasSkill("kezhuanzhenfeng") then
			return 999
		end
		if (table.contains(card:getSkillNames(), "kehexuanfeng")) then
			return 999
		end
		if to and (to:getMark("&kehezhubeisp-Clear") > 0) and from:hasSkill("kehezhubei") then
			return 999
		end
		if to and (to:getMark("&keshuaizhuni-Clear") > 0) and from:hasSkill("keshuaizhuni") then
			return 999
		end
		if (table.contains(card:getSkillNames(), "xingkuangjian")) then
			return 999
		end
		return 0
	end,
	extra_target_func = function(self, from, card)
		if card:isKindOf("FireAttack") 
		and table.contains(card:getSkillNames(), "keshuaiguanshi")
		and from:hasSkill("keshuaiguanshi") then
			return 999
		end
		local n = 0
		if (from:getMark("&kechengneifaNotBasic") > 0 and card:isNDTrick()) then
			n = n + 1
		end
		if from:hasSkill("keheguangao") then
		    n = n+1
		end
		return n
	end,
	distance_limit_func = function(self, from, card, to)
		if to and to:getMark("&keqilue") > 0 and from:hasSkill("keqizhenglue") then
			return 999
		end
		if from:getJudgingArea():length()>0 and to and from:inMyAttackRange(to) and from:hasSkill("keqilimu") then
			return 999
		end
		if to and from:getMark("&kechengbiaozhaofrom+#"..to:objectName())>0 then
			return 999
		end
		if (table.contains(card:getSkillNames(), "kezhuancuifeng")) then
			return 999
		end
		if card:isKindOf("Slash") and to and to:getMark("kezhuanrihui-Clear")<1
		and to:getJudgingArea():length()<1 and from:hasSkill("kezhuanrihui") then
			return 999
		end
		if (table.contains(card:getSkillNames(), "kezhuanzhenfeng")) and from:hasSkill("kezhuanzhenfeng") then
			return 999
		end
		if (from:getMark("&kezhuanfuni-Clear")>0) then
			return 999
		end
		if (table.contains(card:getSkillNames(), "kehexuanfeng")) then
			return 999
		end
		if to and (to:getMark("&keshuaizhuni-Clear") > 0) and from:hasSkill("keshuaizhuni") then
			return 999
		end
		if card:isKindOf("Slash") and table.contains(card:getSkillNames(), "keshuaiyansha") then
			return 999
		end
		return 0
	end
}
extension_qi:addSkills(keslashmore)



keqicaocao = sgs.General(extension_qi, "keqicaocao", "qun", 4)

keqizhenglue = sgs.CreateTriggerSkill{
    name = "keqizhenglue",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging,sgs.Damage},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			room:setPlayerMark(damage.from,"banzhenglue-Clear",1)
			if damage.from:hasSkill(self) and damage.to:getMark("&keqilue")>0
			and damage.from:getMark("zhengluemopai-Clear")<1
			and damage.from:askForSkillInvoke("keqizhenglue", data) then
				room:setPlayerMark(damage.from,"zhengluemopai-Clear",1)
				room:broadcastSkillInvoke(self:objectName())
				damage.from:drawCards(1,self:objectName())
				if damage.card then
					damage.from:obtainCard(damage.card)
				end
			end
		end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) and (player:getRole() == "lord") then
				for _, cc in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if room:askForSkillInvoke(cc, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						cc:drawCards(1,self:objectName())
						local players = sgs.SPlayerList()
						for _, pp in sgs.qlist(room:getAllPlayers()) do
							if (pp:getMark("&keqilue") == 0) then
								players:append(pp)
							end
						end
						if (player:getMark("banzhenglue-Clear") == 0) then
							local getlies = room:askForPlayersChosen(cc, players, self:objectName(), 0, 2, "keqizhenglue-ask", false, true)
							for _,p in sgs.qlist(getlies) do
								room:doAnimate(1,cc:objectName(),p:objectName())
								p:gainMark("&keqilue")
							end	
						else
							local one = room:askForPlayerChosen(cc, players, self:objectName(), "keqizhenglue-ask", true, false)
							if one then
								room:doAnimate(1,cc:objectName(),one:objectName())
							    one:gainMark("&keqilue")
							end
						end
					end
				end
			end
		end
	end,
}
keqicaocao:addSkill(keqizhenglue)

keqihuilie = sgs.CreatePhaseChangeSkill{
	name = "keqihuilie" ,
	frequency = sgs.Skill_Wake ,
	waked_skills = "keqipingrong,feiying",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		local num = 0
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("&keqilue") > 0 then
				num = num + 1
			end
		end
		if (num > 2 or player:canWake(self:objectName())) then
			room:notifySkillInvoked(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:doSuperLightbox("keqicaocao", "keqihuilie")
			room:setPlayerMark(player, self:objectName(), 1)
			if room:changeMaxHpForAwakenSkill(player,-1,self:objectName()) then
				if player:getMark(self:objectName()) == 1 then
					room:handleAcquireDetachSkills(player, "keqipingrong|feiying")
				end
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self) and target:getPhase() == sgs.Player_Start
		and target:getMark(self:objectName()) == 0 
			end
}
keqicaocao:addSkill(keqihuilie)

keqipingrong = sgs.CreateTriggerSkill{
    name = "keqipingrong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging,sgs.Damage,sgs.EventPhaseStart},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			room:setPlayerMark(damage.from,"inthekeqipingrong-Clear",0)
		end
		if (event == sgs.EventPhaseStart) then
			if player:getPhase()~=sgs.Player_NotActive then return false end
			for _,p in sgs.qlist(room:getAllPlayers())do
				if p:getMark("keqipingrongexturn")>0 then
					room:removePlayerMark(p,"keqipingrongexturn")
					room:setPlayerMark(p,"inthekeqipingrong-Clear",1)
					p:gainAnExtraTurn()
				end
			end
		end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				--执行额外回合惩罚
				if (player:getMark("inthekeqipingrong-Clear") > 0) then
					room:loseHp(player,1,true,player,self:objectName())
				end
				for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if (p:getMark("bankeqipingrong_lun") == 0) then--选择出本轮未发动过此技能的角色
						local players = sgs.SPlayerList()
						for _,pp in sgs.qlist(room:getAllPlayers()) do
							if (pp:getMark("&keqilue") > 0) then
								players:append(pp)
							end
						end
						local one = room:askForPlayerChosen(p, players, self:objectName(), "keqipingrong-ask", true, true)
						if one then
							room:broadcastSkillInvoke(self:objectName())
							room:addPlayerMark(p,"bankeqipingrong_lun")
							room:addPlayerMark(p,"keqipingrongexturn")
							one:loseAllMarks("&keqilue")
						end
					end
				end
			end
		end
	end,
}
extension_qi:addSkills(keqipingrong)

keqiliubei = sgs.General(extension_qi, "keqiliubei", "qun", 4)

keqijishan = sgs.CreateTriggerSkill{
    name = "keqijishan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted,sgs.Damage},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			if damage.from:hasSkill(self) and (damage.from:getMark("bandajishan-Clear") == 0) then
				local fris = sgs.SPlayerList()
				local hp = damage.from:getHp()
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if p:getHp()<hp then
						hp = p:getHp()
					end
				end
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if (p:getMark("&keqijishan") > 0) and p:getHp()<=hp then
						fris:append(p)
					end
				end
				local one = room:askForPlayerChosen(damage.from, fris, self:objectName(), "keqijishan-ask", true, true)
				if one then
					room:broadcastSkillInvoke(self:objectName())
					room:setPlayerMark(damage.from,"bandajishan-Clear",1)
					room:recover(one, sgs.RecoverStruct(self:objectName(),damage.from))
				end
			end
		end
		if (event == sgs.DamageInflicted) then
			local damage = data:toDamage()
			for _, lb in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if (lb:getMark("banjishan-Clear") == 0) then
					if lb:askForSkillInvoke(self,data) then
						room:broadcastSkillInvoke(self:objectName())
						room:setPlayerMark(lb,"banjishan-Clear",1)
						room:setPlayerMark(damage.to,"&keqijishan",1)
						room:loseHp(lb,1,true,lb,self:objectName())
						if lb:isAlive() then lb:drawCards(1,self:objectName()) end
						if damage.to:isAlive() then damage.to:drawCards(1,self:objectName()) end
						return true
					end
				end
			end		
		end
	end,
}
keqiliubei:addSkill(keqijishan)

keqizhenqiao = sgs.CreateTriggerSkill{
	name = "keqizhenqiao",
	events = {sgs.CardFinished,sgs.TargetSpecified},
	frequency = sgs.Skill_Compulsory, 
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if (event == sgs.TargetSpecified) then
			local use = data:toCardUse()
			if player:hasSkill(self) and use.card:isKindOf("Slash") and (not player:getWeapon()) then
				room:sendCompulsoryTriggerLog(player,self)
				room:setCardFlag(use.card,"usingzhenqiao")
			end
		end
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if (use.card:hasFlag("usingzhenqiao")) then
				if use.card:isKindOf("Slash") then--[[
					for _,p in sgs.qlist(use.to) do
						local se = sgs.SlashEffectStruct()
						se.from = use.from
						se.to = p
						se.slash = use.card
						se.nullified = table.contains(use.nullified_list, "_ALL_TARGETS") or table.contains(use.nullified_list, p:objectName())
						se.no_offset = table.contains(use.no_offset_list, "_ALL_TARGETS") or table.contains(use.no_offset_list, p:objectName())
						se.no_respond = table.contains(use.no_respond_list, "_ALL_TARGETS") or table.contains(use.no_respond_list, p:objectName())
						se.multiple = use.to:length() > 1
						se.nature = sgs.DamageStruct_Normal
						if use.card:objectName() == "fire_slash" then
							se.nature = sgs.DamageStruct_Fire
						elseif use.card:objectName() == "thunder_slash" then
							se.nature = sgs.DamageStruct_Thunder
						elseif use.card:objectName() == "ice_slash" then
							se.nature = sgs.DamageStruct_Ice
						end
						if use.from:getMark("drank") > 0 then
							room:setCardFlag(use.card, "drank")
							use.card:setTag("drank", sgs.QVariant(use.from:getMark("drank")))
						end
						se.drank = use.card:getTag("drank"):toInt()
						room:slashEffect(se)
					end--]]
					room:removeTag("UseHistory"..use.card:toString())
					use.card:use(room,use.from,use.to)--再次执行生效流程
				end
			end
		end
		return false
	end
}
keqiliubei:addSkill(keqizhenqiao)

keqizhenqiaoex = sgs.CreateAttackRangeSkill{
	name = "keqizhenqiaoex",
	extra_func = function(self, target)
		local n = 0
		if target:hasSkill("keqizhenqiao") then
			n = n+1
		end
		if target:hasSkill("xingzuodan") then
			local x = target:getHp()
			for _,p in sgs.qlist(target:getAliveSiblings()) do
				if p:getMark("&xingzuodan+#"..target:objectName())>0 then
					if p:getHp()>x then x = p:getHp() end
				end
			end
			n = n+math.min(5,x)
		end
		if target:hasSkill("xinglangan") then
			n = n-target:getMark("&xinglangan")
		end
		return n
	end
}
extension_qi:addSkills(keqizhenqiaoex)


keqisunjiantwo = sgs.General(extension_qi, "keqisunjiantwo", "qun", 4)

keqipingtaoCard = sgs.CreateSkillCard{
	name = "keqipingtaoCard" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, from)
		return (#targets == 0) and (to_select:objectName() ~= from:objectName()) 
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		local data = sgs.QVariant()
		data:setValue(player)
		room:setTag("keqipingtaoFrom",data)
		local card = room:askForExchange(target, "keqipingtao", 1,1, true, "#keqipingtao:".. player:getGeneralName(),true)
		if card then
			room:obtainCard(player, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), self:objectName(), ""), false)
			room:addSlashCishu(player,1, true)
		else
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:setSkillName("_keqipingtao")
			if player:canSlash(target,slash,false) then
				room:useCard(sgs.CardUseStruct(slash,player,target), false)
			end
			slash:deleteLater()
		end
	end
}

keqipingtao = sgs.CreateZeroCardViewAsSkill{
	name = "keqipingtao",
	enabled_at_play = function(self, player)
		return not player:hasUsed("#keqipingtaoCard") 
	end ,
	view_as = function()
		return keqipingtaoCard:clone()
	end
}
keqisunjiantwo:addSkill(keqipingtao)


--[[keqijueliedistwoCard = sgs.CreateSkillCard{
	name = "keqijueliedistwoCard",
    target_fixed = true,
    mute = true,
	on_use = function(self, room, source, targets)
		if source:isAlive() then
			local num = self:subcardsLength()
			room:setPlayerMark(source,"keqijueliemarktwo",num)
			room:broadcastSkillInvoke("keqijuelietwo")
		end
	end
}

keqijuelietwoVS = sgs.CreateViewAsSkill{
	name = "keqijuelietwo",
	n = 999,
	response_pattern = "@@keqijuelietwo",
	view_filter = function(self, selected, to_select)
        return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local dis_card = keqijueliedistwoCard:clone()
		for _,card in pairs(cards) do
			dis_card:addSubcard(card)
		end
		dis_card:setSkillName("keqijuelietwo")
		return dis_card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
}]]

keqijuelietwo = sgs.CreateTriggerSkill{
	name = "keqijuelietwo",
	events = {sgs.DamageCaused,sgs.TargetSpecified,sgs.CardFinished},
	frequency = sgs.Skill_NotFrequent, 
	--view_as_skill = keqijuelietwoVS,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card:hasFlag("newjueliecard") then
				for _,p in sgs.qlist(use.to) do
					room:setPlayerFlag(p,"-canjueliejiashang")
				end
			end
		end
		if (event == sgs.TargetSpecified) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				for _,p in sgs.qlist(use.to) do
					local to_data = sgs.QVariant()
					to_data:setValue(p)
					if not player:isNude() then
						local data = sgs.QVariant()
						data:setValue(player)
						room:setTag("keqijuelietwoFrom",data)
						local xxx = room:askForDiscard(player, self:objectName(), 99, 0, true, true, "keqijuelietwoask:"..p:objectName(), ".", self:objectName())
						if xxx then
							local disnum = xxx:getSubcards():length()
							room:broadcastSkillInvoke("keqijuelietwo")
							room:setCardFlag(use.card,"newjueliecard")
							room:setPlayerFlag(p,"canjueliejiashang")
							for i = 1, disnum do
								if p:canDiscard(p, "he") then
									local to_throw = room:askForCardChosen(player, p, "he", self:objectName())
									local card = sgs.Sanguosha:getCard(to_throw)
									room:throwCard(card, p, player)
								end
							end
						end
						--[[local will_use = room:askForSkillInvoke(player, self:objectName(), to_data)
						if will_use then
							room:askForUseCard(player, "@@keqijuelietwo", "keqijuelie-ask")
							if (player:getMark("keqijueliemarktwo") > 0) then
								room:setCardFlag(use.card,"newjueliecard")
								room:setPlayerFlag(p,"canjueliejiashang")
								for i = 0, player:getMark("keqijueliemarktwo") - 1, 1 do
									if p:canDiscard(p, "he") then
										local to_throw = room:askForCardChosen(player, p, "he", self:objectName())
										local card = sgs.Sanguosha:getCard(to_throw)
										room:throwCard(card, p, player)
									end
								end
								room:setPlayerMark(player,"keqijueliemarktwo",0)
							end
						end]]
					end
				end
			end
		end
		if (event == sgs.DamageCaused) then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") 
			and damage.to:hasFlag("canjueliejiashang") 
			and damage.card:hasFlag("newjueliecard") then
				local hpyes = 1
				local spyes = 1
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if (p:getHp() < player:getHp()) then
						hpyes = 0
					end
					if (p:getHandcardNum() < player:getHandcardNum()) then
						spyes = 0
					end
				end
				if (hpyes == 1) or (spyes == 1) then
					local hurt = damage.damage
					damage.damage = hurt + 1
					data:setValue(damage)
				end
			end
		end
		return false
	end
}
keqisunjiantwo:addSkill(keqijuelietwo)


keqidongbai = sgs.General(extension_qi, "keqidongbai", "qun", 3,false)

keqishichong = sgs.CreateTriggerSkill{
	name = "keqishichong",
	frequency = sgs.Skill_NotFrequent,
	change_skill = true,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if (use.to:length() == 1) and (not use.to:contains(use.from)) and (not use.card:isKindOf("SkillCard")) then
				local target = use.to:at(0)
				if (player:getChangeSkillState("keqishichong") == 1) then
					if (not target:isKongcheng()) and player:askForSkillInvoke(self, target) then
						room:broadcastSkillInvoke(self:objectName())
						room:setChangeSkillState(player, "keqishichong", 2)
						local card_id = room:askForCardChosen(player, target, "h", self:objectName())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
						room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
					end
				else
					local da = sgs.QVariant()
					da:setValue(player)
					room:setTag("keqishichongFrom",da)
					local card = room:askForExchange(target, self:objectName(), 1,1, false, "#keqishichongg:".. player:getGeneralName(),true)
					if card then
						room:broadcastSkillInvoke(self:objectName())
						room:setChangeSkillState(player, "keqishichong", 1)
						local log = sgs.LogMessage()
						log.type = "$keqishichonguse"
						log.from = target
						room:sendLog(log)
						room:obtainCard(player, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), self:objectName(), ""), false)
					end	
				end
			end
		end
	end
}
keqidongbai:addSkill(keqishichong)

keqilianzhuCard = sgs.CreateSkillCard{
	name = "keqilianzhuCard",
	will_throw = false,
	filter = function(self, targets, to_select, from)
		return (to_select:objectName() ~= from:objectName())
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:showCard(source,self:getSubcards():first())
		room:getThread():delay()
		room:giveCard(source,target,self,"keqilianzhu",true)
		for _,p in sgs.qlist(room:getOtherPlayers(source)) do
			if p:getKingdom() == target:getKingdom() then
				local dismantlement = sgs.Sanguosha:cloneCard("dismantlement")
				dismantlement:setSkillName("_keqilianzhu")
				dismantlement:deleteLater()
				if source:canUse(dismantlement,p) then
					room:useCard(sgs.CardUseStruct(dismantlement,source,p))
				end
			end
		end
	end,
}
keqilianzhu = sgs.CreateViewAsSkill{
	name = "keqilianzhu" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return to_select:isBlack() and (not to_select:isEquipped())
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local lzcard = keqilianzhuCard:clone()
		lzcard:addSubcard(cards[1])
		return lzcard
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#keqilianzhuCard") 
	end
}
keqidongbai:addSkill(keqilianzhu)



keqihejin = sgs.General(extension_qi, "keqihejin", "qun", 4)
keqizhaobing = sgs.CreateTriggerSkill{
    name = "keqizhaobing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Finish) and (not player:isKongcheng()) then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local num = player:getHandcardNum()
					player:throwAllHandCards(self:objectName())
					local targets = room:askForPlayersChosen(player, room:getOtherPlayers(player), self:objectName(), 0, num, "keqizhaobing-ask", true, true)
					for _,p in sgs.qlist(targets) do
						local card = room:askForExchange(p, self:objectName(), 1,1, true, "#keqizhaobing:".. player:objectName(),true,"Slash")
						if card then
							room:showCard(p,card:getEffectiveId())
							room:obtainCard(player, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), p:objectName(), self:objectName(), ""), false)
						else
							room:loseHp(p,1,true,player,self:objectName())
						end
					end	
				end
			end
		end
	end,
}
keqihejin:addSkill(keqizhaobing)

keqizhuhuan = sgs.CreateTriggerSkill{
    name = "keqizhuhuan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Start) then
				if (not player:isKongcheng()) and room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					room:showAllCards(player)
					local num = 0
					local dummy = sgs.Sanguosha:cloneCard("slash")
					for _, c in sgs.qlist(player:getCards("h")) do 
						if c:isKindOf("Slash") then
							num = num + 1
						    dummy:addSubcard(c:getId())
						end
					end
					room:throwCard(dummy, reason, player)
					dummy:deleteLater()
					local one = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "keqizhuhuan-ask", false, true)
					local choice = "getdamage="..num.."+getrecover="..num
					local result = room:askForChoice(one, self:objectName(),choice,data)
					if result:startsWith("getdamage") then 
						room:damage(sgs.DamageStruct(self:objectName(), player, one))
						room:askForDiscard(one, self:objectName(), num, num, false, true, "keqizhuhuan-discardda") 
					else
						room:recover(player, sgs.RecoverStruct(self:objectName(),player))
						player:drawCards(num,self:objectName())
					end
				end
			end
		end
	end,
}
keqihejin:addSkill(keqizhuhuan)



keqiyanhuo = sgs.CreateTriggerSkill{
	name = "keqiyanhuo",
	events = {sgs.Death,sgs.DamageCaused} ,
	frequency = sgs.Skill_Compulsory ,
	can_trigger = function(self, target)
		return target~=nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Death) then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then return false end
			if death.who:hasSkill(self:objectName()) then
				room:setTag("keqiyanhuonum", sgs.QVariant(1))
				room:sendCompulsoryTriggerLog(death.who,self)
			end
		end
		if (event == sgs.DamageCaused) then
			local damage = data:toDamage()
			if damage.card and (room:getTag("keqiyanhuonum"):toInt()>0) and damage.card:isKindOf("Slash") then
				room:sendCompulsoryTriggerLog(damage.from,"keqiyanhuo")
				local hurt = damage.damage
				damage.damage = 1 + hurt
				data:setValue(damage)
			end
		end
	end
}
keqihejin:addSkill(keqiyanhuo)



keqihuangfusong = sgs.General(extension_qi, "keqihuangfusong", "qun", 4)

keqiguanhuoCard = sgs.CreateSkillCard{
	name = "keqiguanhuoCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select)
		return (#targets < 1) and (not to_select:isKongcheng())
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:addPlayerMark(player,"usekeqiguanhuo-PlayClear",1)
		local fire_attack = sgs.Sanguosha:cloneCard("fire_attack")
		fire_attack:setSkillName("keqiguanhuo")
		local card_use = sgs.CardUseStruct()
		card_use.from = player
		card_use.to:append(target)
		card_use.card = fire_attack
		room:useCard(card_use, false)
		fire_attack:deleteLater()
	end
}
--主技能
keqiguanhuoVS = sgs.CreateViewAsSkill{
	name = "keqiguanhuo",
	view_as = function(self, cards)
		local fireattack = sgs.Sanguosha:cloneCard("fire_attack")
		fireattack:setSkillName("keqiguanhuo")
		fireattack:setFlags("keqiguanhuo")
		return fireattack--keqiguanhuoCard:clone()
	end,
	enabled_at_play = function(self, player)
		return true
	end,
}
keqiguanhuo = sgs.CreateTriggerSkill{
	name = "keqiguanhuo",
	view_as_skill = keqiguanhuoVS,
	events = {sgs.CardUsed,sgs.Damage,sgs.CardFinished,sgs.DamageForseen},
	can_trigger = function(self, target)
		return target
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:isKindOf("FireAttack") and (table.contains(use.card:getSkillNames(),"keqiguanhuo") or use.card:hasFlag("keqiguanhuo")) then
				room:setCardFlag(use.card,"keqiguanhuocard")
				room:addPlayerMark(player,"usekeqiguanhuo-PlayClear")
			end
		end
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("keqiguanhuocard") then
				room:setCardFlag(damage.card,"-keqiguanhuocard")
			end
		end
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card:hasFlag("keqiguanhuocard") then
				if use.from:hasSkill(self:objectName(),true) then
					if (use.from:getMark("usekeqiguanhuo-PlayClear") == 1) then
					    room:setPlayerMark(use.from,"&usekeqiguanhuoda-PlayClear",1)
				    elseif (use.from:getMark("usekeqiguanhuo-PlayClear") > 1) then
						room:handleAcquireDetachSkills(use.from, "-keqiguanhuo")
					end
				end
			end
		end
		if (event == sgs.DamageForseen) then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("FireAttack") and (damage.from:getMark("&usekeqiguanhuoda-PlayClear") > 0) then
				room:sendCompulsoryTriggerLog(damage.from,self)
				local hurt = damage.damage
				damage.damage = 1 + hurt
				data:setValue(damage)
			end
		end
	end ,
}
keqihuangfusong:addSkill(keqiguanhuo)


keqijuxia = sgs.CreateTriggerSkill{
	name = "keqijuxia",
	events = {sgs.TargetConfirmed},
	frequency = sgs.Skill_NotFrequent, 
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if use.to:contains(player) and (not use.card:isKindOf("SkillCard")) and use.from
		and player:getMark("&usekeqijuxia-Clear")<1 and player ~= use.from then
			local skill_listuse = {}
			local skill_listplayer = {}
			for _,skill in sgs.qlist(use.from:getVisibleSkillList()) do
				if (not table.contains(skill_listuse,skill:objectName())) and not skill:isAttachedLordSkill() then
					table.insert(skill_listuse,skill:objectName())
				end
			end
			for _,skill in sgs.qlist(player:getVisibleSkillList()) do
				if (not table.contains(skill_listplayer,skill:objectName())) and not skill:isAttachedLordSkill() then
					table.insert(skill_listplayer,skill:objectName())
				end
			end
			local numuse = #skill_listuse
			local numplayer = #skill_listplayer
			if (numuse > numplayer) then
				local _data = sgs.QVariant()
				_data:setValue(player)
				room:setTag("keqijuxiaData",data)
				if use.from:askForSkillInvoke(self, _data, false) then
					room:broadcastSkillInvoke(self:objectName())
					room:notifySkillInvoked(player,self:objectName())
					room:setPlayerMark(player,"&usekeqijuxia-Clear",1)
					local nullified_list = use.nullified_list
					table.insert(nullified_list, player:objectName())
					use.nullified_list = nullified_list
					data:setValue(use)
					player:drawCards(2,self:objectName())
				end
			end
		end	
	end
}
keqihuangfusong:addSkill(keqijuxia)



keqikongrong = sgs.General(extension_qi, "keqikongrong", "qun", 3)

keqilirang = sgs.CreateTriggerSkill{
    name = "keqilirang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd,sgs.CardsMoveOneTime},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Draw) then
				for _,kr in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if (kr:getMark("bankeqilirang_lun") == 0)
					and (kr:objectName() ~= player:objectName())
					and (kr:getCardCount() >= 2) then
						kr:setTag("keqilirangTo",ToData(player))
						local card = room:askForExchange(kr,self:objectName(), 2,2, true, "#keqilirang:".. player:objectName(),true)
						if card then
							local log = sgs.LogMessage()
							log.type = "$keqiliranggeipai"
							log.from = kr
							room:sendLog(log)
							room:setPlayerMark(kr,"bankeqilirang_lun",1)
							room:broadcastSkillInvoke(self:objectName())
							room:notifySkillInvoked(kr,self:objectName())
							room:obtainCard(player, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), kr:objectName(), self:objectName(), ""), false)
							room:setPlayerMark(kr,player:objectName().."usingkeqilirang-Clear",1)
							--这个轮标记是为了给“名仕”的
							room:setPlayerMark(player,"&keqilirang+#"..kr:objectName().."_lun",1)
						end
					end
				end
			end
		end
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.from and player:objectName() == move.from:objectName()
			and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_DISCARD
			and player:getPhase() == sgs.Player_Discard then
				local tag = player:getTag("lirangToGet"):toIntList()
				for _,card_id in sgs.qlist(move.card_ids) do
					tag:append(card_id)
				end
				local d = sgs.QVariant()
				d:setValue(tag)
				player:setTag("lirangToGet", d)
			end
		end
		if (event == sgs.EventPhaseEnd) then
			if (player:getPhase() == sgs.Player_Discard) then
				for _,kongrong in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if kongrong:getMark(player:objectName().."usingkeqilirang-Clear") > 0 then
						local tag = player:getTag("lirangToGet"):toIntList()
						local cards = sgs.IntList()
						for _,card_id in sgs.qlist(tag) do
							if room:getCardPlace(card_id) == sgs.Player_DiscardPile
							and not cards:contains(card_id) then cards:append(card_id) end
						end
						if cards:length() > 0 then
							if room:askForSkillInvoke(kongrong, "keqilirang_get", data) then
								room:broadcastSkillInvoke(self:objectName())
								local move = sgs.CardsMoveStruct()
								move.card_ids = cards
								move.to = kongrong
								move.to_place = sgs.Player_PlaceHand
								room:moveCardsAtomic(move, true)
							end	
						end
					end
				end
				player:removeTag("lirangToGet")
			end
		end
	end
}
keqikongrong:addSkill(keqilirang)

keqimingshi = sgs.CreateTriggerSkill{
    name = "keqimingshi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.DamageInflicted) then
			local damage = data:toDamage()
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("&keqilirang+#"..damage.to:objectName().."_lun")>0
				and damage.to:getMark("banmingshi-Clear")<1 then
					--本回合禁用！
					room:setPlayerMark(damage.to,"banmingshi-Clear",1)
					local to_data = sgs.QVariant()
					to_data:setValue(damage.to)
					if p:askForSkillInvoke(self, to_data) then
						room:broadcastSkillInvoke(self:objectName())
						damage.to = p
						damage.transfer = true
						data:setValue(damage)
						local log = sgs.LogMessage()
						log.type = "$keqimingshitran"
						log.from = p
						room:sendLog(log)
						player:setTag("TransferDamage",data)
						return true
					end 
				end
			end
		end
	end,
}
keqikongrong:addSkill(keqimingshi)


function askYishi(ysdata)
	if type(ysdata.from)~="userdata" then return end
	local log = sgs.LogMessage()
	log.type = "$askYishi"
	log.from = ysdata.from
	log.arg = ysdata.reason
	for _,p in sgs.list(ysdata.tos)do
		if p:getHandcardNum()>0 then
			log.to:append(p)
		end
	end
	ysdata.tos = {}
	ysdata.result = "no_result"
	if log.to:isEmpty() then return ysdata end
	local room = ysdata.from:getRoom()
    room:sortByActionOrder(log.to)
	room:sendLog(log)
	local yscards = {}
	for _,p in sgs.list(log.to)do
		table.insert(ysdata.tos,p:objectName())
		room:doAnimate(1,ysdata.from:objectName(),p:objectName())
	end
	ysdata.color_num = {}
	for _,p in sgs.list(log.to)do
		local data = sgs.QVariant("askyishicard:"..ysdata.reason..":"..ysdata.from:objectName()..":"..table.concat(ysdata.tos,"+"))
		room:getThread():trigger(sgs.EventForDiy,room,p,data)
		local ask = data:toString():split(":")
		if #ask>4 then
			yscards[p:objectName()] = sgs.Card_Parse(ask[5])
		end
		if type(yscards[p:objectName()])~="userdata" then
			local n = 1
			if #ask>5 then n = tonumber(ask[6]) end
			yscards[p:objectName()] = room:askForExchange(p, ysdata.reason.."_yishi", n, n, false, "askyishicard:"..n)
		end
	end
	ysdata.ids = {}
	ysdata.tos = {}
	ysdata.to2color = {}
	room:getThread():delay(800)
	for _,p in sgs.list(log.to)do
		local dc = yscards[p:objectName()]
		if type(dc)=="userdata" then
			room:showCard(p,dc:getSubcards())
			table.insert(ysdata.ids,dc:toString())
			table.insert(ysdata.tos,p:objectName())
			local colors = {}
			for _,id in sgs.list(dc:getSubcards())do
				local cs = sgs.Sanguosha:getCard(id):getColorString()
				local count = 1
				-- 可扩展的议事颜色计数修改机制
				local count_data = sgs.QVariant("yishi_color_count:"..ysdata.reason..":"..p:objectName()..":"..cs..":"..count)
				room:getThread():trigger(sgs.EventForDiy,room,p,count_data)
				local count_parts = count_data:toString():split(":")
				if #count_parts >= 5 then
					count = tonumber(count_parts[5]) or count
				end
				ysdata.color_num[cs] = (ysdata.color_num[cs] or 0)+count
				table.insert(colors,cs)
			end
			ysdata.to2color[p:objectName()] = table.concat(colors,"|")
		end
	end
	local x = 0
	ysdata.colors = {}
	room:getThread():delay(1200)
	for r,n in pairs(ysdata.color_num)do
		table.insert(ysdata.colors,r)
		if n>x then x = n end
	end
	local m = 0
	for r,n in pairs(ysdata.color_num)do
		if n>=x then
			m = m+1
			ysdata.result = m<2 and r or "no_result"
		end
	end
	log.from = ysdata.from
	log.type = "$yishiresult"
	log.arg = ysdata.result
	room:sendLog(log)
	room:doLightbox("$keyishi"..ysdata.result)
	if type(ysdata.effect)=="function" then
		ysdata.effect(ysdata)
	end
	local data = sgs.QVariant("yishiresult:"..ysdata.reason..":"..ysdata.from:objectName()..":"..table.concat(ysdata.tos,"+")..":"..table.concat(ysdata.ids,"+")..":"..ysdata.result)
	room:getThread():trigger(sgs.EventForDiy,room,ysdata.from,data)
	return ysdata
end

keqiliuhong = sgs.General(extension_qi, "keqiliuhong$", "qun", 4)

keqichaozheng = sgs.CreateTriggerSkill{
    name = "keqichaozheng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	--view_as_skill = keqichaozhengVS,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Start) and player:askForSkillInvoke(self, data) then
				room:broadcastSkillInvoke(self:objectName())
				--议事
				local ys = {}
				ys.reason = self:objectName()
				ys.from = player
				ys.tos = room:getOtherPlayers(player)
				ys.effect = function(ys_data)
					if ys_data.result=="red" then
						for i,pn in sgs.list(ys_data.tos)do
							if ys_data.to2color[pn]:match("red") then
								local to = room:findPlayerByObjectName(pn)
								room:recover(to, sgs.RecoverStruct(self:objectName(),player))
							end
						end
					elseif ys_data.result=="black" then
						for i,pn in sgs.list(ys_data.tos)do
							if ys_data.to2color[pn]:match("red") then
								local to = room:findPlayerByObjectName(pn)
								room:loseHp(to,1,true,player,self:objectName())
							end
						end
					end
				end
				askYishi(ys)
				if #ys.colors==1 then
					player:drawCards(#ys.tos,self:objectName())
				end
				--[[
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						room:setPlayerMark(p,"keyishiing",1)
						--每个人提前挑选牌准备展示
						if not p:isKongcheng() then
							local id = room:askForExchange(p, "keqichaozheng", 1, 1, false, "keqichaozheng_yishi"):getSubcards():first()
							--local id = room:askForCardChosen(p, p, "h", "keqichaozheng_yishi", false, sgs.Card_MethodNone, sgs.IntList(), false)
							local card = sgs.Sanguosha:getCard(id)
							room:setCardFlag(card,"useforyishi")
							if card:isRed() then
								room:setPlayerMark(p,"keyishi_red",1)
							elseif card:isBlack() then
								room:setPlayerMark(p,"keyishi_black",1)
							end
							--标记选择了牌的人（没有空城的人）
							room:setPlayerMark(p,"chooseyishi",1)
						end
					end
					--依次展示选好的牌，公平公正公开
					local sj = room:findPlayerBySkillName("kehebazheng")
					if sj then
						for _,bz in sgs.qlist(room:getAllPlayers()) do
							if (bz:getMark("&kehebazheng-Clear") > 0) then
								if (sj:getMark("keyishi_red") > 0) and (bz:getMark("keyishi_black") > 0) then
									room:setPlayerMark(bz,"keyishi_black",0)
									room:setPlayerMark(bz,"keyishi_red",1)
									local log = sgs.LogMessage()
									log.type = "$kehebazhengredlog"
									log.from = bz
									log.to:append(sj)
									room:sendLog(log)
								elseif (sj:getMark("keyishi_black") > 0) and (bz:getMark("keyishi_red") > 0) then
									room:setPlayerMark(bz,"keyishi_black",1)
									room:setPlayerMark(bz,"keyishi_red",0)
									local log = sgs.LogMessage()
									log.type = "$kehebazhengblacklog"
									log.from = bz
									log.to:append(sj)
									room:sendLog(log)
								end
							end
						end
					end
					room:getThread():delay(800)
					local yishirednum = 0
					local yishiblacknum = 0
					for _,p in sgs.qlist(room:getAllPlayers()) do
						if (p:getMark("keyishi_black") > 0) then yishiblacknum = yishiblacknum + 1 end
						if (p:getMark("keyishi_red") > 0) then yishirednum = yishirednum + 1 end
						for _,c in sgs.qlist(p:getCards("h")) do
							if c:hasFlag("useforyishi") then
								--if c:isRed() then yishirednum = yishirednum + 1 end
								--if c:isBlack() then yishiblacknum = yishiblacknum + 1 end
								room:showCard(p,c:getEffectiveId())
								room:setCardFlag(c,"-useforyishi")
								break
							end
						end
					end
					room:getThread():delay(1200)
					--0为平局（默认），1：红色；2：黑色
					local yishiresult = 0
					if (yishirednum > yishiblacknum) then
						yishiresult = 1
						local log = sgs.LogMessage()
						log.type = "$keyishired"
						log.from = player
						room:sendLog(log)	
						room:doLightbox("$keyishired")
					elseif (yishirednum < yishiblacknum) then
						yishiresult = 2
						local log = sgs.LogMessage()
						log.type = "$keyishiblack"
						log.from = player
						room:sendLog(log)	
						room:doLightbox("$keyishiblack")
					elseif (yishirednum == yishiblacknum) then
						yishiresult = 0
						local log = sgs.LogMessage()
						log.type = "$keyishipingju"
						log.from = player
						room:sendLog(log)	
						room:doLightbox("$keyishipingju")
					end
					--朝争效果：
					if (yishiresult == 1) then
						for _,p in sgs.qlist(room:getAllPlayers()) do
							if (p:getMark("keyishi_red")>0) then
								room:recover(p, sgs.RecoverStruct())
							end
						end
					elseif (yishiresult == 2) then
						for _,p in sgs.qlist(room:getAllPlayers()) do
							if (p:getMark("keyishi_red")>0) then
								room:loseHp(p,1,true,player)
							end
						end
					end
					--开始清理标记
					for _,p in sgs.qlist(room:getAllPlayers()) do
						if (p:getMark("keyishiing")>0) then room:setPlayerMark(p,"keyishiing",0) end
						if (p:getMark("chooseyishi")>0) then room:setPlayerMark(p,"chooseyishi",0) end
					end
					for _,p in sgs.qlist(room:getAllPlayers()) do
						if (p:getMark("keyishi_red")>0) then room:setPlayerMark(p,"keyishi_red",0) end
						if (p:getMark("keyishi_black")>0) then room:setPlayerMark(p,"keyishi_black",0) end
					end
					--结束后朝争效果
					if (yishirednum == 0) then
						player:drawCards(yishiblacknum)
					elseif (yishiblacknum == 0) then
						player:drawCards(yishirednum)
					end
					--清除ai
					for _,p in sgs.qlist(room:getAllPlayers()) do
						room:setPlayerFlag(p,"-chaozhengwantblack")
						room:setPlayerFlag(p,"-chaozhengwantred")
					end]]
			end
		end
	end,
}
keqiliuhong:addSkill(keqichaozheng)


keqishenchongCard = sgs.CreateSkillCard{
	name = "keqishenchongCard" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, from)
		return (#targets == 0) and (to_select:objectName() ~= from:objectName()) 
	end,
	on_use = function(self, room, player, targets)
		room:removePlayerMark(player,"@keqishenchong")
		room:doSuperLightbox("keqiliuhong", "keqishenchong")
		local target = targets[1]
		room:setPlayerMark(player,"useshenchong",1)
		room:setPlayerMark(target,"beuseshenchong",1)
		room:handleAcquireDetachSkills(target, "feiyang|bahu")	
	end
}

keqishenchongVS = sgs.CreateZeroCardViewAsSkill{
	name = "keqishenchong",
	frequency = sgs.Skill_Limited,
	limit_mark = "@keqishenchong",
	enabled_at_play = function(self, player)
		return (player:getMark("@keqishenchong") > 0) 
	end ,
	view_as = function()
		return keqishenchongCard:clone()
	end
}
keqishenchong = sgs.CreateTriggerSkill{
	name = "keqishenchong",
	frequency = sgs.Skill_Limited,
	limit_mark = "@keqishenchong",
	view_as_skill = keqishenchongVS,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who ~= player then return false end
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if (p:getMark("beuseshenchong")>0) then
				room:sendCompulsoryTriggerLog(player,self:objectName())
				local detachList = {}
				for _,skill in sgs.qlist(p:getVisibleSkillList())do
					if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() then
						table.insert(detachList,"-"..skill:objectName())
					end
				end
				room:handleAcquireDetachSkills(p, table.concat(detachList,"|"))
				p:throwAllHandCards(self:objectName())
			end
		end		

	end ,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}
keqiliuhong:addSkill(keqishenchong)


keqijulian = sgs.CreateTriggerSkill{
	name = "keqijulian$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.reason.m_reason==sgs.CardMoveReason_S_REASON_DRAW and move.reason.m_skillName ~= "keqijulian"
			and move.to and move.to:objectName() == player:objectName() and player:getPhase() ~= sgs.Player_Draw
			and player:hasFlag("CurrentPlayer") and player:getKingdom() == "qun" then
				for _, lh in sgs.qlist(room:getOtherPlayers(player))do
					if lh:hasLordSkill(self) then
						if (player:getMark("usekeqijulian-Clear") < 2)
						and player:askForSkillInvoke(self,data,false) then
							room:broadcastSkillInvoke("keqijulian")
							room:addPlayerMark(player,"usekeqijulian-Clear")
							local log = sgs.LogMessage()
							log.type = "$keqijulianmopai"
							log.from = player
							room:sendLog(log)
							room:notifySkillInvoked(lh,"keqijulian")
							player:drawCards(1, self:objectName())
						end
						break
					end
				end
			end
		end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish
		and player:hasLordSkill(self) and player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke("keqijulian")
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if (p:getKingdom() == "qun") and (not p:isKongcheng()) then
					local card_id = room:askForCardChosen(player, p, "h", self:objectName())
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
					room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}
keqiliuhong:addSkill(keqijulian)


keqiliuyan = sgs.General(extension_qi, "keqiliuyan$", "qun", 3)

--[[
keqilimuCard = sgs.CreateSkillCard{
	name = "keqilimuCard",
	target_fixed = true,
	will_throw = false,
	about_to_use = function(self, room, use)
		local c = sgs.Sanguosha:getCard(self:getSubcards():first())
		local card = sgs.Sanguosha:cloneCard("indulgence", c:getSuit(), c:getNumber())
		card:addSubcard(c:getEffectiveId())
		card:setSkillName(self:getSkillName())
		room:useCard(sgs.CardUseStruct(card, use.from, use.from), true)
		room:recover(use.from, sgs.RecoverStruct(use.from))	
	end
}
keqilimu = sgs.CreateOneCardViewAsSkill{
	name = "keqilimu",
	filter_pattern = ".|diamond|.|.",
	response_or_use = true,
	view_as = function(self, card)
		local lm = keqilimuCard:clone()
		lm:addSubcard(card:getEffectiveId())
		lm:setSkillName(self:objectName())
		return lm
	end,
	enabled_at_play = function(self, player)
		local card = sgs.Sanguosha:cloneCard("indulgence")
		card:deleteLater()
		return not player:containsTrick("indulgence") and not player:isProhibited(player, card)
	end
}
keqiliuyan:addSkill(keqilimu)]]
keqiliuyan:addSkill("limu")

keqitushe = sgs.CreateTriggerSkill{
	name = "keqitushe",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.to:length()>0 and not use.card:isKindOf("EquipCard") and not use.card:isKindOf("SkillCard") then
			if player:askForSkillInvoke(self, data) then
				room:broadcastSkillInvoke(self:objectName())
				room:showAllCards(player)
				for _, c in sgs.qlist(player:getCards("h")) do
					if c:isKindOf("BasicCard") then return end
				end
				player:drawCards(use.to:length(), self:objectName())
			end	
		end
	end
}
keqiliuyan:addSkill(keqitushe)

keqitongjueCard = sgs.CreateSkillCard{
	name = "keqitongjueCard" ,
	will_throw = false ,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, selected, to_select, source)
		return (#selected == 0) and (to_select:objectName() ~= source:objectName()) and (to_select:getKingdom() == "qun")
	end ,
	on_use = function(self, room, source, targets)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "keqitongjue", "")
		room:obtainCard(targets[1], self, reason, false)
		room:setPlayerMark(source,targets[1]:objectName().."usekeqitongjue-Clear",1)
	end
}
keqitongjue = sgs.CreateViewAsSkill{
	name = "keqitongjue$" ,
	n = 999 ,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local rende_card = keqitongjueCard:clone()
		for _, c in ipairs(cards) do
			rende_card:addSubcard(c)
		end
		return rende_card
	end ,
	enabled_at_play = function(self, player)
		return not (player:isKongcheng() or player:hasUsed("#keqitongjueCard"))
	end
}
keqiliuyan:addSkill(keqitongjue)

keqitongjueex = sgs.CreateProhibitSkill{
	name = "#keqitongjueex",
	is_prohibited = function(self, from, to, card)
		return from:getMark(to:objectName().."usekeqitongjue-Clear")>0
		and not card:isKindOf("SkillCard")
	end
}
extension_qi:insertRelatedSkills("keqitongjue", "#keqitongjueex")
extension_qi:addSkills(keqitongjueex)



--南华老仙

keqinanhualaoxiantwo = sgs.General(extension_qi, "keqinanhualaoxiantwo", "qun", 3)

function kedestroyEquip(room, move, tag_name) --销毁装备
	local id = room:getTag(tag_name):toInt()
	if move.card_ids:contains(id) then
		local move1 = sgs.CardsMoveStruct(id, nil, sgs.Player_PlaceTable,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, "", "destroy_equip", ""))
		local card = sgs.Sanguosha:getCard(id)
		local log = sgs.LogMessage()
		log.type = "#keDestroyEqiup"
		log.card_str = card:toString()
		room:sendLog(log)
		room:moveCardsAtomic(move1, true)
		room:removeTag(card:getClassName())
		return true
	end
end

--武将技能
keqishoushutwo = sgs.CreateTriggerSkill{
    name = "keqishoushutwo",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BeforeCardsMove,sgs.GameStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.BeforeCardsMove) then
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceEquip) and move.reason.m_skillName~="destroy_equip" then
				local ids = sgs.IntList()
				for i, id in sgs.qlist(move.card_ids)do
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("Taipingyaoshu") and move.from_places:at(i)==sgs.Player_PlaceEquip
					and kedestroyEquip(room,move,"KE_tpys") then
						ids:append(id)
					end
				end
				move:removeCardIds(ids)
				data:setValue(move)
			end
		end
		if (event == sgs.GameStart) then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getArmor() and p:getArmor():isKindOf("Taipingyaoshu")
				then return end
			end
			local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "keqishoushu-ask", false, true)
			if target then
				room:broadcastSkillInvoke(self:objectName())
				for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
					if sgs.Sanguosha:getEngineCard(id):isKindOf("Taipingyaoshu")
					and room:getCardOwner(id)==nil then
						room:setTag("KE_tpys",sgs.QVariant(id))
						local thecard = sgs.Sanguosha:getCard(id)
						room:moveCardTo(thecard, nil, sgs.Player_PlaceTable)
						local tos = sgs.SPlayerList()
						tos:append(target)
						thecard:use(room,player,tos)
						break
					end
				end
			end	
		end
	end,
}
keqinanhualaoxiantwo:addSkill(keqishoushutwo)


keqiwendao = sgs.CreateTriggerSkill{
	name = "keqiwendao" ,
	events = {sgs.AskForRetrial} ,
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		if (judge.who:objectName() == player:objectName()) then
			local players = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if not p:isNude() then
					players:append(p)
				end
			end
			room:setTag("keqiwendaoJudge",data)
			local daomeidans = room:askForPlayersChosen(player, players, self:objectName(), 0, 2, "keqiwendao-ask", true, true)
			if (daomeidans:length() > 0) then room:broadcastSkillInvoke(self:objectName()) end
			local to_throw = sgs.IntList()
			for _,p in sgs.qlist(daomeidans) do
				local card = room:askForDiscard(p, self:objectName(), 1, 1, false, true, "keqiwendao-discard")
				to_throw:append(card:getEffectiveId())
			end
			if to_throw:length()>0 then
				room:fillAG(to_throw,player)
				local card_id = room:askForAG(player, to_throw, false,self:objectName(), "keqiwendao-choice")
				room:clearAG(player)
				room:retrial(sgs.Sanguosha:getCard(card_id), player, judge, self:objectName())
			end
		end
	end
}
keqinanhualaoxiantwo:addSkill(keqiwendao)

keqixuanhua = sgs.CreateTriggerSkill{
    name = "keqixuanhua",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.Damaged},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.Damaged) then
			local damage = data:toDamage()
			if table.contains(damage.tips,self:objectName()) then
				room:setPlayerMark(player,"keqixuanhuahit",1)
			end
		end
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Start) then
				if room:askForSkillInvoke(player, self:objectName(), data) then 
					room:broadcastSkillInvoke(self:objectName())
					local room = player:getRoom()
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|spade|2~9"
					judge.good = false
					judge.negative = true
					judge.play_animation = true
					judge.reason = "lightning"
					judge.who = player
					room:judge(judge)
					if judge:isBad() then
						local damage = sgs.DamageStruct()
						damage.to = player
						damage.damage = 3
						damage.reason = "lightning"
						damage.nature = sgs.DamageStruct_Thunder
						local tips = damage.tips
						table.insert(tips,self:objectName())
						damage.tips = tips
						room:damage(damage)
					end
					if player:getMark("keqixuanhuahit")<1 and player:isAlive() then
						local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "keqixuanhuaco-ask", true, true)
						if target then
							room:recover(target, sgs.RecoverStruct(self:objectName(),player))	
						end
					end
					room:setPlayerMark(player,"keqixuanhuahit",0)
				end
			end
			if (player:getPhase() == sgs.Player_Finish) then
				if room:askForSkillInvoke(player, self:objectName(), data) then 
					room:broadcastSkillInvoke(self:objectName())
					local room = player:getRoom()
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|spade|2~9"
					judge.good = true
					judge.negative = false
					judge.play_animation = true
					judge.reason = "lightning"
					judge.who = player
					room:judge(judge)
					if judge:isBad() then
						local damage = sgs.DamageStruct()
						damage.to = player
						damage.damage = 3
						damage.reason = "lightning"
						damage.nature = sgs.DamageStruct_Thunder
						local tips = damage.tips
						table.insert(tips,self:objectName())
						damage.tips = tips
						room:damage(damage)
					end
					if player:getMark("keqixuanhuahit")<1 and player:isAlive() then
						local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "keqixuanhuada-ask", true, true)
						if target then
							local damagee = sgs.DamageStruct()
							damagee.to = target
							damagee.from = player
							damagee.damage = 1
							damagee.reason = self:objectName()
							damagee.nature = sgs.DamageStruct_Thunder
							room:damage(damagee)
						end
					end
					room:setPlayerMark(player,"keqixuanhuahit",0)
				end
			end
		end
	end,
}

keqinanhualaoxiantwo:addSkill(keqixuanhua)



--桥玄
keqiqiaoxuan = sgs.General(extension_qi, "keqiqiaoxuan", "qun", 3)

keqijuezhi = sgs.CreateTriggerSkill{
	name = "keqijuezhi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime,sgs.DamageCaused,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			room:setPlayerMark(player,"canusekeqijuezhi",1)
		end
		if (event == sgs.DamageCaused) then
			local damage = data:toDamage()
			if damage.card and (damage.from:objectName() == player:objectName()) 
			and (player:getPhase() ~= sgs.Player_NotActive) and (player:getMark("canusekeqijuezhi")>0) then
				local gain = 0
				--[[if (not player:hasEquipArea(0)) and (damage.to:getWeapon() ~= nil) then gain = gain + 1 end
				if (not player:hasEquipArea(1)) and (damage.to:getArmor() ~= nil) then gain = gain + 1 end
				if (not player:hasEquipArea(2)) and (damage.to:getDefensiveHorse() ~= nil) then gain = gain + 1 end
				if (not player:hasEquipArea(3)) and (damage.to:getOffensiveHorse() ~= nil) then gain = gain + 1 end
				if (not player:hasEquipArea(4)) and (damage.to:getTreasure() ~= nil) then gain = gain + 1 end]]
				for i,e in sgs.list(damage.to:getEquips()) do
					local index = e:getRealCard():toEquipCard():location()
					if not player:hasEquipArea(index) then gain = gain+1 end
				end
				if (gain > 0) then
					room:broadcastSkillInvoke(self:objectName())
					room:setPlayerMark(player,"canusekeqijuezhi",0)
					room:sendCompulsoryTriggerLog(player,self:objectName())
					local hurt = damage.damage
					damage.damage = hurt + gain
					data:setValue(damage)
				end
			end
		end
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceEquip)
			and move.from:objectName() == player:objectName() then
				for i,id in sgs.qlist(move.card_ids) do	
					local c = sgs.Sanguosha:getCard(id)
					if c:getTypeId()~=3 or move.from_places:at(i)~=sgs.Player_PlaceEquip then continue end
					local index = c:getRealCard():toEquipCard():location()
					local c_data = sgs.QVariant()
					c_data:setValue(index)
					if player:hasEquipArea(index)
					and player:askForSkillInvoke(self, c_data) then
						room:broadcastSkillInvoke(self:objectName())
						player:throwEquipArea(index)
					end--[[
					if sgs.Sanguosha:getCard(id):isKindOf("Weapon") then
						if player:hasEquipArea(0) then if room:askForSkillInvoke(player, "keqijuezhi_wq", data) then room:broadcastSkillInvoke(self:objectName()) player:throwEquipArea(0) end end
					end
					if sgs.Sanguosha:getCard(id):isKindOf("Armor") then
						if player:hasEquipArea(1) then if room:askForSkillInvoke(player, "keqijuezhi_fj", data) then room:broadcastSkillInvoke(self:objectName()) player:throwEquipArea(1) end end
					end
					if sgs.Sanguosha:getCard(id):isKindOf("DefensiveHorse") then
						if player:hasEquipArea(2) then if room:askForSkillInvoke(player, "keqijuezhi_fy", data) then room:broadcastSkillInvoke(self:objectName()) player:throwEquipArea(2) end end
					end
					if sgs.Sanguosha:getCard(id):isKindOf("OffensiveHorse") then
						if player:hasEquipArea(3) then if room:askForSkillInvoke(player, "keqijuezhi_jg", data) then room:broadcastSkillInvoke(self:objectName()) player:throwEquipArea(3) end end
					end
					if sgs.Sanguosha:getCard(id):isKindOf("Treasure") then
						if player:hasEquipArea(4) then if room:askForSkillInvoke(player, "keqijuezhi_bw", data) then room:broadcastSkillInvoke(self:objectName()) player:throwEquipArea(4) end end
					end--]]
				end
			end
		end
	end,

}
keqiqiaoxuan:addSkill(keqijuezhi)


keqijizhao = sgs.CreateTriggerSkill{
    name = "keqijizhao",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Finish) or (player:getPhase() == sgs.Player_Start) then
				local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "keqijizhao-ask", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					local pattern = {}
					for _,c in sgs.qlist(target:getCards("h")) do
						if c:isAvailable(target) then
							table.insert(pattern,c:getEffectiveId())
						end
					end
					if #pattern<1 or not room:askForUseCard(target, table.concat(pattern, ",") , "keqijizhaouse-ask") then
						choice = sgs.SPlayerList()
						choice:append(target)
						room:moveField(player,"keqijizhao",true,"ej",choice)
					end
				end
			end
		end
	end,
}
keqiqiaoxuan:addSkill(keqijizhao)



keqiwangyun = sgs.General(extension_qi, "keqiwangyun", "qun", 3)

keqishelunCard = sgs.CreateSkillCard{
	name = "keqishelunCard" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select,player)
		return (#targets == 0) and (to_select:objectName() ~= player:objectName()) and (player:inMyAttackRange(to_select))
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		local yishiplayers = sgs.SPlayerList()
		--确定议事人员
		for _,p in sgs.qlist(room:getOtherPlayers(target)) do
			if (p:getHandcardNum() <= player:getHandcardNum()) then
				yishiplayers:append(p)
			end
		end
		--开始议事
		room:setTag("keqishelunTo",ToData(target))
		local ys = {}
		ys.reason = self:getSkillName()
		ys.from = player
		ys.tos = yishiplayers
		ys.effect = function(ys_data)
			if (ys_data.result == "red") then
				if player:canDiscard(target, "he") then
					local to_throw = room:askForCardChosen(player, target, "he", self:objectName())
					room:throwCard(to_throw, target, player);
				end
			elseif (ys_data.result == "black") then
				room:damage(sgs.DamageStruct(self:objectName(), player, target))
			end
		end
		askYishi(ys)
		--[[
		for _,p in sgs.qlist(yishiplayers) do
			room:setPlayerMark(p,"keyishiing",1)
			--每个人提前挑选牌准备展示
			if not p:isKongcheng() then
				local id = room:askForExchange(p, "keqishelun", 1, 1, false, "keqichaozheng_yishi"):getSubcards():first()
				--local id = room:askForCardChosen(p, p, "h", "keqichaozheng_yishi", false, sgs.Card_MethodNone, sgs.IntList(), false)
				local card = sgs.Sanguosha:getCard(id)
				room:setCardFlag(card,"useforyishi")
				if card:isRed() then
					room:setPlayerMark(p,"keyishi_red",1)
				elseif card:isBlack() then
					room:setPlayerMark(p,"keyishi_black",1)
				end
				--标记选择了牌的人（没有空城的人）
				room:setPlayerMark(p,"chooseyishi",1)
			end
		end
		--依次展示选好的牌，公平公正公开
		local sj = room:findPlayerBySkillName("kehebazheng")
		if sj then
			for _,bz in sgs.qlist(room:getAllPlayers()) do
				if (bz:getMark("&kehebazheng-Clear") > 0) then
					if (sj:getMark("keyishi_red") > 0) and (bz:getMark("keyishi_black") > 0) then
						room:setPlayerMark(bz,"keyishi_black",0)
						room:setPlayerMark(bz,"keyishi_red",1)
						local log = sgs.LogMessage()
						log.type = "$kehebazhengredlog"
						log.from = bz
						log.to:append(sj)
						room:sendLog(log)
					elseif (sj:getMark("keyishi_black") > 0) and (bz:getMark("keyishi_red") > 0) then
						room:setPlayerMark(bz,"keyishi_black",1)
						room:setPlayerMark(bz,"keyishi_red",0)
						local log = sgs.LogMessage()
						log.type = "$kehebazhengblacklog"
						log.from = bz
						log.to:append(sj)
						room:sendLog(log)
					end
				end
			end
		end
		room:getThread():delay(800)
		local yishirednum = 0
		local yishiblacknum = 0
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if (p:getMark("keyishi_black") > 0) then yishiblacknum = yishiblacknum + 1 end
			if (p:getMark("keyishi_red") > 0) then yishirednum = yishirednum + 1 end
			for _,c in sgs.qlist(p:getCards("h")) do
				if c:hasFlag("useforyishi") then
					--if c:isRed() then yishirednum = yishirednum + 1 end
					--if c:isBlack() then yishiblacknum = yishiblacknum + 1 end
					room:showCard(p,c:getEffectiveId())
					room:setCardFlag(c,"-useforyishi")
					break
				end
			end
		end
		room:getThread():delay(1200)
		--0为平局（默认），1：红色；2：黑色
		local yishiresult = 0
		if (yishirednum > yishiblacknum) then
			yishiresult = 1
			local log = sgs.LogMessage()
			log.type = "$keyishired"
			log.from = player
			room:sendLog(log)	
			room:doLightbox("$keyishired")
		elseif (yishirednum < yishiblacknum) then
			yishiresult = 2
			local log = sgs.LogMessage()
			log.type = "$keyishiblack"
			log.from = player
			room:sendLog(log)	
			room:doLightbox("$keyishiblack")
		elseif (yishirednum == yishiblacknum) then
			yishiresult = 0
			local log = sgs.LogMessage()
			log.type = "$keyishipingju"
			log.from = player
			room:sendLog(log)	
			room:doLightbox("$keyishipingju")
		end
        --赦论效果
		if (yishiresult == 1) then
			if player:canDiscard(target, "he") then
				local to_throw = room:askForCardChosen(player, target, "he", self:objectName())
				local card = sgs.Sanguosha:getCard(to_throw)
				room:throwCard(card, target, player);
			end
		elseif (yishiresult == 2) then
			room:damage(sgs.DamageStruct(self:objectName(), player, target))
		end
		--结束
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if (p:getMark("keyishiing")>0) then room:setPlayerMark(p,"keyishiing",0) end
			if (p:getMark("chooseyishi")>0) then room:setPlayerMark(p,"chooseyishi",0) end
		end
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if (p:getMark("keyishi_red")>0) then room:setPlayerMark(p,"keyishi_red",0) end
			if (p:getMark("keyishi_black")>0) then room:setPlayerMark(p,"keyishi_black",0) end
		end]]
	end
}
keqishelunVS = sgs.CreateZeroCardViewAsSkill{
	name = "keqishelun",
	enabled_at_play = function(self, player)
		return not player:hasUsed("#keqishelunCard") 
	end ,
	view_as = function()
		return keqishelunCard:clone()
	end
}
keqishelun = sgs.CreateTriggerSkill{
	name = "keqishelun",
	view_as_skill = keqishelunVS,
	on_trigger = function(self, event, player, data)
	end ,
}
keqiwangyun:addSkill(keqishelun)
keqifayi = sgs.CreateTriggerSkill{
	name = "keqifayi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventForDiy},
	can_trigger = function(self,target)
		return target~=nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventForDiy) then
			local ys = data:toString()
			if ys:startsWith("yishiresult:") then
				local sts = ys:split(":")
				local tos = sts[4]:split("+")
				local ids = sts[5]:split("+")
				for i,pn in sgs.list(tos) do
					local to = room:findPlayerByObjectName(pn)
					if to:isAlive() and to:hasSkill(self) then
						-- Parse colors from card string (may contain multiple cards like "$1234+$5678")
						local card_str1 = ids[i]
						local has_red1 = false
						local has_black1 = false
						if card_str1 then
							local dc1 = sgs.Card_Parse(card_str1)
							if dc1 then
								for _,id in sgs.list(dc1:getSubcards()) do
									local cs = sgs.Sanguosha:getCard(id):getColorString()
									if cs == "red" then has_red1 = true end
									if cs == "black" then has_black1 = true end
								end
							end
						end
						-- Check if player has mixed colors (red|black)
						local is_mixed1 = has_red1 and has_black1
						
						local players = sgs.SPlayerList()
						for n,qn in sgs.list(tos) do
							local q = room:findPlayerByObjectName(qn)
							if q:isAlive() then
								-- Parse colors from card string
								local card_str2 = ids[n]
								local has_red2 = false
								local has_black2 = false
								if card_str2 then
									local dc2 = sgs.Card_Parse(card_str2)
									if dc2 then
										for _,id in sgs.list(dc2:getSubcards()) do
											local cs = sgs.Sanguosha:getCard(id):getColorString()
											if cs == "red" then has_red2 = true end
											if cs == "black" then has_black2 = true end
										end
									end
								end
								local can_choose = false
								if is_mixed1 then
									can_choose = true
								elseif has_red1 and not has_black1 then
									can_choose = has_black2
								elseif has_black1 and not has_red1 then
									can_choose = has_red2
								end
								
								if can_choose then
									players:append(q)
								end
							end
						end
						local eny = room:askForPlayerChosen(to, players, self:objectName(), "keqifayi-ask", true, true)
						if eny then
							room:broadcastSkillInvoke(self:objectName())
							room:damage(sgs.DamageStruct(self:objectName(), to, eny))
						end
					end
				end
			end
		end
	end,
}
keqiwangyun:addSkill(keqifayi)


keqixushao = sgs.General(extension_qi, "keqixushao", "qun", 3)
keqiyingmen = sgs.CreateTriggerSkill{
	name = "keqiyingmen" ,
	events = {sgs.TurnStart,sgs.GameStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data,room)
		local Generals = player:property("keqiyingmenGenerals"):toString():split("+")
		if #Generals>=4 then return end
		room:sendCompulsoryTriggerLog(player,self)
		local aps = {}
		for _,p in sgs.list(room:getAlivePlayers())do
			table.insert(aps,p:getGeneralName())
			table.insert(aps,p:getGeneral2Name())
		end
		local splist = sgs.SPlayerList()
		splist:append(player)
		local tes = {}
		for _,name in sgs.list(RandomList(sgs.Sanguosha:getLimitedGeneralNames()))do
			if table.contains(Generals,name) or table.contains(aps,name) then continue end
			room:doAnimate(4,player:objectName(),"unknown",room:getOtherPlayers(player))
			room:doAnimate(4,player:objectName(),name,splist)
			table.insert(Generals,name)
			if #Generals>3 then break end
		end
		for _,name in sgs.list(Generals)do
			table.insert(tes,sgs.Sanguosha:translate(name))
		end
		sgs.Sanguosha:addTranslationEntry(":&keqiyingmenGenerals",table.concat(tes,"、"))
		room:setPlayerProperty(player,"keqiyingmenGenerals",ToData(table.concat(Generals,"+")))
		room:setPlayerMark(player,"&keqiyingmenGenerals",#Generals)
		return false
	end
}
keqixushao:addSkill(keqiyingmen)
function qiPingSkills(player)
	local sk = {}
	for _,n in sgs.list(player:property("keqiyingmenGenerals"):toString():split("+"))do
		for _,s in sgs.list(sgs.Sanguosha:getGeneral(n):getVisibleSkillList())do
			if s:isLordSkill() or s:isChangeSkill() or s:isLimitedSkill() or s:isHideSkill()
			or s:isShiMingSkill() or s:getFrequency(player)==sgs.Skill_Wake
			then continue end
			table.insert(sk,s)
		end
	end
	return sk
end
keqipingjianCard = sgs.CreateSkillCard{
	name = "keqipingjianCard",
	target_fixed = true,
	about_to_use = function(self,room,use)
		local qipjsks = {}
		for _,s in sgs.list(qiPingSkills(use.from))do
			if s:inherits("FilterSkill") then continue end
			if s:inherits("ViewAsSkill") and sgs.Sanguosha:getViewAsSkill(s:objectName()):isEnabledAtPlay(use.from)
			then table.insert(qipjsks,s:objectName()) end
			if s:inherits("TriggerSkill") then
				local ts = sgs.Sanguosha:getTriggerSkill(s:objectName())
				ts = ts:getViewAsSkill()
				if ts and ts:isEnabledAtPlay(use.from)
				then table.insert(qipjsks,ts:objectName()) end
			end
		end
		local qipjsk = room:askForChoice(use.from,"keqipingjian",table.concat(qipjsks,"+"))
		room:setPlayerMark(use.from,"keqipingjianSkill-PlayClear",1)
		room:setPlayerProperty(use.from,"keqipjSkill",sgs.QVariant(qipjsk))
		room:askForUseCard(use.from,"@@keqipingjian","keqipingjian0:"..qipjsk,-1,sgs.Card_MethodPlay)
	end
}
keqipingjianvs = sgs.CreateViewAsSkill{
	name = "keqipingjian",
	n = 999,
	view_filter = function(self,selected,to_select)
		if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_PLAY
		and sgs.Self:getMark("keqipingjianSkill-PlayClear")<1 then return end
		local cards = sgs.CardList()
		for _,c in sgs.list(selected)do
			cards:append(c)
		end
		local va = sgs.Sanguosha:getViewAsSkill(sgs.Self:property("keqipjSkill"):toString())
		return va and va:viewFilter(cards,to_select)
	end,
	view_as = function(self,selected)
		if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_PLAY
		and sgs.Self:getMark("keqipingjianSkill-PlayClear")<1
		then return keqipingjianCard:clone()
		else
			local cards = sgs.CardList()
			for _,c in sgs.list(selected)do
				cards:append(c)
			end
			local va = sgs.Sanguosha:getViewAsSkill(sgs.Self:property("keqipjSkill"):toString())
			return va and va:viewAs(cards)
		end
	end,
	enabled_at_response = function(self,player,pattern)
	   	if pattern=="@@keqipingjian" then return true end
		for _,s in sgs.list(qiPingSkills(player))do
			player:setProperty("keqipjSkill",sgs.QVariant(s:objectName()))
			if sgs.Self then sgs.Self:setProperty("keqipjSkill",sgs.QVariant(s:objectName())) end
			if s:inherits("ViewAsSkill") and sgs.Sanguosha:getViewAsSkill(s:objectName()):isEnabledAtResponse(player,pattern)
			then return true end
			if s:inherits("TriggerSkill") then
				s = sgs.Sanguosha:getTriggerSkill(s:objectName())
				s = s:getViewAsSkill()
				if s and s:isEnabledAtResponse(player,pattern)
				then return true end
			end
		end
	end,
	enabled_at_play = function(self,player)
		for _,s in sgs.list(qiPingSkills(player))do
			if s:inherits("FilterSkill") then continue end
			if s:inherits("ViewAsSkill") and sgs.Sanguosha:getViewAsSkill(s:objectName()):isEnabledAtPlay(player)
			then return true end
			if s:inherits("TriggerSkill") then
				s = sgs.Sanguosha:getTriggerSkill(s:objectName())
				s = s:getViewAsSkill()
				if s and s:isEnabledAtPlay(player)
				then return true end
			end
		end
		return false
	end,
}
local events = {}
for i=sgs.GameStart,sgs.EventForDiy do
	table.insert(events,i)
end
keqipingjian = sgs.CreateTriggerSkill{
	name = "keqipingjian",
	events = events,
	view_as_skill = keqipingjianvs,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if player:hasSkill(self) then
			if event==sgs.ChoiceMade then
				local cm = data:toString()
				if cm:startsWith("notifyInvoked:") then
					cm = cm:split(":")
					for _,s in sgs.list(qiPingSkills(player))do
						if s:objectName()==cm[2] then
							player:addMark("keqipingjianUse"..cm[2])
							break
						end
					end
				end
			elseif event==sgs.CardFinished then
				room:setPlayerMark(player,"keqipingjianSkill-PlayClear",0)
				local use = data:toCardUse()
				if use.card:getSkillName()~="" then
					for _,s in sgs.list(qiPingSkills(player))do
						if table.contains(use.card:getSkillNames(),s:objectName()) then
							room:broadcastSkillInvoke(self:objectName())
							local yg = player:property("keqiyingmenGenerals"):toString()
							local choice = room:askForChoice(player,"keqipingjianRemove",yg)
							yg = yg:split("+")
							table.removeOne(yg,choice)
							local log = sgs.LogMessage()
							log.type = "$keqiyingmenremoveOne"
							log.from = player
							log.arg = choice
							room:sendLog(log)
							room:setPlayerMark(player,"&keqiyingmenGenerals",#yg)
							room:setPlayerProperty(player,"keqiyingmenGenerals",ToData(table.concat(yg,"+")))
							local tes = {}
							for _,name in sgs.list(yg)do
								table.insert(tes,sgs.Sanguosha:translate(name))
							end
							sgs.Sanguosha:addTranslationEntry(":&keqiyingmenGenerals",table.concat(tes,"、"))
							if sgs.Sanguosha:getGeneral(choice):hasSkill(s:objectName())
							then player:drawCards(1,self:objectName()) end
							break
						end
					end
				end
			end
		end
		for _,owner in sgs.list(room:findPlayersBySkillName(self:objectName()))do
			for _,s in sgs.list(qiPingSkills(owner))do
				local ts = sgs.Sanguosha:getTriggerSkill(s:objectName())
				if ts and ts:hasEvent(event) then
					owner:acquireSkill(ts:objectName())
					if ts:triggerable(player) then ts:trigger(event,room,player,data) end
					owner:detachSkill(ts:objectName())
					if owner:getMark("keqipingjianUse"..ts:objectName())>0 then
						owner:setMark("keqipingjianUse"..ts:objectName(),0)
						room:broadcastSkillInvoke(self:objectName())
						local yg = owner:property("keqiyingmenGenerals"):toString()
						local choice = room:askForChoice(owner,"keqipingjianRemove",yg)
						yg = yg:split("+")
						table.removeOne(yg,choice)
						local log = sgs.LogMessage()
						log.type = "$keqiyingmenremoveOne"
						log.from = owner
						log.arg = choice
						room:sendLog(log)
						room:setPlayerMark(owner,"&keqiyingmenGenerals",#yg)
						room:setPlayerProperty(owner,"keqiyingmenGenerals",ToData(table.concat(yg,"+")))
						local tes = {}
						for _,name in sgs.list(yg)do
							table.insert(tes,sgs.Sanguosha:translate(name))
						end
						sgs.Sanguosha:addTranslationEntry(":&keqiyingmenGenerals",table.concat(tes,"、"))
						if sgs.Sanguosha:getGeneral(choice):hasSkill(ts:objectName())
						then owner:drawCards(1,self:objectName()) end
					end
				end
			end
		end
		return false
	end
}
keqixushao:addSkill(keqipingjian)

keqiyangbiao = sgs.General(extension_qi, "keqiyangbiao", "qun", 4, true, false, false, 3)

keqizhaohan = sgs.CreateTriggerSkill{
	name = "keqizhaohan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.SwappedPile,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.SwappedPile) then
			room:setTag("keqizhaohan", sgs.QVariant(1))
		end
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Start) then
				if (room:getTag("keqizhaohan"):toInt() ~= 1) then
					room:broadcastSkillInvoke(self:objectName(),1)
					room:recover(player, sgs.RecoverStruct())	
				else
					room:broadcastSkillInvoke(self:objectName(),2)
					room:loseHp(player,1,true,player,self:objectName())
				end
			end
		end
	end
}
keqiyangbiao:addSkill(keqizhaohan)

keqirangjie = sgs.CreateTriggerSkill{
	name = "keqirangjie",
	events = {sgs.Damaged,sgs.EventPhaseChanging,sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if (move.to_place == sgs.Player_DiscardPile) then
				local ids = room:getTag("rangjieToGet"):toIntList()
				for _,card_id in sgs.qlist(move.card_ids) do
					ids:append(card_id)
				end
				local ta = sgs.QVariant()
				ta:setValue(ids)
				room:setTag("rangjieToGet", ta)
			end
			if move.reason.m_skillName==self:objectName() then
				player:setMark("rangjieId",move.card_ids:first())
			end
		end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				room:removeTag("rangjieToGet")
			end
		end
		if (event == sgs.Damaged) and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			for i = 1, damage.damage do
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					if room:moveField(player,"keqirangjie",true,"ej") then
						local tag = room:getTag("rangjieToGet"):toIntList()
						local cards = sgs.IntList()
						local c = player:getMark("rangjieId")
						c = sgs.Sanguosha:getCard(c)
						for _, id in sgs.qlist(room:getDiscardPile()) do
							if tag:contains(id) and sgs.Sanguosha:getCard(id):getSuit()==c:getSuit() then
								cards:append(id)
							end
						end
						if cards:length()>0 then
							room:fillAG(cards, player)
							local to_back = room:askForAG(player, cards, false, self:objectName())
							room:clearAG(player)
							player:obtainCard(sgs.Sanguosha:getCard(to_back))
						end
					end
				else
					break
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}
keqiyangbiao:addSkill(keqirangjie)

keqiyizhengCard = sgs.CreateSkillCard{
	name = "keqiyizhengCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and player:canPindian(to_select, true)
		and to_select:getHandcardNum() > player:getHandcardNum()
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		if player:pindian(target, "keqiyizheng") then
			room:setPlayerMark(target,"&keqiyizheng",1)
		else
			local result = room:askForChoice(target,self:objectName(),"zero+one+two",ToData(player))
			local damage = sgs.DamageStruct(self:objectName(),target,player)
			if result == "one" then
				damage.damage = 1
				room:damage(damage)
			end
			if result == "two" then	
				damage.damage = 2
				room:damage(damage)
			end
		end
	end
}

keqiyizhengVS = sgs.CreateViewAsSkill{
	name = "keqiyizheng",
	n = 0,
	view_as = function(self, cards)
		return keqiyizhengCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not (player:hasUsed("#keqiyizhengCard")) 
	end, 
}
keqiyizheng = sgs.CreateTriggerSkill{
	name = "keqiyizheng",
	view_as_skill = keqiyizhengVS,
	events = {sgs.EventPhaseChanging},
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local room = player:getRoom()
			if (change.to == sgs.Player_Draw) and (player:isAlive()) and (player:getMark("&keqiyizheng")>0) then
				room:setPlayerMark(player,"&keqiyizheng",0)
				if not player:isSkipped(sgs.Player_Draw) then
			    	player:skip(sgs.Player_Draw)
				end
			end
		end
	end ,
}
keqiyangbiao:addSkill(keqiyizheng)


keqizhujun = sgs.General(extension_qi, "keqizhujun", "qun", 4)

keqifendi = sgs.CreateTriggerSkill{
	name = "keqifendi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetSpecified,sgs.Damage,sgs.CardFinished},
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card:hasFlag("keqifendislash") then
				for _,p in sgs.qlist(use.to) do
					if (p:getMark("beusekeqifendi")  > 0) then
						room:setPlayerMark(p,"beusekeqifendi",0)
						local pattern = p:getTag("keqifendiLimit"):toString()
						if pattern=="" then continue end
						p:removeTag("keqifendiLimit")
						room:removePlayerCardLimitation(p, "use,response", pattern)
					end
				end
				player:removeTag("keqifendiIds")
			end
		end	
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("keqifendislash") 
			and player:hasSkill(self:objectName()) then
				local dummy = sgs.Sanguosha:cloneCard("slash")
				local ids = player:getTag("keqifendiIds"):toIntList()
				for _,id in sgs.qlist(damage.to:handCards()) do
					if ids:contains(id) then
						dummy:addSubcard(id)
					end
				end
				if dummy:subcardsLength()<1 then
					for _,id in sgs.qlist(room:getDiscardPile()) do
						if ids:contains(id) then
							dummy:addSubcard(id)
						end
					end
				end
				player:obtainCard(dummy)
				dummy:deleteLater()
			end
		end

		if (event == sgs.TargetSpecified) then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and player:getMark("bankeqifendi-Clear") < 1
			and use.to:length() == 1 and player:hasSkill(self) then
				local target = use.to:at(0)
				if not target:isKongcheng() then
					local _data = sgs.QVariant()
					_data:setValue(target)
					if player:askForSkillInvoke(self, _data) then
						room:setPlayerMark(player,"bankeqifendi-Clear",1)
						room:setPlayerMark(target,"beusekeqifendi",1)
						room:setCardFlag(use.card,"keqifendislash")
						room:broadcastSkillInvoke(self:objectName())
						local ids = sgs.IntList()
						for i = 1, target:getHandcardNum() do
							local id = room:askForCardChosen(player,target,"h",self:objectName(),false,sgs.Card_MethodNone,ids,i>1)
							if id<0 then break end
							ids:append(id)
						end
						room:showCard(target,ids)
						_data:setValue(ids)
						player:setTag("keqifendiIds",_data)
						local pattern = {}
						for _,id in sgs.qlist(target:handCards()) do
							if not ids:contains(id) then
								table.insert(pattern,id)
							end
						end
						if #pattern<1 then return end
						pattern = table.concat(pattern, ",")
						room:setPlayerCardLimitation(target, "use,response", pattern, false)
						target:setTag("keqifendiLimit",sgs.QVariant(pattern))
					end
				end
			end
		end
	end,
}
keqizhujun:addSkill(keqifendi)


keqijuxiang = sgs.CreateTriggerSkill{
	name = "keqijuxiang",
	events = {sgs.CardsMoveOneTime,sgs.DrawInitialCards,sgs.GameStart},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_PlaceHand
			and move.to:objectName() == player:objectName()
			and move.reason.m_skillName~="InitialHandCards"
			and player:getPhase()~=sgs.Player_Draw
			and player:hasSkill(self:objectName()) then
				local dummy = sgs.Sanguosha:cloneCard("slash")
				dummy:deleteLater()
				for _,id in sgs.qlist(move.card_ids) do	
					if player:handCards():contains(id) then
						dummy:addSubcard(id)
					end
				end
				if dummy:subcardsLength()>0 and player:askForSkillInvoke(self, data) then
					room:broadcastSkillInvoke(self:objectName())
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
					room:throwCard(dummy, reason, player)
					local ss = {}
					for _,id in sgs.qlist(dummy:getSubcards()) do	
						local s = sgs.Sanguosha:getCard(id):getSuit()
						if table.contains(ss,s) then continue end
						table.insert(ss,s)
					end
					local log = sgs.LogMessage()
					log.from = room:getCurrent()
					log.type = "$keqijuxiangadd"
					room:addSlashCishu(log.from,#ss, true)
					room:sendLog(log)
				end
			end
		end
	end,
}
keqizhujun:addSkill(keqijuxiang)

keqisunjian = sgs.General(extension_qi, "keqisunjian", "qun", 4,true,true)

keqisunjian:addSkill("keqipingtao")
keqijueliedisCard = sgs.CreateSkillCard{
	name = "keqijueliedisCard",
    target_fixed = true,
    mute = true,
	on_use = function(self, room, source, targets)
		if source:isAlive() then
			local num = self:subcardsLength()
			room:setPlayerMark(source,"keqijueliemark",num)
			room:broadcastSkillInvoke("keqijuelie")
		end
	end
}

keqijuelieVS = sgs.CreateViewAsSkill{
	name = "keqijuelie",
	n = 999,
	response_pattern = "@@keqijuelie",
	view_filter = function(self, selected, to_select)
        return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local dis_card = keqijueliedisCard:clone()
		for _,card in pairs(cards) do
			dis_card:addSubcard(card)
		end
		dis_card:setSkillName("keqijuelie")
		return dis_card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
}

keqijuelie = sgs.CreateTriggerSkill{
	name = "keqijuelie",
	events = {sgs.DamageCaused,sgs.TargetSpecified},
	frequency = sgs.Skill_Frequent, 
	view_as_skill = keqijuelieVS,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if (event == sgs.TargetSpecified) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				for _,p in sgs.qlist(use.to) do
					if not player:isNude() and room:askForUseCard(player, "@@keqijuelie", "keqijuelie-ask") then
						if (player:getMark("keqijueliemark") > 0) then
							for i = 1, player:getMark("keqijueliemark") do
								if p:canDiscard(p, "he") then
									local to_throw = room:askForCardChosen(player, p, "he", self:objectName())
									local card = sgs.Sanguosha:getCard(to_throw)
									room:throwCard(card, p, player);
								end
							end
							room:setPlayerMark(player,"keqijueliemark",0)
						end
					end
				end
			end
		end
		if (event == sgs.DamageCaused) then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				local hpyes = 1
				local spyes = 1
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if (p:getHp() < player:getHp()) then
						hpyes = 0
					end
					if (p:getHandcardNum() < player:getHandcardNum()) then
						spyes = 0
					end
				end
				if (hpyes == 1) or (spyes == 1) then
					local hurt = damage.damage
					damage.damage = hurt + 1
					data:setValue(damage)
				end
			end
		end
		return false
	end
}
keqisunjian:addSkill(keqijuelie)




keqinanhualaoxian = sgs.General(extension_qi, "keqinanhualaoxian", "qun", 3,true,true)
keqishoushu = sgs.CreateTriggerSkill{
    name = "keqishoushu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.RoundStart,sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.BeforeCardsMove) then
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceEquip) and move.reason.m_skillName~="destroy_equip" then
				local ids = sgs.IntList()
				for i, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("Taipingyaoshu") and move.from_places:at(i)==sgs.Player_PlaceEquip
					and kedestroyEquip(room,move,"KE_tpys") then
						ids:append(id)
					end
				end
				move:removeCardIds(ids)
				data:setValue(move)
			end
		end
		if (event == sgs.RoundStart) then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getArmor() and p:getArmor():isKindOf("Taipingyaoshu")
				then return end
			end
			local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "keqishoushu-ask", false, true)
			if target then
				room:broadcastSkillInvoke(self:objectName())
				for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
					if sgs.Sanguosha:getEngineCard(id):isKindOf("Taipingyaoshu")
					and room:getCardOwner(id)==nil then
						room:setTag("KE_tpys",sgs.QVariant(id))
						local thecard = sgs.Sanguosha:getCard(id)
						room:moveCardTo(thecard, nil, sgs.Player_PlaceTable)
						local tos = sgs.SPlayerList()
						tos:append(target)
						thecard:use(room,player,tos)
						break
					end
				end
			end	
		end
	end,
}
keqinanhualaoxian:addSkill(keqishoushu)

keqinanhualaoxian:addSkill("keqiwendao")

keqinanhualaoxian:addSkill("keqixuanhua")

keqiduanwei = sgs.General(extension_qi, "keqiduanwei", "qun", 4,true,true)
--[[
keqilangmie = sgs.CreateTriggerSkill{
    name = "keqilangmie",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart,sgs.Damage,sgs.CardUsed},
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:isKindOf("BasicCard") then room:addPlayerMark(use.from,"keqilangmiebc-Clear",1) end
			if use.card:isKindOf("TrickCard") then room:addPlayerMark(use.from,"keqilangmietc-Clear",1) end
			if use.card:isKindOf("EquipCard") then room:addPlayerMark(use.from,"keqilangmieec-Clear",1) end
		end
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			room:addPlayerMark(damage.from,"keqilangmieda-Clear",damage.damage)
		end
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Finish) then
				local dws = room:findPlayersBySkillName(self:objectName())
				for _,p in sgs.qlist(dws) do
					if not (p:objectName() == player:objectName()) then
						local choices = {}
						if (player:getMark("keqilangmiebc-Clear")>1) or (player:getMark("keqilangmietc-Clear")>1) or (player:getMark("keqilangmieec-Clear")>1) then
							table.insert(choices, "langmieuse")
						end
						if (player:getMark("keqilangmieda-Clear") > 1) then
							table.insert(choices, "langmieda")
						end
						local choice = room:askForChoice(p, self:objectName(), table.concat(choices, "+"))
						if choice == "langmieuse" then
							if room:askForDiscard(p, self:objectName(), 1, 1, true, true, "keqilangmie-discarduse") then
								p:drawCards(2)
							end
						end
						if choice == "langmieda" then
							if room:askForDiscard(p, self:objectName(), 1, 1, true, true, "keqilangmie-discardda") then
								room:damage(sgs.DamageStruct(self:objectName(), p, player))
							end
						end 
					end
				end
			end
		end
	end,
}]]
keqiduanwei:addSkill("secondlangmie")

keqiwangrong = sgs.General(extension_qi, "keqiwangrong", "qun", 3, false,true)

keqifengzi = sgs.CreateTriggerSkill{
name = "keqifengzi",
events = sgs.CardUsed,
on_trigger = function(self, event, player, data, room)
	if player:getPhase() ~= sgs.Player_Play or player:getMark("fengzi_Used-PlayClear") > 0 then return false end
	local use = data:toCardUse()
	if not use.card:isKindOf("BasicCard") and not use.card:isNDTrick() then return false end
	if not player:canDiscard(player, "h") then return false end
	local typee = (use.card:isKindOf("BasicCard") and "BasicCard") or "TrickCard"
	local card = room:askForCard(player, ""..typee .. "|.|.|hand", "@fengzi-discard:" .. use.card:getType() .. "::" .. use.card:objectName(), data, self:objectName())
	if not card then return false end
	player:peiyin(self)
	player:addMark("fengzi_Used-PlayClear")
	room:setCardFlag(use.card, "fengzi_double")
	return false
end
}

keqifengziDouble = sgs.CreateTriggerSkill{
name = "#keqifengziDouble",
events = sgs.CardFinished,
can_trigger = function(self, player)
	return player and player:isAlive()
end,
on_trigger = function(self, event, player, data, room)
	local use = data:toCardUse()
	if not use.card:isKindOf("BasicCard") and not use.card:isNDTrick() then return false end
	if not use.card:hasFlag("fengzi_double") then return false end
	room:setCardFlag(use.card, "-fengzi_double")
	--if use.card:hasPreAction() then end
	if use.card:isKindOf("Slash") then  --【杀】需要单独处理
		for _,p in sgs.qlist(use.to) do
			local se = sgs.SlashEffectStruct()
			se.from = use.from
			se.to = p
			se.slash = use.card
			se.nullified = table.contains(use.nullified_list, "_ALL_TARGETS") or table.contains(use.nullified_list, p:objectName())
			se.no_offset = table.contains(use.no_offset_list, "_ALL_TARGETS") or table.contains(use.no_offset_list, p:objectName())
			se.no_respond = table.contains(use.no_respond_list, "_ALL_TARGETS") or table.contains(use.no_respond_list, p:objectName())
			se.multiple = use.to:length() > 1
			se.nature = sgs.DamageStruct_Normal
			if use.card:objectName() == "fire_slash" then
				se.nature = sgs.DamageStruct_Fire
			elseif use.card:objectName() == "thunder_slash" then
				se.nature = sgs.DamageStruct_Thunder
			elseif use.card:objectName() == "ice_slash" then
				se.nature = sgs.DamageStruct_Ice
			end
			if use.from:getMark("drank") > 0 then
				room:setCardFlag(use.card, "drank")
				use.card:setTag("drank", sgs.QVariant(use.from:getMark("drank")))
			end
			se.drank = use.card:getTag("drank"):toInt()
			room:slashEffect(se)
		end
	else
		use.card:use(room, use.from, use.to)
	end
	return false
end
}

keqijizhanw = sgs.CreatePhaseChangeSkill{
name = "keqijizhanw",
on_phasechange = function(self, player, room)
	if player:getPhase() ~= sgs.Player_Draw or not player:askForSkillInvoke(self) then return false end
	player:peiyin(self)
	
	local gets = sgs.IntList()
	local ids = room:showDrawPile(player, 1, self:objectName())
	gets:append(ids:first())
	local num = sgs.Sanguosha:getEngineCard(ids:first()):getNumber()
	
	while player:isAlive() do
		local choices = {}
		table.insert(choices, "more=" .. num)
		table.insert(choices, "less=" .. num)
		table.insert(choices, "cancel")
		local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), sgs.QVariant(num))
		if choice == "cancel" then break end
		
		ids = room:showDrawPile(player, 1, self:objectName())
		gets:append(ids:first())
		local next_num = sgs.Sanguosha:getEngineCard(ids:first()):getNumber()
		if (next_num == num) or (next_num > num and choice:startsWith("less")) or (next_num < num and choice:startsWith("more")) then break end
		num = next_num
	end
	
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	for _,id in sgs.qlist(gets) do
		if room:getCardPlace(id) ~= sgs.Player_PlaceTable then continue end
		slash:addSubcard(id)
	end
	
	if slash:subcardsLength() > 0 then
		if player:isDead() then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), "")
			room:throwCard(slash, reason, nil)
			return true
		end
		room:obtainCard(player, slash)
	end
	return true
end
}

keqifusong = sgs.CreateTriggerSkill{
name = "keqifusong",
events = sgs.Death,
can_trigger = function(self, player)
	return player and player:hasSkill(self)
end,
on_trigger = function(self, event, player, data, room)
	local death = data:toDeath()
	if death.who:objectName() ~= player:objectName() then return false end
	
	local players = sgs.SPlayerList()
	local max_hp = player:getMaxHp()
	for _,p in sgs.qlist(room:getOtherPlayers(player)) do
		if p:getMaxHp() <= max_hp then continue end
		players:append(p)
	end
	
	if players:isEmpty() then return false end
	local target = room:askForPlayerChosen(player, players, self:objectName(), "@fusong-invoke", true, true)
	if not target then return false end
	player:peiyin(self)
	
	local skills = {}
	if not target:hasSkill("keqifengzi", true) then table.insert(skills, "keqifengzi") end
	if not target:hasSkill("keqijizhanw", true) then table.insert(skills, "keqijizhanw") end
	if #skills == 0 then return false end
	local skill = room:askForChoice(target, self:objectName(), table.concat(skills, "+"))
	room:acquireSkill(target, skill)
	return false
end
}

keqiwangrong:addSkill("fengzi")
--keqiwangrong:addSkill(keqifengziDouble)
keqiwangrong:addSkill("jizhanw")
keqiwangrong:addSkill("fusong")
--extension_qi:insertRelatedSkills("keqifengzi", "#keqifengziDouble")

sgs.LoadTranslationTable{
    ["kearjsrgqi"] = "江山如故·起",

	["keqixushao"] = "许劭[起]", 
	["&keqixushao"] = "许劭",
	["#keqixushao"] = "识人读心",
	["designer:keqixushao"] = "官方",
	["cv:keqixushao"] = "樰默",
	["illustrator:keqixushao"] = "凡果",
	["keqiyingmen"] = "盈门",
	[":keqiyingmen"] = "锁定技，游戏开始时，你在剩余武将牌堆中随机获得4张武将牌置于你的武将牌上，称为“访客”；回合开始前，若你的“访客”数少于4张，你将之补至4张。",
	["keqiyingmenGenerals"] = "访客",
	["keqipingjian"] = "评鉴",
	[":keqipingjian"] = "当“访客”上无类型标签或只有锁定技标签的技能满足发动时机时，你可以发动该技能。该技能效果结束后，你须移除一张“访客”，若移除的是含有该技能的“访客”，你摸一张牌。",
	["keqipingjian0"] = "评鉴：你可以发动“%src”",
	["~keqipingjian"] = "若无法发动，可以退至空闲点重新点击",
	["$keqiyingmenremoveOne"] = "%from 选择移去武将牌 %arg",
	["keqipingjianRemove"] = "移去武将牌",

	["$keqiyingmen1"] = "韩侯不顾？德高，门楣自盈。",
	["$keqiyingmen2"] = "贫而不阿，名广，胜友满座。",
	["$keqipingjian1"] = "太丘道广，广则不周。仲举性峻，峻则少通。",
	["$keqipingjian2"] = "君生清平则为奸逆，处乱世当居豪雄。",
	["~keqixushao"] = "运去朋友散，满屋余风雨……",


--曹操
	["keqicaocao"] = "曹操[起]", 
	["&keqicaocao"] = "曹操",
	["#keqicaocao"] = "汉征西将军",
	["designer:keqicaocao"] = "官方",
	["cv:keqicaocao"] = "樰默",
	["illustrator:keqicaocao"] = "凡果",
	["information:keqicaocao"] = "ᅟᅠᅟᅠ<i>初平元年二月，董卓徙天子都长安，焚洛阳宫室，众诸侯畏卓兵强，莫敢进。操怒斥众人：“为人臣而临此境，当举义兵以诛暴乱，大众已合，诸君何疑？此一战而天下定矣！”遂引兵汴水，遇卓将徐荣，大破之。操迎天子，攻吕布，伐袁术，安汉室，拜为征西将军。是时，袁绍兼四州之地，将攻许都。操欲扫清寰宇，兴复汉室，遂屯兵官渡。既克绍，操曰：“若天命在吾，吾为周文王矣。”</i>",

	["keqizhenglue"] = "政略",
	[":keqizhenglue"] = "主公的回合结束时，你可以摸一张牌并令一名（若其本回合没有造成过伤害，改为至多两名）没有“猎”标记的角色获得1枚“猎”标记；你对有“猎”标记的角色使用牌无距离和次数限制；每个回合限一次，当你对有“猎”标记的角色造成伤害后，你可以摸一张牌并获得造成此伤害的牌。",

	["keqihuilie"] = "会猎",
	[":keqihuilie"] = "觉醒技，<font color='green'><b>准备阶段，</b></font>若有“猎”标记的角色数大于2，你减1点体力上限并获得技能“平戎”和“飞影”。",
	
	["keqipingrong"] = "平戎",
	[":keqipingrong"] = "每轮限一次，一个回合结束时，你可以令一名有“猎”标记的角色弃置所有“猎”标记，然后你于此回合结束后执行一个额外的回合，该额外回合结束时，若你于此回合内未造成过伤害，你失去1点体力。",
	
	["keqilue"] = "猎",
	["keqizhengluegaincard"] = "政略：获得此造成伤害的牌并摸一张牌",
	["keqizhenglue-ask"] = "你可以发动“政略”选择获得“猎”标记的角色",
	["keqipingrong-ask"] = "你可以选择发动“平戎”的角色",

	["$keqizhenglue1"] = "治政用贤不以德，则四方定。",
	["$keqizhenglue2"] = "秉至公而服天下，孤大略成。",
	["$keqihuilie1"] = "孤上承天命，会猎于江夏，幸勿观望。",
	["$keqihuilie2"] = "今雄兵百万，奉词伐罪，敢不归顺？",
	["$keqipingrong1"] = "万里平戎，岂曰功名，孤心昭昭鉴日月。",
	["$keqipingrong2"] = "四极倾颓，民心思定，试以只手补天裂。",

	["~keqicaocao"] = "汉征西，归去兮，复汉土兮…挽汉旗…",


--刘备
	["keqiliubei"] = "刘备[起]", 
	["&keqiliubei"] = "刘备",
	["#keqiliubei"] = "负戎荷戈",
	["designer:keqiliubei"] = "官方",
	["cv:keqiliubei"] = "玖心粽子",
	["illustrator:keqiliubei"] = "君桓文化",

	["keqijishan"] = "积善",
	["keqijishan_pre"] = "积善：防止伤害",
	["keqijishan-ask"] = "你可以发动“积善”令一名角色回复1点体力",
	[":keqijishan"] = "每个回合限一次，当一名角色受到伤害时，你可以失去1点体力并防止此伤害，然后你与其各摸一张牌；每个回合限一次，当你造成伤害后，你可以令一名体力值最小且因“积善”而防止过伤害的角色回复1点体力。",

	["keqizhenqiao"] = "振鞘",
	[":keqizhenqiao"] = "锁定技，你的攻击范围+1；当你使用【杀】指定目标后，若你的装备区里没有武器牌，你令此【杀】结算完毕后额外执行一次结算。",


	["$keqijishan1"] = "勿以善小而不为。",
	["$keqijishan2"] = "积善成德，而神明自得。",
	["$keqizhenqiao1"] = "豺狼满朝，且看我剑出鞘。",
	["$keqizhenqiao2"] = "欲申大义，此剑一匡天下。",

	["~keqiliubei"] = "大义未信，唯念黎庶之苦……",

	
--孙坚
	["keqisunjian"] = "孙坚[起]-初版", 
	["&keqisunjian"] = "孙坚",
	["#keqisunjian"] = "拨定烈志",
	["designer:keqisunjian"] = "官方",
	["cv:keqisunjian"] = "樰默",
	["illustrator:keqisunjian"] = "凡果",

	["keqisunjiantwo"] = "孙坚[起]", 
	["&keqisunjiantwo"] = "孙坚",
	["#keqisunjiantwo"] = "拨定烈志",
	["designer:keqisunjiantwo"] = "官方",
	["cv:keqisunjiantwo"] = "樰默",
	["illustrator:keqisunjiantwo"] = "凡果",

	["keqipingtao"] = "平讨",
	[":keqipingtao"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.交给你一张牌，然后令你本回合可以多使用一张【杀】；2.令你视为对其使用一张不计入次数的【杀】。",

	["keqijuelie"] = "绝烈",
	["keqijuelie-ask"] = "你可以发动“绝烈”选择弃置牌",
	[":keqijuelie"] = "当你使用【杀】造成伤害时，若你是手牌数或体力值最小的角色，此伤害+1；当你使用【杀】指定一名角色为目标后，你可以弃置任意张牌，然后依次弃置其等量的牌。",

	["keqijuelietwo"] = "绝烈",
	[":keqijuelietwo"] = "当你使用【杀】指定一名角色为目标后，你可以弃置任意张牌，然后依次弃置其等量的牌，若你是手牌数或体力值最小的角色，此【杀】对其造成的伤害+1。",

	["keqijueliedis"] = "绝烈",
	["keqijueliedistwo"] = "绝烈",
	["#keqipingtao"] = "你可以交给 %src 一张牌，否则其视为对你使用一张【杀】",
	["keqijuelietwoask"] = "你可以对 %src 发动“绝烈”弃置任意张牌",
	
	["$keqipingtao1"] = "平贼之功，非我莫属!",
	["$keqipingtao2"] = "贼乱数郡，宜速讨灭！",
	["$keqijuelie1"] = "诸君放手，祸福，某一肩担之！",
	["$keqijuelie2"] = "先登破城，方不负孙氏勇烈！",
	["$keqijuelietwo1"] = "诸君放手，祸福，某一肩担之！",
	["$keqijuelietwo2"] = "先登破城，方不负孙氏勇烈！",

	["~keqisunjian"] = "我，竟会被暗箭所伤…",
	["~keqisunjiantwo"] = "我，竟会被暗箭所伤…",

	--董白
	["keqidongbai"] = "董白[起]", 
	["&keqidongbai"] = "董白",
	["#keqidongbai"] = "魔姬",
	["designer:keqidongbai"] = "官方",
	["cv:keqidongbai"] = "官方",
	["illustrator:keqidongbai"] = "SoniaTang",

	["keqishichong"] = "恃宠",
	["#keqishichongg"] = "你可以交给 %src 一张手牌",
	[":keqishichong"] = "转换技，当你使用牌指定一名其他角色为唯一目标后，\
	①你可以获得其一张手牌；\
	②其可以交给你一张手牌。",

	[":keqishichong1"] = "转换技，当你使用牌指定一名其他角色为唯一目标后，\
	①你可以获得其一张手牌；\
	<font color='#01A5AF'><s>②其可以交给你一张手牌。</s></font>",

	[":keqishichong2"] = "转换技，当你使用牌指定一名其他角色为唯一目标后，\
	<font color='#01A5AF'><s>①你可以获得其一张手牌；</s></font>\
	②其可以交给你一张手牌。",

	["keqilianzhu"] = "连诛",
	["keqilianzhuCard"] = "连诛",
	[":keqilianzhu"] = "出牌阶段限一次，你可以展示一张手牌并交给一名其他角色，然后你依次视为对与其势力相同的其他角色使用一张【过河拆桥】。",
	["$keqishichonguse"] = "%from 发动了<font color='yellow'><b>“恃宠”</b></font>！",

	["$keqishichong1"] = "我家猫咪喜欢的，都要留下。",
	["$keqishichong2"] = "有所付出，才能得到赏赐。",
	["$keqilianzhu1"] = "一荣俱荣，一损俱损，这道理我懂。",
	["$keqilianzhu2"] = "拿了本小姐的东西，就留下点什么吧。",

	["~keqidongbai"] = "爷爷，快来救救我。",

	--段煨
	["keqiduanwei"] = "段煨[起]", 
	["&keqiduanwei"] = "段煨",
	["#keqiduanwei"] = "凉国之英",
	["designer:keqiduanwei"] = "官方",
	["cv:keqiduanwei"] = "官方",
	["illustrator:keqiduanwei"] = "匠人绘",

	["keqilangmie"] = "狼灭",
	[":keqilangmie"] = "其他角色的结束阶段，你可以选择一项：\
	1.若其本回合使用过至少两张相同类型的牌，你弃置一张牌并摸两张牌；\
	2.若其本回合造成过至少2点伤害，你弃置一张牌并对其造成1点伤害。",

	["keqilangmie:langmieuse"] = "弃置一张牌并摸两张牌",
	["keqilangmie:langmieda"] = "弃置一张牌对其造成1点伤害",

	["keqilangmie-discarduse"] = "你可以弃置一张牌，然后摸两张牌",
	["keqilangmie-discardda"] = "你可以弃置一张牌，然后对其造成1点伤害",


	["~keqiduanwei"] = "狼伴其侧，终不胜防。",

	--何进
	["keqihejin"] = "何进[起]", 
	["&keqihejin"] = "何进",
	["#keqihejin"] = "独意误国谋",
	["designer:keqihejin"] = "官方",
	["cv:keqihejin"] = "官方",
	["illustrator:keqihejin"] = "凡果-棉鞋",

	["keqizhaobing"] = "诏兵",
	[":keqizhaobing"] = "<font color='green'><b>结束阶段，</b></font>你可以弃置所有手牌，然后令至多X名其他角色各选择一项：1.展示并交给你一张【杀】；2.失去1点体力（X为你此次弃置的牌数）。",
	["keqizhaobing-ask"] = "请选择发动“诏兵”的角色",
	["#keqizhaobing"] = "诏兵：请交给%src一张【杀】，否则失去1点体力",

	["keqizhuhuan"] = "诛宦",
	[":keqizhuhuan"] = "<font color='green'><b>准备阶段，</b></font>你可以展示所有手牌（至少一张）并弃置其中所有的【杀】，然后令一名其他角色选择一项：1.受到1点伤害并弃置X张牌；2.令你回复1点体力然后你摸X张牌（X为你此次弃置【杀】的数量）。",
	--["keqizhuhuan:getdamage"] = "受到1点伤害并弃置X张牌",
	--["keqizhuhuan:getrecover"] = "令其回复1点体力然后其摸X张牌",
	["keqizhuhuan-ask"] = "请选择发动“诛宦”的角色",
	["keqizhuhuan-discardda"] = "请选择弃置的牌",

	["keqizhuhuan:getdamage"] = "受到1点伤害并弃置 %src 张牌",
	["keqizhuhuan:getrecover"] = "令其回复1点体力然后其摸 %src 张牌",

	["keqiyanhuo"] = "延祸",
	[":keqiyanhuo"] = "锁定技，当你死亡时，你令本局游戏因【杀】造成的伤害+1。",

	["$keqizhaobing1"] = "吾乃皇亲贵胄，威同天子！",
	["$keqizhaobing2"] = "老夫奉诏讨贼，当恩威并施。",
	["$keqizhuhuan1"] = "尔等祸乱朝纲，罪无可赦，按律当诛！",
	["$keqizhuhuan2"] = "天下人之愿，皆系于汝等，还不快认罪服法！",
	["$keqiyanhuo1"] = "你们都要为我殉葬！",
	["$keqiyanhuo2"] = "杀了我，你们也别想活！",

	["~keqihejin"] = "诛宦不成，反遭其害，贻笑天下人矣...",


	--皇甫嵩
	["keqihuangfusong"] = "皇甫嵩[起]", 
	["&keqihuangfusong"] = "皇甫嵩",
	["#keqihuangfusong"] = "安危定倾",
	["designer:keqihuangfusong"] = "官方",
	["cv:keqihuangfusong"] = "官方",
	["illustrator:keqihuangfusong"] = "君桓文化",

	["keqiguanhuo"] = "观火",
	[":keqiguanhuo"] = "出牌阶段，你可以视为使用一张【火攻】，若此牌未造成伤害，此牌结算完毕后：若此牌是你本阶段第一次以此法使用的牌，本阶段你使用【火攻】造成的伤害+1，否则你失去技能“观火”。",
	["usekeqiguanhuoda"] = "观火加伤",

	["keqijuxia"] = "居下",
	[":keqijuxia"] = "每个回合限一次，当其他角色使用牌指定你为目标后，若其技能数大于你，其可以令此牌对你无效并令你摸两张牌。",
	["usekeqijuxia"] = "已使用居下",
	
	["keqijuxia:keqijuxia-pre"] = "你可以发动“居下”令此牌对 %src 无效并令其摸两张牌",

	["$keqiguanhuo1"] = "敌军依草结营，正犯兵家大忌！",
	["$keqiguanhuo2"] = "兵法所云，火攻之计，正合此时之势！",
	["$keqijuxia1"] = "众将平日随心，战则务尽死力！",
	["$keqijuxia2"] = "汝等不怀余力，皆有平贼之功！",
	["~keqihuangfusong"] = "力有所能，臣必为也！",

--孔融
	["keqikongrong"] = "孔融[起]", 
	["&keqikongrong"] = "孔融",
	["#keqikongrong"] = "北海太守",
	["designer:keqikongrong"] = "官方",
	["cv:keqikongrong"] = "官方",
	["illustrator:keqikongrong"] = "官方",

	["keqilirang"] = "礼让",
	[":keqilirang"] = "每轮限一次，其他角色摸牌阶段开始时，你可以交给其两张牌，若如此做，此回合的弃牌阶段结束时，你可以获得其于此阶段因弃置进入弃牌堆的牌。",
	
	["keqilirang_use"] = "礼让",
	["keqilirang_get"] = "礼让：获得弃置的牌",

	["keqimingshi"] = "名仕",
	[":keqimingshi"] = "当你于一个回合首次受到伤害时，本轮因“礼让”效果而获得过牌的其他角色可以将此伤害转移给其。",

	["#keqilirang"] = "你可以发动“礼让”交给 %src 两张牌",
	["mskeqilirang"] = "礼让角色",
	["msusekeqilirang"] = "使用礼让",

	["$keqimingshitran"] = "%from 发动了<font color='yellow'><b>“名仕”</b></font>，转移了伤害！",
	["$keqiliranggeipai"] = "%from 发动了<font color='yellow'><b>“礼让”</b></font>！",

	
	["$keqilirang1"] = "人之所至，礼之所及。",
	["$keqilirang2"] = "施之以礼，还之以德。",
	["$keqimingshi1"] = "纵有强权在侧，亦不可失吾风骨。",
	["$keqimingshi2"] = "黜邪崇正，何惧之有？",
	["~keqikongrong"] = "不遵朝仪？诬害之辞也！",



--刘宏
	["keqiliuhong"] = "刘宏[起]", 
	["&keqiliuhong"] = "刘宏",
	["#keqiliuhong"] = "轧庭焚礼",
	["designer:keqiliuhong"] = "官方",
	["cv:keqiliuhong"] = "官方",
	["illustrator:keqiliuhong"] = "君桓文化",

	["keqichaozheng"] = "朝争",
	["keqichaozheng_yishi"] = "请选择议事展示的牌",
	[":keqichaozheng"] = "<font color='green'><b>准备阶段，</b></font>你可以令所有其他角色议事，若结果为：红色，意见为红色的角色各回复1点体力；黑色，意见为红色的角色各失去1点体力。若所有角色的意见相同，议事结束后你摸X张牌（X为此次议事的角色数）。",

	["keqishenchong"] = "甚宠",
	[":keqishenchong"] = "限定技，出牌阶段，你可以令一名其他角色获得技能“飞扬”和“跋扈”，若如此做，当你死亡时，其失去所有技能并弃置所有手牌。",

	["keqijulian"] = "聚敛",
	[":keqijulian"] = "主公技，其他群势力角色的回合限两次，当其于摸牌阶段外不因“聚敛”摸牌后，其可以摸一张牌；结束阶段，你可以获得所有其他群势力角色的各一张手牌。",
	["$keqijulianmopai"] = "%from 发动了<font color='yellow'><b>“聚敛”</b></font>，摸一张牌！",

	["$askYishi"] = "%from 对 %to 发起了议事",
	["askyishicard"] = "请选择%src张手牌进行议事展示",
	["$keyishired"] = "议事结果：红色",
	["$keyishiblack"] = "议事结果：黑色",
	["$keyishino_result"] = "议事结果：无结果",
	["$yishiresult"] = "%from 本次议事结果为：%arg",
	["no_result"] = "无结果",
	["$yishicolor"] = "%from 本次议事声明颜色为：%arg",

	["$keqichaozheng1"] = "彼岁汉祚无恙，此岁再图中兴。",
	["$keqichaozheng2"] = "新岁开元，蒙诸君助国，请满饮此杯！",
	["$keqishenchong1"] = "今备高官厚禄，慰君劳苦功高，待卿鸣钟而食。",
	["$keqishenchong2"] = "值开元伊始，普天同庆，赐众卿爵加一等！",
	["~keqiliuhong"] = "饮至达旦，不胜酒力。",


--刘焉
	["keqiliuyan"] = "刘焉[起]", 
	["&keqiliuyan"] = "刘焉",
	["#keqiliuyan"] = "裂土之宗",
	["designer:keqiliuyan"] = "官方",
	["cv:keqiliuyan"] = "官方",
	["illustrator:keqiliuyan"] = "心中一凛",

	["keqilimu"] = "立牧",
	[":keqilimu"] = "出牌阶段，你可以将一张♦牌当【乐不思蜀】对自己使用并回复1点体力；若你的判定区里有牌，你对攻击范围内的角色使用牌无距离和次数限制。",

	["keqitushe"] = "图射",
	[":keqitushe"] = "当你使用非装备牌指定目标后，你可以展示所有手牌，若其中没有基本牌，你摸X张牌（X为此牌指定的目标数）。",

	["keqitongjue"] = "通绝",
	[":keqitongjue"] = "主公技，出牌阶段限一次，你可以将任意张手牌交给一名其他群势力角色，若如此做，本回合你使用牌不能指定其为目标。",

	["$keqitushe1"] = "非英杰不图？吾既谋之且射毕。",
	["$keqitushe2"] = "汉室衰微，朝纲祸乱，必图后福。",

	["~keqiliuyan"] = "背疮难治，失子难继！",

--桥玄
	["keqiqiaoxuan"] = "桥玄[起]", 
	["&keqiqiaoxuan"] = "桥玄",
	["#keqiqiaoxuan"] = "泛爱博容",
	["designer:keqiqiaoxuan"] = "官方",
	["cv:keqiqiaoxuan"] = "官方",
	["illustrator:keqiqiaoxuan"] = "君桓文化",

	["keqijuezhi"] = "绝质",
	[":keqijuezhi"] = "当你失去装备区内的一张装备牌时，你可以废除对应的装备栏；你的回合内每阶段限一次，你使用牌对目标角色造成的伤害+X（X为其装备区内与你已废除装备栏类型相同的牌数）。",

	["keqijizhao"] = "急召",
	[":keqijizhao"] = "<font color='green'><b>准备阶段或结束阶段，</b></font>你可以选择一名角色，其选择一项：1.使用一张手牌；2.你可以移动其区域内的一张牌。",

	["keqijuezhi_wq"] = "绝质：废除武器栏",
	["keqijuezhi_fj"] = "绝质：废除防具栏",
	["keqijuezhi_fy"] = "绝质：废除防御马栏",
	["keqijuezhi_jg"] = "绝质：废除进攻马栏",
	["keqijuezhi_bw"] = "绝质：废除宝物栏",
	["keqijizhao-ask"] = "你可以选择发动“急召”的角色",
	["keqijizhaouse-ask"] = "你可以使用一张牌，否则其可以移动你区域内的一张牌",

	
	["$keqijuezhi1"] = "汝等无忠无信，岂能事主？",
	["$keqijuezhi2"] = "心直口快，无需遮拦。",
	["$keqijizhao1"] = "冥冥之中，自有天数。",
	["$keqijizhao2"] = "周而复始，轮回流转。",
	["~keqiqiaoxuan"] = "唉，算不到我有此劫。",

--王荣
	["keqiwangrong"] = "王荣[起]", 
	["&keqiwangrong"] = "王荣",
	["#keqiwangrong"] = "灵怀皇后",
	["designer:keqiwangrong"] = "官方",
	["cv:keqiwangrong"] = "官方",
	["illustrator:keqiwangrong"] = "君桓文化",


	["keqifengzi"] = "丰姿",
	[":keqifengzi"] = "出牌阶段限一次，你使用基本牌或非延时类锦囊牌时，可以弃置一张同类型的手牌，令此牌的效果结算两次。",
	["@fengzi-discard"] = "你可以弃置一张 %src 令 %arg 结算两次",
	["keqijizhanw"] = "吉占",
	[":keqijizhanw"] = "摸牌阶段开始时，你可以放弃摸牌，展示牌堆顶的一张牌，猜测牌堆顶的下一张牌点数大于或小于此牌，然后展示之，若猜对你可重复此流程，最后你获得以此法展示的牌。",
	["keqijizhanw:more"] = "点数大于%src",
	["keqijizhanw:less"] = "点数小于%src",
	["keqifusong"] = "赋颂",
	[":keqifusong"] = "当你死亡时，你可令一名体力上限大于你的角色选择获得“丰姿”或“吉占”。",
	["@fusong-invoke"] = "你可以发动“赋颂”",
	["$keqifengzi1"] = "丰姿秀丽，礼法不失",
	["$keqifengzi2"] = "倩影姿态，悄然入心",
	["$keqijizhanw1"] = "得吉占之兆，言福运之气",
	["$keqijizhanw2"] = "吉占逢时，化险为夷",
	["$keqifusong1"] = "陛下垂爱，妾身方有此位",
	["$keqifusong2"] = "长情颂，君王恩",
	["~keqiwangrong"] = "只求吾儿一生平安",


--王允
	["keqiwangyun"] = "王允[起]", 
	["&keqiwangyun"] = "王允",
	["#keqiwangyun"] = "居功自矜",
	["designer:keqiwangyun"] = "官方",
	["cv:keqiwangyun"] = "官方",
	["illustrator:keqiwangyun"] = "凡果",


	["keqishelun"] = "赦论",
	["keqishelunCard"] = "赦论",
	[":keqishelun"] = "出牌阶段限一次，你可以选择一名攻击范围内的其他角色，你令该角色以外所有手牌数不大于你的角色议事，若结果为：红色，你弃置其一张牌；黑色，你对其造成1点伤害。",

	["keqifayi"] = "伐异",
	[":keqifayi"] = "当你参与的议事结束后，你可以对一名意见与你不同的角色造成1点伤害。",

	["keqifayi-ask"] = "你可以发动“伐异”对一名角色造成1点伤害",

	["$keqishelun1"] = "你终于走到了这一天。",
	["$keqishelun2"] = "看看这身边还有谁替你说话？",
	["$keqifayi1"] = "一石二鸟之计！",
	["$keqifayi2"] = "我已为你布好了死局！",
	["~keqiwangyun"] = "我怎么也会走到这一天，呃...",

--杨彪
	["keqiyangbiao"] = "杨彪[起]", 
	["&keqiyangbiao"] = "杨彪",
	["#keqiyangbiao"] = "德彰海内",
	["designer:keqiyangbiao"] = "官方",
	["cv:keqiyangbiao"] = "官方",
	["illustrator:keqiyangbiao"] = "木美人",


	["keqizhaohan"] = "昭汉",
	[":keqizhaohan"] = "锁定技，<font color='green'><b>准备阶段，</b></font>若牌堆没有洗过牌，你回复1点体力，否则你失去1点体力。",
	
	["keqirangjie"] = "让节",
	[":keqirangjie"] = "当你受到1点伤害后，你可以移动场上的一张牌，然后你可以获得弃牌堆中的一张本回合置入其中的且与你本次移动的牌相同花色的牌。",

	["keqiyizheng"] = "义争",
	[":keqiyizheng"] = "出牌阶段限一次，你可以与一名手牌数大于你的角色拼点，若你赢，其跳过下个摸牌阶段；若你没赢，其可以对你造成0~2点伤害。",

	["keqiyizhengCard:zero"] = "不对其造成伤害",
	["keqiyizhengCard:one"] = "对其造成1点伤害",
	["keqiyizhengCard:two"] = "对其造成2点伤害",

	["$keqizhaohan1"] = "天道昭昭，再兴如光武亦可期！",
	["$keqizhaohan2"] = "汉祚将终，我又岂能无憾？",
	["$keqirangjie1"] = "公既执掌权柄，又何必令君臣遭乱？",
	["$keqirangjie2"] = "公虽权倾朝野，亦当遵圣上之意。",
	["$keqiyizheng1"] = "一人劫天子，一人质公卿，此可行耶？",
	["$keqiyizheng2"] = "诸君举事，当上顺天心，奈何如是！",
	["~keqiyangbiao"] = "未能效死佑汉，只因宗族之重……",

--朱儁
	["keqizhujun"] = "朱儁[起]", 
	["&keqizhujun"] = "朱儁",
	["#keqizhujun"] = "征无遗虑",
	["designer:keqizhujun"] = "官方",
	["cv:keqizhujun"] = "官方",
	["illustrator:keqizhujun"] = "沉睡千年",


	["keqifendi"] = "分敌",
	[":keqifendi"] = "每个回合限一次，当你使用【杀】指定唯一目标后，你可以展示其至少一张手牌，若如此做，该角色不能使用或打出其余手牌直到此【杀】结算完毕，当此【杀】对其造成伤害后，你获得其手牌中或弃牌堆里这些展示的牌。",

	["keqijuxiang"] = "拒降",
	[":keqijuxiang"] = "当你不于摸牌阶段获得牌时，你可以弃置这些牌，然后令当前回合角色本回合可以多使用X张【杀】（X为本次弃置的牌的花色数）。",

	["keqifendi-tip"] = "请选择展示其手牌的数量",
	["$keqijuxiangadd"] = "%from 增加了【杀】的使用次数！",

	["$keqifendi1"] = "全军撤围，待其出城迎战，再攻敌自散矣！",
	["$keqifendi2"] = "佯解敌围，而后城外击之，此为易破之道！",
	["$keqijuxiang1"] = "今非秦项之际，如若受之，徒增逆意！",
	["$keqijuxiang2"] = "兵有形同而势异者，此次乞降断不可受！",
	["~keqizhujun"] = "郭汜小竖！气煞我也！嗯...",


--南华老仙
	["keqinanhualaoxian"] = "南华老仙[起]-初版", 
	["&keqinanhualaoxian"] = "南华老仙-初版",
	["#keqinanhualaoxian"] = "冯虚御风",
	["designer:keqinanhualaoxian"] = "官方",
	["cv:keqinanhualaoxian"] = "官方",
	["illustrator:keqinanhualaoxian"] = "君桓文化",

	["keqinanhualaoxiantwo"] = "南华老仙[起]", 
	["&keqinanhualaoxiantwo"] = "南华老仙",
	["#keqinanhualaoxiantwo"] = "冯虚御风",
	["designer:keqinanhualaoxiantwo"] = "官方",
	["cv:keqinanhualaoxiantwo"] = "官方",
	["illustrator:keqinanhualaoxiantwo"] = "君桓文化",
	
	["keqishoushu"] = "授术",
	[":keqishoushu"] = "锁定技，<font color='green'><b>每轮开始时，</b></font>若场上没有【太平要术】，你将游戏外的【太平要术】置入一名角色的装备区（替换原装备）；【太平要术】离开装备区时销毁。",

	["keqishoushutwo"] = "授术",
	[":keqishoushutwo"] = "锁定技，<font color='green'><b>游戏开始时，</b></font>若场上没有【太平要术】，你将游戏外的【太平要术】置入一名角色的装备区（替换原装备）；【太平要术】离开装备区时销毁。",

	["keqiwendao"] = "问道",
	[":keqiwendao"] = "当你的判定牌生效前，你可以令至多两名角色各弃置一张牌，然后你选择其中一张代替此判定牌。",

	["keqixuanhuafirst"] = "宣化",

	["keqixuanhua"] = "宣化",
	[":keqixuanhua"] = "<font color='green'><b>准备阶段，</b></font>你可以进行一次【闪电】判定，若你未以此法受到伤害，你可以令一名角色回复1点体力；<font color='green'><b>结束阶段，</b></font>你可以进行一次判定结果反转的【闪电】判定，若你未以此法受到伤害，你可以对一名角色造成1点雷电伤害。",

	["keqishoushu-ask"] = "请选择装备【太平要术】的角色",
	["keqiwendao-ask"] = "你可以选择发动“问道”[改判]弃牌的角色",
	["keqiwendao-discard"] = "问道：请弃置一张牌",
	["keqiwendao-choice"] = "请选择其中一张牌作为判定牌",

	["keqixuanhuaco-ask"] = "你可以发动“宣化”令一名角色回复1点体力",
	["keqixuanhuada-ask"] = "你可以发动“宣化”对一名角色造成1点伤害",

	["#keDestroyEqiup"] = "【太平要术】被销毁！",
	["destroy_equip"] = "授术",
	["keqitaipingyaoshuskill"] = "太平要术",

	["$keqishoushu1"] = "汝得天书，当代天宣化，普救世人。",
	["$keqishoushu2"] = "若萌异心，必获恶报。",
	["$keqishoushutwo1"] = "汝得天书，当代天宣化，普救世人。",
	["$keqishoushutwo2"] = "若萌异心，必获恶报。",

	["$keqiwendao1"] = "其耆欲深者，其天机浅。",
	["$keqiwendao2"] = "杀生者不死，生生者不生。",

	["$keqixuanhua1"] = "乘天地之正，御六气之辩。",
	["$keqixuanhua2"] = "燀赫乎宇宙，凭陵乎昆仑。",

	["~keqinanhualaoxian"] = "死生，命也。",
	["~keqinanhualaoxiantwo"] = "死生，命也。",


}






extension_cheng = sgs.Package("kearjsrgrcheng", sgs.Package_GeneralPack)

sgs.Sanguosha:setAudioType("kechengsunce","tenyearzhiheng","3,4")


kechengsunce = sgs.General(extension_cheng, "kechengsunce$", "wu", 4)

kechengduxingCard = sgs.CreateSkillCard{
	name = "kechengduxingCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select, from)
		local duel = sgs.Sanguosha:cloneCard("duel")
		duel:setSkillName("kechengduxing")
		duel:deleteLater()
		return duel:targetFilter(sgs.PlayerList(), to_select, from)
	end,
	about_to_use = function(self,room,use)
		local duel = sgs.Sanguosha:cloneCard("duel")
		duel:setSkillName("kechengduxing")
		duel:deleteLater()
		use.card = duel
		for _,p in sgs.qlist(use.to) do
			for _,h in sgs.qlist(p:getHandcards()) do
				local slash = sgs.Sanguosha:cloneCard("slash", h:getSuit(), h:getNumber())
				slash:setSkillName(self:getSkillName())
				local card = sgs.Sanguosha:getWrappedCard(h:getId())
				card:takeOver(slash)
				room:notifyUpdateCard(p, h:getId(), card)
			end
		end
		self:cardOnUse(room,use)
		for _,p in sgs.qlist(use.to) do
			local cs = sgs.CardList()
			for _,h in sgs.qlist(p:getHandcards()) do
				if h:getSkillName()==self:getSkillName()
				then cs:append(h) end
			end
			room:filterCards(p,cs,true)
		end
	end,
}
--主技能
kechengduxingVS = sgs.CreateViewAsSkill{
	name = "kechengduxing",
	n = 0,
	view_as = function(self, cards)
		return kechengduxingCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kechengduxingCard")
	end, 
}

kechengduxing = sgs.CreateTriggerSkill{
	name = "kechengduxing",
	view_as_skill = kechengduxingVS,
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardFinished) and player:hasSkill(self:objectName())  then
			local use = data:toCardUse()
		    if (table.contains(use.card:getSkillNames(),"kechengduxing")) then
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if p:hasSkill("kechengduxingex",true) then
				    	room:detachSkillFromPlayer(p, "kechengduxingex",true,true,false)
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
}
kechengsunce:addSkill(kechengduxing)

kechengduxingex = sgs.CreateFilterSkill{
	name = "kechengduxingex&", 
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return (place == sgs.Player_PlaceHand) 
	end,
	view_as = function(self, originalCard)
		local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
		slash:setSkillName(self:objectName())
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(slash)
		return card
	end
}
--if not sgs.Sanguosha:getSkill("kechengduxingex") then skills:append(kechengduxingex) end

kechengzhiheng = sgs.CreateTriggerSkill{
	name = "kechengzhiheng",
	events = {sgs.CardResponded,sgs.CardUsed,sgs.DamageCaused},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.DamageCaused) then
			local damage = data:toDamage()
			if damage.to:getMark("&kechengzhiheng+#"..damage.from:objectName().."-Clear")>0
			and damage.from:hasSkill(self) then
				room:sendCompulsoryTriggerLog(damage.from,self)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			local resto = use.who
			--resto就是出杀的人
			if resto and resto:hasSkill(self,true) then
				room:addPlayerMark(player,"&kechengzhiheng+#"..resto:objectName().."-Clear")
			end
		end
		if (event == sgs.CardResponded) then
			local response = data:toCardResponse()
			if response.m_toCard and response.m_who and response.m_who:hasSkill(self,true) then
				room:addPlayerMark(player,"&kechengzhiheng+#"..response.m_who:objectName().."-Clear")
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
}
kechengsunce:addSkill(kechengzhiheng)

kechengzhasi = sgs.CreateTriggerSkill{
    name = "kechengzhasi",
	frequency = sgs.Skill_Limited,
	limit_mark = "@kechengzhasi",
	waked_skills = "tenyearzhiheng",
	events = {sgs.DamageInflicted,sgs.Damaged,sgs.CardUsed},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if not(use.to:length() == 1 and use.to:contains(player)) then
				if (player:getMark("&inzhasi") > 0) then
					room:setPlayerMark(player,"&inzhasi",0)
					room:addDistance(player, -9999, false, false)
					local can = false
					for i, p in sgs.qlist(room:getAlivePlayers()) do
						if p==player or can then
							p:setSeat(i+1)
							room:broadcastProperty(p, "seat")
							can = true
						end
					end
				end
			end
		end
		if (event == sgs.Damaged) then
			if (player:getMark("&inzhasi") > 0) then
				room:setPlayerMark(player,"&inzhasi",0)
				room:addDistance(player, -9999, false, false)
				local can = false
				for i, p in sgs.qlist(room:getAlivePlayers()) do
					if p==player or can then
						p:setSeat(i+1)
						room:broadcastProperty(p, "seat")
						can = true
					end
				end
			end
		end
		if (event == sgs.DamageInflicted) and (player:getMark("@kechengzhasi") > 0) then
			local damage = data:toDamage()
			if (damage.damage >= player:getHp()+player:getHujia()) and player:askForSkillInvoke(self, data) then
				room:broadcastSkillInvoke(self:objectName())
			    room:doSuperLightbox("kechengsunce", "kechengzhasi")
				room:removePlayerMark(player,"@kechengzhasi")
				room:handleAcquireDetachSkills(player, "-kechengzhiheng|tenyearzhiheng")
				room:addDistance(player, 9999, false, false)
				local can = false
				for i, p in sgs.qlist(room:getAlivePlayers()) do
					if p==player then
						p:setSeat(-1)
						can = true
					elseif can then
						p:setSeat(i)
					end
					room:broadcastProperty(p, "seat")
				end
				room:setPlayerMark(player,"&inzhasi",1)
				return true
			end
		end
	end,
}
kechengsunce:addSkill(kechengzhasi)

kechengbashi = sgs.CreateTriggerSkill{
	name = "kechengbashi$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardAsked},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardAsked and player:hasLordSkill(self)
		and player:getMark("usetimebashi-Clear") < 3 then
			local pattern = data:toStringList()
			if pattern[3]~="response" then return false end
			if string.find(pattern[1], "jink") then 
				local lieges = room:getLieges("wu", player)
				if lieges:isEmpty() then return false end
				if not player:askForSkillInvoke(self, data) then return false end
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player,"usetimebashi-Clear")
				local tohelp = sgs.QVariant()
				tohelp:setValue(player)
				for _, p in sgs.qlist(lieges) do
					local jink = room:askForCard(p, "jink", "kechengbashi_ask:jink:"..player:objectName(), tohelp, sgs.Card_MethodResponse, player, false,"", true)
					if jink then
						room:provide(jink)
						return true
					end
				end
			end
			if string.find(pattern[1], "slash") then 
				local lieges = room:getLieges("wu", player)
				if lieges:isEmpty() then return false end
				if not player:askForSkillInvoke(self, data) then return false end
				room:addPlayerMark(player,"usetimebashi-Clear")
				room:broadcastSkillInvoke(self:objectName())
				local tohelp = sgs.QVariant()
				tohelp:setValue(player)
				for _, p in sgs.qlist(lieges) do
					local slash = room:askForCard(p, "slash", "kechengbashi_ask:slash:"..player:objectName(), tohelp, sgs.Card_MethodResponse, player, false,"", true)
					if slash then
						room:provide(slash)
						return true
					end
				end
			end
		end
	end,
}
kechengsunce:addSkill(kechengbashi)




kechengchendeng = sgs.General(extension_cheng, "kechengchendeng", "qun", 3)

kechenglunshiCard = sgs.CreateSkillCard{
	name = "kechenglunshiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0)
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		local num = 0
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if target:inMyAttackRange(p)
			then num = num + 1 end
		end
		num = math.min(num,5-target:getHandcardNum())
		if num>0 then
			target:drawCards(num,self:getSkillName())
		end
		local qi = 0
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:inMyAttackRange(target)
			then qi = qi + 1 end
		end
		if qi>0 then
		    room:askForDiscard(target,self:getSkillName(), qi, qi, false, true, "kechenglunshi-discard")
		end
	end
}
--主技能
kechenglunshi = sgs.CreateViewAsSkill{
	name = "kechenglunshi",
	n = 0,
	view_as = function(self, cards)
		return kechenglunshiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kechenglunshiCard")
	end, 
}
kechengchendeng:addSkill(kechenglunshi)



kechengguitu = sgs.CreateTriggerSkill{
	name = "kechengguitu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Start) then
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if (p:getWeapon() ~= nil) then
						players:append(p)
					end
				end
				if (players:length() > 1) then
					local exs = room:askForPlayersChosen(player, players, self:objectName(), 0, 2, "kechengguitu-ask", true, true)
					if (exs:length() > 1) then
						room:broadcastSkillInvoke(self:objectName())
						local count = {}
						for _,p in sgs.qlist(room:getAllPlayers()) do
							count[p:objectName()] = p:getAttackRange()
						end
						local theone = exs:at(0)
						local thetwo = exs:at(1)
						local exchangeMove = sgs.CardsMoveList()
						local move1 = sgs.CardsMoveStruct(theone:getWeapon():getId(), thetwo, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, theone:objectName(), thetwo:objectName(), self:objectName(), ""))
						local move2 = sgs.CardsMoveStruct(thetwo:getWeapon():getId(), theone, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, thetwo:objectName(), theone:objectName(), self:objectName(), ""))
						exchangeMove:append(move1)
						exchangeMove:append(move2)
						room:moveCardsAtomic(exchangeMove, false)
						for _, p in sgs.qlist(room:getAllPlayers()) do
							if (p:getAttackRange() < count[p:objectName()]) then
								room:recover(p, sgs.RecoverStruct(self:objectName(),player))
							end
						end
					end
				end
			end
		end
	end,
}
kechengchendeng:addSkill(kechengguitu)



kechengguanyu = sgs.General(extension_cheng, "kechengguanyu", "shu", 5)


kechengguanjue = sgs.CreateTriggerSkill{
	name = "kechengguanjue",
	frequency = sgs.Skill_Compulsory,
	waked_skills = "#kechengguanjueex",
	events = {sgs.CardUsed,sgs.CardResponded,sgs.EventPhaseChanging},
	can_trigger = function(self, player)
		return player~=nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardResponded) then
			local response = data:toCardResponse()
			if response.m_card:getTypeId()<1 then return end
			local ss = player:property("kechengguanjueSuits"):toString():split(",")
			if table.contains(ss,response.m_card:getSuitString()) then return end
			table.insert(ss,response.m_card:getSuitString())
			room:setPlayerProperty(player,"kechengguanjueSuits",sgs.QVariant(table.concat(ss,",")))
			if player:isAlive() and player:hasSkill(self,true) then
				local suits = {}
				for _, s in sgs.list(ss) do
					table.insert(suits,s.."_char")
				end
				for _, m in sgs.list(player:getMarkNames()) do
					if m:startsWith("&kechengguanjue+:+") then
						room:setPlayerMark(player,m,0)
					end
				end
				room:setPlayerMark(player,"&kechengguanjue+:+"..table.concat(suits,"+").."-Clear",1)
			end
		end
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:getTypeId()<1 then return end
			local ss = player:property("kechengguanjueSuits"):toString():split(",")
			if table.contains(ss,use.card:getSuitString()) then return end
			table.insert(ss,use.card:getSuitString())
			room:setPlayerProperty(player,"kechengguanjueSuits",sgs.QVariant(table.concat(ss,",")))
			if player:isAlive() and player:hasSkill(self,true) then
				local suits = {}
				for _, s in sgs.list(ss) do
					table.insert(suits,s.."_char")
				end
				for _, m in sgs.list(player:getMarkNames()) do
					if m:startsWith("&kechengguanjue+:+") then
						room:setPlayerMark(player,m,0)
					end
				end
				room:setPlayerMark(player,"&kechengguanjue+:+"..table.concat(suits,"+").."-Clear",1)
			end
		end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					room:setPlayerProperty(p,"kechengguanjueSuits",sgs.QVariant())
				end
			end
		end
	end,
}
kechengguanyu:addSkill(kechengguanjue)

kechengguanjueex = sgs.CreateCardLimitSkill{
	name = "#kechengguanjueex",
	limit_list = function(self, player)
		return "use,response"
	end,
	limit_pattern = function(self, player, card)
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if p:hasSkill("kechengguanjue") then
				local ss = p:property("kechengguanjueSuits"):toString()
				if ss~="" and string.find(ss,card:getSuitString()) then return ".|"..ss end
			end
		end
		return ""
	end
}
kechengguanyu:addSkill(kechengguanjueex)

kechengnianenCard = sgs.CreateSkillCard{
	name = "kechengnianenCard",
	will_throw = false,
	filter = function(self, targets, to_select, from)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card = nil
			if self:getUserString() ~= "" then
				local us = self:getUserString():split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
				card:deleteLater()
				if card:targetFixed() then return false end
				card:setSkillName("kechengnianen")
				card:addSubcards(self:getSubcards())
			end
			local plist = sgs.PlayerList()
			for i = 1, #targets do plist:append(targets[i]) end
			return card and card:targetFilter(plist, to_select, from)
		end
		return false
	end,
	feasible = function(self, targets,from)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
		and self:getUserString() ~= "" then
			local us = self:getUserString():split("+")
			local card = sgs.Sanguosha:cloneCard(us[1])
			card:deleteLater()
			if card:targetFixed() then return true end
			card:setSkillName("kechengnianen")
			card:addSubcards(self:getSubcards())
			local plist = sgs.PlayerList()
			for i = 1, #targets do plist:append(targets[i]) end
			return card and card:targetsFeasible(plist, from)
		end
		return sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
		local room = player:getRoom()
		local us = self:getUserString()
		if us == "slash" then
			us = table.concat(sgs.Sanguosha:getSlashNames(), "+")
		end
		local user_str = room:askForChoice(player, "kechengnianen_slash", us)
		local use_card = sgs.Sanguosha:cloneCard(user_str)
		use_card:setSkillName("kechengnianen")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		return use_card
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local us = self:getUserString()
		if us == "slash" then
			us = table.concat(sgs.Sanguosha:getSlashNames(), "+")
		end
		local user_str = room:askForChoice(user, "kechengnianen_slash", us)
		local use_card = sgs.Sanguosha:cloneCard(user_str)
		use_card:setSkillName("kechengnianen")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		return use_card
	end,
}
kechengnianenVS = sgs.CreateViewAsSkill{
	name = "kechengnianen",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
		or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local skillcard = kechengnianenCard:clone()
			skillcard:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
			for _, card in ipairs(cards) do
				skillcard:addSubcard(card)
			end
			return skillcard
		end
		local c = sgs.Self:getTag("kechengnianen"):toCard()
		if c then
			local use_card = sgs.Sanguosha:cloneCard(c:objectName())
			use_card:setSkillName("kechengnianen")
			for _, card in ipairs(cards) do
				use_card:addSubcard(card)
			end
			return use_card
		end
	end,
	enabled_at_play = function(self, player)
		if (player:getMark("&bannianen-Clear") > 0) then return false end
		local basic = {"slash", "peach"}
		table.insert(basic, "fire_slash")
		table.insert(basic, "thunder_slash")
		table.insert(basic, "ice_slash")
		table.insert(basic, "analeptic")
		for _, patt in ipairs(basic) do
			local poi = sgs.Sanguosha:cloneCard(patt)
			if poi then
				poi:deleteLater()
				poi:setSkillName("kechengnianen")
				if poi:isAvailable(player) then
					return true
				end
			end
		end
		return false
	end,
	enabled_at_response = function(self, player, pattern)
        if (player:getMark("&bannianen-Clear") > 0) then return false end
		if pattern:startsWith(".") or pattern:startsWith("@") then return false end
        if pattern == "peach" and player:getMark("Global_PreventPeach") > 0 then return false end
		for _, patt in ipairs(pattern:split("+")) do
			local poi = sgs.Sanguosha:cloneCard(patt)
			if poi then
				poi:deleteLater()
				poi:setSkillName("kechengnianen")
				if poi:isKindOf("BasicCard") and not player:isLocked(poi)
				then return true end
			end
		end
        return false
	end,
}

kechengnianen = sgs.CreateTriggerSkill{
	name = "kechengnianen",
	view_as_skill = kechengnianenVS,
	waked_skills = "mashu",
	events = {sgs.CardUsed,sgs.CardResponded,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if (p:getMark("&bannianen-Clear")>0) then
						room:handleAcquireDetachSkills(p, "-mashu")
					end
				end
			end
		end
		if (event == sgs.CardResponded) and player:hasSkill(self:objectName()) then
			local response = data:toCardResponse()
			if (table.contains(response.m_card:getSkillNames(),"kechengnianen")) then
				if (not response.m_card:isRed()) or (response.m_card:objectName() ~= "slash") then
					room:handleAcquireDetachSkills(player, "mashu")
					room:setPlayerMark(player,"&bannianen-Clear",1)
				end
			end
		end
		if (event == sgs.CardUsed) and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if (table.contains(use.card:getSkillNames(),"kechengnianen")) then
				if (not use.card:isRed()) or (use.card:objectName() ~= "slash") then
					room:handleAcquireDetachSkills(player, "mashu")
					room:setPlayerMark(player,"&bannianen-Clear",1)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
kechengnianen:setGuhuoDialog("l")
kechengguanyu:addSkill(kechengnianen)



kechengxugong = sgs.General(extension_cheng, "kechengxugong", "wu", 3)

kechengbiaozhao = sgs.CreateTriggerSkill{
	name = "kechengbiaozhao",
	frequency = sgs.Skill_Frequent ,
	events = {sgs.EventPhaseStart,sgs.ConfirmDamage,sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Death) then
			local death = data:toDeath()
			if death.who == player and player:hasSkill(self:objectName()) then 
				for _, p in sgs.qlist(room:getAllPlayers()) do
					for _, m in sgs.list(p:getMarkNames()) do
						if m:startsWith("&kechengbiaozhao") then
							room:setPlayerMark(p,m,0)
						end
					end
				end
			end
		end
		if (event == sgs.ConfirmDamage) then
			local damage = data:toDamage()
			if damage.card and (damage.from:getMark("&kechengbiaozhaoto+#"..damage.to:objectName())>0) then
				room:sendCompulsoryTriggerLog(damage.to, self)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		if (event == sgs.EventPhaseStart) and player:hasSkill(self:objectName()) then
			if (player:getPhase() == sgs.Player_RoundStart) then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					for _, m in sgs.list(p:getMarkNames()) do
						if m:startsWith("&kechengbiaozhao") then
							room:setPlayerMark(p,m,0)
						end
					end
				end
			end
			if (player:getPhase() == sgs.Player_Start) then
				local players = room:askForPlayersChosen(player, room:getAllPlayers(), self:objectName(), 0, 2, "kechengbiaozhao-ask", true, false)
				if (players:length() == 2) then
					room:broadcastSkillInvoke(self:objectName())
					room:setPlayerMark(players:at(0),"&kechengbiaozhaofrom+#"..players:at(1):objectName(),1)
					room:setPlayerMark(players:at(1),"&kechengbiaozhaoto+#"..player:objectName(),1)
				end
			end
		end

	end,
	can_trigger = function(self, target)
		return target
	end,
}
kechengxugong:addSkill(kechengbiaozhao)

kechengyechou = sgs.CreateTriggerSkill{
	name = "kechengyechou",
	events = {sgs.Death,sgs.DamageForseen} ,
	frequency = sgs.Skill_Frequent ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Death) then
			local death = data:toDeath()
			if death.who:objectName()==player:objectName()
			and player:hasSkill(self) then
				local one = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "kechengyechou-ask", true, true)
				if one then
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(one,"&kechengyechou")
				end
			end
		else
			local damage = data:toDamage()
			if damage.to:getMark("&kechengyechou")>0
			and damage.damage >= damage.to:getHp() then
				room:sendCompulsoryTriggerLog(damage.to,self)
			    damage.damage = damage.damage*2*damage.to:getMark("&kechengyechou")
				data:setValue(damage)
			end
		end
	end
}
kechengxugong:addSkill(kechengyechou)





kechenglvbu = sgs.General(extension_cheng, "kechenglvbu", "qun+shu", 5)

kechengwuchang = sgs.CreateTriggerSkill{
	name = "kechengwuchang" ,
	events = {sgs.CardsMoveOneTime, sgs.DamageCaused} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_PlaceHand and move.to:objectName() == player:objectName() and move.from and move.to:getKingdom() ~= move.from:getKingdom()
			and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then
				room:sendCompulsoryTriggerLog(player,self)
				room:changeKingdom(player,move.from:getKingdom())
				local log = sgs.LogMessage()
				log.type = "$kechengwuchangchange"
				log.from = player
				log.to:append(room:findPlayerByObjectName(move.from:objectName()))
				room:sendLog(log)
			end
		end
		if (event == sgs.DamageCaused) then
			local damage = data:toDamage()
			if damage.from == player and damage.card
			and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) 
			and damage.from:getKingdom() == damage.to:getKingdom() then
				room:sendCompulsoryTriggerLog(damage.from, self)
				damage.damage = damage.damage + 1
				data:setValue(damage)
				room:changeKingdom(damage.from, "qun")
			end
		end
	end
}
kechenglvbu:addSkill(kechengwuchang)

--推心置腹
KCTuixinzhifu = sgs.CreateTrickCard{
	name = "_kecheng_tuixinzhifu",
	class_name = "Tuixinzhifu",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = false,
	can_recast = false,
	is_cancelable = true,
--	damage_card = true,
    available = function(self,player)
    	for _,to in sgs.list(player:getAliveSiblings())do
			if CanToCard(self,player,to) then
				return self:cardIsAvailable(player)
			end
		end
    end,
	filter = function(self,targets,to_select,source)
	    local range_fix = 0
		if self:isVirtualCard()
		and self:subcardsLength()>0 then
			local oh = source:getOffensiveHorse()
			if oh and self:getSubcards():contains(oh:getId())
			then range_fix = range_fix+1 end
		end
		return source:distanceTo(to_select,range_fix)==1 and to_select:getCardCount(true,true)>0
		and #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self,to_select)
	end,
	on_effect = function(self,effect)
		local from,to,room = effect.from,effect.to,effect.to:getRoom()
		local dc = sgs.Sanguosha:cloneCard("slash")
		dc:deleteLater()
		--for liuyong
		for i=1,2 do
			if from:isAlive() and to:getCardCount(true,true)>dc:subcardsLength() then
				local id = room:askForCardChosen(from,to,"hej",self:objectName(),false,sgs.Card_MethodNone,dc:getSubcards(),true)
				if id>=0 then dc:addSubcard(id)
				else break end
			end
		end
		if dc:subcardsLength()>0 then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION,from:objectName(),to:objectName(),self:objectName(),"")
			room:obtainCard(from,dc,reason,false)
			if from:hasSkill("kehedanxin") and table.contains(effect.card:getSkillNames(),"kehedanxin") then
				room:showCard(from,dc:getSubcards())
				for _, id in sgs.qlist(dc:getSubcards()) do
					if (sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Heart) then
						room:recover(from, sgs.RecoverStruct("kehedanxin",from))
						break
					end
				end
			end
			if from:isAlive() and to:isAlive() then
	    	   	local givenum = dc:subcardsLength()
				local recoveryes = 0
				from:setTag("_kecheng_tuixinzhifu", ToData(to))
				local dccard = room:askForExchange(from,self:objectName(),givenum,givenum,false,"kechengtuixinzhifuask")
				from:removeTag("_kecheng_tuixinzhifu")
				if from:hasSkill("kehedanxin") and table.contains(effect.card:getSkillNames(),"kehedanxin") then
					for _, id in sgs.qlist(dccard:getSubcards()) do
						if (sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Heart) then
							recoveryes = 1
						end
					end
					room:showCard(from,dccard:getSubcards())
				end
				room:giveCard(from,to,dccard,"_kecheng_tuixinzhifu")
				if (recoveryes == 1) then
					room:recover(to, sgs.RecoverStruct("kehedanxin",from))
				end
			end
		end
	end,
}
local card = KCTuixinzhifu:clone()
card:setSuit(-1)
card:setNumber(-1)
card:setParent(extension_cheng)

--趁火打劫
KCChenhuodajie = sgs.CreateTrickCard{
	name = "_kecheng_chenhuodajie",
	class_name = "Chenhuodajie",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = false,
	can_recast = false,
	is_cancelable = true,
	damage_card = true,
    available = function(self,player)
    	for _,to in sgs.list(player:getAliveSiblings())do
			if CanToCard(self,player,to) then
				return self:cardIsAvailable(player)
			end
		end
    end,
	filter = function(self,targets,to_select,source)
	    return to_select:getHandcardNum()>0 and to_select:objectName()~=source:objectName()
		and #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self,to_select)
	end,
	on_effect = function(self,effect)
		local from,to,room = effect.from,effect.to,effect.to:getRoom()
		if to:getHandcardNum()<1 then return end
		local id = room:askForCardChosen(from,to,"h",self:objectName())
		if id>=0 then
			room:showCard(to,id)
			local c = sgs.Sanguosha:getCard(id)
			local _data = sgs.QVariant()
			_data:setValue(effect)
			if room:askForCard(to,id,"_kecheng_chenhuodajie0:"..c:objectName()..":"..from:objectName(),_data ,sgs.Card_MethodNone) then 
				room:obtainCard(from,c) 
			else
				room:damage(sgs.DamageStruct(self,from,to)) 
			end
			--[[local result = room:askForChoice(effect.to, "kechengchenhuodajieask","givepai+shanghai")
			if result == "givepai" then
			    room:obtainCard(from,c) 
			else 
				room:damage(sgs.DamageStruct(self,from,to)) 
			end]]
		end
		return false
	end,
}
local card = KCChenhuodajie:clone()
card:setSuit(-1)
card:setNumber(-1)
card:setParent(extension_cheng)

kechengqingjiaoCard = sgs.CreateSkillCard{
	name = "kechengqingjiaoCard",
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select, source)
		if #targets>0 then return false end
		if to_select:getHandcardNum()>source:getHandcardNum()
		and source:getMark("&useqingjiaotxzf-Clear")<1 then
			local txzf = sgs.Sanguosha:cloneCard("_kecheng_tuixinzhifu")
			txzf:setSkillName("kechengqingjiao") 
			txzf:addSubcard(self)
			txzf:deleteLater()
			local plist = sgs.PlayerList()
			for i = 1, #targets do plist:append(targets[i]) end
			return txzf and txzf:targetFilter(plist, to_select, source)
		elseif to_select:getHandcardNum()<source:getHandcardNum()
		and source:getMark("&useqingjiaochdj-Clear")<1 then
			local chdj = sgs.Sanguosha:cloneCard("_kecheng_chenhuodajie")
			chdj:setSkillName("kechengqingjiao") 
			chdj:addSubcard(self)
			chdj:deleteLater()
			local plist = sgs.PlayerList()
			for i = 1, #targets do plist:append(targets[i]) end
			return chdj and chdj:targetFilter(plist, to_select, source)
		end
		return false
	end,
	about_to_use = function(self,room,use)
		if use.to:first():getHandcardNum()>use.from:getHandcardNum()
		and use.from:getMark("&useqingjiaotxzf-Clear")<1 then
			local txzf = sgs.Sanguosha:cloneCard("_kecheng_tuixinzhifu")
			txzf:setSkillName("kechengqingjiao") 
			txzf:addSubcard(self)
			txzf:deleteLater()
			use.card = txzf
		elseif use.to:first():getHandcardNum()<use.from:getHandcardNum()
		and use.from:getMark("&useqingjiaochdj-Clear")<1 then
			local chdj = sgs.Sanguosha:cloneCard("_kecheng_chenhuodajie")
			chdj:setSkillName("kechengqingjiao") 
			chdj:addSubcard(self)
			chdj:deleteLater()
			use.card = chdj
		end
		self:cardOnUse(room,use)
		if use.card:objectName()=="_kecheng_tuixinzhifu" then
			room:setPlayerMark(use.from,"&useqingjiaotxzf-Clear",1)
		elseif use.card:objectName()=="_kecheng_chenhuodajie" then
			room:setPlayerMark(use.from,"&useqingjiaochdj-Clear",1)
		end
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local usethis = 0
		if (target:getHandcardNum() > source:getHandcardNum()) then
			usethis = 1
			local card = sgs.Sanguosha:getCard(self:getSubcards():first())
			local txzf = sgs.Sanguosha:cloneCard("_kecheng_tuixinzhifu", card:getSuit(), card:getNumber())
			txzf:setSkillName("kechengqingjiao") 
			txzf:addSubcard(card)
			if not source:isProhibited(target, txzf) then
				room:useCard(sgs.CardUseStruct(txzf, source, target))
				room:setPlayerMark(source,"&useqingjiaotxzf-Clear",1)
			end
			txzf:deleteLater()
		elseif (target:getHandcardNum() < source:getHandcardNum()) and (usethis == 0) then
			local card = sgs.Sanguosha:getCard(self:getSubcards():first())
			local chdj = sgs.Sanguosha:cloneCard("_kecheng_chenhuodajie", card:getSuit(), card:getNumber())
			chdj:setSkillName("kechengqingjiao") 
			chdj:addSubcard(card)
			if not source:isProhibited(target, chdj) then
				room:useCard(sgs.CardUseStruct(chdj, source, target))
				room:setPlayerMark(source,"&useqingjiaochdj-Clear",1)
			end
			chdj:deleteLater()
		end
	end,
}

kechengqingjiao = sgs.CreateViewAsSkill{
	name = "kechengqingjiao",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end ,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = kechengqingjiaoCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return (player:getKingdom() == "qun") and not ((player:getMark("&useqingjiaotxzf-Clear")>0) and (player:getMark("&useqingjiaochdj-Clear")>0))
	end, 
}
kechenglvbu:addSkill(kechengqingjiao)


kechengchengxu = sgs.CreateTriggerSkill{
	name = "kechengchengxu",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.TargetSpecified},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.TargetSpecified) and (player:getKingdom() == "shu") then
			local use = data:toCardUse()
			if use.card:isKindOf("SkillCard") then return false end
			local no_respond_list = use.no_respond_list
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if (p:getKingdom() == player:getKingdom()) then
					table.insert(no_respond_list, p:objectName())
				end
			end
			use.no_respond_list = no_respond_list
			data:setValue(use)
			if #no_respond_list > 0 then
				room:sendCompulsoryTriggerLog(player,self)
			end
		end
	end,
}
kechenglvbu:addSkill(kechengchengxu)




local cscard = sgs.Sanguosha:cloneCard("slash")
cscard:setObjectName("_kecheng_stabs_slash")
cscard:setParent(extension_cheng)





kechengcisha = sgs.CreateTriggerSkill{
	name = "kechengcisha",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardOffset},
	global = true,
	can_trigger = function(self,target)
		return target and target:isAlive()
		and not table.contains(sgs.Sanguosha:getBanPackages(),"kearjsrgrcheng")
	end,
	on_trigger = function(self,event,player,data,room)
		if (event == sgs.CardOffset) then
			local effect = data:toCardEffect()
			if (effect.card:objectName()=="_kecheng_stabs_slash") 
			and effect.offset_card:isKindOf("Jink") and effect.to:getHandcardNum()>0 then
				if (effect.to:getState() ~= "online") and (effect.to:getHandcardNum()>1) then
					if room:askForDiscard(effect.to,"_kecheng_stabs_slash",1,1,false,false,"_kecheng_stabs_slash0:")
					then else return true end
				else
					if room:askForDiscard(effect.to,"_kecheng_stabs_slash",1,1,true,false,"_kecheng_stabs_slash0:")
					then else return true end
				end
			end
		end
	end
}
extension_cheng:addSkills(kechengcisha)


kechengxuyou = sgs.General(extension_cheng, "kechengxuyou", "qun+wei", 3)

kechenglipan = sgs.CreateTriggerSkill{
	name = "kechenglipan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				if player:askForSkillInvoke(self,data,false) then
					local kd = room:askForKingdom(player,self:objectName())
					if (player:getKingdom() ~= kd) then
						player:skillInvoked(self,-1)
						room:changeKingdom(player, kd)
					else
						return
					end
					local num = 0
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if (p:getKingdom() == player:getKingdom()) then
							num = num + 1
						end
					end
					if (num > 0) then
						player:drawCards(num,self:objectName())
					end
					room:setPlayerMark(player,"&kechenglipan",1)
					player:setPhase(sgs.Player_Play)
					room:broadcastProperty(player, "phase")
					local thread = room:getThread()
					if not thread:trigger(sgs.EventPhaseStart, room, player) then
						thread:trigger(sgs.EventPhaseProceeding, room, player)
					end
					thread:trigger(sgs.EventPhaseEnd, room, player)
					player:setPhase(sgs.Player_NotActive)
					room:broadcastProperty(player, "phase")
					room:setPlayerMark(player,"&kechenglipan",0)
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getKingdom() == player:getKingdom()
						and p:getCardCount()>0 and p:isAlive() and player:isAlive() then
							local to_duelint = room:askForExchange(p, self:objectName(), 1, 1, true, "lipanuseduel",true)
							if to_duelint then
								local juedou = sgs.Sanguosha:cloneCard("duel")
								juedou:setSkillName("_kechenglipan") 
								juedou:addSubcard(to_duelint)
								if p:canUse(juedou,player) then
									room:useCard(sgs.CardUseStruct(juedou, p, player))
								end
								juedou:deleteLater()	
							end
						end
					end
				end
			end
		end	
	end,

}
kechengxuyou:addSkill(kechenglipan)

kechengqingxiCard = sgs.CreateSkillCard{
	name = "kechengqingxiCard",
	target_fixed = false,
	--will_throw = false,
	mute = true,
	filter = function(self, targets, to_select, player)
		return #targets<1 and player:getHandcardNum()-to_select:getHandcardNum()==self:subcardsLength()
		and to_select:getMark("beusekechengqingxi-PlayClear")<1
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:setPlayerMark(target,"beusekechengqingxi-PlayClear",1)
		local slash = sgs.Sanguosha:cloneCard("_kecheng_stabs_slash")
		slash:setSkillName("kechengqingxi")
		slash:deleteLater()
		if player:canSlash(target,slash,false) then
			room:useCard(sgs.CardUseStruct(slash,player,target), true)
		end
	end
}
--主技能
kechengqingxi = sgs.CreateViewAsSkill{
	name = "kechengqingxi",
	n = 998,
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards>0 then
			local card = kechengqingxiCard:clone()
			for _, c in sgs.list(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return (player:getKingdom() == "qun")
	end, 
}

kechengxuyou:addSkill(kechengqingxi)

kechengjinmieCard = sgs.CreateSkillCard{
	name = "kechengjinmieCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select, player)
		local slash = sgs.Sanguosha:cloneCard("fire_slash")
		slash:setSkillName("kechengjinmie")
		slash:deleteLater() 
		return (#targets == 0) and (to_select:getHandcardNum() > player:getHandcardNum())
		and player:canSlash(to_select,slash,false)
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		local slash = sgs.Sanguosha:cloneCard("fire_slash")
		slash:setSkillName("kechengjinmie")
		room:useCard(sgs.CardUseStruct(slash,player,target),true)
		slash:deleteLater() 
	end
}
--主技能
kechengjinmieVS = sgs.CreateViewAsSkill{
	name = "kechengjinmie",
	n = 0,
	view_as = function(self, cards)
		return kechengjinmieCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (player:getKingdom() == "wei") and not player:hasUsed("#kechengjinmieCard") 
	end, 
}
kechengjinmie = sgs.CreateTriggerSkill{
	name = "kechengjinmie",
	view_as_skill = kechengjinmieVS,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			if damage.card and table.contains(damage.card:getSkillNames(),"kechengjinmie") and not damage.chain then
				local cha = damage.to:getHandcardNum()-damage.from:getHandcardNum()
				if cha>0 then
				    --room:broadcastSkillInvoke(self:objectName())
					local dc = sgs.Sanguosha:cloneCard("slash")
					dc:deleteLater()
					for i=1,cha do
						local id = room:askForCardChosen(damage.from, damage.to, "h", self:objectName(),false,sgs.Card_MethodDiscard,dc:getSubcards())
						if id>=0 then dc:addSubcard(id)
						else break end
					end
					room:throwCard(dc, damage.to, damage.from)
				end
			end
		end
	end,
}
kechengxuyou:addSkill(kechengjinmie)



kechengzhanghe = sgs.General(extension_cheng, "kechengzhanghe", "qun+wei", 4)

--技能穷途：鸣谢luas
kechengqongtuCard = sgs.CreateSkillCard{
	name = "kechengqongtuCard",
	will_throw = false,
	target_fixed = true,
	on_validate = function(self,use)
		use.from:getRoom():addPlayerMark(use.from,"kechengqongtu-Clear")
		use.from:addToPile("kechengqongtu",self)
		local use_card = sgs.Sanguosha:cloneCard("nullification")
		use_card:setSkillName("kechengqongtu")
		return use_card
	end,
	on_validate_in_response = function(self,from)
		from:getRoom():addPlayerMark(from,"kechengqongtu-Clear")
		from:addToPile("kechengqongtu",self)
		local use_card = sgs.Sanguosha:cloneCard("nullification")
		use_card:setSkillName("kechengqongtu")
		return use_card
	end
}
kechengqongtuvs = sgs.CreateViewAsSkill{
	name = "kechengqongtu",	
	n = 1,
	view_filter = function(self,selected,to_select)
		return to_select:getTypeId()>1
	end,
	view_as = function(self,cards)
		if #cards<1 then return end
		local new_card = kechengqongtuCard:clone()
		for _,c in ipairs(cards) do
			new_card:addSubcard(c)
		end
		return new_card
	end,
	enabled_at_response = function(self,player,pattern)
		if pattern=="nullification" and player:getMark("kechengqongtu-Clear")<1
		and (player:getHandcardNum()>0 or player:hasEquip())
		and player:getKingdom()=="qun"
		then return true end
	end,
	enabled_at_play = function(self,player)				
		return false
	end,
	enabled_at_nullification = function(self,player)
		return player:getMark("kechengqongtu-Clear")<1
		and player:getKingdom()=="qun"
		and (player:getHandcardNum()>0 or player:hasEquip())
	end
}
kechengqongtu = sgs.CreateTriggerSkill{
	name = "kechengqongtu" ,
	events = {sgs.CardFinished,sgs.PostCardEffected},
	view_as_skill = kechengqongtuvs,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.CardFinished then
		   	local use = data:toCardUse()
			if use.card:isKindOf("Nullification") and use.whocard then
				if not use.whocard:isKindOf("Nullification") then
					room:setTag("NullFromCard",sgs.QVariant(use.whocard:toString()))
				end
				for i,owner in sgs.list(room:findPlayersBySkillName(self:objectName()))do
					if use.whocard:toString()==owner:getTag("kechengqongtuCard"):toString() then
						owner:addMark("kechengqongtuNull")
						owner:setTag("kechengqongtuCard",sgs.QVariant(use.card:toString()))
					elseif table.contains(use.card:getSkillNames(),"kechengqongtu") then
						owner:setTag("kechengqongtuCard",sgs.QVariant(use.card:toString()))
						owner:setMark("kechengqongtuNull",1)
					end
				end
			end
		elseif event==sgs.PostCardEffected then
            local effect = data:toCardEffect()
			if effect.card:toString()~=room:getTag("NullFromCard"):toString() then return end
			for i,owner in sgs.list(room:findPlayersBySkillName(self:objectName()))do
				if owner:getTag("kechengqongtuCard"):toString()~="" then
					owner:removeTag("kechengqongtuCard")
					local can = owner:getMark("kechengqongtuNull")
					if math.mod(can,2)==1 then
						owner:drawCards(1,self:objectName())
					else
						room:changeKingdom(owner,"wei")
						local dummy = sgs.Sanguosha:cloneCard("slash")
						dummy:addSubcards(owner:getPile("kechengqongtu"))
						dummy:deleteLater()
						if dummy:subcardsLength()>0 then
							owner:obtainCard(dummy)
						end
					end
				end
			end
		end
		return false
	end
}
kechengzhanghe:addSkill(kechengqongtu)

kechengxianzhuVS = sgs.CreateOneCardViewAsSkill{
	name = "kechengxianzhu",
	response_or_use = true,
	view_filter = function(self, card)
		if card:isNDTrick() then
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:setSkillName("kechengxianzhu")
			slash:addSubcard(card)
			slash:deleteLater()
			return not sgs.Self:isLocked(slash)
		end
		return false
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("kechengxianzhu")
		slash:addSubcard(card)
		return slash
	end,
	enabled_at_play = function(self, player)
		return player:getKingdom() == "wei"
		and sgs.Slash_IsAvailable(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return player:getKingdom() == "wei" and string.find(pattern,"slash")
		and sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
	end
}

kechengxianzhu = sgs.CreateTriggerSkill{
	name = "kechengxianzhu",
	view_as_skill = kechengxianzhuVS,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			if damage.card and table.contains(damage.card:getSkillNames(),"kechengxianzhu")
			and damage.to:isAlive() then
				room:doAnimate(1, damage.from:objectName(), damage.to:objectName())
				room:getThread():delay(500)
				local card = sgs.Sanguosha:getCard(damage.card:getEffectiveId())
				if not card:isKindOf("Nullification") then
					room:broadcastSkillInvoke(self:objectName())
					local xzplayers = sgs.SPlayerList()
					xzplayers:append(damage.to)
					card:use(room,damage.from,xzplayers)
				end
			end
		end
	end,
}
kechengzhanghe:addSkill(kechengxianzhu)


kechengzhangliao = sgs.General(extension_cheng, "kechengzhangliao", "qun+wei", 4)

kechengzhengbingCard = sgs.CreateSkillCard{
	name = "kechengzhengbingCard",
	target_fixed = true ,
	will_throw = false,
	handling_method = sgs.Card_MethodRecast,
	on_use = function(self, room, source, targets)
		local card = sgs.Sanguosha:getCard(self:getEffectiveId())
		local msg = sgs.LogMessage()
		msg.type = "$kechengzhengbingcz"
		msg.from = source
		msg.card_str = card:toString()
		room:sendLog(msg)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, source:objectName(), self:getSkillName(), "")
		room:moveCardTo(card, nil, sgs.Player_DiscardPile, reason)
		source:drawCards(1,"recast")
		if card:isKindOf("Slash") then
			room:addMaxCards(source, 2, true)
			room:addPlayerMark(source,"&kechengzhengbingsp-Clear",2)
		elseif card:isKindOf("Jink") then
			source:drawCards(1,self:getSkillName())
		elseif card:isKindOf("Peach") then
			room:changeKingdom(source, "wei")
		end
	end,
}

kechengzhengbing = sgs.CreateViewAsSkill{
	name = "kechengzhengbing",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isCardLimited(to_select,sgs.Card_MethodRecast)
	end ,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = kechengzhengbingCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#kechengzhengbingCard") < 3
		and player:getKingdom() == "qun"
	end, 
}
kechengzhangliao:addSkill(kechengzhengbing)


kechengtuwei = sgs.CreateTriggerSkill{
	name = "kechengtuwei",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging,sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damaged) then
			local damage = data:toDamage()
			if (damage.to:getMark("&kechengtuwei") > 0) then
			    room:setPlayerMark(damage.to,"&kechengtuwei",0)
			end
		end
		if (event == sgs.EventPhaseChanging) and player:hasSkill(self:objectName()) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if (p:getMark("&kechengtuwei") > 0) then
						room:sendCompulsoryTriggerLog(player,self:objectName())
						room:setPlayerMark(p,"&kechengtuwei",0)
						local card_id = room:askForCardChosen(p, player, "he", self:objectName())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, p:objectName())
						room:obtainCard(p, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
					end
				end
			end
		end
		if event == sgs.EventPhaseStart and player:hasSkill(self)
		and player:getKingdom() == "wei" and player:getPhase() == sgs.Player_Play then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if player:inMyAttackRange(p) then
					players:append(p)
				end
			end
			if players:length() > 0 then
				local enys = room:askForPlayersChosen(player, players, self:objectName(), 0, 99, "kechengtuwei-ask", true, true)
				if (enys:length() > 0) then
					room:broadcastSkillInvoke(self:objectName())
				end
				for _, p in sgs.qlist(enys) do
					if not p:isNude() then
						room:setPlayerMark(p,"&kechengtuwei",1)
						local card_id = room:askForCardChosen(player, p, "he", self:objectName())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
						room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
kechengzhangliao:addSkill(kechengtuwei)



kechengzoushi = sgs.General(extension_cheng, "kechengzoushi", "qun", 3,false)

kechengguyin = sgs.CreateTriggerSkill{
    name = "kechengguyin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.GameStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.GameStart then
			local num = 0
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if (p:getGender() == sgs.General_Male) then
					num = num + 1
				end
			end
			room:setTag("kechengguyinmale",sgs.QVariant(num))
		end
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Start) then
				local n = room:getTag("kechengguyinmale"):toInt()
				room:setPlayerMark(player,"&kechengguyinmale",n)
				if player:askForSkillInvoke(self, data) then
					room:broadcastSkillInvoke(self:objectName())
					player:turnOver()
					local players = sgs.SPlayerList()
					players:append(player)
					for _, p in sgs.qlist(room:getOtherPlayers(player))do
						if p:getGender() == sgs.General_Male
						and p:askForSkillInvoke("kechengguyinturnover",data,false) then
							local can = p:faceUp()
							p:turnOver()
							if can~=p:faceUp()
							then players:append(p) end
						end
					end
					local mopai = 0
					while (mopai < n) do
						for _, p in sgs.qlist(players)do
							if (mopai < n) then
								p:drawCards(1,self:objectName())
								mopai = mopai + 1
							end
						end
					end
				end
				room:setPlayerMark(player,"&kechengguyinmale",0)
			end
		end
	end,
}
kechengzoushi:addSkill(kechengguyin)

kechengzhangdengCard = sgs.CreateSkillCard{
	name = "kechengzhangdengCard",
	target_fixed = true,
	mute = true,
	on_validate = function(self,use)
		local room = use.from:getRoom()
		local tos = sgs.SPlayerList()
		for _,p in sgs.list(room:getAlivePlayers())do
			if p:hasSkill(self:getSkillName())
			then tos:append(p) end
		end
		if tos:isEmpty() then return nil end
		tos = room:askForPlayerChosen(use.from,tos,self:getSkillName(),"kechengzhangdeng0:")
		if tos==nil then return nil end
		room:addPlayerMark(tos,"&kechengzhangdeng-Clear")
		if (tos:getMark("&kechengzhangdeng-Clear") == 2) then
			if not tos:faceUp() then tos:turnOver() end
		end
		local analeptic = sgs.Sanguosha:cloneCard("analeptic")
		analeptic:setSkillName(self:getSkillName())
		analeptic:deleteLater()
		return analeptic
	end,
	on_validate_in_response = function(self,from)
		local room = from:getRoom()
		local tos = sgs.SPlayerList()
		for _,p in sgs.list(room:getAlivePlayers())do
			if p:hasSkill(self:getSkillName())
			then tos:append(p) end
		end
		if tos:isEmpty() then return nil end
		tos = room:askForPlayerChosen(from,tos,self:getSkillName(),"kechengzhangdeng0:")
		if tos==nil then return nil end
		room:addPlayerMark(tos,"&kechengzhangdeng-Clear")
		if (tos:getMark("&kechengzhangdeng-Clear") == 2) then
			if not tos:faceUp() then tos:turnOver() end
		end
		local analeptic = sgs.Sanguosha:cloneCard("analeptic")
		analeptic:setSkillName(self:getSkillName())
		analeptic:deleteLater()
		return analeptic
	end,
}

kechengzhangdengex = sgs.CreateZeroCardViewAsSkill{
	name = "kechengzhangdengex&",
	view_as = function(self) 
		return kechengzhangdengCard:clone()
	end,
	enabled_at_play = function(self, player)
		--监测到邹氏并且她处于翻面，则玩家也可以在自己翻面时使用此技能：视为使用酒
		if player:faceUp() then return false end
		local tos = player:getAliveSiblings()
		tos:append(player)
		for _, p in sgs.qlist(tos) do
			if p:hasSkill("kechengzhangdeng") and not p:faceUp()
			then return sgs.Analeptic_IsAvailable(player) end
		end
	    return false
	end,
	enabled_at_response = function(self, player, pattern)
		--这个同理
		if player:faceUp() then return false end
		if string.find(pattern, "analeptic") then
			local tos = player:getAliveSiblings()
			tos:append(player)
			for _, p in sgs.qlist(tos) do
				if p:hasSkill("kechengzhangdeng") and not p:faceUp()
				then return true end
			end
		end
	    return false
	end,
}
extension_cheng:addSkills(kechengzhangdengex)

kechengzhangdeng = sgs.CreateTriggerSkill{
    name = "kechengzhangdeng",
	events = {sgs.GameStart,sgs.EventAcquireSkill},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		--游戏开始时或获得技能时，每个人发一个技能
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if not p:hasSkill("kechengzhangdengex",true) then
				room:attachSkillToPlayer(p,"kechengzhangdengex")
			end
		end
	end,
}
kechengzoushi:addSkill(kechengzhangdeng)


kechengchunyuqiong = sgs.General(extension_cheng, "kechengchunyuqiong", "qun", 4)

kechengcangchu = sgs.CreateTriggerSkill{
	name = "kechengcangchu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_PlaceHand
			and move.reason.m_skillName~="InitialHandCards"
			and move.to:objectName() == player:objectName() and player:hasSkill(self,true) then
				room:addPlayerMark(player,"&kechengcangchu-Clear",move.card_ids:length())
			end
		end
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Finish) then
				for _, cyq in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					local marknum = cyq:getMark("&kechengcangchu-Clear")
					if marknum>0 then
						local fris = room:askForPlayersChosen(cyq, room:getAllPlayers(), self:objectName(), 0, marknum, "kechengcangchu-ask", true, true)
						if fris:length() > 0 then
							room:broadcastSkillInvoke(self:objectName())
						end
						local livenum = room:getAlivePlayers():length()
						for _, fri in sgs.qlist(fris) do
							if (marknum <= livenum) then
								fri:drawCards(1,self:objectName())
							else
								fri:drawCards(2,self:objectName())
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
        return target and target:isAlive()
	end,
}
kechengchunyuqiong:addSkill(kechengcangchu)


kechengshishou = sgs.CreateTriggerSkill{
	name = "kechengshishou",
	frequency = sgs.Skill_Compulsory,
	waked_skills = "#kechengshishouex",
	events = {sgs.CardUsed,sgs.Damaged,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getMark("&kechengcangchushixiao-SelfClear")>0 then
				room:removePlayerMark(player,"Qingchengkechengcangchu")
			end
		end
		if (event == sgs.Damaged) then
			local damage = data:toDamage()
			if (damage.nature == sgs.DamageStruct_Fire) then
				room:sendCompulsoryTriggerLog(player,self)
				room:setPlayerMark(player,"&kechengcangchushixiao-SelfClear",1)
				room:addPlayerMark(player,"Qingchengkechengcangchu")
			end
		end
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:isKindOf("Analeptic") then
				room:sendCompulsoryTriggerLog(player,self)
				player:drawCards(3,self:objectName())
				room:setPlayerMark(player,"&kechengshishou-Clear",1)
			end
		end
	end,
}
kechengchunyuqiong:addSkill(kechengshishou)

kechengshishouex = sgs.CreateCardLimitSkill{
	name = "#kechengshishouex",
	limit_list = function(self, player)
		return "use"
	end,
	limit_pattern = function(self, player)
		if player:getMark("&kechengshishou-Clear")>0 then
			return "."
		end
		return ""
	end
}
kechengchunyuqiong:addSkill(kechengshishouex)



kechengzhenfu = sgs.General(extension_cheng, "kechengzhenfu", "qun", 3,false)

kechengjixiangCard = sgs.CreateSkillCard{
	name = "kechengjixiangCard",
	--target_fixed = true,
	mute = true,
	filter = function(self, targets, to_select, from)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
		then return false end
		local card = nil
		if self:getUserString() ~= "" then
			local us = self:getUserString():split("+")
			card = sgs.Sanguosha:cloneCard(us[1])
			card:deleteLater()
			if card:targetFixed() then return false end
			card:setSkillName("kechengjixiang")
		end
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		return card and card:targetFilter(plist, to_select, from)
	end,
	feasible = function(self, targets,from)
		if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
		and self:getUserString() ~= "" then
			local us = self:getUserString():split("+")
			local card = sgs.Sanguosha:cloneCard(us[1])
			card:deleteLater()
			if card:targetFixed() then return true end
			card:setSkillName("kechengjixiang")
			local plist = sgs.PlayerList()
			for i = 1, #targets do plist:append(targets[i]) end
			return card and card:targetsFeasible(plist, from)
		end
		return true
	end,
	on_validate = function(self, use) 
		use.m_isOwnerUse = false
		local room = use.from:getRoom()
		local tos = sgs.SPlayerList()
		for _,p in sgs.list(room:getOtherPlayers(use.from))do
			if p:hasSkill(self:getSkillName())
			and p:hasFlag("CurrentPlayer")
			then tos:append(p) end
		end
		tos = room:askForPlayerChosen(use.from,tos,self:getSkillName(),"kechengjixiang0:")
		if tos==nil then return nil end
		local us = {}
		for _,pn in sgs.list(self:getUserString():split("+"))do
			if tos:getMark(pn.."kechengjixiang-Clear")<1
			then table.insert(us,pn) end
		end
		if #us<1 then return nil end
		tos:setTag("kechengjixiangTo",ToData(use.from))
		if room:askForDiscard(tos,self:getSkillName(),1,1,true,true,"kechengjixiangsha:"..use.from:objectName(),".",self:getSkillName()) then
			tos:peiyin("kechengjixiang")
			local cn = room:askForChoice(use.from,self:getSkillName(),table.concat(us,"+"))
			room:addPlayerMark(tos,cn.."kechengjixiang-Clear")
			local dc = sgs.Sanguosha:cloneCard(cn)
			dc:setSkillName("_"..self:getSkillName())
			dc:deleteLater()
			room:addPlayerMark(tos,"exusetimekechengchengxian-Clear")
			return dc
		end
		room:setPlayerFlag(use.from,"Global_Kechengjixiang")
		return nil
	end,
	on_validate_in_response = function(self,from)
		local room = from:getRoom()
		local tos = sgs.SPlayerList()
		for _,p in sgs.list(room:getOtherPlayers(from))do
			if p:hasSkill(self:getSkillName())
			and p:hasFlag("CurrentPlayer")
			then tos:append(p) end
		end
		tos = room:askForPlayerChosen(from,tos,self:getSkillName(),"kechengjixiang0:")
		if tos==nil then return nil end
		local us = {}
		for _,pn in sgs.list(self:getUserString():split("+"))do
			if tos:getMark(pn.."kechengjixiang-Clear")<1
			then table.insert(us,pn) end
		end
		if #us<1 then return nil end
		tos:setTag("kechengjixiangTo",ToData(from))
		if room:askForDiscard(tos,self:getSkillName(),1,1,true,true,"kechengjixiangsha:"..from:objectName(),".",self:getSkillName()) then
			tos:peiyin("kechengjixiang")
			local cn = room:askForChoice(from,self:getSkillName(),table.concat(us,"+"))
			room:addPlayerMark(tos,cn.."kechengjixiang-Clear")
			local dc = sgs.Sanguosha:cloneCard(cn)
			dc:setSkillName("_"..self:getSkillName())
			dc:deleteLater()
			room:addPlayerMark(tos,"exusetimekechengchengxian-Clear")
			return dc
		end
		room:setPlayerFlag(from,"Global_Kechengjixiang")
		return nil
	end,
}

kechengjixiangex = sgs.CreateZeroCardViewAsSkill{
	name = "kechengjixiangex&",
	view_as = function(self) 
		local dc = kechengjixiangCard:clone()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="" then
			local dc = sgs.Self:getTag("kechengjixiangex"):toCard()
			if dc==nil then return end
			pattern = dc:objectName()
		end
		dc:setUserString(pattern)
		return dc
	end,
	enabled_at_play = function(self, player)
		if player:hasFlag("Global_Kechengjixiang") then return false end
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if p:hasSkill("kechengjixiang") and p:hasFlag("CurrentPlayer") then
				for _, pn in sgs.list(patterns())do
					if p:getMark(pn.."kechengjixiang-Clear")>0 then continue end
					local dc = sgs.Sanguosha:cloneCard(pn)
					if dc then
						dc:setSkillName("kechengjixiang")
						dc:deleteLater()
						if dc:getTypeId()==1
						and dc:isAvailable(player)
						then return true end
					end
				end
			end
		end
	    return false
	end,
	enabled_at_response = function(self, player, pattern)
		if player:hasFlag("Global_Kechengjixiang") then return false end
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if p:hasSkill("kechengjixiang") and p:hasFlag("CurrentPlayer") then
				for _, pn in sgs.list(pattern:split("+")) do
					if p:getMark(pn.."kechengjixiang-Clear")>0 then continue end
					local dc = sgs.Sanguosha:cloneCard(pn)
					if dc then
						dc:deleteLater()
						if dc:getTypeId()==1
						then return true end
					end
				end
			end
		end
	    return false
	end,
}
kechengjixiangex:setGuhuoDialog("l")
extension_cheng:addSkills(kechengjixiangex)


kechengjixiang = sgs.CreateTriggerSkill{
	name = "kechengjixiang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventAcquireSkill,sgs.EventPhaseChanging},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("kechengjixiangex",true) then
						room:detachSkillFromPlayer(p,"kechengjixiangex",true)
					end
				end
			elseif change.from == sgs.Player_NotActive and player:hasSkill(self,true) then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if not p:hasSkill("kechengjixiangex",true) then
						room:attachSkillToPlayer(p,"kechengjixiangex")
					end
				end
			end
		elseif player:hasFlag("CurrentPlayer") and player:hasSkill(self,true) then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:hasSkill("kechengjixiangex",true) then
					room:attachSkillToPlayer(p,"kechengjixiangex")
				end
			end
		end
	end,
}
kechengzhenfu:addSkill(kechengjixiang)

kechengchengxianCard = sgs.CreateSkillCard{
	name = "kechengchengxianCard" ,
	target_fixed = true ,
	mute = true,
	will_throw = false,
	about_to_use = function(self,room,use)
		local card = sgs.Sanguosha:getCard(self:getEffectiveId())
		local orinum = room:getCardTargets(use.from,card):length()
		if card:isKindOf("AOE") or card:isKindOf("GlobalEffect")
		then elseif card:targetFixed() then orinum = 1 end
		if orinum<1 then return end
		local choices = {}
		local ids = sgs.Sanguosha:getRandomCards()
		for id=0,sgs.Sanguosha:getCardCount() do
			local tcard = sgs.Sanguosha:getEngineCard(id)
			if ids:contains(id) and tcard:isNDTrick() then
				if table.contains(choices,tcard:objectName())
				or use.from:getMark(tcard:objectName().."kechengchengxian-Clear")>0
				then continue end
				local transcard = sgs.Sanguosha:cloneCard(tcard:objectName())
				transcard:setSkillName("kechengchengxian")
				transcard:addSubcard(self)
				transcard:deleteLater()
				if not transcard:isAvailable(use.from) then continue end
				local trannum = room:getCardTargets(use.from,tcard):length()
				if tcard:isKindOf("AOE") or tcard:isKindOf("GlobalEffect")
				then elseif tcard:targetFixed() then trannum = 1 end
				if trannum==orinum then table.insert(choices,tcard:objectName()) end
			end
		end
		if #choices<1 then return end
		table.insert(choices,"cancel")
		local choice = room:askForChoice(use.from,"kechengchengxian", table.concat(choices, "+"))
		if choice=="cancel" then return end
		for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
			local c = sgs.Sanguosha:getEngineCard(id)
			if c:objectName()==choice then room:setPlayerMark(use.from,"kechengchengxianName",id) break end
		end
		room:setPlayerMark(use.from,"kechengchengxianId",self:getEffectiveId())
		if room:askForUseCard(use.from,"@@kechengchengxian","kechengchengxian-ask:"..choice) then
			room:addPlayerMark(use.from,choice.."kechengchengxian-Clear")
			room:addPlayerMark(use.from,"kechengchengxianCard-PlayClear")
		end
	end
}
kechengchengxian = sgs.CreateViewAsSkill{
	name = "kechengchengxian",
	n = 1 ,
	view_filter = function(self, cards, to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern()=="@@kechengchengxian" then return end
		return not to_select:isEquipped() and to_select:isAvailable(sgs.Self)
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUsePattern()=="@@kechengchengxian" then
			local c = sgs.Sanguosha:getEngineCard(sgs.Self:getMark("kechengchengxianName"))
			local transcard = sgs.Sanguosha:cloneCard(c:objectName())
			transcard:addSubcard(sgs.Self:getMark("kechengchengxianId"))
			transcard:setSkillName("kechengchengxian")
			return transcard
		elseif #cards==1 then
			local card = kechengchengxianCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern=="@@kechengchengxian"
	end,
	enabled_at_play = function(self, player)
		return player:getMark("kechengchengxianCard-PlayClear")-player:getMark("exusetimekechengchengxian-Clear")<2
	end

}
kechengzhenfu:addSkill(kechengchengxian)


kechengeryuan = sgs.General(extension_cheng, "kechengeryuan", "qun", 4)

kechengneifa = sgs.CreateTriggerSkill{
	name = "kechengneifa",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.TargetSpecifying,sgs.CardUsed,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) and (player:getMark("&kechengneifaNotBasic") > 0) then
				room:removePlayerCardLimitation(player, "use", "BasicCard")
				room:setPlayerMark(player,"&kechengneifaNotBasic",0)
			end
		end
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Play) and room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(2)
				local card_id = room:askForDiscard(player, self:objectName(), 1, 1, false, true, "kechengneifa-discard"):getSubcards():first() 
				--local card = room:askForCard(player, ".", "kechengneifa-discard", sgs.QVariant(), self:objectName())
				local card = sgs.Sanguosha:getCard(card_id)
				if card then
					room:addPlayerMark(player, "HandcardVisible_ALL-Clear")
					if card:isKindOf("BasicCard") then
						local pren = 0
						for _,c in sgs.qlist(player:getCards("h")) do
							if not player:canUse(c) then
								pren = pren + 1
							end
						end
						room:setPlayerCardLimitation(player, "use", "TrickCard,EquipCard", true)
						local n = 0
						for _,c in sgs.qlist(player:getCards("h")) do
							if not player:canUse(c) then
								n = n + 1
							end
						end
						local nfn = math.max(n - pren,0)
						room:addSlashCishu(player, nfn)
						room:addSlashMubiao(player, 1)
						room:setPlayerMark(player, "&kechengneifaBasic-Clear", nfn)
					else
						room:setPlayerCardLimitation(player, "use", "BasicCard",false)
						room:setPlayerMark(player, "&kechengneifaNotBasic", 1)
					end
				--room:askForDiscard(player,self:objectName(), math.min(player:getCardCount(),1), math.min(player:getCardCount(),1), false, true, "kechengneifa-discard")
				end
			end
		end
		if (event == sgs.TargetSpecifying) then
			local use = data:toCardUse()
			if use.card:isNDTrick() and (player:getMark("&kechengneifaNotBasic") > 0) then
				--for ai
				if use.card:isKindOf("SavageAssault") or use.card:isKindOf("ArcheryAttack") then
					room:setPlayerFlag(player,"neifaremovefri")
				end
				local data = room:setTag("kechengneifa", data)
				local one = room:askForPlayerChosen(player, use.to, self:objectName(), "kechengneifa-ask", true, true)
				room:removeTag("kechengneifa")
				if one then
					if use.to:contains(one) then
					    use.to:removeOne(one)
					--else
						--use.to:append(one)
					end
					data:setValue(use)
				end
			end
		end
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()		
			if use.card:isKindOf("EquipCard")
			and (player:getMark("banneifafirst-Clear") == 0)
			and (player:getMark("&kechengneifaNotBasic") > 0) then
				room:setPlayerMark(player,"banneifafirst-Clear",1)
				room:removePlayerCardLimitation(player, "use", "BasicCard")
				local pren = 0
				for _,c in sgs.qlist(player:getCards("h")) do
					if not player:canUse(c) then
						pren = pren + 1
					end
				end
				room:setPlayerCardLimitation(player, "use", "BasicCard",false)
				local n = 0
				for _,c in sgs.qlist(player:getCards("h")) do
					if not player:canUse(c) then
						n = n + 1
					end
				end
				local cha = n - pren
				if (cha <= 0) then cha = 1 end
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(cha)
			end
		end
	end,
}
kechengeryuan:addSkill(kechengneifa)








kechengtaoqian = sgs.General(extension_cheng, "kechengtaoqian", "qun", 3)
kechengtaoqian:addSkill("zhaohuo")
kechengtaoqian:addSkill("tenyearyixiang")

kechengyirang = sgs.CreateTriggerSkill{
	name = "kechengyirang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Play) and not player:isNude() then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					room:setPlayerFlag(player,"-aiuseyirang")
					room:showAllCards(player)
					local dummy = sgs.Sanguosha:cloneCard("slash")
					for _,card in sgs.qlist(player:getCards("he")) do
						if not card:isKindOf("BasicCard") then
							dummy:addSubcard(card:getId())
						end
					end
					dummy:deleteLater()
					if dummy:subcardsLength()<1 then return false end
					local one = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "kechengyirang-ask", false, true)
					if one then
						if one:isAlive() then
							one:obtainCard(dummy)
						end
						if (one:getMaxHp() > player:getMaxHp()) then
							room:gainMaxHp(player,one:getMaxHp() - player:getMaxHp())
						end
						room:recover(player, sgs.RecoverStruct(self:objectName(),player,dummy:subcardsLength()))
					end
				end
			end
		end
	end,
}
kechengtaoqian:addSkill(kechengyirang)






--[[
kechengchengxianCard = sgs.CreateSkillCard{
	name = "kechengchengxianCard" ,
	target_fixed = true ,
	mute = true,
	will_throw = false,
	on_use = function(self, room, player, targets)
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		--room:setCardFlag(card,"readytochengxian")
		--空壳列表用于填充参数
		local kplayers = sgs.SPlayerList()
		--先让系统判断一下目标，过河拆桥，南蛮入侵，杀这些还是可以正常判断的
		local orinum = room:getCardTargets(player,card,kplayers,true):length()
		--修正：否则装备牌判断为可以对所有人使用，闪，酒，桃，无中生有也是
		--手动修正目标数
		if card:isKindOf("Jink")
		or (card:isKindOf("Peach") and not player:isWounded()) 
		or (card:isKindOf("Analeptic") and not sgs.Analeptic_IsAvailable(player))  then 
			orinum = 0
		end
		if (card:isKindOf("Analeptic") and sgs.Analeptic_IsAvailable(player)) 
		or (card:isKindOf("Peach") and player:isWounded()) 
		or card:isKindOf("EquipCard") 
		or card:isKindOf("ExNihilo") then 
			orinum = 1
		end
		player:drawCards(orinum)
		if not (orinum == 0) then
			local choices = {}
			--看这局游戏有哪些锦囊牌
			--local allids = 
			for _, id in sgs.qlist(room:getDrawPile()) do
				local tcard = sgs.Sanguosha:getCard(id)
				if tcard:isNDTrick() then
					local trannum = room:getCardTargets(player,tcard,kplayers,true):length()
					--无中生有目标数修正一下！为1
					if tcard:isKindOf("ExNihilo")  then 
						trannum = 1
					end
					--如果这个牌目标数和用来转换的牌合法目标数相同，就加入选项
					if (trannum == orinum) and (not table.contains(choices, tcard:objectName())) and (not table.contains(player:getTag("Alreadychengxian"):toString():split("+"), tcard:objectName()) ) then
						table.insert(choices, tcard:objectName())
					end
				end
			end
			--加入取消选项
			table.insert(choices, "cancel")
			--玩家选一个牌名
			local choice = room:askForChoice(player, "kechengchengxian", table.concat(choices, "+"))

			local transcard = sgs.Sanguosha:cloneCard( xkscard:getName() , card:getSuit(), card:getNumber())
			transcard:setSkillName(self:objectName())
			local newcard = sgs.Sanguosha:getWrappedCard(card:getId())
			newcard:takeOver(transcard)
			if room:askForUseCard(player, ""..newcard:getId(), "zhuangzhiuse-ask",-1,sgs.Card_MethodUse, false, player, nil) then
				--使用之后就减少剩余可用次数（默认两次和来自另一个技能赠送的
				if (player:getMark("usetimekechengchengxian-PlayClear") > 0) then
					room:removePlayerMark(player,"usetimekechengchengxian-PlayClear",1)
				elseif (player:getMark("exusetimekechengchengxian-PlayClear") > 0) then
					room:removePlayerMark(player,"exusetimekechengchengxian-PlayClear",1)
				end
			end
		end
	end
}
--挑选一张牌
kechengchengxianVS = sgs.CreateViewAsSkill{
	name = "kechengchengxian" ,
	n = 1 ,
	view_filter = function(self, cards, to_select)
		return (not sgs.Self:isJilei(to_select)) and (not to_select:isEquipped())
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = kechengchengxianCard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end ,
	enabled_at_play = function(self, player)
		--默认两次，加上额外次数必须大于0，才能发动
		return ((player:getMark("usetimekechengchengxian-PlayClear") + player:getMark("exusetimekechengchengxian-PlayClear")) > 0)
	end
}
kechengchengxian = sgs.CreateTriggerSkill{
	name = "kechengchengxian",
	view_as_skill = kechengchengxianVS,
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging,sgs.EventAcquireSkill,sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		--回合结束清除本回合记录的牌名，下回合就能重新用了
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				room:removeTag("Alreadychengxian")
			end
		end
		--出牌阶段开始，给玩家2枚使用次数
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Play) then
				room:setPlayerMark(player,"usetimekechengchengxian-PlayClear",2)
			end
		end
	end,
}
kechengzhenfu:addSkill(kechengchengxian)]]
--[[
kechengchengxianuseVS = sgs.CreateOneCardViewAsSkill{
	name = "kechengchengxianuse", 
	view_filter = function(self, cards, to_select)
		return true--to_select:hasFlag("readytochengxian")
	end ,
	view_as = function(self, card) 
		local pai = sgs.Self:getTag("Chengxianusetag"):toString()
		local cxcard = sgs.Sanguosha:cloneCard(pai, card:getSuit(), card:getNumber())
		cxcard:addSubcard(card:getId())
		cxcard:setSkillName("kechengchengxian")
		return cxcard
	end, 
	response_pattern = "@@kechengchengxianxks",
	enabled_at_play = function(self, player)
		return false
	end
}

--if not sgs.Sanguosha:getSkill("kechengchengxianuse") then skills:append(kechengchengxianuse) end

kechengchengxianuse = sgs.CreateTriggerSkill{
	name = "kechengchengxianuse",
	view_as_skill = kechengchengxianuseVS,
	events = {sgs.MarkChanged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.MarkChanged) then
			local mark = data:toMark()
			if (mark.name == "mbxks_zhenfu") and (mark.who:objectName() == player:objectName()) then
				player:drawCards(5)
				if room:askForUseCard(player, "@@kechengchengxianxks", "kechengchengxian1") then
					--减少使用次数
					if (player:getMark("usetimekechengchengxian-PlayClear") > 0) then
						room:removePlayerMark(player,"usetimekechengchengxian-PlayClear",1)
					elseif (player:getMark("exusetimekechengchengxian-PlayClear") > 0) then
						room:removePlayerMark(player,"exusetimekechengchengxian-PlayClear",1)
					end
					--增加本回合已用过的牌名纪录，结束时清除
					local alreadychengxian = player:getTag("Alreadychengxian"):toString():split("+")
					if not table.contains(alreadychengxian, choice) then
						table.insert(alreadychengxian, choice)
						player:setTag("Alreadychengxian", sgs.QVariant(table.concat(alreadychengxian, "+")))
					end
				end
				room:removeTag("Chengxianusetag")
			end
		end
	end,
}
kechengzhenfu:addSkill(kechengchengxianuse)
]]



kechengquyi = sgs.General(extension_cheng, "kechengquyi", "qun", 4,true,true)
kechengquyi:addSkill("fuqi")
kechengquyi:addSkill("jiaozi")

kechengcaosong = sgs.General(extension_cheng, "kechengcaosong", "wei", 4,true,true)
kechengcaosong:addSkill("lilu")
kechengcaosong:addSkill("yizhengc")

kechenggaolan = sgs.General(extension_cheng, "kechenggaolan", "qun", 4,true,true)
kechenggaolan:addSkill("mobileyongjungong")
kechenggaolan:addSkill("mobileyongdengli")

kechengyanfuren = sgs.General(extension_cheng, "kechengyanfuren", "qun", 3,false,true)
kechengyanfuren:addSkill("channi")
kechengyanfuren:addSkill("nifu")







sgs.LoadTranslationTable{
    ["kearjsrgrcheng"] = "江山如故·承",

	["_kecheng_chenhuodajie"] = "趁火打劫",
	[":_kecheng_chenhuodajie"] = "锦囊牌·单目标锦囊<br /><b>时机</b>：出牌阶段，对一名其他角色使用<br /><b>效果</b>：你展示其一张手牌，然后其选择一项：将此牌交给你；或受到你造成的1点伤害。",
	["_kecheng_tuixinzhifu"] = "推心置腹",
	[":_kecheng_tuixinzhifu"] = "锦囊牌·单目标锦囊<br /><b>时机</b>：出牌阶段，对与你距离为1的一名角色使用<br /><b>效果</b>：你获得其区域内至多两张牌，然后交给其等量的手牌。",
	["_kecheng_stabs_slash"] = "刺杀",
	["_kecheng_stabs_slash0"] = "刺杀：请弃置一张手牌，否则此【刺杀】依旧造成伤害",
	[":_kecheng_stabs_slash"] = "基本牌<br /><b>时机</b>：出牌阶段限一次，对攻击范围内的一名角色使用<br /><b>效果</b>：对目标角色造成1点伤害。\
	<b>额外效果</b>：目标使用【闪】抵消此【刺杀】时，若其有手牌，其需弃置一张手牌，否则此【刺杀】依旧造成伤害。",
	["_kecheng_tuixinzhifu0"] = "推心置腹：请选择 %src 张手牌交给 %dest",
	["_kecheng_chenhuodajie0"] = "趁火打劫：你可以将此【%src】交给 %dest ；或受到 %dest 造成的1点伤害",
	["kechengchenhuodajieask"] = "趁火打劫",
	["kechengchenhuodajieask:givepai"] = "令其获得展示的牌",
	["kechengchenhuodajieask:shanghai"] = "受到其造成的1点伤害",
	["kechengtuixinzhifuask"] = "请选择交给该角色的牌",


	["kechengsunce"] = "孙策[承]", 
	["&kechengsunce"] = "孙策",
	["#kechengsunce"] = "问鼎的霸王",
	["designer:kechengsunce"] = "官方",
	["cv:kechengsunce"] = "凉水汐月",
	["illustrator:kechengsunce"] = "君桓文化",
	["information:kechengsunce"] = "ᅟᅠᅟᅠ<i>建安五年，曹操与袁绍相拒于官渡，孙策阴欲袭许昌，迎汉帝，密治兵，部署诸将。未发，会为许贡门客所刺，遂将计就计，江东尽托于孙权，诈死以待天时。同年八月，曹、袁决战，孙策亲冒矢石，斩将刈旗，得扬、豫之地。曹操败走翼、青，刘备远遁荆、益。而后历时七年，孙策已有天下三分之二。于洛阳称帝，建霸王末竟之功业。孙权上表求吴王号，策封权为仲帝，令其共治天下。</i>",

	["kechengduxing"] = "独行",
	["kechengduxingCard"] = "独行",
	["kechengduxingex"] = "独行buff",
	[":kechengduxingex"] = "独行：你的手牌均视为【杀】",
	[":kechengduxing"] = "出牌阶段限一次，你可以视为使用一张无目标数限制的【决斗】，目标角色的手牌均视为【杀】直到此牌结算完毕。",

	["kechengzhiheng"] = "猘横",
	[":kechengzhiheng"] = "锁定技，你使用牌对当前回合响应过你使用的牌的角色造成的伤害+1。",
	
	["kechengzhasi"] = "诈死",
	["inzhasi"] = "诈死",
	[":kechengzhasi"] = "限定技，你可以防止你受到的致命伤害，失去“猘横”并获得“制衡”，然后其他角色与你的距离为无限直到你对其他角色使用牌时或当你受到伤害后。",
	
	["kechengbashi"] = "霸世",
	[":kechengbashi"] = "主公技，<font color='green'><b>每个回合限三次，</b></font>其他吴势力角色可以代替你打出【杀】或【闪】。",
	["kechengbashi_ask"] = "霸世：你可以替%dest打出【%src】",

	
	["$usekechengbashi"] = "%from 发动了技能<font color='yellow'><b>“霸世”</b></font>",

	--[[["$kechengduxing1"] = "沙场破敌，于我易如反掌！",
	["$kechengduxing2"] = "逢对手，遇良将，快哉快哉！",
	["$kechengzhiheng1"] = "天下之大，我可尽情驰骋！",
	["$kechengzhiheng2"] = "诸位，今日必让天下知我江东男儿勇武！",
	["$kechengzhasi1"] = "承父勇烈，雄踞江东！",
	["$kechengzhasi2"] = "须当谨记，江东英烈之功。",
	["$kechengbashi1"] = "酣阵强敌，正在此时！",
	["$kechengbashi2"] = "将军要与我切磋武艺？有趣！",]]

	["$kechengduxing1"] = "尔辈世族皆碌碌，千里函关我独行！",
	["$kechengduxing2"] = "江东英豪，可当我一人乎？",
	["$kechengzhiheng1"] = "杀尽逆竖，何人还敢平视！",
	["$kechengzhiheng2"] = "畏罪而返，区区螳臂，我何惧之！",
	["$kechengzhasi1"] = "内外大事悉付权弟，无需问我。",
	["$kechengzhasi2"] = "今遭小人暗算，不如将计就计。",
	["$kechengbashi1"] = "江东多逆，必兴兵戈，敢战者，进禄加官。",
	["$kechengbashi2"] = "汉失其鹿，群雄竞逐，从我者，封妻荫子。",
	["$tenyearzhiheng3"] = "省身以严，用权以慎，方能上使下力。",
	["$tenyearzhiheng4"] = "惩前毖后，宽严相济，士人自念吾恩。",

	--["~kechengsunce"] = "仲谋，孙家基业就要靠你了，呃。",
	["~kechengsunce"] = "天不假年，天不假年！",

	["kechengchendeng"] = "陈登[承]", 
	["&kechengchendeng"] = "陈登",
	["#kechengchendeng"] = "惊涛弄潮",
	["designer:kechengchendeng"] = "官方",
	["cv:kechengchendeng"] = "官方",
	["illustrator:kechengchendeng"] = "鬼画府，极乐",

	["kechenglunshi"] = "论势",
	[":kechenglunshi"] = "出牌阶段限一次，你可以令一名角色摸X张牌（X为其攻击范围内包含的角色数且至多摸至五张），然后其弃置Y张牌（Y为攻击范围内含有其的角色数）。",

	["kechengguitu"] = "诡图",
	[":kechengguitu"] = "<font color='green'><b>准备阶段，</b></font>你可以交换两名角色装备区的武器牌，然后攻击范围因此减少的角色回复1点体力。",
	
	["kechenglunshi-discard"] = "请选择弃置的牌",
	["kechengguitu-ask"] = "你可以发动“诡图”交换场上的两张武器牌",
	
	

	["$kechenglunshi1"] = "急施援手，救人于危难。",
	["$kechenglunshi2"] = "雪中送炭，扶人于困顿。",
	["$kechengguitu1"] = "动之以情，不若胁之以危。",
	["$kechengguitu2"] = "晓之以理，不如诱之以利。",


	["~kechengchendeng"] = "华元化不在，吾命休矣。",


--关羽
	["kechengguanyu"] = "关羽[承]", 
	["&kechengguanyu"] = "关羽",
	["#kechengguanyu"] = "羊左之义",
	["designer:kechengguanyu"] = "官方",
	["cv:kechengguanyu"] = "雨叁大魔王",
	["illustrator:kechengguanyu"] = "鬼画府，极乐",

	["kechengguanjue"] = "冠绝",
	[":kechengguanjue"] = "锁定技，其他角色不能使用或打出与你当前回合使用或打出过的牌花色相同的牌。",

	["kechengnianen"] = "念恩",
	[":kechengnianen"] = "你可以将一张牌当任意基本牌使用或打出，若以此法使用或打出的牌不是红色普通【杀】，本回合你获得“马术”且“念恩”失效。",
	["kechengnianen_slash"] = "念恩",
	["kechengnianen_saveself"] = "念恩",
	["bannianen"] = "禁用念恩",
	
	["$kechengguanjue1"] = "河北诸将，以某观之，如土鸡瓦狗！",
	["$kechengguanjue2"] = "小儿舞刀，不值一哂。",
	["$kechengnianen1"] = "丞相厚恩，今斩将以报。",
	["$kechengnianen2"] = "丈夫信义为先，恩信岂可负之？",
	["$kechengnianen3"] = "桃园之谊，殷殷在怀，不敢或忘。",
	["$kechengnianen4"] = "解印封金离许都，惟思恩义走长途。",

	["~kechengguanyu"] = "皇叔厚恩，来世再报了。",

	--[[["$kechengnianen1"] = "手握青龙，跨骑赤兔！",
	["$kechengnianen2"] = "过关斩将，谁能拦我？",


	["~kechengguanyu"] = "马上就能见到大哥了。",]]


--许贡
	["kechengxugong"] = "许贡[承]", 
	["&kechengxugong"] = "许贡",
	["#kechengxugong"] = "独计击流",
	["designer:kechengxugong"] = "官方",
	["cv:kechengxugong"] = "官方",
	["illustrator:kechengxugong"] = "君桓文化",

	["kechengbiaozhao"] = "表召",
	[":kechengbiaozhao"] = "<font color='green'><b>准备阶段，</b></font>你可以依次选择两名角色，直到你下个回合开始时或当你死亡时，第一名角色对第二名角色使用牌无距离和次数限制，且第二名角色使用牌对你造成的伤害+1。",

	["kechengyechou"] = "业仇",
	[":kechengyechou"] = "<font color='green'><b>当你死亡时，</b></font>你可以令一名其他角色本局游戏受到的致命伤害×2。",
	["kechengyechouex"] = "业仇",

	["kechengyechou-ask"] = "你可以选择发动“业仇”的角色",
	["kechengbiaozhao-ask"] = "你可以选择发动“表召”的角色",
	["kechengbiaozhaofrom"] = "表召一",
	["kechengbiaozhaoto"] = "表召二",

	["$kechengbiaozhao1"] = "此密诏，望得丞相重视。",
	["$kechengbiaozhao2"] = "孙策枭雄，若放于外，必作事患。",
	["$kechengyechou1"] = "你的命数也快到尽头了！",
	["$kechengyechou2"] = "今日之仇来日必报！",

	["~kechengxugong"] = "吾身之死，愿得丞相之醒。",


	--吕布
	["kechenglvbu"] = "吕布[承]", 
	["&kechenglvbu"] = "吕布",
	["#kechenglvbu"] = "虎视中原",
	["designer:kechenglvbu"] = "官方",
	["cv:kechenglvbu"] = "官方",
	["illustrator:kechenglvbu"] = "鬼画府，极乐",

	["kechengwuchang"] = "无常",
	[":kechengwuchang"] = "锁定技，当你获得其他角色的牌后，你变更势力至与其相同；你使用【杀】或【决斗】对相同势力的角色造成伤害时，你变更势力至“群”且此伤害+1。",
	["$kechengwuchangchange"] = "%from 变更势力至与 %to 相同！",

	["kechengqingjiao"] = "轻狡",
	[":kechengqingjiao"] = "群势力技，<font color='green'><b>出牌阶段各限一次，</b></font>你可以将一张牌当【推心置腹】/【趁火打劫】对一名手牌数大于/小于你的角色使用。",
	["useqingjiaotxzf"] = "轻狡：推心置腹",
	["useqingjiaochdj"] = "轻狡：趁火打劫",

	["kechengchengxu"] = "乘虚",
	[":kechengchengxu"] = "蜀势力技，锁定技，与你势力相同的其他角色不能响应你使用的牌。",

	["$kechengwuchang1"] = "我，才是举世无双之人。",
	["$kechengwuchang2"] = "无双的力量，无人撼动！",
	["$kechengqingjiao1"] = "权利与财富，我都要拿走！",
	["$kechengqingjiao2"] = "唯有利益才能驱使我。",

	["~kechenglvbu"] = "来日再战，要你有去无回！",


	--许攸
	["kechengxuyou"] = "许攸[承]", 
	["&kechengxuyou"] = "许攸",
	["#kechengxuyou"] = "毕方矫翼",
	["designer:kechengxuyou"] = "官方",
	["cv:kechengxuyou"] = "官方",
	["illustrator:kechengxuyou"] = "鬼画府，极乐",

	["kechenglipan"] = "离叛",
	[":kechenglipan"] = "<font color='green'><b>回合结束时，</b></font>你可以变更势力并摸X张牌（X为与你势力相同的其他角色数），然后你执行一个额外的出牌阶段，此阶段结束时，与你势力相同的其他角色可以各将一张牌当【决斗】对你使用。",
	["$kechenglipanqun"] = "%from 选择了<font color='yellow'><b> “群” </b></font>势力",
	["$kechenglipanwei"] = "%from 选择了<font color='yellow'><b> “魏” </b></font>势力",

	["kechengqingxi"] = "轻袭",
	[":kechengqingxi"] = "群势力技，<font color='green'><b>出牌阶段每名角色限一次，</b></font>你可以将手牌弃置至与一名手牌数小于你的角色相同，然后你视为对其使用一张刺【杀】。",

	["lipanuseduel"] = "离叛：你可以将一张牌当【决斗】对其使用",
	["kechengqingxi-discard"] = "请选择弃置的牌",

	["kechengjinmie"] = "烬灭",
	[":kechengjinmie"] = "魏势力技，出牌阶段限一次，你可以视为对一名手牌数大于你的角色使用一张火【杀】，此牌对该角色造成伤害后，你弃置其手牌至与你相同。",
	["$kechengqingxiCardcisha"] = "%from 对 %to 使用了刺【杀】！",

	["$kechenglipan1"] = "兵戈伐谋之事，乃某之所长也。",
	["$kechenglipan2"] = "攸之大才事于袁绍，言不听计不从。",
	["$kechengqingxi1"] = "此非为一时之利，乃千秋万载之功！",
	["$kechengqingxi2"] = "汝等皆匹夫尔，何足道哉？",
	["$kechengjinmie1"] = "大略如此，明公速行勿疑。",
	["$kechengjinmie2"] = "若取乌巢焚其粮，袁贼还可坚守几许？",

	["~kechengxuyou"] = "兔死狗烹，天不怜我！",


	--张郃
	["kechengzhanghe"] = "张郃[承]", 
	["&kechengzhanghe"] = "张郃",
	["#kechengzhanghe"] = "微子去殷",
	["designer:kechengzhanghe"] = "官方",
	["cv:kechengzhanghe"] = "官方",
	["illustrator:kechengzhanghe"] = "君桓文化，极乐",

	["kechengqongtu"] = "穷途",
	[":kechengqongtu"] = "群势力技，每个回合限一次，你可以将一张非基本牌置于武将牌上视为使用一张【无懈可击】，若此牌生效，你摸一张牌，否则你变更势力至“魏”并获得武将牌上的所有牌。",

	["kechengxianzhu"] = "先著",
	["kechengxianzhuslash"] = "先著",
	[":kechengxianzhu"] = "魏势力技，你可以将一张普通锦囊牌当【杀】使用（无次数限制），当此【杀】对唯一目标角色造成伤害后，你对其执行该锦囊牌的效果。",

	["$kechengqongtu1"] = "时以进而取之，无则磨锋以待。",
	["$kechengqongtu2"] = "知敌之薄弱，略我之计谋。",
	["$kechengxianzhu1"] = "天易之理可胜，知略更甚以往。",


	["~kechengzhanghe"] = "吾筹划而思，奈何还是慢了一步。",


	--张辽
	["kechengzhangliao"] = "张辽[承]", 
	["&kechengzhangliao"] = "张辽",
	["#kechengzhangliao"] = "利刃风骑",
	["designer:kechengzhangliao"] = "官方",
	["cv:kechengzhangliao"] = "官方",
	["illustrator:kechengzhangliao"] = "君桓文化，极乐",

	["kechengzhengbing"] = "整兵",
	[":kechengzhengbing"] = "群势力技，<font color='green'><b>出牌阶段限三次，</b></font>你可以重铸一张牌，然后若此牌为：【杀】，你本回合手牌上限+2；【闪】，你摸一张牌；【桃】，你变更势力至“魏”。",
	["kechengzhengbingsp"] = "整兵手牌上限",
	["$kechengzhengbingcz"] = "%from 重铸了【%card】",
	
	["kechengtuwei"] = "突围",
	["kechengtuwei-ask"] = "你可以选择发动“突围”的目标",
	[":kechengtuwei"] = "魏势力技，<font color='green'><b>出牌阶段开始时，</b></font>你可以获得攻击范围内任意名角色的各一张牌，若如此做，此回合结束时，其中本回合没有受到过伤害的角色各获得你的一张牌。",

	["$kechengzhengbing1"] = "调令一出，差者无弗远近！",
	["$kechengzhengbing2"] = "调令在此，尔等皆随差遣！",
	["$kechengtuwei1"] = "传檄募兵，呼无不应！",
	["$kechengtuwei2"] = "凡入伍者，皆干赏蹈利！",


	["~kechengzhangliao"] = "奈何病重，无力再战。",



	--邹氏
	["kechengzoushi"] = "邹氏[承]", 
	["&kechengzoushi"] = "邹氏",
	["#kechengzoushi"] = "淯水香魂",
	["designer:kechengzoushi"] = "官方",
	["cv:kechengzoushi"] = "官方",
	["illustrator:kechengzoushi"] = "君桓文化，极乐",

	["kechengguyin"] = "孤吟",
	[":kechengguyin"] = "<font color='green'><b>准备阶段，</b></font>你可以翻面并令其他男性角色依次选择是否翻面，然后你和其他所有翻面的角色轮流摸一张牌直到以此法的摸牌数达到X（X为游戏开始时的男性角色数）。",

	["kechengzhangdeng"] = "帐灯",
	[":kechengzhangdeng"] = "若你的武将牌背面向上，一名武将牌背面向上的角色可以视为使用【酒】，当“帐灯”于一个回合内第二次发动时，你翻至正面向上。",

	["kechengzhangdengex"] = "帐灯酒",
	[":kechengzhangdengex"] = "若邹氏的武将牌背面向上，你可以视为使用【酒】；当“帐灯”于一个回合内第二次发动时，邹氏翻至正面向上。",
	["kechengzhangdeng0"] = "帐灯：请选择一名拥有“帐灯”的角色",

	["kechengguyinmale"] = "初始男性数",
	["kechengguyinturnover"] = "孤吟：将武将牌翻面",

	["$kechengguyin1"] = "佳人倾城又倾国，何怨幽王戏诸侯？",
	["$kechengguyin2"] = "武夫以力破阵，佳人凭貌倾城。",
	["$kechengzhangdeng1"] = "三千青丝化弱水，含泪明眸溺英雄。",
	["$kechengzhangdeng2"] = "温柔乡里忘归路，香唇软语最噬人。",

	["~kechengzoushi"] = "生逢乱世，身何由己？",


	--淳于琼
	["kechengchunyuqiong"] = "淳于琼[承]", 
	["&kechengchunyuqiong"] = "淳于琼",
	["#kechengchunyuqiong"] = "乌巢酒仙",
	["designer:kechengchunyuqiong"] = "官方",
	["cv:kechengchunyuqiong"] = "官方",
	["illustrator:kechengchunyuqiong"] = "君桓文化",

	["kechengcangchu"] = "仓储",
	[":kechengcangchu"] = "一名角色的<font color='green'><b>结束阶段，</b></font>你可以令至多X名角色各摸一张牌（X为你当前回合获得的牌数），若X大于存活角色数，改为两张。",

	["$usekechengcangchu"] = "%from 发动了<font color='yellow'><b> “仓储” </b></font>",

	["kechengshishou"] = "失守",
	[":kechengshishou"] = "锁定技，你使用【酒】时摸三张牌，然后你当前回合不能使用牌；当你受到火焰伤害后，“仓储”失效直到你的回合结束。",

	["kechengcangchu-ask"] = "你可以选择发动“仓储”摸牌的角色",
	["kechengcangchushixiao"] = "仓储失效",

	["$kechengcangchu1"] = "广积粮草，有备无患。",
	["$kechengcangchu2"] = "吾奉命于此建仓储粮。",
	["$kechengshishou1"] = "腹痛骤发，痛不可当！",
	["$kechengshishou2"] = "火光冲天，悔不当初！",

	["~kechengchunyuqiong"] = "这酒饮不得啊！",

	--甄宓
	["kechengzhenfu"] = "甄宓[承]", 
	["&kechengzhenfu"] = "甄宓",
	["#kechengzhenfu"] = "一顾倾国",
	["designer:kechengzhenfu"] = "官方",
	["cv:kechengzhenfu"] = "离瞳鸭",
	["illustrator:kechengzhenfu"] = "君桓文化",

	["kechengjixiang"] = "济乡",
	["kechengjixiangex"] = "济乡",
	[":kechengjixiang"] = "你的回合内每种牌名限一次，当一名其他角色需要使用或打出一张基本牌时，你可以弃置一张牌令其视为使用或打出之，然后你摸一张牌且本回合“称贤”的次数限制+1。",

	["kechengchengxian"] = "称贤",
	[":kechengchengxian"] = "<font color='green'><b>出牌阶段限两次，</b></font>你可以将一张手牌当做本回合未以此法使用过且与此牌的合法目标数相同的普通锦囊牌使用。",

	["kechengjixiangtao"] = "济乡：你可以弃置一张牌令 %src 视为使用【桃】",
	["kechengjixiangjiu"] = "济乡：你可以弃置一张牌令 %src 视为使用【酒】",
	["kechengjixiangshan"] = "济乡：你可以弃置一张牌令 %src 视为使用/打出【闪】",
	["kechengjixiangsha"] = "济乡：你可以弃置一张牌令 %src 视为使用/打出【杀】",
	["kechengchengxian-ask"] = "请选择此【%src】的目标 -> 点击确定",


--CV：离瞳鸭
	["$kechengjixiang1"] = "珠玉不足贵，德行传家久。",
	["$kechengjixiang2"] = "人情一日不食则饥，愿母亲慎思之。",
	["$kechengchengxian1"] = "所愿广求淑媛，以丰继嗣。",
	["$kechengchengxian2"] = "贤妻夫祸少，夫宽妻多福。",

	["~kechengzhenfu"] = "乱世人如苇，随波雨打浮……",


	--袁谭&袁尚
	["kechengeryuan"] = "袁谭＆袁尚[承]", 
	["&kechengeryuan"] = "袁谭袁尚",
	["#kechengeryuan"] = "操戈同室",
	["designer:kechengeryuan"] = "官方",
	["cv:kechengeryuan"] = "官方",
	["illustrator:kechengeryuan"] = "李秀森",

	["kechengneifa"] = "内伐",
	["kechengneifa-discard"] = "内伐：请弃置一张牌",
	["kechengneifaNotBasic"] = "内伐非基本牌",
	["kechengneifaBasic"] = "内伐基本牌",
	["kechengneifa-ask"] = "内伐：你可以移除一个目标",
	[":kechengneifa"] = "<font color='green'><b>出牌阶段开始时，</b></font>你可以摸两张牌，然后弃置一张牌并令你本回合手牌对其他角色可见，若弃置的牌：是基本牌，本回合你不能使用非基本牌且你可以多使用X张【杀】，你使用【杀】的目标数限制+1；不是基本牌，本回合你不能使用基本牌，你使用普通锦囊牌的目标数限制+1，且使用普通锦囊牌指定目标时可以移除一个目标，且你首次使用装备牌时摸X张牌（X为你手牌中仅因“内伐”不能使用的牌数且至少为1至多为5）。",

	["$kechengneifa1"] = "同室内伐，贻笑外人。",
	["$kechengneifa2"] = "自相恩残，相煎何急？",

	["~kechengeryuan"] = "兄弟难齐心，该有此果。",
	

--陶谦
	["kechengtaoqian"] = "陶谦[承]", 
	["&kechengtaoqian"] = "陶谦",
	["#kechengtaoqian"] = "膺秉温仁",
	["designer:kechengtaoqian"] = "官方",
	["cv:kechengtaoqian"] = "官方",
	["illustrator:kechengtaoqian"] = "福州明暗",

	["kechengyirang"] = "揖让",
	[":kechengyirang"] = "<font color='green'><b>出牌阶段开始时，</b></font>你可以展示所有牌并将其中的非基本牌交给一名其他角色，然后你增加体力上限至与其相同并回复X点体力（X为你以此法交给其的牌数）。",
	["kechengyirang-ask"] = "揖让：请选择一名角色交给其非基本牌",

	["~kechengtaoqian"] = "悔不该差使小人，遭此祸患。",

	--麴义
	["kechengquyi"] = "麴义[承]", 
	["&kechengquyi"] = "麴义",
	["#kechengquyi"] = "名门的骁将",
	["designer:kechengquyi"] = "官方",
	["cv:kechengquyi"] = "官方",
	["illustrator:kechengquyi"] = "秋呆呆",

	["~kechengquyi"] = "为主公戎马一生，主公为何如此对我！",

	--曹嵩
	["kechengcaosong"] = "曹嵩[承]", 
	["&kechengcaosong"] = "曹嵩",
	["#kechengcaosong"] = "依权弼子",
	["designer:kechengcaosong"] = "官方",
	["cv:kechengcaosong"] = "官方",
	["illustrator:kechengcaosong"] = "凝聚永恒",

	["~kechengcaosong"] = "孟德，勿忘汝父之仇！",

	--高览
	["kechenggaolan"] = "高览[承]", 
	["&kechenggaolan"] = "高览",
	["#kechenggaolan"] = "绝击坚营",
	["designer:kechenggaolan"] = "官方",
	["cv:kechenggaolan"] = "官方",
	["illustrator:kechenggaolan"] = "兴游",

	["~kechenggaolan"] = "满腹忠肝，难抵一句谮言，唉！",

--严夫人
	["kechengyanfuren"] = "严夫人[承]", 
	["&kechengyanfuren"] = "严夫人",
	["#kechengyanfuren"] = "霜天薄裳",
	["designer:kechengyanfuren"] = "官方",
	["cv:kechengyanfuren"] = "官方",
	["illustrator:kechengyanfuren"] = "君桓文化",

	["~kechengyanfuren"] = "妾身，绝不会害将军呀！",

}







extension_zhuan = sgs.Package("kearjsrgszhuan", sgs.Package_GeneralPack)

kezhuanguojia = sgs.General(extension_zhuan, "kezhuanguojia", "wei", 3,true)

kezhuanqingzi = sgs.CreateTriggerSkill{
    name = "kezhuanqingzi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.Death},
	waked_skills = "tenyearshensu",
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end ,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.Death) then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then return false end
			for _, p in sgs.qlist(room:getAllPlayers()) do 
				if (p:getMark("&kezhuanqingzi") > 0) then
					room:setPlayerMark(p,"&kezhuanqingzi",0)
					room:handleAcquireDetachSkills(p, "-tenyearshensu")
				end
			end		
		end
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Start) then
				local players = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:canDiscard(p, "e") then
						players:append(p)
					end
				end	
				local ones = room:askForPlayersChosen(player, players, self:objectName(), 0, players:length(), "kezhuanqingzi-ask", true, true)
				if not ones:isEmpty() then room:broadcastSkillInvoke(self:objectName()) end
				for _,q in sgs.qlist(ones) do
					local to_throw = room:askForCardChosen(player, q, "e", self:objectName(),false,sgs.Card_MethodDiscard)
					room:throwCard(to_throw, q, player)
					if not q:hasSkill("tenyearshensu",true) then
						room:setPlayerMark(q,"&kezhuanqingzi",1)
						room:handleAcquireDetachSkills(q, "tenyearshensu")
					end
				end	
			end
			if (player:getPhase() == sgs.Player_RoundStart) then
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if (p:getMark("&kezhuanqingzi") > 0) then
				        room:handleAcquireDetachSkills(p, "-tenyearshensu")
						room:setPlayerMark(p,"&kezhuanqingzi",0)
					end
				end
			end
		end
	end,
}
kezhuanguojia:addSkill(kezhuanqingzi)

kezhuandingce = sgs.CreateTriggerSkill{
	name = "kezhuandingce" ,
	events = {sgs.Damaged} ,
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.Damaged then
			local to_data = sgs.QVariant()
			to_data:setValue(damage.from)
			if player:askForSkillInvoke(self, to_data) then
				room:broadcastSkillInvoke(self:objectName())
				local cs = {}
				if player:canDiscard(player, "h") then
					local id = room:askForCardChosen(player,player,"h",self:objectName(),false,sgs.Card_MethodDiscard)
					room:throwCard(id, player, player)
					table.insert(cs,sgs.Sanguosha:getCard(id):getColor())
				end
				if player:isAlive() and player:canDiscard(damage.from, "h") then
					local id = room:askForCardChosen(player,damage.from,"h",self:objectName(),false,sgs.Card_MethodDiscard)
					room:throwCard(id, damage.from, player)
					table.insert(cs,sgs.Sanguosha:getCard(id):getColor())
				end
				if #cs>1 and cs[1]==cs[2] and player:isAlive() then
					local dzxj = sgs.Sanguosha:cloneCard("dongzhuxianji")
					dzxj:setSkillName("_kezhuandingce")
					dzxj:deleteLater()  
					if player:canUse(dzxj,player) then
						room:useCard(sgs.CardUseStruct(dzxj,player,player), true)
					end
				end
			end
		end
	end
}
kezhuanguojia:addSkill(kezhuandingce)


function zhuanJfNames(player)
	local aps = player:getAliveSiblings()
	aps:append(player)
	local ption = ""
	for _,p in sgs.list(aps)do
		for _,s in sgs.list(p:getSkillList())do
			if s:isAttachedLordSkill() then continue end
			ption = ption..s:getDescription()
		end
	end
	local names = {}
	for id=0,sgs.Sanguosha:getCardCount()-1 do
		local c = sgs.Sanguosha:getEngineCard(id)
		if c:getTypeId()>2 or table.contains(names,c:objectName())
		or player:getMark(c:getType().."kezhuanzhenfeng-PlayClear")>0 then continue end
		if string.find(ption,"【"..sgs.Sanguosha:translate(c:objectName()).."】")
		and (c:isNDTrick() or c:isKindOf("BasicCard")) and (not c:isKindOf("kezhuan_ying"))
		then table.insert(names,c:objectName()) end
	end
	return names
end

function zhuandummyCard(name,suit,number)
	name = name or "slash"
	local c = sgs.Sanguosha:cloneCard(name)
	if c then
		if suit then c:setSuit(suit) end
		if number then c:setNumber(number) end
		c:deleteLater()
		return c
	end
end

kezhuanzhenfengCard = sgs.CreateSkillCard{
	name = "kezhuanzhenfengCard",
	target_fixed = true,
	about_to_use = function(self,room,use)
		local p_choices = {}
		for _,p in sgs.list(zhuanJfNames(use.from))do
			local dc = zhuandummyCard(p)
			dc:setSkillName("kezhuanzhenfeng")
			if use.from:getMark(dc:getType().."kezhuanzhenfeng-PlayClear")<1 and dc:isAvailable(use.from)
			then table.insert(p_choices,p) end
		end
		if #p_choices<1 then return end
		table.insert(p_choices,"cancel")
		p_choices = room:askForChoice(use.from,"kezhuanzhenfeng",table.concat(p_choices,"+"))
		if p_choices=="cancel" then return end
		for i=0,sgs.Sanguosha:getCardCount()-1 do
			local c = sgs.Sanguosha:getEngineCard(i)
			if c:objectName()==p_choices then
				room:setPlayerMark(use.from,"kezhuanzhenfeng_id",i)
				room:askForUseCard(use.from,"@@kezhuanzhenfeng","kezhuanzhenfeng1:"..p_choices,-1,sgs.Card_MethodPlay)
				break
			end
		end
	end
}
kezhuanzhenfengvs = sgs.CreateViewAsSkill{
	name = "kezhuanzhenfeng",
	view_as = function(self,cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="@@kezhuanzhenfeng" then
			pattern = sgs.Self:getMark("kezhuanzhenfeng_id")
			pattern = sgs.Sanguosha:getEngineCard(pattern)
			pattern = sgs.Sanguosha:cloneCard(pattern:objectName())
			pattern:setSkillName("kezhuanzhenfeng")
			return pattern
		elseif sgs.Sanguosha:getCurrentCardUseReason()~=sgs.CardUseStruct_CARD_USE_REASON_PLAY
		and pattern~="" then
			local gn = zhuanJfNames(sgs.Self)
			for _,p in sgs.list(pattern:split("+"))do
				local dc = sgs.Sanguosha:cloneCard(p)
				dc:setSkillName("kezhuanzhenfeng")
				if table.contains(gn,p)
				then return dc end
				dc:deleteLater()
			end
			return false
		end
		return kezhuanzhenfengCard:clone()
	end,
	enabled_at_response = function(self,player,pattern)
	   	if pattern=="@@kezhuanzhenfeng" then return true
		elseif sgs.Sanguosha:getCurrentCardUseReason()~=sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
		or player:getPhase()~=sgs.Player_Play then return end
		local gn = zhuanJfNames(player)
		for _,p in sgs.list(pattern:split("+"))do
			if table.contains(gn,p)
			then return true end
		end
	end,
	enabled_at_nullification = function(self,player)				
	   	return player:getPhase()==sgs.Player_Play
		and player:getMark("trickkezhuanzhenfeng-PlayClear")<1
	end,
	enabled_at_play = function(self,player)
		for _,p in sgs.list(zhuanJfNames(player))do
			local dc = zhuandummyCard(p)
			dc:setSkillName("kezhuanzhenfeng")
			if player:getMark(dc:getType().."kezhuanzhenfeng-PlayClear")<1 and dc:isAvailable(player)
			then return true end
		end
	end,
}

kezhuanzhenfeng = sgs.CreateTriggerSkill{
	name = "kezhuanzhenfeng",
	events = {sgs.PostCardEffected,sgs.PreCardUsed,sgs.CardOnEffect},
	view_as_skill = kezhuanzhenfengvs,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.PostCardEffected then
            local effect = data:toCardEffect()
			if table.contains(effect.card:getSkillNames(),"kezhuanzhenfeng")
			and effect.card:hasFlag("kezhuanzhenfengBf") then
				for _,s in sgs.list(effect.to:getVisibleSkillList())do
					if s:isAttachedLordSkill() then continue end
					if string.find(s:getDescription(),"【"..sgs.Sanguosha:translate(effect.card:objectName()).."】") then
						room:getThread():delay(500)
						room:sendCompulsoryTriggerLog(effect.from,self:objectName())
						room:damage(sgs.DamageStruct(self:objectName(),effect.from,effect.to))
						break
					end
				end
			end
		elseif event==sgs.CardOnEffect then
            local effect = data:toCardEffect()
			if table.contains(effect.card:getSkillNames(),"kezhuanzhenfeng") and effect.to==player
			then room:setCardFlag(effect.card,"kezhuanzhenfengBf") end
		else
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"kezhuanzhenfeng") then
				room:addPlayerMark(player,use.card:getType().."kezhuanzhenfeng-PlayClear")
			end
		end
		return false
	end
}
kezhuanguojia:addSkill(kezhuanzhenfeng)

kezhuan_ying = sgs.CreateBasicCard{
	name = "_kezhuan_ying",
	class_name = "Ying",
	subtype = "kespecial_card",
    can_recast = false,
	damage_card = false,
    available = function(self,player)
		return false
    end,
}
for i=0,16 do
	local card = kezhuan_ying:clone()
	card:setSuit(0)
	card:setNumber(1)
	card:setParent(extension_zhuan)
end
kezhuanYing = sgs.CreateTriggerSkill{
	name = "#kezhuanYing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if (move.to_place == sgs.Player_DiscardPile) then
				local ids = sgs.IntList()
				for _,id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):isKindOf("Ying")
					and room:getCardPlace(id)==sgs.Player_DiscardPile
					then ids:append(id) end
				end
				if ids:isEmpty() then return end
						local log = sgs.LogMessage()
						log.type = "$kezhuandestroyEquip"
				log.card_str = tostring(ids:last())
						room:sendLog(log)
				kezhuandestroyEquip(room,ids)
					end
				end
	end,
}
extension_zhuan:addSkills(kezhuanYing)


kezhuanzhangren = sgs.General(extension_zhuan, "kezhuanzhangren", "qun", 4)

function kezhuandestroyEquip(room,ids)
	local move1 = sgs.CardsMoveStruct(ids,nil,sgs.Player_PlaceTable,sgs.CardMoveReason(sgs.CardMoveReason_S_MASK_BASIC_REASON,"","destroy_equip",""))
	room:moveCardsAtomic(move1, true)
end

kezhuanfuni = sgs.CreateTriggerSkill{
	name = "kezhuanfuni",
	waked_skills = "#kezhuanfuniex",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime,sgs.RoundStart,sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.TargetSpecified) then
			local use = data:toCardUse()
			if (use.from:getMark("&kezhuanfuni-Clear") > 0)
			and (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard")) then
				local log = sgs.LogMessage()
				log.type = "$kezhuanfunixiangying"
				log.from = player
				room:sendLog(log)
				local no_respond_list = use.no_respond_list
				table.insert(no_respond_list, "_ALL_TARGETS")
				use.no_respond_list = no_respond_list
				data:setValue(use)
			end
		end
		if (event == sgs.RoundStart) then
			local ids = sgs.IntList()
			local num = math.ceil(player:aliveCount()/2)
			for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
				if sgs.Sanguosha:getEngineCard(id):isKindOf("Ying")
				and room:getCardOwner(id) == nil then
				    ids:append(id)
					if ids:length()>=num then break end
				end
			end
			if ids:length()>0 then
				room:sendCompulsoryTriggerLog(player,self)
				player:assignmentCards(ids,self:objectName(),room:getAlivePlayers(),-1,ids:length(),true)--[[
				local dummy = sgs.Sanguosha:cloneCard("slash")
				dummy:addSubcards(ids)
				player:obtainCard(dummy)
				dummy:deleteLater()
				local origin_yiji = sgs.IntList()
				for _, id in sgs.qlist(ids) do
					origin_yiji:append(id)
				end
				while room:askForYiji(player, ids, self:objectName(), true, false, true, -1, room:getAlivePlayers(),sgs.CardMoveReason(), "kezhuanfuni-distribute") do
					for _, id in sgs.qlist(origin_yiji) do
						if room:getCardOwner(id) ~= player then
							ids:removeOne(id)
						end
					end
					origin_yiji = sgs.IntList()
					for _, id in sgs.qlist(ids) do
						origin_yiji:append(id)
					end
					if not player:isAlive() then return end
				end]]
			end
		end
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if (move.to_place == sgs.Player_DiscardPile) then
				for _,id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):isKindOf("Ying") then
						room:setPlayerMark(player,"&kezhuanfuni-Clear",1)
						break
					end
				end
			end
		end		
	end,
}
kezhuanzhangren:addSkill(kezhuanfuni)

kezhuanfuniex = sgs.CreateAttackRangeSkill{
	name = "#kezhuanfuniex",
	fixed_func = function(self, target)
		if target:hasSkill("kezhuanfuni") then
			return 0			
		end
		return -1
	end
}
kezhuanzhangren:addSkill(kezhuanfuniex)

kezhuanchuanxinCard = sgs.CreateSkillCard{
	name = "kezhuanchuanxinCard" ,
	mute = true,
	filter = function(self, targets, to_select, source)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("kezhuanchuanxin")
		slash:deleteLater()
		return slash:targetFilter(targets_list, to_select, source)
	end ,
	on_use = function(self, room, source, targets)
		local targets_list = sgs.SPlayerList()
		for _, target in ipairs(targets) do
			if source:canSlash(target, nil, false) then
				targets_list:append(target)
			end
		end
		if targets_list:length() > 0 then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("kezhuanchuanxin")
			slash:addSubcard(self)
			room:useCard(sgs.CardUseStruct(slash, source, targets_list))
		end
	end
}
kezhuanchuanxinVS = sgs.CreateViewAsSkill{
	name = "kezhuanchuanxin" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("kezhuanchuanxin")
		slash:addSubcard(to_select)
		return not sgs.Self:isLocked(slash)
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return end
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("kezhuanchuanxin")
		for _, cd in ipairs(cards) do
			slash:addSubcard(cd)
		end
		return slash
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern:startsWith("@@kezhuanchuanxin")
	end
}
kezhuanchuanxin = sgs.CreateTriggerSkill{
	name = "kezhuanchuanxin" ,
	events = {sgs.EventPhaseStart,sgs.DamageCaused,sgs.HpRecover} ,
	view_as_skill = kezhuanchuanxinVS,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Finish) then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:hasSkill(self) and not p:isNude() then
						for _, pp in sgs.qlist(room:getAllPlayers()) do
							if p:canSlash(pp) then
								room:askForUseCard(p, "@@kezhuanchuanxin", "kezhuanchuanxin-ask")
								break
							end
						end
					end
				end
			end
		end
		if (event == sgs.DamageCaused) then
			local damage = data:toDamage()
			local n = damage.to:getMark("kezhuanchuanxin-Clear")
			if damage.from:hasSkill(self) and n>0 and damage.card
			and table.contains(damage.card:getSkillNames(),"kezhuanchuanxin") then
				room:sendCompulsoryTriggerLog(damage.from,self:objectName())
				local log = sgs.LogMessage()
				log.type = "$kezhuanchuanxinda"
				log.from = player
				log.arg = n
				room:sendLog(log)
				damage.damage = damage.damage + n
				data:setValue(damage)
			end
		end
		if (event == sgs.HpRecover) then
			local recover = data:toRecover()
			room:addPlayerMark(player,"kezhuanchuanxin-Clear",recover.recover)
		end
	end
}
kezhuanzhangren:addSkill(kezhuanchuanxin)




kezhuanmachao = sgs.General(extension_zhuan, "kezhuanmachao", "qun", 4)

kezhuanzhuiming = sgs.CreateTriggerSkill{
	name = "kezhuanzhuiming",
	events = {sgs.TargetSpecified,sgs.ConfirmDamage},
	frequency = sgs.Skill_NotFrequent, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.ConfirmDamage) then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("kezhuanzhuimingcard") then
				room:sendCompulsoryTriggerLog(damage.from,self)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		if (event == sgs.TargetSpecified) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and (use.to:length() == 1) then
				local target = use.to:at(0)
				local to_data = sgs.QVariant()
				to_data:setValue(target)
				if player:askForSkillInvoke(self, to_data) then
					room:broadcastSkillInvoke(self:objectName())
					local result = room:askForChoice(player, self:objectName(),"red+black",to_data)
					local log = sgs.LogMessage()
					log.type = "$kezhuanzhuiming"
					log.from = player
					log.arg = result
					room:sendLog(log)
					to_data:setValue(player)
					target:setTag("kezhuanzhuimingFrom",to_data)
					room:getThread():delay(300)
					room:askForDiscard(target,self:objectName(),999,0,true,true,"zhuiming_dis:"..result)
					room:getThread():delay(200)
					if target:getCardCount()>0 then
						local to_show = room:askForCardChosen(player, target, "he", self:objectName())
						room:showCard(target,to_show)
						if sgs.Sanguosha:getCard(to_show):getColorString()==result then
							local log = sgs.LogMessage()
							log.type = "$kezhuanzhuimingtrigger"
							log.from = player
							room:sendLog(log)
							use.m_addHistory = false
							local no_respond_list = use.no_respond_list
							for _, szm in sgs.qlist(use.to) do
								table.insert(no_respond_list, szm:objectName())
							end
							use.no_respond_list = no_respond_list
							data:setValue(use)
							room:setCardFlag(use.card,"kezhuanzhuimingcard")
						end
					end
				end
			end
		end
	end
}
kezhuanmachao:addSkill(kezhuanzhuiming)
kezhuanmachao:addSkill("mashu")




kezhuanzhangfei = sgs.General(extension_zhuan, "kezhuanzhangfei", "shu", 5)

kezhuanbaohe = sgs.CreateTriggerSkill{
	name = "kezhuanbaohe" ,
	events = {sgs.EventPhaseEnd,sgs.CardResponded,sgs.DamageCaused,sgs.CardFinished} ,
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"kezhuanbaohe") then
				use.card:removeTag("kezhuanbaoheda")
			end
			if use.whocard and table.contains(use.whocard:getSkillNames(),"kezhuanbaohe") then
				local n = use.whocard:getTag("kezhuanbaoheda"):toInt()+1
				use.whocard:setTag("kezhuanbaoheda",sgs.QVariant(n))
			end
		end
		if (event == sgs.EventPhaseEnd) then
			if (player:getPhase() == sgs.Player_Play) then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:hasSkill(self:objectName()) and (p:getCardCount() >= 2) then
						local players = sgs.SPlayerList()
						local slash = sgs.Sanguosha:cloneCard("slash")
						slash:setSkillName("_kezhuanbaohe")
						for _, pp in sgs.qlist(room:getOtherPlayers(p)) do
							if pp:inMyAttackRange(player) and p:canSlash(pp,slash,false)
							then players:append(pp) end	
						end
						p:setTag("kezhuanbaoheWho",ToData(player))
						if room:askForDiscard(p,self:objectName(),2,2,true,true,"kezhuanbaohe-ask:"..player:objectName(),".",self:objectName()) then
							p:peiyin("kezhuanbaohe")
							room:useCard(sgs.CardUseStruct(slash,p,players), true)
						end
						slash:deleteLater()  
					end
				end
			end
		end
		if (event == sgs.CardResponded) then
			local response = data:toCardResponse()
			local restocard = response.m_toCard
			if table.contains(restocard:getSkillNames(),"kezhuanbaohe") then
				local num = restocard:getTag("kezhuanbaoheda"):toInt() + 1
				restocard:setTag("kezhuanbaoheda", sgs.QVariant(num))
			end
		end
		if (event == sgs.DamageCaused) then
			local damage = data:toDamage()
			if damage.card and table.contains(damage.card:getSkillNames(),"kezhuanbaohe") then
				local n = damage.card:getTag("kezhuanbaoheda"):toInt()
				if n<1 then return false end
				local log = sgs.LogMessage()
				log.type = "$kezhuanbaoheda"
				log.from = player
				log.arg = n
				room:sendLog(log)
				damage.damage = damage.damage + n
				data:setValue(damage)
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
}
kezhuanzhangfei:addSkill(kezhuanbaohe)

kezhuanxushiCard = sgs.CreateSkillCard{
	name = "kezhuanxushiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < self:subcardsLength()
		and (to_select:objectName() ~= player:objectName()) 
	end,
	feasible = function(self,targets)
		return #targets==self:subcardsLength()
	end,
	about_to_use = function(self,room,use)
		local data = sgs.QVariant()
		data:setValue(use)
		use.from:setTag("kezhuanxushiUse",data)
		self:cardOnUse(room,use)
	end,
	on_use = function(self, room, player, targets)
		local use = player:getTag("kezhuanxushiUse"):toCardUse()
		local ids = self:getSubcards()
		local n = 0
		for i, p in sgs.qlist(use.to) do
			if p:isDead() then continue end
			room:giveCard(player,p,sgs.Sanguosha:getCard(ids:at(i)),self:getSkillName())
			n = n+1
		end
		if player:isDead() then return end
		local dummy = sgs.Sanguosha:cloneCard("slash")
		for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
			if sgs.Sanguosha:getEngineCard(id):isKindOf("Ying")
			and room:getCardOwner(id)==nil then
				dummy:addSubcard(id)
				if dummy:subcardsLength()>=n*2 then break end
			end
		end
		dummy:deleteLater()
		if dummy:subcardsLength()>0 then
			player:obtainCard(dummy)
		end
	end
}

kezhuanxushi = sgs.CreateViewAsSkill{
	name = "kezhuanxushi",
	n = 998,
	view_filter = function(self, selected, to_select)
		return #selected<sgs.Self:getAliveSiblings():length()
	end ,
	view_as = function(self, cards)
		local dc = kezhuanxushiCard:clone()
		for _, c in ipairs(cards) do
			dc:addSubcard(c)
		end
		return dc
	end ,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#kezhuanxushiCard")) and (not player:isNude())
	end, 
}
kezhuanzhangfei:addSkill(kezhuanxushi)



kezhuanxiahourong = sgs.General(extension_zhuan, "kezhuanxiahourong", "wei", 4)

kezhuanfenjianCard = sgs.CreateSkillCard{
	name = "kezhuanfenjianCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select,player)
		local duel = sgs.Sanguosha:cloneCard("duel")
		duel:setSkillName("kezhuanfenjian")
		duel:deleteLater() 
		return #targets < 1 and to_select:objectName() ~= player:objectName()
		and not player:isProhibited(to_select, duel)
	end,
	on_use = function(self, room, player, targets)
		local duel = sgs.Sanguosha:cloneCard("duel")
		duel:setSkillName("kezhuanfenjian")
		room:useCard(sgs.CardUseStruct(duel,player,targets[1]))    
		duel:deleteLater() 
	end
}

kezhuanfenjianvs = sgs.CreateViewAsSkill{
	name = "kezhuanfenjian",
	n = 0,
	view_as = function(self, cards)
		local duel = sgs.Sanguosha:cloneCard("duel")
		duel:setSkillName("kezhuanfenjian")
		return duel
	end,
	enabled_at_play = function(self, player)
		return player:getMark("&kezhuanfenjian+:+duel-Clear") < 1--(not player:hasUsed("#kezhuanfenjianCard"))
	end,
}
kezhuanfenjian = sgs.CreateTriggerSkill{
	name = "kezhuanfenjian",
	view_as_skill = kezhuanfenjianvs,
	events = {sgs.AskForPeaches,sgs.DamageInflicted,sgs.PreCardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.AskForPeaches) then
			local dying = data:toDying()
			if dying.who~=player and player:getMark("&kezhuanfenjian+:+peach-Clear") < 1 then
				local peach = sgs.Sanguosha:cloneCard("peach")
				peach:setSkillName("kezhuanfenjian")
				if player:canUse(peach,dying.who) and player:askForSkillInvoke(self, dying.who,false) then
					room:useCard(sgs.CardUseStruct(peach,player,dying.who), true)
				end
				peach:deleteLater()
			end
		end
		if (event == sgs.DamageInflicted) then
			local damage = data:toDamage()
			local n = damage.to:getMark("&kezhuanfenjian+:+peach-Clear")+damage.to:getMark("&kezhuanfenjian+:+duel-Clear")
			if n>0 then
				room:sendCompulsoryTriggerLog(damage.to,self:objectName())
				damage.damage = damage.damage + n
				data:setValue(damage)
			end
		end
		if (event == sgs.PreCardUsed) then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and table.contains(use.card:getSkillNames(),"kezhuanfenjian") then
				room:addPlayerMark(player,"&kezhuanfenjian+:+"..use.card:objectName().."-Clear")
			end
		end
	end,
}
kezhuanxiahourong:addSkill(kezhuanfenjian)



kezhuansunshuangxiang = sgs.General(extension_zhuan, "kezhuansunshuangxiang", "wu", 3,false)

kezhuanguijiCard = sgs.CreateSkillCard{
	name = "kezhuanguijiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < 1 and (to_select:getGender() == sgs.General_Male)
		and (to_select:getHandcardNum() < player:getHandcardNum())
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:setPlayerMark(target,"&kezhuanguiji+#"..player:objectName(),1)
		room:addPlayerMark(player,"usekezhuanguiji")
		player:setFlags("kezhuanguijiTarget")
		target:setFlags("kezhuanguijiTarget")
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:objectName() ~= player:objectName() and p:objectName() ~= target:objectName() then
				room:doNotify(p, sgs.CommandType.S_COMMAND_EXCHANGE_KNOWN_CARDS, json.encode({player:objectName(), target:objectName()}))
			end
		end
		local exchangeMove = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct(player:handCards(), target, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), target:objectName(), "kezhuanguiji", ""))
		local move2 = sgs.CardsMoveStruct(target:handCards(), player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, target:objectName(), player:objectName(), "kezhuanguiji", ""))
		exchangeMove:append(move1)
		exchangeMove:append(move2)
		room:moveCardsAtomic(exchangeMove, false)
		player:setFlags("-kezhuanguijiTarget")
		target:setFlags("-kezhuanguijiTarget")
	end
}

kezhuanguijiVS = sgs.CreateViewAsSkill{
	name = "kezhuanguiji",
	n = 0,
	view_as = function(self, cards)
		return kezhuanguijiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("usekezhuanguiji")<1 and (not player:hasUsed("#kezhuanguijiCard")) 
	end, 
}

kezhuanguiji = sgs.CreateTriggerSkill{
	name = "kezhuanguiji",
	events = {sgs.EventPhaseEnd,sgs.Death},
	view_as_skill = kezhuanguijiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseEnd) then
			if (player:getPhase() == sgs.Player_Play) then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if player:getMark("&kezhuanguiji+#"..p:objectName()) > 0 then
						room:setPlayerMark(player,"&kezhuanguiji+#"..p:objectName(),0)
						room:setPlayerMark(p,"usekezhuanguiji",0)
						if p:askForSkillInvoke(self, ToData(player)) then
							room:broadcastSkillInvoke(self:objectName())
							player:setFlags("kezhuanguijiTarget")
							p:setFlags("kezhuanguijiTarget")
							for _, p in sgs.qlist(room:getAlivePlayers()) do
								if p:objectName() ~= player:objectName() and p:objectName() ~= p:objectName() then
									room:doNotify(p, sgs.CommandType.S_COMMAND_EXCHANGE_KNOWN_CARDS, json.encode({player:objectName(), p:objectName()}))
								end
							end
							local exchangeMove = sgs.CardsMoveList()
							local move1 = sgs.CardsMoveStruct(player:handCards(), p, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), p:objectName(), "kezhuanguiji", ""))
							local move2 = sgs.CardsMoveStruct(p:handCards(), player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, p:objectName(), player:objectName(), "kezhuanguiji", ""))
							exchangeMove:append(move1)
							exchangeMove:append(move2)
							room:moveCardsAtomic(exchangeMove, false)
							player:setFlags("-kezhuanguijiTarget")
							p:setFlags("-kezhuanguijiTarget")
						end
					end
				end
			end
		end
		if (event == sgs.Death) then
			local death = data:toDeath()
			if death.who == player then
				for _, p in sgs.qlist(room:getAllPlayers()) do 
					if (player:getMark("&kezhuanguiji+#"..p:objectName()) > 0) then
						room:setPlayerMark(p,"usekezhuanguiji",0)
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end
}
kezhuansunshuangxiang:addSkill(kezhuanguiji)


kezhuanjiaohaoCard = sgs.CreateSkillCard{
	name = "kezhuanjiaohaoCard",
	will_throw = false,
	mute = true,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, liubei)
		if #targets ~= 0 or (to_select:objectName() == liubei:objectName())
		or (not to_select:hasSkill("kezhuanjiaohao")) then return false end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local equip = card:getRealCard():toEquipCard()
		local equip_index = equip:location()
		return to_select:getEquip(equip_index) == nil
	end,
	on_effect = function(self, effect)
		local liubei = effect.from
		liubei:getRoom():broadcastSkillInvoke("kezhuanjiaohao",math.random(3,4))
		liubei:getRoom():moveCardTo(self, liubei, effect.to, sgs.Player_PlaceEquip,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, liubei:objectName(), "kezhuanjiaohao", ""))
	end
}
kezhuanjiaohaoex = sgs.CreateOneCardViewAsSkill{
	name = "kezhuanjiaohaoex&",	
	filter_pattern = "EquipCard|.|.|hand",
	view_as = function(self, card)
		local kezhuanjiaohao_card = kezhuanjiaohaoCard:clone()
		kezhuanjiaohao_card:addSubcard(card)
		kezhuanjiaohao_card:setSkillName(self:objectName())
		return kezhuanjiaohao_card
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#kezhuanjiaohaoCard"))
	end, 
}
extension_zhuan:addSkills(kezhuanjiaohaoex)

kezhuanjiaohao = sgs.CreateTriggerSkill{
    name = "kezhuanjiaohao",
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.EventPhaseEnd) then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:hasSkill("kezhuanjiaohaoex",true) then
				    room:detachSkillFromPlayer(player, "kezhuanjiaohaoex",true)
				end
			end
		end
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Play) then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasSkill(self:objectName(),true) then
						room:attachSkillToPlayer(player, "kezhuanjiaohaoex")
						break
					end
				end
			end
			if (player:getPhase() == sgs.Player_Start) and player:hasSkill(self:objectName()) then
				local num = 0
				for i=0,4 do
					if player:hasEquipArea(i)
					and player:getEquip(i)==nil
					then num = num + 1 end
				end
				num = math.ceil(num/2)
				if num<1 then return end
				room:sendCompulsoryTriggerLog(player,self,math.random(1,2))
				local dummy = sgs.Sanguosha:cloneCard("slash")
				for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
					if sgs.Sanguosha:getEngineCard(id):isKindOf("Ying")
					and room:getCardOwner(id) == nil then
						dummy:addSubcard(id)
						if dummy:subcardsLength()>=num then break end
					end
				end
				dummy:deleteLater()
				if dummy:subcardsLength()>0 then
					player:obtainCard(dummy)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
}
kezhuansunshuangxiang:addSkill(kezhuanjiaohao)

kezhuanhuangzhong = sgs.General(extension_zhuan, "kezhuanhuangzhong", "shu", 4)

kezhuancuifengCard = sgs.CreateSkillCard{
	name = "kezhuancuifengCard" ,
	target_fixed = true ,
	mute = true,
	will_throw = false,
	about_to_use = function(self,room,use)
		--local card = sgs.Sanguosha:getCard(self:getEffectiveId())
		local choices = {}
		for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
			local tcard = sgs.Sanguosha:getEngineCard(id)
			if tcard:isDamageCard() then
				if table.contains(choices,tcard:objectName()) then continue end
				local transcard = sgs.Sanguosha:cloneCard(tcard:objectName())
				transcard:setSkillName("kezhuancuifeng")
				--transcard:addSubcard(self)
				if not transcard:isAvailable(use.from) then continue end
				if (not tcard:isKindOf("DelayedTrick")) and (tcard:isSingleTargetCard() 
				or ((use.from:aliveCount() == 2) and (tcard:isKindOf("AOE")))) then 
					table.insert(choices,tcard:objectName()) 
				end
			end
		end
		if #choices<1 then return end
		table.insert(choices,"cancel")
		local choice = room:askForChoice(use.from,"kezhuancuifeng", table.concat(choices, "+"))
		if choice=="cancel" then return end
		for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
			local c = sgs.Sanguosha:getEngineCard(id)
			if c:objectName()==choice then
				room:setPlayerMark(use.from,"kezhuancuifengName",id) 
				break 
			end
		end
		--room:setPlayerMark(use.from,"kezhuancuifengId",self:getEffectiveId())
		room:askForUseCard(use.from,"@@kezhuancuifeng","kezhuancuifeng-ask:"..choice)
	end
}
kezhuancuifengVS = sgs.CreateViewAsSkill{
	name = "kezhuancuifeng" ,
	n = 0 ,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUsePattern()=="@@kezhuancuifeng" then
			local c = sgs.Sanguosha:getEngineCard(sgs.Self:getMark("kezhuancuifengName"))
			local transcard = sgs.Sanguosha:cloneCard(c:objectName())
			--transcard:addSubcard(sgs.Self:getMark("kezhuancuifengId"))
			transcard:setSkillName("kezhuancuifeng")
			return transcard
		elseif #cards==0
		then
			return kezhuancuifengCard:clone()
		end
	end ,
	enabled_at_response = function(self,player,pattern)
		return pattern=="@@kezhuancuifeng"
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("@kezhuancuifeng") > 0)
	end
}
kezhuancuifeng = sgs.CreateTriggerSkill{
    name = "kezhuancuifeng",
	events = {sgs.CardUsed,sgs.DamageDone,sgs.CardFinished,sgs.EventPhaseChanging},
	frequency = sgs.Skill_Limited,
	limit_mark = "@kezhuancuifeng",
	view_as_skill = kezhuancuifengVS,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if (use.from:objectName() == player:objectName()) then
				if table.contains(use.card:getSkillNames(),"kezhuancuifeng") and player:hasSkill(self:objectName()) then
					room:removePlayerMark(player,"@kezhuancuifeng")
					room:setPlayerMark(player,"usingcuifeng",1)
				end
			end
		end
		if (event == sgs.DamageDone) then
			local damage = data:toDamage()
			if damage.card and table.contains(damage.card:getSkillNames(),"kezhuancuifeng") then
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if (p:getMark("usingcuifeng") > 0) then
				        room:addPlayerMark(p,"cuifengda",damage.damage)
						break
					end
				end
			end
		end
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if (use.from:objectName() == player:objectName()) then
				if (table.contains(use.card:getSkillNames(),"kezhuancuifeng")) then
					room:setPlayerMark(player,"usingcuifeng",0)
					if (player:getMark("cuifengda") ~= 1) and player:hasSkill(self:objectName()) then
						--room:addPlayerMark(player,"@kezhuancuifeng")
						room:setPlayerMark(player,"&kezhuancuifengchongzhi-Clear",1)
					end
					room:setPlayerMark(player,"cuifengda",0)
				end
			end
		end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) and (player:getMark("&kezhuancuifengchongzhi-Clear") > 0) then
				room:addPlayerMark(player,"@kezhuancuifeng")
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kezhuanhuangzhong:addSkill(kezhuancuifeng)


kezhuandengnanCard = sgs.CreateSkillCard{
	name = "kezhuandengnanCard" ,
	target_fixed = true ,
	mute = true,
	will_throw = false,
	about_to_use = function(self,room,use)
		local choices = {}
		for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
			local tcard = sgs.Sanguosha:getEngineCard(id)
			if not tcard:isDamageCard() and tcard:isNDTrick()
			then
				if table.contains(choices,tcard:objectName())
				then continue end
				local transcard = sgs.Sanguosha:cloneCard(tcard:objectName())
				transcard:setSkillName("kezhuandengnan")
				if not transcard:isAvailable(use.from) then continue end
				table.insert(choices,tcard:objectName()) 
			end
		end
		if #choices<1 then return end
		table.insert(choices,"cancel")
		local choice = room:askForChoice(use.from,"kezhuandengnan", table.concat(choices, "+"))
		if choice=="cancel" then return end
		for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
			local c = sgs.Sanguosha:getEngineCard(id)
			if c:objectName()==choice then
				room:setPlayerMark(use.from,"kezhuandengnanName",id) 
				break 
			end
		end
		room:askForUseCard(use.from,"@@kezhuandengnan","kezhuandengnan-ask:"..choice)
	end
}
kezhuandengnanVS = sgs.CreateViewAsSkill{
	name = "kezhuandengnan" ,
	n = 0 ,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUsePattern()=="@@kezhuandengnan"
		then
			local c = sgs.Sanguosha:getEngineCard(sgs.Self:getMark("kezhuandengnanName"))
			local transcard = sgs.Sanguosha:cloneCard(c:objectName())
			transcard:setSkillName("kezhuandengnan")
			return transcard
		elseif #cards==0
		then
			return kezhuandengnanCard:clone()
		end
	end ,
	enabled_at_response = function(self,player,pattern)
		return pattern=="@@kezhuandengnan"
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("@kezhuandengnan") > 0)
	end
}
kezhuandengnan = sgs.CreateTriggerSkill{
    name = "kezhuandengnan",
	events = {sgs.TargetSpecified,sgs.DamageDone,sgs.CardUsed,sgs.EventPhaseChanging},
	frequency = sgs.Skill_Limited,
	limit_mark = "@kezhuandengnan",
	view_as_skill = kezhuandengnanVS,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"kezhuandengnan") and player:hasSkill(self:objectName()) then
				room:removePlayerMark(player,"@kezhuandengnan")
			end
		end
		if (event == sgs.TargetSpecified) then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"kezhuandengnan") and use.from:hasSkill(self:objectName()) then
				room:setPlayerMark(use.from,"usingdengnan-Clear",1)
				for _,p in sgs.qlist(use.to) do
					if (p:getMark("&kezhuandengnanover-Clear") == 0) then
						if (p:getMark("&kezhuandengnanda-Clear") > 0) then
							room:setPlayerMark(p,"&kezhuandengnanda-Clear",0)
							room:setPlayerMark(p,"&kezhuandengnanover-Clear",1)
						else
							room:setPlayerMark(p,"&kezhuandengnantar-Clear",1)
						end
					end
				end
			end
		end
		if (event == sgs.DamageDone) then
			local damage = data:toDamage()
			local hz = room:findPlayerBySkillName(self:objectName())
			if hz and (hz:getPhase() ~= sgs.Player_NotActive) then
				if (damage.to:getMark("&kezhuandengnanover-Clear") == 0) then
					if (damage.to:getMark("&kezhuandengnantar-Clear") > 0) then
						room:setPlayerMark(damage.to,"&kezhuandengnantar-Clear",0)
						room:setPlayerMark(damage.to,"&kezhuandengnanover-Clear",1)
					else
						room:setPlayerMark(damage.to,"&kezhuandengnanda-Clear",1)
					end
				end
			end
		end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				if (player:getMark("usingdengnan-Clear") > 0) then
					for _,p in sgs.qlist(room:getAllPlayers()) do
						if (p:getMark("&kezhuandengnantar-Clear") > 0) and (p:getMark("&kezhuandengnanda-Clear") == 0) then
							return
						end
					end
					room:addPlayerMark(player,"@kezhuandengnan")
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kezhuanhuangzhong:addSkill(kezhuandengnan)


kezhuanpangtong = sgs.General(extension_zhuan, "kezhuanpangtong", "qun", 3)


kezhuanmanjuanVsCard = sgs.CreateSkillCard{
	name = "kezhuanmanjuanVsCard",
	filter = function(self,targets,to_select,from)
		local pattern = self:getUserString()
		if pattern=="@@kezhuanmanjuan" then
			local c = sgs.Sanguosha:getCard(from:getMark("kezhuanmanjuan_id"))
			if c:targetFixed() then return false end
			local plist = sgs.PlayerList()
			for i = 1,#targets do plist:append(targets[i]) end
			return c:targetFilter(plist,to_select,from)
		else
			if sgs.Sanguosha:getCurrentCardUseReason()~=sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
			for i=0,sgs.Sanguosha:getCardCount()-1 do
				local c = sgs.Sanguosha:getEngineCard(i)
				if from:getMark(i.."manjuanPile-Clear")>0
				and from:getMark(c:getNumber().."manjuanNumber-Clear")<1
				and not from:isLocked(c) then
					local pn = c:isKindOf("Slash") and "slash" or c:objectName()
					if string.find(pattern,pn) then
						if c:targetFixed() then return false end
						local plist = sgs.PlayerList()
						for i = 1,#targets do plist:append(targets[i]) end
						return c:targetFilter(plist,to_select,from)
					end
				end
			end
		end
	end,
	feasible = function(self,targets,from)
		local pattern = self:getUserString()
		if pattern=="@@kezhuanmanjuan" then
			local c = sgs.Sanguosha:getCard(from:getMark("kezhuanmanjuan_id"))
			if c:targetFixed() then return true end
			local plist = sgs.PlayerList()
			for i = 1,#targets do plist:append(targets[i]) end
			return c:targetsFeasible(plist,from)
		else
			if sgs.Sanguosha:getCurrentCardUseReason()~=sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return true end
			for i=0,sgs.Sanguosha:getCardCount()-1 do
				local c = sgs.Sanguosha:getEngineCard(i)
				if from:getMark(i.."manjuanPile-Clear")>0
				and from:getMark(c:getNumber().."manjuanNumber-Clear")<1
				and not from:isLocked(c) then
					local pn = c:isKindOf("Slash") and "slash" or c:objectName()
					if string.find(pattern,pn) then
						if c:targetFixed() then return true end
						local plist = sgs.PlayerList()
						for i = 1,#targets do plist:append(targets[i]) end
						return c:targetsFeasible(plist,from)
					end
				end
			end
		end
	end,
	on_validate = function(self,use)
		local room = use.from:getRoom()
		local pattern = self:getUserString()
		if pattern=="@@kezhuanmanjuan" then
			local c = sgs.Sanguosha:getCard(use.from:getMark("kezhuanmanjuan_id"))
			room:broadcastSkillInvoke("kezhuanmanjuan")--播放配音
			room:addPlayerMark(use.from,c:getNumber().."manjuanNumber-Clear")
			return c
		else
			local ids = sgs.IntList()
			for i=0,sgs.Sanguosha:getCardCount()-1 do
				local c = sgs.Sanguosha:getEngineCard(i)
				if use.from:getMark(i.."manjuanPile-Clear")>0
				and use.from:getMark(c:getNumber().."manjuanNumber-Clear")<1
				and not use.from:isCardLimited(c,sgs.Card_MethodUse) then
					local pn = c:isKindOf("Slash") and "slash" or c:objectName()
					if string.find(pattern,pn) and (use.from:canUse(c,use.to) or c:targetFixed())
					then ids:append(i) end
				end
			end
			room:fillAG(ids,use.from)
			local c = room:askForAG(use.from,ids,ids:length()<2,"kezhuanmanjuan","kezhuanmanjuan0")
			room:clearAG(use.from)
			c = c<0 and ids:at(0) or c
			c = sgs.Sanguosha:getCard(c)
			room:broadcastSkillInvoke("kezhuanmanjuan")--播放配音
			room:addPlayerMark(use.from,c:getNumber().."manjuanNumber-Clear")
			return c
		end
	end,
	on_validate_in_response = function(self,from)
		local room = from:getRoom()
		local pattern = self:getUserString()
		if pattern=="@@kezhuanmanjuan" then
			local c = sgs.Sanguosha:getCard(from:getMark("kezhuanmanjuan_id"))
			room:broadcastSkillInvoke("kezhuanmanjuan")--播放配音
			room:addPlayerMark(from,c:getNumber().."manjuanNumber-Clear")
			return c
		else
			local ids = sgs.IntList()
			local hm = sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
			for i=0,sgs.Sanguosha:getCardCount()-1 do
				local c = sgs.Sanguosha:getCard(i)
				if from:getMark(i.."manjuanPile-Clear")>0
				and from:getMark(c:getNumber().."manjuanNumber-Clear")<1
				and not from:isCardLimited(c,hm and sgs.Card_MethodUse or sgs.Card_MethodResponse) then
					local pn = c:isKindOf("Slash") and "slash" or c:objectName()
					if string.find(pattern,pn) then ids:append(i) end
				end
			end
			room:fillAG(ids,from)
			local c = room:askForAG(from,ids,ids:length()<2,"kezhuanmanjuan","kezhuanmanjuan1")
			room:clearAG(from)
			c = c<0 and ids:at(0) or c
			c = sgs.Sanguosha:getCard(c)
			room:broadcastSkillInvoke("kezhuanmanjuan")--播放配音
			room:addPlayerMark(from,c:getNumber().."manjuanNumber-Clear")
			return c
		end
	end
}

kezhuanmanjuanCard = sgs.CreateSkillCard{
	name = "kezhuanmanjuanCard",
	target_fixed = true,
	about_to_use = function(self,room,use)
		local ids = sgs.IntList()
		for i=0,sgs.Sanguosha:getCardCount()-1 do
			local c = sgs.Sanguosha:getCard(i)
			if use.from:getMark(i.."manjuanPile-Clear")>0
			and use.from:getMark(c:getNumber().."manjuanNumber-Clear")<1
			and c:isAvailable(use.from) then ids:append(i) end
		end
		room:fillAG(ids,use.from)
		local id = room:askForAG(use.from,ids,ids:length()<2,"kezhuanmanjuan","kezhuanmanjuan0")
		id = id<0 and ids:at(0) or id
		room:clearAG(use.from)
		room:setPlayerMark(use.from,"kezhuanmanjuan_id",id)
		room:askForUseCard(use.from,"@@kezhuanmanjuan","kezhuanmanjuan2:"..sgs.Sanguosha:getCard(id):objectName())
	end
}
kezhuanmanjuanvs = sgs.CreateViewAsSkill{
	name = "kezhuanmanjuan",
	view_as = function(self,cards)
		if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_PLAY
		then return kezhuanmanjuanCard:clone()
		else
			local c = kezhuanmanjuanVsCard:clone()
			c:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
			return c
		end
	end,
	enabled_at_response = function(self,player,pattern)
	   	if pattern=="@@kezhuanmanjuan" then return true
		elseif player:getHandcardNum()>0 then return false end
		local hm = sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
		hm = hm and sgs.Card_MethodUse or sgs.Card_MethodResponse
		for i=0,sgs.Sanguosha:getCardCount()-1 do
			local c = sgs.Sanguosha:getEngineCard(i)
			if player:getMark(i.."manjuanPile-Clear")>0
			and player:getMark(c:getNumber().."manjuanNumber-Clear")<1
			and not player:isCardLimited(c,hm) then
				c = c:isKindOf("Slash") and "slash" or c:objectName()
				if string.find(pattern,c) then return true end
			end
		end
	end,
	enabled_at_nullification = function(self,player)				
		if player:getHandcardNum()>0 then return end
		for i=0,sgs.Sanguosha:getCardCount()-1 do
			local c = sgs.Sanguosha:getEngineCard(i)
			if player:getMark(i.."manjuanPile-Clear")>0
			and player:getMark(c:getNumber().."manjuanNumber-Clear")<1
			and not player:isLocked(c) and c:isKindOf("Nullification")
			then return true end
		end
	end,
	enabled_at_play = function(self,player)
		if player:getHandcardNum()>0 then return end
		for i=0,sgs.Sanguosha:getCardCount()-1 do
			local c = sgs.Sanguosha:getEngineCard(i)
			if player:getMark(i.."manjuanPile-Clear")>0
			and player:getMark(c:getNumber().."manjuanNumber-Clear")<1
			and c:isAvailable(player) then return true end
		end
	end
}
kezhuanmanjuan = sgs.CreateTriggerSkill{
	name = "kezhuanmanjuan",
	events = {sgs.CardsMoveOneTime,sgs.SwappedPile},
	view_as_skill = kezhuanmanjuanvs,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.CardsMoveOneTime then
	     	local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_DiscardPile then
				for _,id in sgs.list(move.card_ids)do
					if room:getCardPlace(id)~=sgs.Player_DiscardPile then continue end
					room:addPlayerMark(player,id.."manjuanPile-Clear")
				end
			elseif move.from_places:contains(sgs.Player_DiscardPile) then
				for _,id in sgs.list(move.card_ids)do
					room:setPlayerMark(player,id.."manjuanPile-Clear",0)
				end
			end
		elseif event==sgs.SwappedPile then
			for _,m in sgs.list(player:getMarkNames()) do
				if m:endsWith("manjuanPile-Clear") then
					room:setPlayerMark(player,m,0)
				end
			end
		end
		return false
	end
}

kezhuanpangtong:addSkill(kezhuanmanjuan)

kezhuanyangmingCard = sgs.CreateSkillCard{
	name = "kezhuanyangmingCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and (to_select:objectName() ~= player:objectName())
		and (player:canPindian(to_select, true))
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		while player:isAlive() and target:isAlive() and player:canPindian(target) do
			if player:pindian(target, self:getSkillName()) then
				if player:isAlive() and target:isAlive() and player:canPindian(target)
				and player:askForSkillInvoke(self:getSkillName(),ToData("kezhuanyangming-jixu:"..target:objectName()))
				then else break end
			else
				if target:isAlive() then
					target:drawCards(target:getMark("&kezhuanyangminglose-PlayClear"),self:getSkillName())
				end
				if player:isAlive() then
					room:recover(player, sgs.RecoverStruct(self:getSkillName(),player))
				end
				break
			end
		end
	end
}

kezhuanyangmingVS = sgs.CreateViewAsSkill{
	name = "kezhuanyangming",
	n = 0,
	view_as = function(self, cards)
		return kezhuanyangmingCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not (player:hasUsed("#kezhuanyangmingCard")) 
	end, 
}

kezhuanyangming = sgs.CreateTriggerSkill{
	name = "kezhuanyangming" ,
	view_as_skill = kezhuanyangmingVS,
	events = {sgs.Pindian} ,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Pindian) then
			local cp = room:getCurrent()
			if cp and cp:hasSkill(self,true) and cp:getPhase()==sgs.Player_Play then
				local pindian = data:toPindian()
				--不管是因为什么拼点，给输的人标记
				if pindian.success then
					room:addPlayerMark(pindian.to,"&kezhuanyangminglose-PlayClear")
				else
					room:addPlayerMark(pindian.from,"&kezhuanyangminglose-PlayClear")
				end
			end
		end
	end
}
kezhuanpangtong:addSkill(kezhuanyangming)


kezhuanlougui = sgs.General(extension_zhuan, "kezhuanlougui", "wei", 3,true)

kezhuanshacheng = sgs.CreateTriggerSkill{
    name = "kezhuanshacheng",
	events = {sgs.GameStart,sgs.CardFinished,sgs.CardsMoveOneTime},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
			and move.from:objectName() == player:objectName()
			and not(move.to and (move.to:objectName() == player:objectName() 
			and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then
				room:addPlayerMark(player,"kezhuanshachenglose-Clear",move.card_ids:length())
			end
		end
		if (event == sgs.GameStart) and player:hasSkill(self:objectName()) then
			room:sendCompulsoryTriggerLog(player,self)
			local sc_card = room:getNCards(2)
			player:addToPile("kezhuanshacheng", sc_card)
		end
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				for _,lg in sgs.qlist(room:getAllPlayers()) do
					if lg:hasSkill(self:objectName()) then
						local ids = lg:getPile("kezhuanshacheng")
						if ids:isEmpty() then continue end
						local tos = sgs.SPlayerList()
						for _,p in sgs.qlist(use.to) do
							if p:isAlive() then
								tos:append(p)
							end
						end
						local fri = room:askForPlayerChosen(lg, tos, self:objectName(), "kezhuanshacheng-ask",true,true)
						if fri then
							room:broadcastSkillInvoke(self:objectName())
							room:fillAG(ids, lg)
							local id = room:askForAG(lg, lg:getPile("kezhuanshacheng"), false, self:objectName())
							room:clearAG(lg)
							room:throwCard(id, lg)
							local num = fri:getMark("kezhuanshachenglose-Clear")
							fri:drawCards(math.min(5,num),self:objectName())
						end	
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
}
kezhuanlougui:addSkill(kezhuanshacheng)

kezhuanninghan = sgs.CreateTriggerSkill{
    name = "kezhuanninghan",
	events = {sgs.Damaged,sgs.GameStart,sgs.Death,sgs.EventAcquireSkill,sgs.EventLoseSkill},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.Damaged) then
			local damage = data:toDamage()
			if damage.card and (damage.nature == sgs.DamageStruct_Ice) then
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if room:getCardOwner(damage.card:getEffectiveId())==nil
					and p:hasSkill(self:objectName()) then
						if p:askForSkillInvoke(self,ToData("kezhuanninghan-ask:"..damage.card:objectName())) then
							room:broadcastSkillInvoke(self:objectName())
							p:addToPile("kezhuanshacheng", damage.card)
							break	  
						end
					end
				end
			end
		end
		if (event == sgs.GameStart or event == sgs.EventAcquireSkill) and player:hasSkill(self,true) then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if not p:hasSkill("kezhuanninghanbuff") then
					room:attachSkillToPlayer(p, "kezhuanninghanbuff")
					room:filterCards(p, p:getHandcards(), false)
				end
			end
		end
		if (event == sgs.Death) then
			local death = data:toDeath()
			if death.who == player and player:hasSkill(self,true) then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do 
					if p:hasSkill(self,true) then
						return false
					end
				end
				for _,p in sgs.qlist(room:getAllPlayers()) do
					room:detachSkillFromPlayer(p, "kezhuanninghanbuff",true,true,false)
				end
			end
		end
		if (event == sgs.EventLoseSkill) and data:toString() == "kezhuanninghan" then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do 
				if p:hasSkill(self,true) then
					return false
				end
			end
			for _,p in sgs.qlist(room:getAllPlayers()) do
				room:detachSkillFromPlayer(p, "kezhuanninghanbuff",true,true,false)
				local cs = sgs.CardList()
				for _,h in sgs.qlist(p:getHandcards())do
					if table.contains(h:getSkillNames(), "kezhuanninghan")
					then cs:append(h) end
				end
				room:filterCards(p, cs, true)
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kezhuanlougui:addSkill(kezhuanninghan)

kezhuanninghanbuff = sgs.CreateFilterSkill{
	name = "kezhuanninghanbuff&",
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		return room:getCardPlace(to_select:getEffectiveId()) == sgs.Player_PlaceHand
		and to_select:getSuit() == sgs.Card_Club and to_select:isKindOf("Slash")
	end,
	view_as = function(self, originalCard)
		local slash = sgs.Sanguosha:cloneCard("ice_slash", originalCard:getSuit(), originalCard:getNumber())
		slash:setSkillName("kezhuanninghan")
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(slash)
		return card
	end
}
extension_zhuan:addSkills(kezhuanninghanbuff)


kezhuanhansui = sgs.General(extension_zhuan, "kezhuanhansui$", "qun", 4,true)

kezhuanniluanCard = sgs.CreateSkillCard{
	name = "kezhuanniluanCard",
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return self:subcardsLength()~=to_select:getMark("kezhuanniluan"..player:objectName())
	end,
	on_use = function(self, room, source, targets)
		for _, p in ipairs(targets)do
			if (self:subcardsLength() == 0) then
				p:drawCards(2,self:getSkillName())
			else
				room:damage(sgs.DamageStruct(self:getSkillName(), source, p))
			end
		end
	end,
}

kezhuanniluanVS = sgs.CreateViewAsSkill{
	name = "kezhuanniluan",
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isJilei(to_select)
	end ,
	view_as = function(self, cards)
		local dc = kezhuanniluanCard:clone()
		for _, c in ipairs(cards) do
			dc:addSubcard(c)
		end
		return dc
	end ,
	enabled_at_response = function(self,player,pattern)
		return pattern=="@@kezhuanniluan"
	end,
	enabled_at_play = function(self, player)
		return false
	end
}

kezhuanniluan = sgs.CreateTriggerSkill{
    name = "kezhuanniluan",
	events = {sgs.EventPhaseStart,sgs.Damage,sgs.Damaged},
	view_as_skill = kezhuanniluanVS,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.Damaged) then
			local damage = data:toDamage()
			room:setPlayerMark(player,"kezhuanniluan"..damage.from:objectName(),1)
		end
		if (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Start) then
			room:askForUseCard(player,"@@kezhuanniluan","kezhuanniluan-ask")
		end
	end,
}
kezhuanhansui:addSkill(kezhuanniluan)

kezhuanhuchou = sgs.CreateTriggerSkill{
    name = "kezhuanhuchou",
	events = {sgs.CardUsed,sgs.ConfirmDamage},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.ConfirmDamage) then
			local damage = data:toDamage()
			if damage.from:hasSkill(self) and damage.to:getMark("&kezhuanhuchou+#"..damage.from:objectName())>0 then
				room:sendCompulsoryTriggerLog(damage.from,self)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:isDamageCard() then
				for _, p in sgs.qlist(use.to) do 
					if p:hasSkill(self:objectName()) then
						for _, ap in sgs.qlist(room:getAllPlayers()) do 
							room:setPlayerMark(ap,"&kezhuanhuchou+#"..p:objectName(),0)
						end
						room:setPlayerMark(use.from,"&kezhuanhuchou+#"..p:objectName(),1)
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end
}
kezhuanhansui:addSkill(kezhuanhuchou)

kezhuanjiemeng = sgs.CreateDistanceSkill{
	name = "kezhuanjiemeng$",
	correct_func = function(self, from)
		if from:getKingdom() ~= "qun"
		then return 0 end
		local yes,num = false,0
		local tos = from:getAliveSiblings()
		tos:append(from)
		for _, p in sgs.qlist(tos) do 
			if p:getKingdom() == "qun" then num = num-1 end
			if yes==false and p:hasLordSkill(self:objectName())
			then yes = true end
		end
		return yes and num or 0
	end,
}
kezhuanhansui:addSkill(kezhuanjiemeng)



kezhuanzhangchu = sgs.General(extension_zhuan, "kezhuanzhangchu", "qun", 3,false)

kezhuanhuozhongCard = sgs.CreateSkillCard{
	name = "kezhuanhuozhongCard",
	will_throw = false,
	--mute = true,
	filter = function(self, targets, to_select, source)
		local shortage = sgs.Sanguosha:cloneCard("supply_shortage")
		shortage:setSkillName(self:getSkillName()) 
		shortage:addSubcard(self)
		shortage:deleteLater()
		return not to_select:containsTrick("supply_shortage")
		and to_select:objectName()==source:objectName() and to_select:hasJudgeArea()
		and not source:isProhibited(to_select, shortage)
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local supplyshortage = sgs.Sanguosha:cloneCard("supply_shortage")
		supplyshortage:setSkillName(self:getSkillName()) 
		supplyshortage:addSubcard(self)
		local tos = sgs.SPlayerList()
		tos:append(target)
        room:moveCardTo(supplyshortage, nil, sgs.Player_PlaceTable, true)
		supplyshortage:use(room,source,tos)
		supplyshortage:deleteLater()
		tos = room:findPlayersBySkillName(self:getSkillName())
		local zc = room:askForPlayerChosen(source, tos, self:getSkillName(), "kezhuanhuozhong-choose", false, false)
		if zc then
			zc:drawCards(2,self:getSkillName())
		end
	end,
}

kezhuanhuozhongVS = sgs.CreateViewAsSkill{
	name = "kezhuanhuozhong",
	n = 1,
	view_filter = function(self, selected, to_select)
		return (to_select:isBlack() and not to_select:isKindOf("TrickCard"))
	end ,
	view_as = function(self, cards)
        if #cards == 1 then
			local card = kezhuanhuozhongCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		local tos = player:getAliveSiblings()
		tos:append(player)
		for _, p in sgs.qlist(tos) do
			if p:hasSkill("kezhuanhuozhong") then
				return not player:hasUsed("#kezhuanhuozhongCard")
			end
		end
	end, 
}
kezhuanhuozhongex = sgs.CreateViewAsSkill{
	name = "kezhuanhuozhongex&",
	n = 1,
	view_filter = function(self, selected, to_select)
		return (to_select:isBlack() and not to_select:isKindOf("TrickCard"))
	end ,
	view_as = function(self, cards)
        if #cards == 1 then
			local card = kezhuanhuozhongCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		local tos = player:getAliveSiblings()
		tos:append(player)
		for _, p in sgs.qlist(tos) do
			if p:hasSkill("kezhuanhuozhong") then
				return not player:hasUsed("#kezhuanhuozhongCard")
			end
		end
	end, 
}
extension_zhuan:addSkills(kezhuanhuozhongex)

kezhuanhuozhong = sgs.CreateTriggerSkill{
    name = "kezhuanhuozhong",
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd},
	view_as_skill = kezhuanhuozhongVS,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.EventPhaseEnd) then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasSkill("kezhuanhuozhongex",true) then
				    room:detachSkillFromPlayer(player, "kezhuanhuozhongex",true,true,false)
				end
			end
		end
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Play) then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasSkill(self:objectName(),true) then
						room:attachSkillToPlayer(player, "kezhuanhuozhongex")
						break
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kezhuanzhangchu:addSkill(kezhuanhuozhong)


kezhuanrihui = sgs.CreateTriggerSkill{
    name = "kezhuanrihui",
	events = {sgs.Damage},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then 
				local use = room:getUseStruct(damage.card)
				if use.to:contains(damage.to)
				and player:askForSkillInvoke(self,ToData("kezhuanrihui")) then
					room:broadcastSkillInvoke(self:objectName())
					for _, p in sgs.qlist(room:getOtherPlayers(player))do
						if p:getJudgingArea():length()>0 then
							p:drawCards(1,self:objectName())
						end
					end
				end
			end
		end
	end,
}
kezhuanzhangchu:addSkill(kezhuanrihui)


kezhuanxiahouen = sgs.General(extension_zhuan, "kezhuanxiahouen", "wei", 4)

kezhuanchixueqingfengskill = sgs.CreateTriggerSkill{
	name = "_kezhuan_chixueqingfeng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirming, sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.TargetConfirming then
			if use.card:isKindOf("Slash") and use.from:hasWeapon(self:objectName()) then
				room:sendCompulsoryTriggerLog(use.from, self:objectName())
				room:setEmotion(use.from, "weapon/qinggang_sword")
				for _, p in sgs.qlist(use.to) do
					room:setPlayerCardLimitation(p, "use,response", ".|.|.|hand", false)
					p:addQinggangTag(use.card)
					p:setFlags("kezhuan_cxqfto")
				end
				local log = sgs.LogMessage()
				log.type = "#IgnoreArmor"
				log.from = player
				log.card_str = use.card:toString()
				room:sendLog(log)
				data:setValue(use)
			end
		elseif event == sgs.CardFinished and use.card:isKindOf("Slash") then
			for _, p in sgs.qlist(room:getAllPlayers())do
				if p:hasFlag("kezhuan_cxqfto") then
					p:setFlags("-kezhuan_cxqfto")
					room:removePlayerCardLimitation(p, "use,response", ".|.|.|hand")
					p:removeQinggangTag(use.card)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
extension_zhuan:addSkills(kezhuanchixueqingfengskill)
KezhuanChixueqingfeng = sgs.CreateWeapon{
	name = "_kezhuan_chixueqingfeng",
	class_name = "Chixueqingfeng",
	range = 2,
	on_install = function(self, player)
		local room = player:getRoom()
		room:acquireSkill(player,kezhuanchixueqingfengskill,true,true,false)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player,"_kezhuan_chixueqingfeng",true,true)
	end,
}

--KezhuanChixueqingfeng:clone(sgs.Card_Spade, 6):setParent(extension_zhuan)

kezhuanhujian = sgs.CreateTriggerSkill{
    name = "kezhuanhujian",
	waked_skills = "_kezhuan_chixueqingfeng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging,sgs.GameStart,sgs.CardResponded,sgs.CardUsed},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.GameStart) and player:hasSkill(self:objectName()) then
			for id=0,sgs.Sanguosha:getCardCount()-1 do
				if sgs.Sanguosha:getEngineCard(id):isKindOf("GodSword")
				and not room:getCardOwner(id) then
					room:sendCompulsoryTriggerLog(player,self,1)
					player:obtainCard(sgs.Sanguosha:getCard(id))
					break
				end
			end
		end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if (p:getMark("&kezhuanhujian-Clear") > 0) then
						for _,id in sgs.qlist(room:getDiscardPile()) do
							if sgs.Sanguosha:getEngineCard(id):isKindOf("GodSword") then
								if p:askForSkillInvoke(self:objectName(),ToData("kezhuanhujian-ask:"..p:objectName())) then
									room:broadcastSkillInvoke(self:objectName(),2)
									p:obtainCard(sgs.Sanguosha:getCard(id))
								end
								break
							end
						end
					end
				end
			end
		end
		if (event == sgs.CardResponded) then
			local response = data:toCardResponse()
			if response.m_card:getTypeId()<1 or not room:findPlayerBySkillName(self:objectName()) then return end
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerMark(p,"&kezhuanhujian-Clear",0)
			end
			room:setPlayerMark(player,"&kezhuanhujian-Clear",1)
		end
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:getTypeId()<1 or not room:findPlayerBySkillName(self:objectName()) then return end
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerMark(p,"&kezhuanhujian-Clear",0)
			end
			room:setPlayerMark(player,"&kezhuanhujian-Clear",1)
		end
	end,
}
kezhuanxiahouen:addSkill(kezhuanhujian)

kezhuanshiliVS = sgs.CreateOneCardViewAsSkill{
	name = "kezhuanshili",
	response_or_use = true,
	view_filter = function(self, card)
		return (not card:isEquipped()) and card:isKindOf("EquipCard")
	end,
	view_as = function(self, card)
		local duel = sgs.Sanguosha:cloneCard("duel")
		duel:addSubcard(card)
		duel:setSkillName("kezhuanshili")
		return duel
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("usekezhuanshili-PlayClear") == 0)
	end, 
}

kezhuanshili = sgs.CreateTriggerSkill{
    name = "kezhuanshili",
	events = {sgs.CardUsed},
	view_as_skill = kezhuanshiliVS,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"kezhuanshili") then
				if (player:objectName() == use.from:objectName()) then
				    room:setPlayerMark(player,"usekezhuanshili-PlayClear",1)
				end
			end
		end
	end,
}
kezhuanxiahouen:addSkill(kezhuanshili)




kezhuanfanjiangzhangda = sgs.General(extension_zhuan, "kezhuanfanjiangzhangda", "wu", 5)

kezhuanfushan = sgs.CreateTriggerSkill{
    name = "kezhuanfushan",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Play) then
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					local card = room:askForExchange(p, self:objectName(), 1, 0, true, "kezhuanfushangive:"..player:objectName(),true)
					if card then
						room:addPlayerMark(p,"&kezhuanfushan-PlayClear")
						room:addPlayerMark(player,"kezhuanfushannum-PlayClear")
						room:obtainCard(player, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), player:objectName(), self:objectName(), ""), false)
						room:addSlashCishu(player,1, true)
					end
				end	
			end
		end
		if (event == sgs.EventPhaseEnd) then
			if (player:getPhase() == sgs.Player_Play) then
				local willlose = 0
				if sgs.Slash_IsAvailable(player) then
					willlose = willlose + 1
				end
				local num = 0
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("&kezhuanfushan-PlayClear") > 0 then
						num = num + 1
					end
				end
				if (num == player:getMark("kezhuanfushannum-PlayClear")) and (num ~= 0) then
					willlose = willlose + 1
				end	
				if (willlose == 2) then
					room:sendCompulsoryTriggerLog(player,self)
					room:loseHp(player,2,true, player, self:objectName())
				else
					local cha = player:getMaxHp() - player:getHandcardNum() 
					if (cha > 0) then
						room:sendCompulsoryTriggerLog(player,self)
						player:drawCards(cha,self:objectName())
					end
				end
			end
		end
	end,
}
kezhuanfanjiangzhangda:addSkill(kezhuanfushan)

















kezhuancaimaozhangyun = sgs.General(extension_zhuan, "kezhuancaimaozhangyun", "wei", 4,true,true)
kezhuancaimaozhangyun:addSkill("lianzhou")
kezhuancaimaozhangyun:addSkill("jinglan")

kezhuanjianggan = sgs.General(extension_zhuan, "kezhuanjianggan", "wei", 3,true,true)
kezhuanjianggan:addSkill("weicheng")
kezhuanjianggan:addSkill("daoshu")

kezhuanhuangchengyan = sgs.General(extension_zhuan, "kezhuanhuangchengyan", "qun", 3,true,true)
kezhuanhuangchengyan:addSkill("guanxu")
kezhuanhuangchengyan:addSkill("yashi")

kezhuankanze = sgs.General(extension_zhuan, "kezhuankanze", "wu", 3,true,true)
kezhuankanze:addSkill("xiashu")
kezhuankanze:addSkill("tenyearkuanshi")



sgs.LoadTranslationTable{
    ["kearjsrgszhuan"] = "江山如故·转",

	["Ying"] = "影",
	["_kezhuan_ying"] = "影",
	["kespecial_card"] = "特殊牌",

	[":_kezhuan_ying"] = "基本牌<br /><b>时机</b>：无<br /><b>效果</b>：无",

	["_kezhuan_chixueqingfeng"] = "赤血青锋", 
	[":_kezhuan_chixueqingfeng"] = "装备牌/武器<br /><b>攻击范围</b>：２\
	<b>武器技能</b>：锁定技，你使用的【杀】结算结束前，目标角色不能使用或打出手牌，且此【杀】无视其防具。",

	--郭嘉
	["kezhuanguojia"] = "郭嘉[转]", 
	["&kezhuanguojia"] = "郭嘉",
	["#kezhuanguojia"] = "赤壁的先知",
	["designer:kezhuanguojia"] = "官方",
	["cv:kezhuanguojia"] = "官方",
	["illustrator:kezhuanguojia"] = "Kayak&DEEMO",
	["information:kezhuanguojia"] = "ᅟᅠᅟᅠ<i>初平元年二月，郭嘉拜见袁绍，曹操怒斥众诸侯，乃对曰：董卓于汴水或有埋伏，慎之！曹操未从，果败于徐荣。三月，曹操与郭嘉论天下事：使孤成大业者，必此人也。\
	ᅟᅠᅟᅠ郭嘉从破袁绍，讨谭、尚，连战连克，计定辽东。时年三十八，征乌桓归途郭嘉因劳染疾，命悬之际竟意外饮下柳皮醋水而愈。建安十三年，曹操屯兵赤壁，郭嘉识破连环之计，设上中下三策，可胜刘备。尚未献策，曹操便决意采纳上策：“奉孝之才，足胜孤百倍，卿言上策，如何不取？”由此，赤壁战后曹操尽得天下。</i>",


	["kezhuanqingzi"] = "轻辎",
	[":kezhuanqingzi"] = "<font color='green'><b>准备阶段，</b></font>你可以弃置任意名其他角色装备区里的各一张牌，然后这些角色获得“神速”直到你下回合开始。",

	["kezhuandingce"] = "定策",
	[":kezhuandingce"] = "当你受到伤害后，你可以弃置你和伤害来源的各一张手牌，若这两张牌颜色相同，你视为使用一张【洞烛先机】。",

	["kezhuanzhenfeng"] = "针锋",
	[":kezhuanzhenfeng"] = "<font color='green'><b>出牌阶段每种类型限一次，</b></font>你可以视为使用一张存活角色的技能描述中包含的基本牌或普通锦囊牌（无次数和距离限制），当此牌对一名技能描述中包含此牌名的角色生效后，你对其造成1点伤害。",

	["kezhuanzhenfeng1"] = "你可以视为使用【%src】",
	["kezhuanqingzi-ask"] = "你可以选择发动“轻辎”的角色",
	["kezhuandingce-discard"] = "请选择发动“定策”弃置的牌",

	["$kezhuanqingzi1"] = "下一步棋，我已经计划好了。",
	["$kezhuanqingzi2"] = "我已有所顿悟。",
	["$kezhuandingce1"] = "一身才落拓，狂慧藐凡尘。",
	["$kezhuandingce2"] = "平生多偃蹇，何幸得天恩。",
	["$kezhuanzhenfeng1"] = "深感情之切，策谋以报君！",
	["$kezhuanzhenfeng2"] = "此笺相寄予，数语以销魂。",

	["~kezhuanguojia"] = "奉孝将去，主公保重。",


	--马超
	["kezhuanmachao"] = "马超[转]", 
	["&kezhuanmachao"] = "马超",
	["#kezhuanmachao"] = "潼关之勇",
	["designer:kezhuanmachao"] = "官方",
	["cv:kezhuanmachao"] = "官方",
	["illustrator:kezhuanmachao"] = "鬼画府",

	["kezhuanzhuiming"] = "追命",
	[":kezhuanzhuiming"] = "当你使用【杀】指定唯一目标后，你可以声明一种颜色且该角色可以弃置任意张牌，然后你展示其一张牌，若此牌的颜色与你声明的颜色相同，此【杀】不计入次数、不能被响应且造成的伤害+1。",

	["zhuiming_dis"] = "【杀】使用来源发动“追命”声明了%srg，你可以弃置任意张牌",
	["$kezhuanzhuiming"] = "%from 声明的颜色为 %arg ！",
	["$kezhuanzhuimingtrigger"] = "%from 的 <font color='yellow'><b>“追命”</b></font> 生效，此【杀】不计入次数、不能被响应且造成的伤害+1！",

	["$kezhuanzhuiming1"] = "以尔等之血，祭我族人！",
	["$kezhuanzhuiming2"] = "去地下忏悔你们的罪行吧！",

	["~kezhuanmachao"] = "西凉众将离心，父仇难报！",


	--张任
	["kezhuanzhangren"] = "张任[转]", 
	["&kezhuanzhangren"] = "张任",
	["#kezhuanzhangren"] = "索命神射",
	["designer:kezhuanzhangren"] = "官方",
	["cv:kezhuanzhangren"] = "官方",
	["illustrator:kezhuanzhangren"] = "鬼画府，极乐",

	["kezhuanfuni"] = "伏匿",
	["kezhuanfuni-distribute"] = "你可以将这些【影】分配给任意名角色",
	[":kezhuanfuni"] = "锁定技，你的攻击范围始终为0；<font color='green'><b>每轮开始时，</b></font>你将游戏外的X张【影】交给任意名角色（X为存活角色数的一半，向上取整）；当一张【影】进入弃牌堆时，你当前回合使用牌无距离限制且不能被响应。",

	["kezhuanchuanxin"] = "穿心",
	["kezhuanchuanxin-ask"] = "穿心：你可以将一张牌当【杀】使用",
	[":kezhuanchuanxin"] = "一名角色的<font color='green'><b>结束阶段，</b></font>你可以将一张牌当【杀】使用；你以此法使用的【杀】对一名角色造成伤害时，伤害值+X（X为其当前回合回复过的体力值）。",
	["$kezhuandestroyEquip"] = "%card 被销毁！",
	["$kezhuanchuanxinda"] = "%from 本回合回复了 %arg 点体力，此伤害值增加等量数值 !",
	
	["$kezhuanfuni1"] = "进入埋伏，倒要看你如何脱身。",
	["$kezhuanfuni2"] = "谅你肋生双翅，也逃不出这天罗地网。",
	["$kezhuanchuanxin1"] = "弩搭穿心箭，葬敌落凤坡。",
	["$kezhuanchuanxin2"] = "麒麟弓一出，定穿心取命。",

	["~kezhuanzhangren"] = "诸将无能，悉数终亡。",

	["$kezhuanfunixiangying"] = "%from 的 <font color='yellow'><b>“伏匿”</b></font> 触发，此牌不能被响应！",


	--张飞
	["kezhuanzhangfei"] = "张飞[转]", 
	["&kezhuanzhangfei"] = "张飞",
	["#kezhuanzhangfei"] = "长坂之威",
	["designer:kezhuanzhangfei"] = "官方",
	["cv:kezhuanzhangfei"] = "官方",
	["illustrator:kezhuanzhangfei"] = "鬼画府",

	["kezhuanbaohe"] = "暴喝",
	[":kezhuanbaohe"] = "一名角色的<font color='green'><b>出牌阶段结束时，</b></font>你可以弃置两张牌视为对攻击范围内包含其的所有其他角色使用一张【杀】；你以此法使用的【杀】造成的伤害+X（X为此牌被响应的次数）。",
	["$kezhuanbaoheda"] = "%from 的 <font color='yellow'><b>“暴喝”</b></font> 触发，此牌伤害 + %arg ！",

	["kezhuanxushi"] = "虚势",
	[":kezhuanxushi"] = "出牌阶段限一次，你可以交给任意名其他角色各一张牌，然后从游戏外获得2X张【影】（X为你给出的牌数）。",


	["kezhuanbaohe-ask"] = "你可以弃置两张牌对 %src 发动“暴喝”",
	["kezhuanxushigive"] = "请选择交给 %src 的牌",

	["$kezhuanbaohe1"] = "哇呀呀呀呀呀！",
	["$kezhuanbaohe2"] = "此声一震，桥断水停！",
	["$kezhuanxushi1"] = "我燕人自有妙计！",
	["$kezhuanxushi2"] = "偃旗息鼓，蓄势待发！",

	["~kezhuanzhangfei"] = "我这脾气，该收敛收敛了。",


	--夏侯荣
	["kezhuanxiahourong"] = "夏侯荣[转]", 
	["&kezhuanxiahourong"] = "夏侯荣",
	["#kezhuanxiahourong"] = "擐甲执兵",
	["designer:kezhuanxiahourong"] = "官方",
	["cv:kezhuanxiahourong"] = "傲雪梅枪",
	["illustrator:kezhuanxiahourong"] = "鬼画府，极乐",

	["kezhuanfenjian"] = "奋剑",

	[":kezhuanfenjian"] = "<font color='green'><b>每回合各限一次，</b></font>你可以令你当前回合受到的伤害+1视为使用一张【决斗】或对一名处于濒死状态的其他角色使用一张【桃】。",
	
	["$kezhuanfenjian1"] = "临险必夷，背水一战！",
	["$kezhuanfenjian2"] = "处变之际，决胜之间！",

	["~kezhuanxiahourong"] = "天下已定，我固当烹！",

	--孙尚香
	["kezhuansunshuangxiang"] = "孙尚香[转]", 
	["&kezhuansunshuangxiang"] = "孙尚香",
	["#kezhuansunshuangxiang"] = "情断吴江",
	["designer:kezhuansunshuangxiang"] = "官方",
	["cv:kezhuansunshuangxiang"] = "官方",
	["illustrator:kezhuansunshuangxiang"] = "鬼画府，极乐",

	["kezhuanguiji"] = "闺忌",
	["kezhuanguijiagain"] = "闺忌：与其交换手牌",
	--[":kezhuanguiji"] = "出牌阶段，你可以与一名手牌数小于你的男性角色交换手牌，若如此做，“闺忌”失效直到其死亡时，或其下个<font color='green'><b>出牌阶段结束时，</b></font>你可以与其交换手牌。",
	[":kezhuanguiji"] = "出牌阶段限一次，你可以与一名手牌数小于你的男性角色交换手牌，然后“闺忌”失效直到满足下列一项:\
	1.该角色下个<font color='green'><b>出牌阶段结束时</b></font>，且你可以与其交换手牌；\
	2.该角色死亡时。",

	["kezhuanjiaohaoex"] = "骄豪放牌",
	[":kezhuanjiaohaoex"] = "出牌阶段限一次，你可以将手牌中的一张装备牌置于一名拥有“骄豪”的角色对应空置的装备栏中。",
	["kezhuanjiaohao"] = "骄豪",
	[":kezhuanjiaohao"] = "其他角色的出牌阶段限一次，其可以将手牌中的一张装备牌置于你对应空置的装备栏中；<font color='green'><b>准备阶段，</b></font>你从游戏外获得X张【影】（X为你空置的装备栏数的一半，向上取整）。",

	["$kezhuanguiji1"] = "鸾凤和鸣，情投意合。",
	["$kezhuanguiji2"] = "双剑同鸣，双心灵犀。",
	["$kezhuanjiaohao1"] = "边月随弓影，胡霜拂剑花！",
	["$kezhuanjiaohao2"] = "轻叶心间过，刀剑光影掠！",
	["$kezhuanjiaohao3"] = "这些都交给我吧！",
	["$kezhuanjiaohao4"] = "那小女子就却之不恭喽！",

	["~kezhuansunshuangxiang"] = "何处吴歌起，夜望不知乡。",


	--黄忠
	["kezhuanhuangzhong"] = "黄忠[转]", 
	["&kezhuanhuangzhong"] = "黄忠",
	["#kezhuanhuangzhong"] = "定军之英",
	["designer:kezhuanhuangzhong"] = "官方",
	["cv:kezhuanhuangzhong"] = "官方",
	["illustrator:kezhuanhuangzhong"] = "鬼画府",

	["kezhuancuifeng"] = "摧锋",
	["kezhuancuifeng-ask"] = "请选择此【%src】的目标 -> 点击确定",
	["kezhuancuifengchongzhi"] = "摧锋重置",
	[":kezhuancuifeng"] = "限定技，出牌阶段，你可以视为使用一张指定唯一目标的伤害类牌（不为延时类锦囊牌，无距离限制），若此牌没有造成伤害或造成的总伤害值大于1，本<font color='green'><b>回合结束时，</b></font>“摧锋”视为未发动过。",


	["kezhuandengnan"] = "登难",
	[":kezhuandengnan"] = "限定技，出牌阶段，你可以视为使用一张非伤害类普通锦囊牌，若此牌的目标均于本回合受到过伤害，本<font color='green'><b>回合结束时，</b></font>“登难”视为未发动过。",
	["kezhuandengnanover"] = "登难目标达成",
	["kezhuandengnantar"] = "登难目标",
	["kezhuandengnanda"] = "已受到伤害",
	["kezhuandengnan-ask"] = "请选择此【%src】的目标 -> 点击确定",

	["$kezhuandengnan1"] = "一箭从戎起长沙，射得益州做汉家！",
	["$kezhuandengnan2"] = "将拜五虎从风雨，功夸定军造乾坤！",
	["$kezhuancuifeng1"] = "龙骨成镞，矢破苍穹。",
	["$kezhuancuifeng2"] = "凤翎为羽，箭没坚城。",

	["~kezhuanhuangzhong"] = "末将，有负主公重托。",


	--娄圭
	["kezhuanlougui"] = "娄圭[转]", 
	["&kezhuanlougui"] = "娄圭",
	["#kezhuanlougui"] = "梦梅居士",
	["designer:kezhuanlougui"] = "官方",
	["cv:kezhuanlougui"] = "三国演义",
	["illustrator:kezhuanlougui"] = "鬼画府",

	["kezhuanshacheng"] = "沙城",
	
	["kezhuanshacheng-ask"] = "你可以选择“沙城”摸牌的目标角色",
	[":kezhuanshacheng"] = "<font color='green'><b>游戏开始时，</b></font>你将牌堆顶的两张牌置于武将牌上，称为“沙城”；当一名角色使用的【杀】结算完毕后，你可以将一张“沙城”置入弃牌堆并令一名目标角色摸X张牌（X为其当前回合失去的牌数且至多为5）。",
	["kezhuanshacheng:kezhuanshacheng-ask"] = "你可以发动“沙城”令一名目标角色摸牌",


	["kezhuanninghan"] = "凝寒",
	[":kezhuanninghan"] = "锁定技，所有角色手牌中的♣【杀】均视为冰【杀】；当一名角色受到冰冻伤害后，你可以将造成此伤害的牌置于武将牌上，称为“沙城”。",
	["kezhuanninghan:kezhuanninghan-ask"] = "你可以发动“凝寒”将 %src 置于武将牌上",
	["kezhuanninghanbuff"] = "凝寒杀",
	[":kezhuanninghanbuff"] = "锁定技，你手牌中的♣【杀】均视为冰【杀】。",

	["kezhuanshachengcandraw"] = "沙城可摸牌",

	["$kezhuanshacheng1"] = "天色已晚，丞相为何不筑城建营呢？",
	["$kezhuanshacheng2"] = "晚上极冷，边筑土边泼水，马上冻结，随筑随冻，不就成了？",
	["$kezhuanninghan1"] = "哈哈哈哈哈，丞相熟知兵法，难道不知因时而动？",
	["$kezhuanninghan2"] = "丞相，我只是希望您能早日统一天下，让百姓脱离战乱之苦。",

	["~kezhuanlougui"] = "啊，请丞相好自为之。",




	--韩遂
	["kezhuanhansui"] = "韩遂[转]", 
	["&kezhuanhansui"] = "韩遂",
	["#kezhuanhansui"] = "雄踞北疆",
	["designer:kezhuanhansui"] = "官方",
	["cv:kezhuanhansui"] = "官方",
	["illustrator:kezhuanhansui"] = "盲特",

	["kezhuanniluan"] = "逆乱",
	["kezhuanniluan-ask"] = "你可以发动“逆乱”",
	[":kezhuanniluan"] = "<font color='green'><b>准备阶段，</b></font>你可以令一名对你造成过伤害的角色摸两张牌，或弃置一张牌对一名未对你造成过伤害的角色造成1点伤害。",
	["$kezhuanniluanlog"] = "%from 发动了 <font color='yellow'><b>“逆乱”</b></font> ",

	["kezhuanhuchou"] = "互雠",
	[":kezhuanhuchou"] = "锁定技，你对上一名对你使用伤害类牌的角色造成的伤害+1。",

	["kezhuanjiemeng"] = "皆盟",
	[":kezhuanjiemeng"] = "主公技，锁定技，群势力角色与其他角色的距离-X（X为群势力角色数）。",

	["$kezhuanniluan1"] = "天下动乱，我怎能坐视不管？",
	["$kezhuanniluan2"] = "骁雄武力，岂可甘为他将？",
	["$kezhuanhuchou1"] = "众十余万，天下扰动。",
	["$kezhuanhuchou2"] = "诛杀宦官，吾亦出力！",

	["~kezhuanhansui"] = "称雄三十载，一败化为尘。",


	--张楚
	["kezhuanzhangchu"] = "张楚[转]", 
	["&kezhuanzhangchu"] = "张楚",
	["#kezhuanzhangchu"] = "大贤后裔",
	["designer:kezhuanzhangchu"] = "官方",
	["cv:kezhuanzhangchu"] = "官方",
	["illustrator:kezhuanzhangchu"] = "花第",

	["kezhuanhuozhong"] = "惑众",
	["kezhuanhuozhongex"] = "惑众放牌",
	[":kezhuanhuozhong"] = "每名角色的出牌阶段限一次，其可以将一张黑色非锦囊牌当【兵粮寸断】置于其判定区内，然后令一名拥有“惑众”的角色摸两张牌。",
	[":kezhuanhuozhongex"] = "出牌阶段限一次，你可以将一张黑色非锦囊牌当【兵粮寸断】置于你的判定区内，然后令一名拥有“惑众”的角色摸两张牌。",

	["kezhuanrihui"] = "日慧",
	[":kezhuanrihui"] = "当你使用【杀】对目标角色造成伤害后，你可以令判定区有牌的其他角色各摸一张牌；你每回合对判定区没有牌的角色使用的第一张【杀】无次数限制。",

	["kezhuanrihui:kezhuanrihui"] = "你可以发动“日慧”令判定区有牌的角色各摸一张牌",

	["$kezhuanhuozhong1"] = "天地裹黄巾者无数，如麦粟绽于秋雨。",
	["$kezhuanhuozhong2"] = "天地之不仁者，吾可登长辇而伐天地。",
	["$kezhuanrihui1"] = "今连方七十二，宁为战魂，勿做刍狗。",
	["$kezhuanrihui2"] = "吾父黄泉未远，定可见黄天再现人间。",

	["~kezhuanzhangchu"] = "大贤良师之女，不畏一死。",

	--夏侯恩
	["kezhuanxiahouen"] = "夏侯恩[转]", 
	["&kezhuanxiahouen"] = "夏侯恩",
	["#kezhuanxiahouen"] = "背剑之将",
	["designer:kezhuanxiahouen"] = "官方",
	["cv:kezhuanxiahouen"] = "官方",
	["illustrator:kezhuanxiahouen"] = "蚂蚁君",

	["kezhuanhujian"] = "护剑",
	[":kezhuanhujian"] = "<font color='green'><b>游戏开始时，</b></font>你从游戏外获得一张【赤血青锋】；一个<font color='green'><b>回合结束时，</b></font>此回合最后一名使用或打出牌的角色可以获得弃牌堆中的【赤血青锋】。",
	["kezhuanhujian:kezhuanhujian-ask"] = "护剑：你可以获得弃牌堆中的【赤血青锋】",

	["kezhuanshili"] = "恃力",
	[":kezhuanshili"] = "出牌阶段限一次，你可以将手牌中的一张装备牌当【决斗】使用。",

	["$kezhuanhujian1"] = "得此宝剑，如虎添翼！",
	["$kezhuanhujian2"] = "丞相之宝，汝岂配用之？啊哈！",
	["$kezhuanshili1"] = "小小匹夫，可否闻长坂剑神之名啊？",
	["$kezhuanshili2"] = "此剑吹毛得过，削铁如泥！",

	["~kezhuanxiahouen"] = "长坂剑神，也陨落了。",


	--庞统
	["kezhuanpangtong"] = "庞统[转]", 
	["&kezhuanpangtong"] = "庞统",
	["#kezhuanpangtong"] = "荆楚之高俊",
	["designer:kezhuanpangtong"] = "官方",
	["cv:kezhuanpangtong"] = "官方",
	["illustrator:kezhuanpangtong"] = "鬼画府，极乐",

	["kezhuanmanjuan"] = "漫卷",
	[":kezhuanmanjuan"] = "每回合每种点数限一次，若你没有手牌，你可以使用或打出本回合置入弃牌堆的牌。",

	["kezhuanyangming"] = "养名",
	[":kezhuanyangming"] = "出牌阶段限一次，你可以与一名角色拼点：若其赢，其摸X张牌（X为其本阶段拼点没赢的次数）且你回复1点体力，否则你可以对其重复此流程。",
	
	["kezhuanyangming:kezhuanyangming-jixu"] = "你可以发动“养名”继续与 %src 拼点",
	["kezhuanyangminglose"] = "拼点没赢",

	["kezhuanmanjuan0"] = "你可以使用其中一张牌",
	["kezhuanmanjuan2"] = "请选择此牌的目标 -> 点击确定",
	["kezhuanmanjuan1"] = "你可以使用此牌",

	["$kezhuanmanjuan1"] = "吾非百里才，必有千里之行。",
	["$kezhuanmanjuan2"] = "展吾骥足，施吾羽翅！",
	["$kezhuanyangming1"] = "表虽言过其实，实则引人向善。",
	["$kezhuanyangming2"] = "吾与卿之才干，孰高孰低？",

	["~kezhuanpangtong"] = "雏凤未飞已先陨。",


	--范疆＆张达
	["kezhuanfanjiangzhangda"] = "范疆＆张达[转]", 
	["&kezhuanfanjiangzhangda"] = "范疆张达",
	["#kezhuanfanjiangzhangda"] = "你死我亡",
	["designer:kezhuanfanjiangzhangda"] = "官方",
	["cv:kezhuanfanjiangzhangda"] = "官方",
	["illustrator:kezhuanfanjiangzhangda"] = "游漫美绘",

	["kezhuanfushan"] = "负山",
	[":kezhuanfushan"] = "<font color='green'><b>出牌阶段开始时，</b></font>所有其他角色可以依次选择是否交给你一张牌并令你此阶段可以多使用一张【杀】；<font color='green'><b>出牌阶段结束时，</b></font>若你使用【杀】的剩余次数不为0且此阶段以此法交给你牌的角色均存活，你失去2点体力，否则你将手牌摸至体力上限。",

	["kezhuanfushangive"] = "负山：你可以交给 %src 一张牌",

	["$kezhuanfushan1"] = "鞭鞭入肉，似钢钉入骨，此仇如何消得？",
	["$kezhuanfushan2"] = "斥我如奴，鞭我如畜，如何叫我以德报怨？",

	["~kezhuanfanjiangzhangda"] = "什么！刘备伐吴了？",


	--蔡瑁＆张允
	["kezhuancaimaozhangyun"] = "蔡瑁＆张允[转]", 
	["&kezhuancaimaozhangyun"] = "蔡瑁张允",
	["#kezhuancaimaozhangyun"] = "乘雷潜狡",
	["designer:kezhuancaimaozhangyun"] = "官方",
	["cv:kezhuancaimaozhangyun"] = "官方",
	["illustrator:kezhuancaimaozhangyun"] = "君桓文化",
	["~kezhuancaimaozhangyun"] = "丞相，冤枉，冤枉啊！",

	--黄承彦
	["kezhuanhuangchengyan"] = "黄承彦[转]", 
	["&kezhuanhuangchengyan"] = "黄承彦",
	["#kezhuanhuangchengyan"] = "沔阳雅士",
	["designer:kezhuanhuangchengyan"] = "官方",
	["cv:kezhuanhuangchengyan"] = "官方",
	["illustrator:kezhuanhuangchengyan"] = "凡果",
	["~kezhuanhuangchengyan"] = "卧龙出山天伦逝，悔教吾婿离南阳。",

		--蒋干
	["kezhuanjianggan"] = "蒋干[转]", 
	["&kezhuanjianggan"] = "蒋干",
	["#kezhuanjianggan"] = "锋镝悬信",
	["designer:kezhuanjianggan"] = "官方",
	["cv:kezhuanjianggan"] = "官方",
	["illustrator:kezhuanjianggan"] = "biou09",
	["~kezhuanjianggan"] = "丞相，再给我一次机会啊！",

		--阚泽
	["kezhuankanze"] = "阚泽[转]", 
	["&kezhuankanze"] = "阚泽",
	["#kezhuankanze"] = "慧眼的博士",
	["designer:kezhuankanze"] = "官方",
	["cv:kezhuankanze"] = "官方",
	["illustrator:kezhuankanze"] = "游漫美绘",
	["~kezhuankanze"] = "谁又能来宽释我呢？",

}








extension_he = sgs.Package("kearjsrgthe", sgs.Package_GeneralPack)


--[[
kehexumou_card_one = sgs.CreateTrickCard{
	name = "_kehexumou_card_one",
	class_name = "XumouCardone",
	subtype = "xumou_card",
	subclass = sgs.LuaTrickCard_TypeDelayedTrick,
	target_fixed = false,
	can_recast = false,
	is_cancelable = false,
	movable = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:containsTrick(self:objectName()) 
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, effect.to:objectName())
		room:throwCard(self, reason, nil)
	end,
}
local card = kehexumou_card_one:clone()
card:setSuit(0)
card:setNumber(0)
card:setParent(extension_he)

kehexumou_card_two = sgs.CreateTrickCard{
	name = "_kehexumou_card_two",
	class_name = "XumouCardtwo",
	subtype = "xumou_card",
	subclass = sgs.LuaTrickCard_TypeDelayedTrick,
	target_fixed = false,
	can_recast = false,
	is_cancelable = false,
	movable = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:containsTrick(self:objectName()) 
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, effect.to:objectName())
		room:throwCard(self, reason, nil)
	end,
}
local card = kehexumou_card_two:clone()
card:setSuit(0)
card:setNumber(0)
card:setParent(extension_he)

kehexumou_card_three = sgs.CreateTrickCard{
	name = "_kehexumou_card_three",
	class_name = "XumouCardthree",
	subtype = "xumou_card",
	subclass = sgs.LuaTrickCard_TypeDelayedTrick,
	target_fixed = false,
	can_recast = false,
	is_cancelable = false,
	movable = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:containsTrick(self:objectName()) 
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, effect.to:objectName())
		room:throwCard(self, reason, nil)
	end,
}
local card = kehexumou_card_three:clone()
card:setSuit(0)
card:setNumber(0)
card:setParent(extension_he)

kehexumou_card_four = sgs.CreateTrickCard{
	name = "_kehexumou_card_four",
	class_name = "XumouCardfour",
	subtype = "xumou_card",
	subclass = sgs.LuaTrickCard_TypeDelayedTrick,
	target_fixed = false,
	can_recast = false,
	is_cancelable = false,
	movable = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:containsTrick(self:objectName()) 
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, effect.to:objectName())
		room:throwCard(self, reason, nil)
	end,
}
local card = kehexumou_card_four:clone()
card:setSuit(0)
card:setNumber(0)
card:setParent(extension_he)

kehexumou_card_five = sgs.CreateTrickCard{
	name = "_kehexumou_card_five",
	class_name = "XumouCardfive",
	subtype = "xumou_card",
	subclass = sgs.LuaTrickCard_TypeDelayedTrick,
	target_fixed = false,
	can_recast = false,
	is_cancelable = false,
	movable = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:containsTrick(self:objectName()) 
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, effect.to:objectName())
		room:throwCard(self, reason, nil)
	end,
}
local card = kehexumou_card_five:clone()
card:setSuit(0)
card:setNumber(0)
card:setParent(extension_he)--]]


kehexumou = sgs.CreateTrickCard{
	name = "__kehexumou",
	class_name = "Xumou",
	subtype = "xumou_card",
	subclass = sgs.LuaTrickCard_TypeDelayedTrick,
	target_fixed = false,
	can_recast = false,
	is_cancelable = false,
	movable = false,
	filter = function(self, targets, to_select)
		return #targets<1 and not to_select:containsTrick(self:objectName()) 
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, effect.to:objectName())
		room:throwCard(self, reason, nil)
	end,
}
for i=1,9 do
	local xm = kehexumou:clone(6,0)
	xm:setObjectName("__kehexumou"..i)
	xm:setParent(extension_he)
end

kehezhugeliang = sgs.General(extension_he, "kehezhugeliang", "shu", 3,true)

kehewentianVS = sgs.CreateViewAsSkill{
	name = "kehewentian",
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "nullification" then
			local use_card = sgs.Sanguosha:cloneCard("nullification")
			use_card:addSubcard(sgs.Self:getMark("kehewentianId"))
			use_card:setSkillName("kehewentian")
			return use_card
		else
			local use_card = sgs.Sanguosha:cloneCard("fire_attack")
			use_card:addSubcard(sgs.Self:getMark("kehewentianId"))
			use_card:setSkillName("kehewentian")
			return use_card
		end
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("&bankehewentian_lun") == 0)
	end, 
    enabled_at_response = function(self,player,pattern)
	   	return player:getMark("&bankehewentian_lun") == 0 and (pattern == "nullification")
	end,
	enabled_at_nullification = function(self,player)				
		return (player:getMark("&bankehewentian_lun") == 0) 
	end
}
kehewentian = sgs.CreateTriggerSkill{
	name = "kehewentian",
	view_as_skill = kehewentianVS,
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseStart,sgs.PreCardUsed,sgs.Death,sgs.GameReady},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.GameReady) and player:hasSkill(self,true) then
			room:setPlayerMark(player,"@usekehewentian",7)
		end
		if event == sgs.EventPhaseStart
		and player:getMark("usedkehewentian-Clear")<1
		and player:getMark("&bankehewentian_lun")<1
		and player:getPhase()>=sgs.Player_Start--一般主阶段范围
		and player:getPhase()<=sgs.Player_Finish
		and player:hasSkill(self) and player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName())
			room:setPlayerMark(player,"usedkehewentian-Clear",1)
			local card_ids = room:getNCards(math.max(1,player:getMark("@usekehewentian")))
			room:fillAG(card_ids,player)
			--选牌给人
			local card_id = room:askForAG(player, card_ids, true, "kehewentian","kehewentianchoose-ask")
			room:clearAG(player)
			if card_id>-1 then
				local fri = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "kehewentian-ask",false)
				if fri then
					card_ids:removeOne(card_id)
					fri:obtainCard(sgs.Sanguosha:getCard(card_id),false)
				end
			end
			--开始观星
			if (card_ids:length() > 0) then
				room:askForGuanxing(player,card_ids)
			end
			room:removePlayerMark(player,"@usekehewentian")
		end
		if (event == sgs.CardsMoveOneTime) then
	     	local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_DrawPile or move.from_places:contains(sgs.Player_DrawPile)
			then room:setPlayerMark(player,"kehewentianId",room:getDrawPile():first()) end
		end
		if (event == sgs.PreCardUsed) then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"kehewentian") then
				if use.card:isKindOf("Nullification") and not use.card:isBlack()
				or use.card:isKindOf("FireAttack") and not use.card:isRed()
				then room:addPlayerMark(player,"&bankehewentian_lun") end
			end
		end
		--鸣谢毒主任
		if (event == sgs.Death) then
			local death = data:toDeath()
			if death.who:hasSkill(self,true) and not(death.damage and death.damage.from)
			then room:broadcastSkillInvoke("kehewentiancaidan") end
		end
	end,
	can_trigger = function(self,target)
		return target~=nil
	end
}
kehezhugeliang:addSkill(kehewentian)

kehewentiancaidan = sgs.CreateTriggerSkill{
	name = "kehewentiancaidan",
	events = {},
	on_trigger = function(self, event, player, data)
	end,
	can_trigger = function(self,target)
		return false
	end
}
extension_he:addSkills(kehewentiancaidan)

kehechushiCard = sgs.CreateSkillCard{
	name = "kehechushiCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, player, targets)
		local zhugong
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if (p:getRole() == "lord") then
				zhugong = p
				break
			end
		end
		--议事
		local zgandzg = sgs.SPlayerList()
		zgandzg:append(player)
		if (zhugong:objectName() ~= player:objectName()) then
		    zgandzg:append(zhugong)
		end
		local ys = {}
		ys.reason = self:getSkillName()
		ys.from = player
		ys.tos = zgandzg
		ys.effect = function(ys_data)
			if (ys_data.result == "red") then
				while player:isAlive() or zhugong:isAlive() do
					if player:isAlive() then player:drawCards(1,self:getSkillName()) end
					if zhugong:isAlive() then zhugong:drawCards(1,self:getSkillName()) end
					if player:getHandcardNum()+zhugong:getHandcardNum()>=7 then break end
				end
			elseif (ys_data.result == "black") then
				room:setPlayerMark(player,"&kehechushi_lun",1)
			end
		end
		askYishi(ys)
		--[[
		for _,p in sgs.qlist(zgandzg) do
			room:setPlayerMark(p,"keyishiing",1)
			--每个人提前挑选牌准备展示
			if not p:isKongcheng() then
				local id = room:askForExchange(p, "kehechushi", 1, 1, false, "keqichaozheng_yishi"):getSubcards():first()
				local card = sgs.Sanguosha:getCard(id)
				room:setCardFlag(card,"useforyishi")
				if card:isRed() then
					room:setPlayerMark(p,"keyishi_red",1)
				elseif card:isBlack() then
					room:setPlayerMark(p,"keyishi_black",1)
				end
				--标记选择了牌的人（没有空城的人）
				room:setPlayerMark(p,"chooseyishi",1)
			end
		end
		--依次展示选好的牌，公平公正公开
		local sj = room:findPlayerBySkillName("kehebazheng")
		if sj then
			for _,bz in sgs.qlist(room:getAllPlayers()) do
				if (bz:getMark("&kehebazheng-Clear") > 0) then
					if (sj:getMark("keyishi_red") > 0) and (bz:getMark("keyishi_black") > 0) then
						room:setPlayerMark(bz,"keyishi_black",0)
						room:setPlayerMark(bz,"keyishi_red",1)
						local log = sgs.LogMessage()
						log.type = "$kehebazhengredlog"
						log.from = bz
						log.to:append(sj)
						room:sendLog(log)
					elseif (sj:getMark("keyishi_black") > 0) and (bz:getMark("keyishi_red") > 0) then
						room:setPlayerMark(bz,"keyishi_black",1)
						room:setPlayerMark(bz,"keyishi_red",0)
						local log = sgs.LogMessage()
						log.type = "$kehebazhengblacklog"
						log.from = bz
						log.to:append(sj)
						room:sendLog(log)
					end
				end
			end
		end
		room:getThread():delay(800)
		local yishirednum = 0
		local yishiblacknum = 0
		for _,p in sgs.qlist(zgandzg) do
			if (p:getMark("keyishi_black") > 0) then yishiblacknum = yishiblacknum + 1 end
			if (p:getMark("keyishi_red") > 0) then yishirednum = yishirednum + 1 end
			for _,c in sgs.qlist(p:getCards("h")) do
				if c:hasFlag("useforyishi") then
					room:showCard(p,c:getEffectiveId())
					room:setCardFlag(c,"-useforyishi")
					break
				end
			end	
		end
		room:getThread():delay(1200)
		--0为平局（默认），1：红色；2：黑色
		local yishiresult = 0
		if (yishirednum > yishiblacknum) then
			yishiresult = 1
			local log = sgs.LogMessage()
			log.type = "$keyishired"
			log.from = player
			room:sendLog(log)	
			room:doLightbox("$keyishired")
		elseif (yishirednum < yishiblacknum) then
			yishiresult = 2
			local log = sgs.LogMessage()
			log.type = "$keyishiblack"
			log.from = player
			room:sendLog(log)	
			room:doLightbox("$keyishiblack")
		elseif (yishirednum == yishiblacknum) then
			yishiresult = 0
			local log = sgs.LogMessage()
			log.type = "$keyishipingju"
			log.from = player
			room:sendLog(log)	
			room:doLightbox("$keyishipingju")
		end
		--结果
		if (yishiresult == 1) then
			local goon = 1
			while (goon == 1) do
				player:drawCards(1)
				zhugong:drawCards(1)
				local allnum = 0
				allnum = player:getHandcardNum() + zhugong:getHandcardNum()
				if (allnum >= 7) then
					goon = 0
				end
			end	
		elseif (yishiresult == 2) then
			room:setPlayerMark(player,"&kehechushi_lun",1)
		end
		--开始清理标记
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if (p:getMark("keyishiing")>0) then room:setPlayerMark(p,"keyishiing",0) end
			if (p:getMark("chooseyishi")>0) then room:setPlayerMark(p,"chooseyishi",0) end
		end
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if (p:getMark("keyishi_red")>0) then room:setPlayerMark(p,"keyishi_red",0) end
			if (p:getMark("keyishi_black")>0) then room:setPlayerMark(p,"keyishi_black",0) end
		end]]
	end 
}

kehechushiVS = sgs.CreateZeroCardViewAsSkill{
	name = "kehechushi",
	view_as = function(self, cards)
		return kehechushiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kehechushiCard")
	end, 
}

kehechushi = sgs.CreateTriggerSkill{
	name = "kehechushi",
	view_as_skill = kehechushiVS,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.ConfirmDamage) then
			local damage = data:toDamage()
			if (damage.nature ~= sgs.DamageStruct_Normal) and (player:getMark("&kehechushi_lun") > 0) then
				room:sendCompulsoryTriggerLog(player,self:objectName())
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
	end,
}
kehezhugeliang:addSkill(kehechushi)

keheyinlue = sgs.CreateTriggerSkill{
	name = "keheyinlue",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.DamageInflicted) then
			local damage = data:toDamage()
			if (damage.nature == sgs.DamageStruct_Fire) then
				for _, zgl in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if zgl:getMark("&keheyinluemp")<1 and zgl:canDiscard(zgl,"he") then
						local to_data = sgs.QVariant()
						to_data:setValue(damage.to)
						zgl:setTag("keheyinlueTo",to_data)
						if room:askForDiscard(zgl, self:objectName(), 1, 1, true,true,"keheyinluedishuoyan:"..damage.to:objectName(),".",self:objectName()) then
							room:broadcastSkillInvoke(self:objectName())
							room:setPlayerMark(zgl,"&keheyinluemp",1)
							return true		
					    end
					end
				end
			elseif (damage.nature == sgs.DamageStruct_Thunder) then
				for _, zgl in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if zgl:getMark("&keheyinlueqp")<1 and zgl:canDiscard(zgl,"he") then
						local to_data = sgs.QVariant()
						to_data:setValue(damage.to)
						zgl:setTag("keheyinlueTo",to_data)
						if room:askForDiscard(zgl, self:objectName(), 1, 1, true,true,"keheyinluedisleidian:"..damage.to:objectName(),".",self:objectName()) then
							room:broadcastSkillInvoke(self:objectName())
							room:setPlayerMark(zgl,"&keheyinlueqp",1)
							return true
						end
					end
				end
			end
		end
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_NotActive) then
				for _, zgl in sgs.qlist(room:getAllPlayers()) do
					if (zgl:getMark("&keheyinluemp") > 0) then
						room:setPlayerMark(zgl,"&keheyinluemp",0)
						local phases = sgs.PhaseList()
						phases:append(sgs.Player_Draw)
						zgl:gainAnExtraTurn(phases)
					end
					if (zgl:getMark("&keheyinlueqp") > 0) then
						room:setPlayerMark(zgl,"&keheyinlueqp",0)
						local phases = sgs.PhaseList()
						phases:append(sgs.Player_Discard)
						zgl:gainAnExtraTurn(phases)
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player~=nil
	end,
}
kehezhugeliang:addSkill(keheyinlue)

kehejiangwei = sgs.General(extension_he, "kehejiangwei", "shu", 4,true)

kehejinfaCard = sgs.CreateSkillCard{
	name = "kehejinfaCard" ,
	target_fixed = true ,
	will_throw = false,
	on_use = function(self, room, player, targets)
		room:showCard(player,self:getEffectiveId())
		local zhanshicard = sgs.Sanguosha:getCard(self:getEffectiveId())
		local jfplayers = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if (p:getMaxHp() <= player:getMaxHp()) then
				jfplayers:append(p)
			end
		end
		room:setTag("kehejinfaFrom",ToData(player))
		local ys = {}
		ys.reason = self:getSkillName()
		ys.from = player
		ys.tos = jfplayers
		ys.effect = function(ys_data)
			if (ys_data.result == zhanshicard:getColorString()) then
				local fris = room:askForPlayersChosen(player, jfplayers, "kehejinfa", 0, 2, "kehejinfa-ask", true, true)
				for _,p in sgs.qlist(fris) do
					local cha = p:getMaxHp() - p:getHandcardNum()
					if cha > 0 then
						p:drawCards(math.min(5,cha),self:getSkillName())
					end
				end
			else
				local dummy = sgs.Sanguosha:cloneCard("slash")
				dummy:deleteLater()
				for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
					if sgs.Sanguosha:getEngineCard(id):isKindOf("Ying")
					and room:getCardOwner(id)==nil then
						dummy:addSubcard(id)
						if dummy:subcardsLength()>=2 then
							player:obtainCard(dummy)
							break
						end
					end
				end
			end
		end
		askYishi(ys)
		for _,p in sgs.list(ys.tos) do
			if p~=player:objectName()
			and (ys.to2color[p]:contains(ys.to2color[player:objectName()]) or ys.to2color[player:objectName()]:contains(ys.to2color[p]))
			then return end
		end
		--[[
		for _,p in sgs.qlist(jfplayers) do
			room:setPlayerMark(p,"keyishiing",1)
			--每个人提前挑选牌准备展示
			if not p:isKongcheng() then
				local id = room:askForExchange(p, "kehejinfa", 1, 1, false, "keqichaozheng_yishi"):getSubcards():first()
				local card = sgs.Sanguosha:getCard(id)
				room:setCardFlag(card,"useforyishi")
				if card:isRed() then
					room:setPlayerMark(p,"keyishi_red",1)
				elseif card:isBlack() then
					room:setPlayerMark(p,"keyishi_black",1)
				end
				--标记选择了牌的人（没有空城的人）
				room:setPlayerMark(p,"chooseyishi",1)
			end
		end
		--依次展示选好的牌，公平公正公开
		room:getThread():delay(800)
		local sj = room:findPlayerBySkillName("kehebazheng")
		if sj then
			for _,bz in sgs.qlist(room:getAllPlayers()) do
				if (bz:getMark("&kehebazheng-Clear") > 0) then
					if (sj:getMark("keyishi_red") > 0) and (bz:getMark("keyishi_black") > 0) then
						room:setPlayerMark(bz,"keyishi_black",0)
						room:setPlayerMark(bz,"keyishi_red",1)
						local log = sgs.LogMessage()
						log.type = "$kehebazhengredlog"
						log.from = bz
						log.to:append(sj)
						room:sendLog(log)
					elseif (sj:getMark("keyishi_black") > 0) and (bz:getMark("keyishi_red") > 0) then
						room:setPlayerMark(bz,"keyishi_black",1)
						room:setPlayerMark(bz,"keyishi_red",0)
						local log = sgs.LogMessage()
						log.type = "$kehebazhengblacklog"
						log.from = bz
						log.to:append(sj)
						room:sendLog(log)
					end
				end
			end
		end
		local yishirednum = 0
		local yishiblacknum = 0
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if (p:getMark("keyishi_black") > 0) then yishiblacknum = yishiblacknum + 1 end
			if (p:getMark("keyishi_red") > 0) then yishirednum = yishirednum + 1 end
			for _,c in sgs.qlist(p:getCards("h")) do
				if c:hasFlag("useforyishi") then
					--if c:isRed() then yishirednum = yishirednum + 1 end
					--if c:isBlack() then yishiblacknum = yishiblacknum + 1 end
					room:showCard(p,c:getEffectiveId())
					room:setCardFlag(c,"-useforyishi")
					break
				end
			end
		end
		room:getThread():delay(1200)
		--0为平局（默认），1：红色；2：黑色
		local yishiresult = 0
		if (yishirednum > yishiblacknum) then
			yishiresult = 1
			local log = sgs.LogMessage()
			log.type = "$keyishired"
			log.from = player
			room:sendLog(log)	
			room:doLightbox("$keyishired")
		elseif (yishirednum < yishiblacknum) then
			yishiresult = 2
			local log = sgs.LogMessage()
			log.type = "$keyishiblack"
			log.from = player
			room:sendLog(log)	
			room:doLightbox("$keyishiblack")
		elseif (yishirednum == yishiblacknum) then
			yishiresult = 0
			local log = sgs.LogMessage()
			log.type = "$keyishipingju"
			log.from = player
			room:sendLog(log)	
			room:doLightbox("$keyishipingju")
		end--]]
		local kd = room:askForKingdom(player,self:getSkillName())
		if (player:getKingdom() ~= kd) then
			room:changeKingdom(player, kd)
		end
	end
}
kehejinfa = sgs.CreateViewAsSkill{
	name = "kehejinfa" ,
	n = 1 ,
	view_filter = function(self, cards, to_select)
		return not to_select:isEquipped()
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = kehejinfaCard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kehejinfaCard")
	end
}
kehejiangwei:addSkill(kehejinfa)


kehefumouex = sgs.CreateProhibitSkill{
	name = "#kehefumouex",
	is_prohibited = function(self, from, to, card)
		return table.contains(card:getSkillNames(), "kehefumou") and card:isKindOf("Chuqibuyi")
		and to and to:getMark("&kehefumou+red")+to:getMark("&kehefumou+black")<1
		and from:hasSkill("kehefumou")
	end
}
kehejiangwei:addSkill(kehefumouex)

kehefumouVS = sgs.CreateViewAsSkill{
	name = "kehefumou" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("Ying") 
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then
			return nil
		end
		local slash = sgs.Sanguosha:cloneCard("chuqibuyi")
		slash:setSkillName("kehefumou")
		slash:addSubcard(cards[1])
		return slash
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern:startsWith("@@kehefumou")
	end
}

kehefumou = sgs.CreateTriggerSkill{
	name = "kehefumou",
	view_as_skill = kehefumouVS,
	frequency = sgs.Skill_Frequent,
	waked_skills = "#kehefumouex",
	events = {sgs.EventForDiy,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				for _, p in sgs.qlist(room:getAllPlayers()) do 
					local ct = p:getTag("kehefumouColor"):toString()
					if p:getMark("&kehefumou+"..ct) > 0 then
						room:removePlayerMark(p, "&kehefumou+"..ct)
						room:removePlayerCardLimitation(p, "use,response", ".|"..ct)
					end
				end
			end
		end
		if (event == sgs.EventForDiy) then
			local str = data:toString()
			if str:startsWith("yishiresult:") then
				local strs = str:split(":")
				local tos = strs[4]:split("+")
				local ids = strs[5]:split("+")
				for i,pt in sgs.list(tos) do
					local p = room:findPlayerByObjectName(pt)
					if p:hasSkill(self) and p:getKingdom()=="wei" then
						local cc = sgs.Card_Parse(ids[i])
						if cc==nil then
							continue
						end
						cc = cc:getColorString()
						for n,pr in sgs.list(tos) do
							local tc = sgs.Card_Parse(ids[n])
							if tc==nil then
								continue
							end
							tc = tc:getColorString()
							if pr~=pt and cc~=tc then
								local q = room:findPlayerByObjectName(pr)
								room:setPlayerMark(q,"&kehefumou+"..tc,1)
								room:setPlayerCardLimitation(q, "use,response", ".|"..tc, false)
								q:setTag("kehefumouColor",sgs.QVariant(tc))
							end
						end
						room:askForUseCard(p, "@@kehefumou", "kehefumoucpby-ask")
					end
				end
			end
		end
	end ,
	can_trigger = function(self, player)
		return player~=nil
	end,
}
kehejiangwei:addSkill(kehefumou)



kehexuanfengVS = sgs.CreateOneCardViewAsSkill{
	name = "kehexuanfeng",
	view_filter = function(self, card)
		return card:isKindOf("Ying") 
	end,
	view_as = function(self, card)
		local cisha = sgs.Sanguosha:cloneCard("_kecheng_stabs_slash")
		cisha:setSkillName("kehexuanfeng")
		cisha:addSubcard(card)
		return cisha
	end,
	enabled_at_play = function(self, player)
		for _,c in sgs.qlist(player:getHandcards()) do
			if c:isKindOf("Ying") then
				return (player:getKingdom() == "shu")
			end
		end
		return false
	end, 
}

kehexuanfeng = sgs.CreateTriggerSkill{
	name = "kehexuanfeng",
	view_as_skill = kehexuanfengVS,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if (table.contains(use.card:getSkillNames(),"kehexuanfeng")) then
				local log = sgs.LogMessage()
				log.type = "$kehexuanfengcisha"
				log.from = player
				--room:sendLog(log)
			end
		end
	end ,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
}
kehejiangwei:addSkill(kehexuanfeng)

kehesimayi = sgs.General(extension_he, "kehesimayi", "wei", 4,true)

kehe_jiejiaguitian = sgs.CreateTrickCard{
	name = "_kehe_jiejiaguitian",
	class_name = "Jiejiaguitian",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = false,
	can_recast = false,
	is_cancelable = true,
    available = function(self,player)
    	local tos = player:getAliveSiblings()
		tos:append(player)
		for _,to in sgs.list(tos)do
			if CanToCard(self,player,to) then
				return self:cardIsAvailable(player)
			end
		end
    end,
	filter = function(self,targets,to_select,source)
        if source:isProhibited(to_select,self) then return end
	    return to_select:hasEquip()
		and #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self,to_select)
	end,
	feasible = function(self,targets,source)
		if source:hasEquip() and not source:isProhibited(source,self)
		then return #targets>=0 end
		return #targets>0
	end,
	about_to_use = function(self,room,use)
		if use.to:isEmpty() then use.to:append(use.from) end
		self:cardOnUse(room,use)
	end,
	on_effect = function(self,effect)
		local room = effect.to:getRoom()
		local dc = dummyCard()
		dc:addSubcards(effect.to:getEquips())
		if dc:subcardsLength()>0 then
			if table.contains(effect.card:getSkillNames(),"kehetuigu") then
				local ids = {}
				for _, id in sgs.list(dc:getSubcards()) do
					table.insert(ids,id)
				end
				ids = table.concat(ids,",")
				room:setPlayerCardLimitation(effect.to, "use", ids, true)
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE,effect.from:objectName(),effect.to:objectName(),"kehe_jiejiaguitian","")
			room:obtainCard(effect.to,dc,reason,false)
		end
		return false
	end,
}
kehe_jiejiaguitian:clone(-1,-1):setParent(extension_he)

keheyingshi = sgs.CreateTriggerSkill{
	name = "keheyingshi",
	events = {sgs.TurnedOver} ,
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.TurnedOver) then
			local num = 3
			if room:getAllPlayers(true):length()-room:getAllPlayers():length()>2
			then num = 5 end
			if player:askForSkillInvoke(self,ToData("keheyingshiuse-ask:"..num)) then
				room:broadcastSkillInvoke(self:objectName())
				local card_ids = room:getNCards(num,true,false)
				room:askForGuanxing(player,card_ids)
			end
		end
	end	
}
kehesimayi:addSkill(keheyingshi)

kehetuiguvs = sgs.CreateViewAsSkill{
	name = "kehetuigu" ,
	n = 0 ,
	view_as = function(self, cards)
		local dc = sgs.Sanguosha:cloneCard("_kehe_jiejiaguitian")
		dc:setSkillName("kehetuigu")
		return dc
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern:startsWith("@@kehetuigu")
	end
}
kehetuigu = sgs.CreateTriggerSkill{
	name = "kehetuigu",
	events = {sgs.CardsMoveOneTime,sgs.TurnStart,sgs.EventPhaseStart,sgs.Death,sgs.RoundEnd,sgs.EventPhaseChanging} ,
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = kehetuiguvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.from == sgs.Player_NotActive) then
				room:addPlayerMark(player,"kehetuiguhuihe_lun",1)
			end
		end
		if (event == sgs.RoundEnd) then
			if (player:getMark("kehetuiguhuihe_lun") == 0) then
				room:sendCompulsoryTriggerLog(player,self,math.random(1,2))
				local log = sgs.LogMessage()
				log.type = "$kehetuigulog"
				log.from = player
				room:sendLog(log)
				player:gainAnExtraTurn()
			end
		end
		if (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_RoundStart) then
			if player:askForSkillInvoke(self,ToData("kehetuiguuse-ask")) then
				room:broadcastSkillInvoke(self:objectName(),math.random(3,4))
				player:turnOver()
				local num = math.floor(player:aliveCount()/2)
				room:addMaxCards(player, num, true)
				player:drawCards(num,self:objectName())
				local xjgt = sgs.Sanguosha:cloneCard("_kehe_jiejiaguitian")
				xjgt:setSkillName("kehetuigu")
				xjgt:deleteLater() 
				for _, p in sgs.qlist(room:getAllPlayers()) do 
					if player:canUse(xjgt,p) then
						room:askForUseCard(player,"@@kehetuigu","kehetuiguxjgt_ask:")
						break
					end
				end
			end
		end
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from_places:contains(sgs.Player_PlaceEquip))
			and (move.from:objectName() == player:objectName()) then
				room:sendCompulsoryTriggerLog(player,self,math.random(3,4))
				room:recover(player, sgs.RecoverStruct(self:objectName(),player))
			end
		end
	end,
}
kehesimayi:addSkill(kehetuigu)

keheluxun = sgs.General(extension_he, "keheluxun", "wu", 3,true)

keheyoujin = sgs.CreateTriggerSkill{
	name = "keheyoujin",
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_NotFrequent,
	waked_skills = "#keheyoujinex",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart
		and player:getPhase() == sgs.Player_Play then
			local pds = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:canPindian(p, true) then pds:append(p) end
			end
			local eny = room:askForPlayerChosen(player, pds, self:objectName(), "keheyoujin-ask", true, true)
			if eny then
				room:broadcastSkillInvoke(self:objectName())
				local pd = player:PinDian(eny, self:objectName())
				room:setPlayerMark(pd.from,"&keheyoujinnum-Clear",pd.from_number)
				room:setPlayerMark(pd.to,"&keheyoujinnum-Clear",pd.to_number)
				if pd.from_number==pd.to_number then return end
				local from,to = pd.to,pd.from
				if pd.success then
					from,to = pd.from,pd.to
				end
				local dc = sgs.Sanguosha:cloneCard("slash")
				dc:setSkillName("_"..self:objectName())
				if from:isAlive() and from:canSlash(to,dc,false) then
					room:useCard(sgs.CardUseStruct(dc,from,to))
				end
				dc:deleteLater()
			end
		end
	end,
}
keheluxun:addSkill(keheyoujin)

keheyoujinex = sgs.CreateCardLimitSkill{
	name = "#keheyoujinex",
	limit_list = function(self, player)
		return "use,response"
	end,
	limit_pattern = function(self, player)
		if (player:getMark("&keheyoujinnum-Clear") > 1) then
			return ".|.|1~"..player:getMark("&keheyoujinnum-Clear")-1
		end
		return ""
	end
}
keheluxun:addSkill(keheyoujinex)


kehedailaoCard = sgs.CreateSkillCard{
	name = "kehedailaoCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, player, targets)
		room:showAllCards(player)
		player:drawCards(2,"kehedailao")
		local log = sgs.LogMessage()
		log.type = "$kehedailaolog"
		log.from = player
		room:sendLog(log)
		room:throwEvent(sgs.TurnBroken)
	end 
}

kehedailao = sgs.CreateZeroCardViewAsSkill{
	name = "kehedailao",
	view_as = function(self, cards)
		return kehedailaoCard:clone()
	end,
	enabled_at_play = function(self, player)
		for _,c in sgs.qlist(player:getHandcards()) do
			if c:isAvailable(player)
			then return false end
		end
		return true
	end, 
}
keheluxun:addSkill(kehedailao)

kehezhubei = sgs.CreateTriggerSkill{
	name = "kehezhubei",
	events = {sgs.Damaged,sgs.CardsMoveOneTime,sgs.ConfirmDamage} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.ConfirmDamage) then
			local damage = data:toDamage()
			if damage.from:hasSkill(self:objectName()) and (damage.to:getMark("&kehezhubeida-Clear") > 0) then
				room:sendCompulsoryTriggerLog(damage.from,self)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceHand)
			and move.from:objectName() == player:objectName() 
			and move.is_last_handcard then
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if p:hasSkill(self,true) then
						room:setPlayerMark(player,"&kehezhubeisp-Clear",1)
						break
					end
				end
			end
		end
		if (event == sgs.Damaged) then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:hasSkill(self,true) then
					room:setPlayerMark(player,"&kehezhubeida-Clear",1)
					break
				end
			end
		end
	end,
	can_trigger = function(self, player)
	    return player and player:isAlive()
	end,
}
keheluxun:addSkill(kehezhubei)

kehezhaoyun = sgs.General(extension_he, "kehezhaoyun", "shu", 4,true)

kehelonglin = sgs.CreateTriggerSkill{
	name = "kehelonglin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage,sgs.TargetSpecified,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.TargetSpecified) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and (use.from:getPhase() == sgs.Player_Play) then
				room:addPlayerMark(use.from,"kehelonglinusetimes-PlayClear",1)
				if (use.from:getMark("kehelonglinusetimes-PlayClear") == 1) then
					for _, zy in sgs.qlist(room:getOtherPlayers(use.from))do
						zy:setTag("kehelonglinData",data)
						if zy:hasSkill(self) and zy:canDiscard(zy,"he")
						and room:askForDiscard(zy,self:objectName(),1,1,true,true,"kehelonglin-ask",".",self:objectName()) then
							room:broadcastSkillInvoke(self:objectName())
							local nullified_list = use.nullified_list
							table.insert(nullified_list, "_ALL_TARGETS")
							use.nullified_list = nullified_list
							data:setValue(use)
							local _data = sgs.QVariant()
							_data:setValue(zy)
							local juedou = sgs.Sanguosha:cloneCard("duel")
							juedou:setSkillName("_kehelonglin")
							if use.from:canUse(juedou,zy) and use.from:askForSkillInvoke("kehelonglinjuedou",_data,false) then
								room:setPlayerMark(zy,"kehelonglinzy"..juedou:toString(),1)
								room:useCard(sgs.CardUseStruct(juedou,use.from,zy))    
								room:setPlayerMark(zy,"kehelonglinzy"..juedou:toString(),0)
							end
							juedou:deleteLater() 
						end
					end
				end
			end
		end
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			if damage.card and table.contains(damage.card:getSkillNames(),"kehelonglin")
			and damage.from:getMark("kehelonglinzy"..damage.card:toString())>0 then
				room:setPlayerMark(damage.to,"&kehelonglin-Clear",1)
				room:setPlayerCardLimitation(damage.to, "use,response", ".|.|.|hand", false)
			end
		end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.from == sgs.Player_Play) then
				if (player:getMark("&kehelonglin-Clear") > 0) then
					room:setPlayerMark(player,"&kehelonglin-Clear",0)
					room:removePlayerCardLimitation(player, "use,response", ".|.|.|hand")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target~=nil
	end
}
kehezhaoyun:addSkill(kehelonglin)


kehezhendanCard = sgs.CreateSkillCard{
	name = "kehezhendanCard",
	will_throw = false,
	filter = function(self, targets, to_select, from)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
		then return false end
		if self:getUserString() ~= "" then
			local us = self:getUserString():split("+")
			card = sgs.Sanguosha:cloneCard(us[1])
			card:setSkillName(self:getSkillName())
			card:addSubcard(self)
			card:deleteLater()
			local plist = sgs.PlayerList()
			for i = 1, #targets do plist:append(targets[i]) end
			return card:targetFilter(plist, to_select, from)
		end
	end,
	target_fixed = function(self)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
		then return true end
		if self:getUserString() ~= "" then
			local us = self:getUserString():split("+")
			local card = sgs.Sanguosha:cloneCard(us[1])
			return card and card:targetFixed()
		end
	end,
	feasible = function(self, targets,from)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
		then return true end
		if self:getUserString() ~= "" then
			local us = self:getUserString():split("+")
			local card = sgs.Sanguosha:cloneCard(us[1])
			card:setSkillName(self:getSkillName())
			card:addSubcard(self)
			card:deleteLater()
			local plist = sgs.PlayerList()
			for i = 1, #targets do plist:append(targets[i]) end
			return card:targetsFeasible(plist, from)
		end
	end,
	on_validate = function(self, use)
		local room, user_str = use.from:getRoom(), self:getUserString()
		if user_str == "slash" then
			user_str = sgs.Sanguosha:getSlashNames()
			user_str = table.concat(user_str, "+")
		end
		user_str = room:askForChoice(use.from, "kehezhendan", user_str)
		local use_card = sgs.Sanguosha:cloneCard(user_str)
		use_card:setSkillName("_kehezhendan")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		return use_card
	end,
	on_validate_in_response = function(self, user)
		local room, user_str = user:getRoom(), self:getUserString()
		if user_str == "slash" then
			user_str = sgs.Sanguosha:getSlashNames()
			user_str = table.concat(user_str, "+")
		end
		user_str = room:askForChoice(user, "kehezhendan", user_str)
		local use_card = sgs.Sanguosha:cloneCard(user_str)
		use_card:setSkillName("_kehezhendan")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		return use_card
	end,
}
kehezhendanVS = sgs.CreateViewAsSkill{
	name = "kehezhendan",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return (not to_select:isEquipped()) and (not to_select:isKindOf("BasicCard"))
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="" then
			local dc = sgs.Self:getTag("kehezhendan"):toCard()
			if dc==nil then return end
			pattern = dc:objectName()
		end
		if string.find(pattern,"+") then
			local sc = kehezhendanCard:clone()
			sc:setUserString(pattern)
			for _, card in ipairs(cards) do
				sc:addSubcard(card)
			end
			return sc
		else
			local dc = sgs.Sanguosha:cloneCard(pattern)
			dc:setSkillName(self:objectName())
			for _, card in ipairs(cards) do
				dc:addSubcard(card)
			end
			return dc
		end
	end,
	enabled_at_play = function(self, player)
		if player:getMark("&kehezhendan_lun")>0 then return false end
		for _, patt in ipairs(patterns())do
			local poi = sgs.Sanguosha:cloneCard(patt)
			if poi then
				poi:deleteLater()
				if poi:getTypeId()==1 and poi:isAvailable(player)
				then return true end
			end
		end
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if pattern:startsWith(".") or pattern:startsWith("@")
		or player:getMark("&kehezhendan_lun")>0 then return false end
        if pattern == "peach" and player:getMark("Global_PreventPeach") > 0 then return false end
		for _, patt in ipairs(pattern:split("+"))do
			local poi = sgs.Sanguosha:cloneCard(patt)
			if poi then
				poi:deleteLater()
				if poi:getTypeId()==1
				then return true end
			end
		end
        return false
	end,
}
kehezhendan = sgs.CreateTriggerSkill{
	name = "kehezhendan",
	view_as_skill = kehezhendanVS,
	events = {sgs.Damaged,sgs.RoundEnd,sgs.TurnStart},
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.TurnStart) then
			if player:faceUp() then
			    room:addPlayerMark(player,"kehezhendanhuihe_lun")
			end
		end
		--[[if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				room:addPlayerMark(player,"kehezhendanhuihe_lun",1)
			end
		end]]
		if (event == sgs.Damaged) then
			local damage = data:toDamage()
			if damage.to:hasSkill(self:objectName()) and (damage.to:getMark("&kehezhendan_lun") == 0) then
				local num = 0
				for _, p in sgs.qlist(room:getAllPlayers()) do
					num = num + p:getMark("kehezhendanhuihe_lun")
				end
				room:sendCompulsoryTriggerLog(player,self)
				damage.to:drawCards(math.min(5,num),self:objectName())
				room:setPlayerMark(damage.to,"&kehezhendan_lun",1)
			end
		end
		if (event == sgs.RoundEnd) then
			if (player:getMark("&kehezhendan_lun") == 0) and player:hasSkill(self:objectName()) then
				local num = 0
				for _, p in sgs.qlist(room:getAllPlayers()) do
					num = num + p:getMark("kehezhendanhuihe_lun")
				end
				room:sendCompulsoryTriggerLog(player,self)
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(math.min(5,num),self:objectName())
				room:setPlayerMark(player,"&kehezhendan_lun",1)
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}
kehezhendan:setGuhuoDialog("l")
kehezhaoyun:addSkill(kehezhendan)

kehecaofang = sgs.General(extension_he, "kehecaofang$", "wei", 3,true)

kehezhaotuVS = sgs.CreateViewAsSkill{
	name = "kehezhaotu",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isRed() and (not to_select:isKindOf("TrickCard"))
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local indulgence = sgs.Sanguosha:cloneCard("indulgence")
			indulgence:setSkillName("kehezhaotu")
			indulgence:addSubcard(cards[1])
			return indulgence
		end
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("kehezhaotuuse_lun") == 0)
	end, 
}

kehezhaotu = sgs.CreateTriggerSkill{
	name = "kehezhaotu",
	view_as_skill = kehezhaotuVS,
	events = {sgs.CardUsed,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"kehezhaotu") then
				room:setPlayerMark(use.from,"kehezhaotuuse_lun",1)
				room:setPlayerMark(use.to:at(0),"&kehezhaotu",1)
			end
		end
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_NotActive) then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if (p:getMark("&kehezhaotu") > 0) then
						room:setPlayerMark(p,"&kehezhaotu",0)
						room:addMaxCards(p, -2, true)
						p:gainAnExtraTurn()
					end
				end
			end
		end
	end ,
	can_trigger = function(self, player)
		return player
	end,
}
kehecaofang:addSkill(kehezhaotu)

kehejingjuCard = sgs.CreateSkillCard{
	name = "kehejingjuCard",
	will_throw = false,
	filter = function(self,targets,to_select,from)
		local pattern = self:getUserString()
		local use_card = dummyCard(pattern:split("+")[1])
		if use_card:targetFixed() then return false end
		use_card:setSkillName("kehejingju")
		local plist = sgs.PlayerList()
		for _,p in sgs.list(targets)do
			plist:append(p)
		end
		return use_card:targetFilter(plist,to_select,from)
	end,
	feasible = function(self,targets,from)
		local pattern = self:getUserString()
		local dc = dummyCard(pattern:split("+")[1])
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		return dc:targetFixed() or dc:targetsFeasible(plist, from)
	end,
	on_validate = function(self,use)
		local room = use.from:getRoom()
		local tos = sgs.SPlayerList()
		for _,p in sgs.list(room:getOtherPlayers(use.from))do
			for _,j in sgs.list(p:getJudgingArea())do
				if use.from:containsTrick(j:objectName())
				then continue end
				tos:append(p)
				break
			end
		end
		tos = room:askForPlayerChosen(use.from,tos,"kehejingju","kehejingju0:",false,true)
		if not tos then return nil end
		use.from:peiyin("kehejingju")
		local ids = sgs.IntList()
		for _,j in sgs.list(tos:getJudgingArea())do
			if use.from:containsTrick(j:objectName())
			then ids:append(j:getId()) end
		end
		local id = room:askForCardChosen(use.from,tos,"j","kehejingju",false,sgs.Card_MethodNone,ids)
		if id<0 then return nil end
		room:moveCardTo(sgs.Sanguosha:getCard(id),use.from,sgs.Player_PlaceDelayedTrick)
		local pattern = self:getUserString()
		pattern = room:askForChoice(use.from,"kehejingju",pattern)
		local use_card = dummyCard(pattern)
		use_card:setSkillName("_kehejingju")
		return use_card
	end,
	on_validate_in_response = function(self,from)
		local room = from:getRoom()
		local tos = sgs.SPlayerList()
		for _,p in sgs.list(room:getOtherPlayers(from))do
			for _,j in sgs.list(p:getJudgingArea())do
				if from:containsTrick(j:objectName())
				then continue end
				tos:append(p)
				break
			end
		end
		tos = room:askForPlayerChosen(from,tos,"kehejingju","kehejingju0:",false,true)
		if not tos then return nil end
		from:peiyin("kehejingju")
		local ids = sgs.IntList()
		for _,j in sgs.list(tos:getJudgingArea())do
			if from:containsTrick(j:objectName())
			then ids:append(j:getId()) end
		end
		local id = room:askForCardChosen(from,tos,"j","kehejingju",false,sgs.Card_MethodNone,ids)
		if id<0 then return nil end
		room:moveCardTo(sgs.Sanguosha:getCard(id),from,sgs.Player_PlaceDelayedTrick)
		local pattern = self:getUserString()
		pattern = room:askForChoice(from,"kehejingju",pattern)
		local use_card = dummyCard(pattern)
		use_card:setSkillName("_kehejingju")
		return use_card
	end
}
kehejingju = sgs.CreateViewAsSkill{
	name = "kehejingju",
	guhuo_type = "l",
	view_as = function(self,cards)
		local new_card = kehejingjuCard:clone()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="" then
			local dc = sgs.Self:getTag("kehejingju"):toCard()
			if dc==nil then return end
			pattern = dc:objectName()
		end
		new_card:setUserString(pattern)
		return new_card
	end,
	enabled_at_response = function(self,player,pattern)
		if sgs.Sanguosha:getCurrentCardUseReason()~=sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		for _,p in sgs.list(pattern:split("+"))do
			local dc = dummyCard(p)
			if dc and dc:getTypeId()==1 then
				dc:setSkillName("kehejingju")
				if player:isLocked(dc) then continue end
				for _,ap in sgs.list(player:getAliveSiblings())do
					for _,j in sgs.list(ap:getJudgingArea())do
						if player:containsTrick(j:objectName())
						then continue end
						return true
					end
				end
				break
			end
		end
	end,
	enabled_at_play = function(self,player)
		for _,p in sgs.list(patterns())do
			local dc = dummyCard(p)
			if dc and dc:getTypeId()==1 and dc:isAvailable(player) then
				for _,ap in sgs.list(player:getAliveSiblings())do
					for _,j in sgs.list(ap:getJudgingArea())do
						if player:containsTrick(j:objectName())
						then continue end
						return true
					end
				end
				break
			end
		end
		return false
	end,
}
kehecaofang:addSkill(kehejingju)

keheweizhui = sgs.CreateTriggerSkill{
	name = "keheweizhui$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart
		and player:getPhase() == sgs.Player_Finish
		and player:getKingdom() == "wei" then
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:getHandcardNum()>0 and p:hasLordSkill(self:objectName()) then
					local ghcq = dummyCard("dismantlement")
					ghcq:setSkillName("keheweizhui")
					local ids = {}
					for _,c in sgs.qlist(player:getCards("h")) do
						if c:isBlack() then
							ghcq:addSubcard(c)
							if player:canUse(ghcq,p) then
								table.insert(ids,c:getId())
							end
							ghcq:clearSubcards()
						end
					end
					if #ids<1 then continue end
					player:setTag("keheweizhuiFrom",ToData(p))
					local dc = room:askForExchange(player, "keheweizhui", 1, 1, false, "keheweizhuiask:"..p:objectName(),true,table.concat(ids,","))
					if dc then
						ghcq:addSubcard(dc)
						room:useCard(sgs.CardUseStruct(ghcq, player, p))
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}
kehecaofang:addSkill(keheweizhui)

kehesunjun = sgs.General(extension_he, "kehesunjun", "wu", 4,true)

keheyaoyan = sgs.CreateTriggerSkill{
	name = "keheyaoyan",
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Start) then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:setPlayerMark(player,"willyaoyanyishi-Clear",1)
					room:broadcastSkillInvoke(self:objectName())
					for _, p in sgs.qlist(room:getAllPlayers()) do
						room:doAnimate(1,player:objectName(),p:objectName())
					end
					for _, p in sgs.qlist(room:getAllPlayers()) do
						if room:askForChoice(p,"keheyaoyan","join+notjoin") == "join" then	
							room:setPlayerMark(p,"&keheyaoyanjoin-Clear",1)
						end
					end
				end
			end
			if player:getPhase() == sgs.Player_Finish and player:getMark("willyaoyanyishi-Clear")>0 then
				local yaoyanplayers = sgs.SPlayerList()
				for _,pp in sgs.qlist(room:getAllPlayers()) do
					if pp:getMark("&keheyaoyanjoin-Clear") > 0
					then yaoyanplayers:append(pp) end
				end
				room:broadcastSkillInvoke(self:objectName())
				local ys = {}
				ys.reason = self:objectName()
				ys.from = player
				ys.tos = yaoyanplayers
				ys.effect = function(ys_data)
					if (ys_data.result == "red") then
						local notjoins = sgs.SPlayerList()
						for _,pp in sgs.qlist(room:getAllPlayers()) do
							if table.contains(ys_data.tos,pp:objectName()) then continue end
							notjoins:append(pp)
						end
						local daomeidan = room:askForPlayersChosen(player, notjoins, self:objectName(), 0, 99, "keheyaoyanget-ask", false, true)
						for _,dmd in sgs.qlist(daomeidan)do
							if not dmd:isKongcheng() then
								local id = room:askForCardChosen(player, dmd, "h", self:objectName())
								local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
								room:obtainCard(player, sgs.Sanguosha:getCard(id), reason, false)
							end
						end
					elseif (ys_data.result == "black") then
						local joins = sgs.SPlayerList()
						for _,pp in sgs.qlist(room:getAllPlayers()) do
							if table.contains(ys_data.tos,pp:objectName())
							then joins:append(pp) end
						end
						local eny = room:askForPlayerChosen(player, joins, self:objectName(), "keheyaoyandamage-ask", true, true)
						if eny then
							room:damage(sgs.DamageStruct(self:objectName(), player, eny, 2))
						end	
					end
				end
				room:setTag("keheyaoyanFrom", ToData(player))
				askYishi(ys)
				room:removeTag("keheyaoyanFrom")
				--[[
				for _,p in sgs.qlist(yaoyanplayers) do
					room:setPlayerMark(p,"keyishiing",1)
					--每个人提前挑选牌准备展示
					if not p:isKongcheng() then
						local id = room:askForExchange(p, "keheyaoyan", 1, 1, false, "keqichaozheng_yishi"):getSubcards():first()
						local card = sgs.Sanguosha:getCard(id)
						room:setCardFlag(card,"useforyishi")
						if card:isRed() then
							room:setPlayerMark(p,"keyishi_red",1)
						elseif card:isBlack() then
							room:setPlayerMark(p,"keyishi_black",1)
						end
						--标记选择了牌的人（没有空城的人）
						room:setPlayerMark(p,"chooseyishi",1)
					end
				end
				--依次展示选好的牌，公平公正公开
				local sj = room:findPlayerBySkillName("kehebazheng")
				if sj then
					for _,bz in sgs.qlist(room:getAllPlayers()) do
						if (bz:getMark("&kehebazheng-Clear") > 0) then
							if (sj:getMark("keyishi_red") > 0) and (bz:getMark("keyishi_black") > 0) then
								room:setPlayerMark(bz,"keyishi_black",0)
								room:setPlayerMark(bz,"keyishi_red",1)
								local log = sgs.LogMessage()
								log.type = "$kehebazhengredlog"
								log.from = bz
								log.to:append(sj)
								room:sendLog(log)
							elseif (sj:getMark("keyishi_black") > 0) and (bz:getMark("keyishi_red") > 0) then
								room:setPlayerMark(bz,"keyishi_black",1)
								room:setPlayerMark(bz,"keyishi_red",0)
								local log = sgs.LogMessage()
								log.type = "$kehebazhengblacklog"
								log.from = bz
								log.to:append(sj)
								room:sendLog(log)
							end
						end
					end
				end
				room:getThread():delay(800)
				local yishirednum = 0
				local yishiblacknum = 0
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if (p:getMark("keyishi_black") > 0) then yishiblacknum = yishiblacknum + 1 end
					if (p:getMark("keyishi_red") > 0) then yishirednum = yishirednum + 1 end
					for _,c in sgs.qlist(p:getCards("h")) do
						if c:hasFlag("useforyishi") then
							--if c:isRed() then yishirednum = yishirednum + 1 end
							--if c:isBlack() then yishiblacknum = yishiblacknum + 1 end
							room:showCard(p,c:getEffectiveId())
							room:setCardFlag(c,"-useforyishi")
							break
						end
					end
				end
				room:getThread():delay(1200)
				--0为平局（默认），1：红色；2：黑色
				local yishiresult = 0
				if (yishirednum > yishiblacknum) then
					yishiresult = 1
					local log = sgs.LogMessage()
					log.type = "$keyishired"
					log.from = player
					room:sendLog(log)	
					room:doLightbox("$keyishired")
				elseif (yishirednum < yishiblacknum) then
					yishiresult = 2
					local log = sgs.LogMessage()
					log.type = "$keyishiblack"
					log.from = player
					room:sendLog(log)	
					room:doLightbox("$keyishiblack")
				elseif (yishirednum == yishiblacknum) then
					yishiresult = 0
					local log = sgs.LogMessage()
					log.type = "$keyishipingju"
					log.from = player
					room:sendLog(log)	
					room:doLightbox("$keyishipingju")
				end
				--效果：
				if (yishiresult == 1) then
					local daomeidan = room:askForPlayersChosen(player, notjoins, self:objectName(), 0, 99, "keheyaoyanget-ask", false, true)
					for _,dmd in sgs.qlist(daomeidan) do
						if not dmd:isKongcheng() then
							local card_id = room:askForCardChosen(player, dmd, "h", self:objectName())
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
							room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
						end
					end
				elseif (yishiresult == 2) then
					local eny = room:askForPlayerChosen(player, yaoyanplayers, self:objectName(), "keheyaoyandamage-ask", true, true)
					if eny then
						room:damage(sgs.DamageStruct(self:objectName(), player, eny, 2))
					end	
				end--]]
			end
		end
	end	
}
kehesunjun:addSkill(keheyaoyan)

kehebazheng = sgs.CreateTriggerSkill{
	name = "kehebazheng",
	events = {sgs.Damage,sgs.EventForDiy},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target~=nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			if player:isAlive() and player ~= damage.to and player:hasSkill(self:objectName()) then
				room:setPlayerMark(damage.to,"&kehebazheng+#"..player:objectName().."-Clear",1)
			end
		else
			local str = data:toString()
			if str:startsWith("yishiresult:") then
				local strs = str:split(":")
				for _, pn in sgs.list(strs[4]:split("+"))do
					local p = room:findPlayerByObjectName(pn)
					local id = p:getMark("kehebazhengTid")
					if id>0 then
						local cs = sgs.CardList()
						cs:append(sgs.Sanguosha:getCard(id-1))
						room:filterCards(p,cs,true)
						p:setMark("kehebazhengTid",0)
					end
					p:setMark("kehebazhengFid",0)
				end
			elseif str:startsWith("askyishicard:") then
				local strs = str:split(":")
				if player:hasSkill(self) then
					local dc = room:askForExchange(player, strs[2], 1, 1, false, "askyishicard")
					table.insert(strs,dc:getEffectiveId())
					player:setMark("kehebazhengFid",strs[5]+1)
					for _, p in sgs.qlist(room:getAllPlayers())do
						if table.contains(strs[4]:split("+"),p:objectName())
						and p:getMark("&kehebazheng+#"..player:objectName().."-Clear")>0 then
							local tid = p:getMark("kehebazhengTid")
							if tid<1 then continue end
							tid = tid-1
							room:sendCompulsoryTriggerLog(player,self)
							local wc = sgs.Sanguosha:getWrappedCard(tid)
							wc:setSkillName(self:objectName())
							wc:setSuit(dc:getSuit())
							room:broadcastUpdateCard(room:getPlayers(),tid,wc)
						end
					end
				end
				for _, p in sgs.qlist(room:getAllPlayers())do
					if p:hasSkill(self) and table.contains(strs[4]:split("+"),p:objectName())
					and player:getMark("&kehebazheng+#"..p:objectName().."-Clear")>0 then
						if #strs<5 then
							local dc = room:askForExchange(player, strs[2], 1, 1, false, "askyishicard")
							table.insert(strs,dc:getEffectiveId())
							player:setMark("kehebazhengTid",strs[5]+1)
						end
						local fid = p:getMark("kehebazhengFid")
						if fid<1 then continue end
						fid = fid-1
						room:sendCompulsoryTriggerLog(p,self)
						local c = sgs.Sanguosha:getCard(fid)
						local wc = sgs.Sanguosha:getWrappedCard(strs[5])
						wc:setSkillName(self:objectName())
						wc:setSuit(c:getSuit())
						room:broadcastUpdateCard(room:getPlayers(),strs[5],wc)
					end
				end
				data:setValue(table.concat(strs,":"))
			end
		end
	end	
}
kehesunjun:addSkill(kehebazheng)

keheguoxun = sgs.General(extension_he, "keheguoxun", "wei", 4,true)

kehexumouusevs = sgs.CreateViewAsSkill{
	name = "kehexumouuse",
	response_pattern = "@@kehexumouuse",
	expand_pile = "#kehexumou",
	n = 1,
	view_filter = function(self, selected, to_select)
		return sgs.Self:getPileName(to_select:getId())=="#kehexumou"
		and to_select:isAvailable(sgs.Self)
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	view_as = function(self,cards)
		if #cards>0 then
			return cards[1]
		end
	end
}
kehexumouuse = sgs.CreateTriggerSkill{
	name = "kehexumouuse",
	global = true,
	view_as_skill = kehexumouusevs,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local xmcn = {}
		local dc = sgs.Sanguosha:cloneCard("slash")
		local jcs = player:getJudgingArea()
		while jcs:length()>0 do
			local jc = jcs:last()
			jcs:removeOne(jc)
			if string.find(jc:objectName(),"kehexumou") then
				local id = jc:getEffectiveId()
				local xmc = sgs.Sanguosha:getEngineCard(id)
				local m_name = xmc:objectName()
				if xmc:isKindOf("Slash") then m_name = "slash" end
				if table.contains(xmcn,m_name) then continue end
				local cs = sgs.CardList()
				cs:append(xmc)
				room:filterCards(player,cs,true)
				local js = sgs.IntList()
				js:append(id)
	           	room:notifyMoveToPile(player,js,"kehexumou",sgs.Player_PlaceDelayedTrick,true)
				local has = room:askForUseCard(player,"@@kehexumouuse","kehexumouuse-ask:"..m_name,-1,sgs.Card_MethodUse,false,player,nil,"xumoucard")
	           	room:notifyMoveToPile(player,js,"kehexumou",sgs.Player_PlaceDelayedTrick,false)
				if not has then dc:addSubcard(id) break end
				table.insert(xmcn,m_name)
				jcs = player:getJudgingArea()
			end
		end
		for _,c in sgs.qlist(player:getJudgingArea())do
			if string.find(c:objectName(),"kehexumou")
			then dc:addSubcard(c) end
		end
		dc:deleteLater()
		if dc:subcardsLength()<1 then return end
		room:throwCard(dc, "#kehexumou", nil)
	end,
	can_trigger = function(self, target)
		return target and target:getPhase()==sgs.Player_Judge
		and target:getJudgingArea():length()>0
	end
}
extension_he:addSkills(kehexumouuse)
function xumouCard(player,card)
	local ids = {card}
	if type(card)~="number" and card:isVirtualCard()
	then ids = card:getSubcards() end
	local room = player:getRoom()
	local tos = sgs.SPlayerList()
	tos:append(player)
	for _,id in sgs.list(ids)do
		local n = 1
		for _,c in sgs.qlist(player:getJudgingArea())do
			if string.find(c:objectName(),"kehexumou")
			then n = n+1 end
		end
		if n>9 or not player:hasJudgeArea() then return false end
		local xm = sgs.Sanguosha:cloneCard("__kehexumou"..n,6,0)
		xm:addSubcard(id)
		room:moveCardTo(xm,player,sgs.Player_PlaceTable,false)
		xm:use(room,player,tos)
	end
	return true
end

keheeqianjl = sgs.CreateDistanceSkill{
	name = "#keheeqianjl",
	correct_func = function(self, from, to)
		return 2*to:getMark("&keheeqian+#"..from:objectName().."-Clear")
	end,
}
keheguoxun:addSkill(keheeqianjl)

keheeqian = sgs.CreateTriggerSkill{
	name = "keheeqian",
	waked_skills = "#keheeqianjl",
	events = {sgs.EventPhaseStart,sgs.TargetSpecified,sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.from and use.card:hasFlag("xumoucard") then
				room:setPlayerMark(use.from,use.card:objectName().."+-Clear",1)
			end
		end
		if (event == sgs.TargetSpecified) and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if (use.card:isKindOf("Slash") or use.card:hasFlag("xumoucard"))
			and (use.to:length() == 1) and (use.to:at(0) ~= player) then
				local to_data = sgs.QVariant()
				to_data:setValue(use.to:at(0))
				if room:askForSkillInvoke(player,self:objectName(), to_data) then
					room:broadcastSkillInvoke(self:objectName())
					local eny = use.to:at(0)
					use.m_addHistory = false
					data:setValue(use)
					if not eny:isNude() then
						local card_id = room:askForCardChosen(player, eny, "he", self:objectName())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
						room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
					end
					if room:askForChoice(eny,self:objectName(),"add+cancel",data) == "add" then 
						room:addPlayerMark(eny,"&keheeqian+#"..player:objectName().."-Clear")
					end
				end
			end
		end
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Finish) and player:hasSkill(self:objectName()) then
				while player:isAlive() and player:getHandcardNum()>0 and player:hasJudgeArea() do
					local n = 0
					for _,c in sgs.qlist(player:getCards("j"))do
						if string.find(c:objectName(),"kehexumou")
						then n = n+1 end
					end
					if n>=9 then break end
					local dc = room:askForExchange(player, self:objectName(), 9-n, 1, false, "keheeqian-ask",true)
					if dc and xumouCard(player,dc)
					then else break end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}
keheguoxun:addSkill(keheeqian)

kehefushaCard = sgs.CreateSkillCard{
	name = "kehefushaCard" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return (#targets == 0) and (to_select:objectName() ~= player:objectName()) 
		and (player:inMyAttackRange(to_select))
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:removePlayerMark(player,"@kehefusha")
		room:doSuperLightbox("keheguoxun", "kehefusha")
		room:damage(sgs.DamageStruct(self:objectName(), player, target,math.min(player:getAttackRange(),room:getPlayers():length())))
	end
}

kehefusha = sgs.CreateZeroCardViewAsSkill{
	name = "kehefusha",
	frequency = sgs.Skill_Limited,
	limit_mark = "@kehefusha",
	enabled_at_play = function(self, player)
		local num = 0
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if player:inMyAttackRange(p) then
				num = num + 1
			end
		end
		if (num == 1) then 
		    return (player:getMark("@kehefusha") > 0)
		end
	end,
	view_as = function()
		return kehefushaCard:clone()
	end
}
keheguoxun:addSkill(kehefusha)


keheerhu = sgs.General(extension_he, "keheerhu", "wu", 3,false)

kehedaimou = sgs.CreateTriggerSkill {
	name = "kehedaimou",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					for _, pp in sgs.qlist(use.to) do
						if pp~=p then
							if p:getMark("usedaimouone-Clear")<1
							and p:askForSkillInvoke(self, data) then
								room:broadcastSkillInvoke(self:objectName(),math.random(1,2))
								room:setPlayerMark(p,"usedaimouone-Clear",1)
								xumouCard(p,room:getDrawPile():first())
							end
							break
						end
					end
					--包含你
					if use.to:contains(p) and p:getMark("usedaimoutwo-Clear")<1 then
						local ids = sgs.IntList()
						for _,c in sgs.qlist(p:getJudgingArea()) do
							if string.find(c:objectName(),"kehexumou") and p:canDiscard(p,c:getEffectiveId())
							then ids:append(c:getEffectiveId()) end
						end
						if ids:length()>0 then
							room:sendCompulsoryTriggerLog(p,self,math.random(3,4))
							room:setPlayerMark(p,"usedaimoutwo-Clear",1)
							room:fillAG(ids,p)
							local id = room:askForAG(p, ids, false, self:objectName())
							room:clearAG(p)
							if id>=0 then room:throwCard(id, self:objectName(), p, p) end
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
keheerhu:addSkill(kehedaimou)

kehefangjie = sgs.CreateTriggerSkill{
	name = "kehefangjie",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Start) then
				local ids = sgs.IntList()
				local hasxm = 0
				for _,c in sgs.qlist(player:getJudgingArea()) do
					if string.find(c:objectName(),"kehexumou") then hasxm = hasxm+1
					else ids:append(c:getEffectiveId()) end
				end
				if hasxm>0 then
					if player:askForSkillInvoke(self, data) then
						room:broadcastSkillInvoke(self,math.random(3,4))
						local dc = sgs.Sanguosha:cloneCard("slash")
						dc:deleteLater()
						for i=1,hasxm do
							local id = room:askForCardChosen(player,player,"j",self:objectName(),false,sgs.Card_MethodDiscard,ids,i>1)
							if id>=0 then
								dc:addSubcard(id)
								ids:append(id)
							else break end
						end
						if dc:subcardsLength()>0 then
							room:throwCard(dc,self:objectName(),player)
							room:handleAcquireDetachSkills(player, "-kehefangjie")
						end
					end
				else
					room:sendCompulsoryTriggerLog(player,self,math.random(1,2))
					room:recover(player, sgs.RecoverStruct(self:objectName(),player))
					player:drawCards(1,self:objectName())
				end
			end
		end
	end,
	--[[can_trigger = function(self, player)
		return player
	end,]]
}
keheerhu:addSkill(kehefangjie)


keheweiwenzhugezhi = sgs.General(extension_he, "keheweiwenzhugezhi", "wu", 4,true)

kehefuhaiCard = sgs.CreateSkillCard{
	name = "kehefuhaiCard" ,
	target_fixed = true ,
	on_use = function(self, room, player, targets)
		--准备选择牌，记录
		local shows = {}
		local tos = room:getOtherPlayers(player)
		for _, p in sgs.qlist(tos) do
			if p:isKongcheng() then continue end
			shows[p:objectName()] = room:askForExchange(p, "kehefuhai", 1, 1, false, "kehefuhai-ask")
		end
		--依次展示记录的牌
		for _, p in sgs.qlist(tos) do
			if p:isKongcheng() then continue end
			room:showCard(p,shows[p:objectName()]:getEffectiveId())
		end
		--选方向
		tos = sgs.QList2Table(tos)
		if room:askForChoice(player,"kehefuhai","ssz+nsz")=="ssz"
		then tos = sgs.reverse(tos) end
		local c,n
		for i,p in ipairs(tos) do
			c = shows[p:objectName()]
			n = i
			if c then break end
		end
		local a,b,x = c:getNumber(),0,1
		table.remove(tos,n)
		for i,p in ipairs(tos) do
			c = shows[p:objectName()]
			if not c then continue end
			if i==1
			then
				if c:getNumber()>a then b = 1
				elseif c:getNumber()<a then b = -1
				else break end
				x = x+1
			elseif b==1 and c:getNumber()>a
			or b==-1 and c:getNumber()<a
			then x = x+1
			else break end
			a = c:getNumber()
		end
		player:drawCards(x,"kehefuhai")
	end
}
kehefuhai = sgs.CreateViewAsSkill{
	name = "kehefuhai" ,
	view_as = function(self, cards)
		return kehefuhaiCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kehefuhaiCard")
	end
}
keheweiwenzhugezhi:addSkill(kehefuhai)



keheguozhao = sgs.General(extension_he, "keheguozhao", "wei", 3,false)

kehepianchong = sgs.CreateTriggerSkill{
	name = "kehepianchong",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if (move.to_place == sgs.Player_DiscardPile) and player:hasSkill(self,true) then
				for _,id in sgs.qlist(move.card_ids) do
					local cs = sgs.Sanguosha:getCard(id):getColorString()
					room:addPlayerMark(player,cs.."kehepianchongcount-Clear")
				end
			end
			if ((move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and move.from:objectName() == player:objectName())
			and not((move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip) and move.to:objectName() == player:objectName())
			and player:hasSkill(self) then
				room:setPlayerMark(player,"&kehepianchong-Clear",1)
			end
		end
		if (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Finish) then	
			for _, gz in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if gz:getMark("&kehepianchong-Clear")>0 --[[and gz:askForSkillInvoke(self, data)]] then 
				    room:sendCompulsoryTriggerLog(gz,self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = "."
					judge.good = true
					judge.play_animation = true
					judge.who = gz
					judge.reason = self:objectName()
					room:judge(judge)
					local n = gz:getMark(judge.card:getColorString().."kehepianchongcount-Clear")
					local all = 0
					for _,m in sgs.list(gz:getMarkNames())do
						if m:endsWith("kehepianchongcount-Clear")
						and gz:getMark(m)>0 then all = gz:getMark(m) end
					end
					local oth = all - n
					if n >= oth then
						gz:drawCards(1,self:objectName())
					else
						room:askForDiscard(gz, self:objectName(), 1, 1, false, true, "kehepianchong-discard")
					end
					--gz:drawCards(math.min(n,gz:getMaxHp()),self:objectName())
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
}
keheguozhao:addSkill(kehepianchong)
keheguozhao:addSkill("zunwei")


kehegaoxiang = sgs.General(extension_he, "kehegaoxiang", "shu", 4,true)

kehechiyingCard = sgs.CreateSkillCard{
	name = "kehechiyingCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets < 1) 
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		local alldis = sgs.IntList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do 
			if target:inMyAttackRange(p) and not p:isNude() then
				local dis = room:askForDiscard(p, "kehechiying", 1, 1, false,true,"kehechiying-ask") 
				if dis then alldis:append(dis:getEffectiveId()) end
			end
		end
		room:getThread():delay(800)
		if (alldis:length() > 0) then
			local dummy = sgs.Sanguosha:cloneCard("slash")
			for _, id in sgs.qlist(alldis) do
				if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
					dummy:addSubcard(id)
				end
			end
			dummy:deleteLater()
			if (dummy:subcardsLength() <= target:getHp()) then
				alldis = dummy:getSubcards()
				dummy:clearSubcards()
				for _, id in sgs.qlist(alldis) do
					if room:getCardPlace(id)==sgs.Player_DiscardPile then
						dummy:addSubcard(id)
					end
				end
				target:obtainCard(dummy)
			end
		end
	end
}
--主技能
kehechiying = sgs.CreateViewAsSkill{
	name = "kehechiying",
	n = 0,
	view_as = function(self, cards)
		return kehechiyingCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#kehechiyingCard")) 
	end, 
}
kehegaoxiang:addSkill(kehechiying)

keheliuyong = sgs.General(extension_he, "keheliuyong", "shu", 3,true)

kehedanxinVS = sgs.CreateOneCardViewAsSkill{
	name = "kehedanxin", 
	filter_pattern = ".",
	view_as = function(self, card) 
		local acard = sgs.Sanguosha:cloneCard("_kecheng_tuixinzhifu")
		acard:setSkillName("kehedanxin")
		acard:addSubcard(card)
		return acard
	end, 
}

kehedanxin = sgs.CreateTriggerSkill{
	name = "kehedanxin",
	events = {sgs.CardFinished} ,
	view_as_skill = kehedanxinVS,
	waked_skills = "#kehedanxinex",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"kehedanxin") then
				for _, p in sgs.qlist(use.to) do 
				    room:addPlayerMark(p,player:objectName().."kehedanxinjuli-Clear")
				end
			end
		end
	end,
}
keheliuyong:addSkill(kehedanxin)

kehedanxinex = sgs.CreateDistanceSkill{
	name = "#kehedanxinex",
	correct_func = function(self, from,to)
		return to:getMark(from:objectName().."kehedanxinjuli-Clear")
	end,
}
keheliuyong:addSkill(kehedanxinex)

kehefengxiang = sgs.CreateTriggerSkill{
	name = "kehefengxiang",
	events = {sgs.Damaged} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damaged) then
			local damage = data:toDamage()
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "kehefengxiang-ask",false,true)
			if target then
				room:broadcastSkillInvoke(self:objectName())
				local orinum = player:getEquips():length()
				local exchangeMove = sgs.CardsMoveList()
				local move1 = sgs.CardsMoveStruct(player:getEquipsId(), target, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), target:objectName(), "kehefengxiang", ""))
				local move2 = sgs.CardsMoveStruct(target:getEquipsId(), player, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, target:objectName(), player:objectName(), "kehefengxiang", ""))
				exchangeMove:append(move1)
				exchangeMove:append(move2)	
				room:moveCardsAtomic(exchangeMove, false)
				local twonum = player:getEquips():length()
				if orinum-twonum>0 then
					player:drawCards(orinum-twonum,self:objectName())
				end
			end
		end
	end,
}
keheliuyong:addSkill(kehefengxiang)


--搬运

kehezhugeliangpre = sgs.General(extension_he, "kehezhugeliangpre", "shu", 3,true,true)

--[[kehewentianCard = sgs.CreateSkillCard{
	name = "kehewentianCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select, player)
		local qtargets = sgs.PlayerList()
		for _,p in ipairs(targets) do
			qtargets:append(p)
		end
		local huogong = sgs.Sanguosha:cloneCard("FireAttack")
		return huogong and huogong:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, card, qtargets)
		--return (#targets < 1) and (not to_select:isKongcheng())
	end,
	on_use = function(self, room, player, targets)
		--local target = targets[1]
		local qtargets = sgs.SPlayerList()
		for _,p in ipairs(targets) do
			qtargets:append(p)
		end
	    local card_id = room:getNCards(1):first()
		local card = sgs.Sanguosha:getCard(card_id)
		local huogong = sgs.Sanguosha:cloneCard("FireAttack", card:getSuit(), card:getNumber())
		huogong:addSubcard(card)
		huogong:setSkillName("kehewentian")
		local card_use = sgs.CardUseStruct()
		card_use.from = player
		card_use.to = qtargets
		card_use.card = huogong
		room:useCard(card_use, false)
		huogong:deleteLater() 
	end 
}

kehewentianVS = sgs.CreateViewAsSkill{
	name = "kehewentian",
	n = 0,
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern and (pattern == "nullification") then
			return kehewentianwxCard:clone()
		else
		    return kehewentianCard:clone()
		end
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("&bankehewentian") == 0)
	end, 
    enabled_at_response = function(self,player,pattern)
	   	return ((player:getMark("&bankehewentian") == 0) and (pattern == "nullification")) 
	end,
	enabled_at_nullification = function(self,player)				
		return (player:getMark("&bankehewentian") == 0) 
	end
}

kehewentian = sgs.CreateTriggerSkill{
	name = "kehewentian",
	--frequency = sgs.Skill_NotFrequent,
	view_as_skill = kehewentianVS,
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseStart,sgs.PreCardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) 
		and (player:getMark("usedkehewentian-Clear") == 0)
		and (player:getPhase() ~= sgs.Player_NotActive) then	
			if room:askForSkillInvoke(player,self:objectName(), data) then
				room:setPlayerMark(player,"usedkehewentian-Clear",1)
				local card_ids = room:getNCards(5)
				room:fillAG(card_ids)
				local to_get = sgs.IntList()
				local to_guanxing = sgs.IntList()
				--选牌给人
				local card_id = room:askForAG(player, card_ids, false, "kehewentian")
				card_ids:removeOne(card_id)
				to_get:append(card_id)
				local card = sgs.Sanguosha:getCard(card_id)
				room:takeAG(player, card_id, false)
				local fri = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "kehewentian-ask")
				if fri then
					fri:obtainCard(card)
				end
				room:clearAG()
				--开始观星
				room:askForGuanxing(player,card_ids)
			end
		end
		
	end,
}]]
kehewentianpreVS = sgs.CreateViewAsSkill{
	name = "kehewentianpre",
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "nullification" then
			local use_card = sgs.Sanguosha:cloneCard("nullification")
			use_card:addSubcard(sgs.Self:getMark("kehewentianId"))
			use_card:setSkillName("kehewentian")
			return use_card
		else
			local use_card = sgs.Sanguosha:cloneCard("fire_attack")
			use_card:addSubcard(sgs.Self:getMark("kehewentianId"))
			use_card:setSkillName("kehewentian")
			return use_card
		end
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("&bankehewentian_lun") == 0)
	end, 
    enabled_at_response = function(self,player,pattern)
	   	return ((player:getMark("&bankehewentian_lun") == 0) and (pattern == "nullification")) 
	end,
	enabled_at_nullification = function(self,player)				
		return (player:getMark("&bankehewentian_lun") == 0) 
	end
}
kehewentianpre = sgs.CreateTriggerSkill{
	name = "kehewentianpre",
	view_as_skill = kehewentianpreVS,
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseStart,sgs.PreCardUsed,sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart)
		and (player:getMark("usedkehewentian-Clear") == 0)
		--一般主阶段列举
		and ((player:getPhase() == sgs.Player_Start) 
		or (player:getPhase() == sgs.Player_Judge)
		or (player:getPhase() == sgs.Player_Draw)
		or (player:getPhase() == sgs.Player_Play)
		or (player:getPhase() == sgs.Player_Discard)
		or (player:getPhase() == sgs.Player_Finish)
	    )
		then	
			if (player:getMark("&bankehewentian_lun") == 0) and room:askForSkillInvoke(player,self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:setPlayerMark(player,"usedkehewentian-Clear",1)
				local card_ids = room:getNCards(5)
				room:fillAG(card_ids,player)
				--选牌给人
				local duiyounum = 0
				if (player:getState() ~= "online") then
					for _,other in sgs.qlist(room:getOtherPlayers(player)) do
						if (player:isYourFriend(other)) then
							duiyounum = 1 
							break 
						end
					end
				end
				local card_id 
				--电脑且没有队友
				if (player:getState() ~= "online") and (duiyounum == 0) then
					card_id = -1
				else
				    card_id = room:askForAG(player, card_ids, true, "kehewentian","kehewentianchoose-ask")
				end
				if not (card_id == -1) then
					room:takeAG(nil, card_id, false)
					local fri = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "kehewentian-ask",false)
					if fri then
						if (player:getState() == "online") then
							if sgs.Sanguosha:getCard(card_id):isRed() then
								room:setPlayerFlag(fri,"kehewentianred")
							else
								room:setPlayerFlag(fri,"kehewentianblack")
							end
						end
						card_ids:removeOne(card_id)
						fri:obtainCard(sgs.Sanguosha:getCard(card_id))
					end
				end	
				room:clearAG()
				--开始观星
				room:askForGuanxing(player,card_ids)
			end
		end
		if (event == sgs.CardsMoveOneTime)
		then
	     	local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_DrawPile or move.from_places:contains(sgs.Player_DrawPile)
			then room:setPlayerMark(player,"kehewentianId",room:getDrawPile():first()) end
		end
		if (event == sgs.PreCardUsed)
		then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"kehewentian") then
				if use.card:isKindOf("Nullification") and not use.card:isBlack()
				or use.card:isKindOf("FireAttack") and not use.card:isRed()
				then room:addPlayerMark(player,"&bankehewentian_lun") end
			end
		end
		if (event == sgs.Death) then
			local death = data:toDeath()
			if death.who:hasSkill(self:objectName()) then
				local reason = death.damage
				if not reason then
				    room:broadcastSkillInvoke("kehewentiancaidan")
				else
					local killer = reason.from
					if not killer then
				        room:broadcastSkillInvoke("kehewentiancaidan")
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill(self:objectName())
	end,
}
kehezhugeliangpre:addSkill(kehewentianpre)

kehezhugeliangpre:addSkill("kehechushi")

keheyinluepre = sgs.CreateTriggerSkill{
	name = "keheyinluepre",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.DamageInflicted) then
			local damage = data:toDamage()
			if (damage.nature == sgs.DamageStruct_Fire) then
				for _, zgl in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if (zgl:getMark("&keheyinluemp") == 0) then
						local to_data = sgs.QVariant()
						to_data:setValue(damage.to)
						if room:askForSkillInvoke(zgl, self:objectName(), to_data) then
							room:broadcastSkillInvoke(self:objectName())
							room:setPlayerMark(zgl,"&keheyinluemp",1)
							return true
						end
					end
				end
			elseif (damage.nature == sgs.DamageStruct_Thunder) then
				for _, zgl in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if (zgl:getMark("&keheyinlueqp") == 0) then
						local to_data = sgs.QVariant()
						to_data:setValue(damage.to)
						if room:askForSkillInvoke(zgl, self:objectName(), to_data) then
							room:broadcastSkillInvoke(self:objectName())
							room:setPlayerMark(zgl,"&keheyinlueqp",1)
							return true
						end
					end
				end
			end
		end
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_NotActive) then
				for _, zgl in sgs.qlist(room:getAllPlayers()) do
					if (zgl:getMark("&keheyinluemp") > 0) then
						room:setPlayerMark(zgl,"&keheyinluemp",0)
						local phases = sgs.PhaseList()
						phases:append(sgs.Player_Draw)
						zgl:gainAnExtraTurn(phases)
					end
					if (zgl:getMark("&keheyinlueqp") > 0) then
						room:setPlayerMark(zgl,"&keheyinlueqp",0)
						local phases = sgs.PhaseList()
						phases:append(sgs.Player_Discard)
						zgl:gainAnExtraTurn(phases)
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kehezhugeliangpre:addSkill(keheyinluepre)

kehecaoshuang = sgs.General(extension_he, "kehecaoshuang", "wei", 4,true,true)
kehecaoshuang:addSkill("tuogu")
kehecaoshuang:addSkill("shanzhuan")

kehechentai = sgs.General(extension_he, "kehechentai", "wei", 4,true,true)

kehejiuxian = sgs.CreateViewAsSkill{
    name = "kehejiuxian",
    n = 999,
    view_filter = function(self, selected, to_select)
        return sgs.Self:getHandcards():contains(to_select)
        and #selected < math.ceil(sgs.Self:getHandcardNum()/2)
    end,
    view_as = function(self, cards)
        if #cards > 0 and #cards == math.ceil(sgs.Self:getHandcardNum()/2) then
            local cc = kehejiuxianCard:clone()
            for _,card in ipairs(cards) do
                cc:addSubcard(card)
            end
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#kehejiuxian")
    end,
}

kehejiuxianCard = sgs.CreateSkillCard{
    name = "kehejiuxian",
    will_throw = false,
    handling_method = sgs.Card_MethodRecast,
    filter = function(self, targets, to_select, player)
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
    
        local duel = sgs.Sanguosha:cloneCard("duel")
        duel:setSkillName("kehejiuxian")

        duel:deleteLater()
        return duel:targetFilter(qtargets,to_select,player)
    end,
    feasible = function(self, targets, player)
        local duel = sgs.Sanguosha:cloneCard("duel")
        duel:setSkillName("kehejiuxian")
        duel:deleteLater()
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
        return duel:targetsFeasible(qtargets,player)
    end,
    on_validate = function(self, cardUse)
        local source = cardUse.from
        local room = source:getRoom()

        source:skillInvoked("kehejiuxian")

        local log = sgs.LogMessage()
        log.from = source
        log.type = "$RecastCard"
        log.card_str = self:subcardString()
        room:sendLog(log)

        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, source:objectName(), self:objectName(), "")
        room:moveCardTo(self,source,nil,sgs.Player_DiscardPile,reason)

        source:drawCards(self:subcardsLength(), "recast")

        local duel = sgs.Sanguosha:cloneCard("duel")
        duel:setSkillName("_kehejiuxian")
        return duel
    end,
}

kehejiuxian_buff = sgs.CreateTriggerSkill{
    name = "#kehejiuxian_buff",
    events = {sgs.TargetConfirmed, sgs.Damage},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card:isKindOf("Duel") and table.contains(use.card:getSkillNames(),"kehejiuxian") then
                for _,p in sgs.qlist(use.to) do
                    room:setCardFlag(use.card, "kehejiuxian_target_"..p:objectName())
                end
            end
        end
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("kehejiuxian_target_"..damage.to:objectName()) then
                local targets = sgs.SPlayerList()
                for _,p in sgs.qlist(room:getOtherPlayers(damage.to)) do
                    if p:isWounded() and damage.to:inMyAttackRange(p) and p:objectName() ~= player:objectName() then
                        targets:append(p)
                    end
                end
                if not targets:isEmpty() then
                    local target = room:askForPlayerChosen(player, targets, "kehejiuxian", "@kehejiuxian:"..damage.to:getGeneralName(), true, true)
                    if target then
                        room:broadcastSkillInvoke("kehejiuxian")
                        room:recover(target, sgs.RecoverStruct(player, nil, 1))
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

kehechenyong = sgs.CreateTriggerSkill{
    name = "kehechenyong",
    events = {sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event ~= sgs.EventPhaseStart then
            local card = nil
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            elseif event == sgs.CardResponded then
                local respose = data:toCardResponse()
                if respose.m_isUse then
                    card = respose.m_card
                end
            end
            if (not card) or (card:isKindOf("SkillCard")) then return false end
            local types = {"BasicCard", "TrickCard", "EquipCard"}
            for _,cardtype in ipairs(types) do
                if card:isKindOf(cardtype) and player:getMark("kehechenyong_"..cardtype.."-Clear") == 0 then
                    room:setPlayerMark(player, "kehechenyong_"..cardtype.."-Clear", 1)
                    room:addPlayerMark(player, "&kehechenyong-Clear", 1)
                end
            end
        end

        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Finish then return false end
            if player:getMark("&kehechenyong-Clear") <= 0 then return false end
            local prompt = string.format("draw:%s:", player:getMark("&kehechenyong-Clear"))
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(player:getMark("&kehechenyong-Clear"), self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getPhase() ~= sgs.Player_NotActive
    end,
}

kehechentai:addSkill(kehejiuxian)
kehechentai:addSkill(kehejiuxian_buff)
kehechentai:addSkill(kehechenyong)
extension_he:insertRelatedSkills("kehejiuxian", "#kehejiuxian_buff")


kehewenqin = sgs.General(extension_he, "kehewenqin", "wei", 4,true,true)

keheguangao = sgs.CreateTriggerSkill{
	name = "keheguangao",
	frequency == sgs.Skill_Frequent,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				--别人额外目标
			    for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasSkill(self:objectName()) and (not use.to:contains(p)) then
						if not player:isYourFriend(p) then room:setPlayerFlag(player,"wantusekeheguangao") end
						if player:askForSkillInvoke(self,ToData("keheguangao-ask:"..p:objectName())) then
							room:doAnimate(1, player:objectName(), p:objectName())
							room:broadcastSkillInvoke(self:objectName())
							room:setPlayerFlag(player,"-wantusekeheguangao")
							use.to:append(p)
						end
						room:setPlayerFlag(player,"-wantusekeheguangao")
					end
				end
				--自己用杀摸牌情形
				if (use.from:hasSkill(self:objectName())) then
					if (use.from:getHandcardNum() % 2 == 0) then
						use.from:drawCards(1)
						local fris = room:askForPlayersChosen(use.from, use.to, self:objectName(), 0, 99, "keheguangaominus-ask", true, true)
						if (fris:length() > 0) then
							room:broadcastSkillInvoke(self:objectName())
						end
						local nullified_list = use.nullified_list
						for _,p in sgs.qlist(fris) do
							table.insert(nullified_list, p:objectName())
						end
						use.nullified_list = nullified_list
						data:setValue(use)
					end
				end
				--被杀摸牌情形
				for _,p in sgs.qlist(use.to) do
					if p:hasSkill(self:objectName()) then
						if (p:getHandcardNum() % 2 == 0) then
							p:drawCards(1)
							local fris = room:askForPlayersChosen(p, use.to, self:objectName(), 0, 99, "keheguangaominus-ask", true, true)
							if (fris:length() > 0) then
								room:broadcastSkillInvoke(self:objectName())
							end
							local nullified_list = use.nullified_list
							for _,p in sgs.qlist(fris) do
								table.insert(nullified_list, p:objectName())
							end
							use.nullified_list = nullified_list
							data:setValue(use)
						end
					end
				end
				data:setValue(use)
			end
		end
	end,
	can_trigger = function(self,target)
		return target ~= nil
	end
}
kehewenqin:addSkill(keheguangao)

extension_he:insertRelatedSkills("keheguangao", "#keheguangaoex")

kehehuiqi = sgs.CreateTriggerSkill{
	name = "kehehuiqi",
	events = {sgs.TargetConfirmed,sgs.EventPhaseChanging},
	frequency = sgs.Skill_Wake,
	waked_skills = "kehexieju",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _,wq in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if (wq:getMark("kehehuiqi-Clear") == 3)
					and (wq:getMark("&kehehuiqi-Clear") > 0) and (wq:getMark(self:objectName()) == 0) then
						room:sendCompulsoryTriggerLog(wq,self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		room:doSuperLightbox("kehewenqin", "kehehuiqi")
						room:setPlayerMark(wq, self:objectName(), 1)
						room:changeMaxHpForAwakenSkill(wq, 0,self:objectName())
						room:recover(wq, sgs.RecoverStruct())
						room:acquireSkill(wq, "kehexieju")
					end
				end		
				end
		end
		if (event == sgs.TargetConfirmed) then
			local use = data:toCardUse()
			local wqs = room:findPlayersBySkillName(self:objectName())
			if not use.card:isKindOf("SkillCard") then
				for _,p in sgs.qlist(use.to) do
					if (p:getMark("&kehehuiqi-Clear") == 0) then
						for _,pp in sgs.qlist(wqs) do
						    room:addPlayerMark(pp,"kehehuiqi-Clear",1)
						end
						room:setPlayerMark(p,"&kehehuiqi-Clear",1,wqs)
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target ~= nil
	end
}
kehewenqin:addSkill(kehehuiqi)

--黑牌当杀（以下）
kehexiejuslash = sgs.CreateViewAsSkill{
	name = "kehexiejuslash" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and (not sgs.Self:isJilei(to_select)) and to_select:isBlack()
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then
			return nil
		end
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("_kehexieju")
		slash:addSubcard(cards[1])
		return slash
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern:startsWith("@@kehexiejuslash")
	end
}
extension_he:addSkills(kehexiejuslash)
--黑牌当杀（以上结束）

kehexiejuCard = sgs.CreateSkillCard{
	name = "kehexiejuCard" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (to_select:getMark("kehexiejutar-Clear") > 0)
	end,
	on_use = function(self, room, player, targets)
		for _, p in sgs.list(targets) do 
			--依次询问黑牌当杀
			room:askForUseCard(p, "@@kehexiejuslash", "kehexiejuslash-ask") 
		end
	end
}

kehexiejuVS = sgs.CreateZeroCardViewAsSkill{
	name = "kehexieju",
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kehexiejuCard") 
	end ,
	view_as = function()
		return kehexiejuCard:clone()
	end
}

kehexieju = sgs.CreateTriggerSkill{
	name = "kehexieju",
	view_as_skill = kehexiejuVS,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.TargetConfirmed) then
			local use = data:toCardUse()
			local wq = room:getCurrent()
			if wq:hasSkill(self:objectName()) and (not use.card:isKindOf("SkillCard")) then
				for _, p in sgs.qlist(use.to) do 
					room:setPlayerMark(p,"kehexiejutar-Clear",1)
				end
			end
		end
	end ,
	can_trigger = function(self,target)
		return target ~= nil
	end
}
extension_he:addSkills(kehexieju)

kehezhangxuan = sgs.General(extension_he, "kehezhangxuan", "wu", 4,false,true)
kehezhangxuan:addSkill("tongli")
kehezhangxuan:addSkill("shezang")


sgs.LoadTranslationTable{
    ["kearjsrgthe"] = "江山如故·合",
	["xumou_card"] = "蓄谋牌",
	["kehexumouuse-ask"] = "你可以使用蓄谋牌【%src】：选择目标 -> 点击确定",
    ["__kehexumou1"] = "蓄谋",
	["__kehexumou2"] = "蓄谋",
	["__kehexumou3"] = "蓄谋",
	["__kehexumou4"] = "蓄谋",
	["__kehexumou5"] = "蓄谋",
    ["__kehexumou6"] = "蓄谋",
	["__kehexumou7"] = "蓄谋",
	["__kehexumou8"] = "蓄谋",
	["__kehexumou9"] = "蓄谋",
    ["#kehexumou"] = "蓄谋",

	["_kehe_jiejiaguitian"] = "解甲归田",
	[":_kehe_jiejiaguitian"] = "锦囊牌·单目标锦囊<br /><b>时机</b>：出牌阶段，对一名装备区有牌的角色使用<br /><b>效果</b>：目标角色获得其装备区里的所有牌。",

	--郭循
	["keheguoxun"] = "郭循[合]", 
	["&keheguoxun"] = "郭循",
	["#keheguoxun"] = "秉心不回",
	["designer:keheguoxun"] = "官方",
	["cv:keheguoxun"] = "泪何不寐",
	["illustrator:keheguoxun"] = "鬼画府，极乐",

	["keheeqian"] = "遏前",
	["keheeqian:add"] = "令其本回合与你距离+2",
	["keheeqian-ask"] = "你可以发动“遏前”蓄谋任意张牌",
	[":keheeqian"] = "<font color='green'><b>结束阶段，</b></font>你可以蓄谋任意次；当你使用【杀】或蓄谋牌指定其他角色为唯一目标后，你可以令此牌不计入次数并获得其一张牌，然后其可以令你本回合与其距离+2。",

	["kehefusha"] = "伏杀",
	[":kehefusha"] = "限定技，出牌阶段，你可以对攻击范围内的唯一角色造成X点伤害（X为你的攻击范围且至多为总角色数）。",


	["$keheeqian1"] = "勇过聂政，功逾介子。",
	["$keheeqian2"] = "砥节砺行，秉心不回！",
	["$kehefusha1"] = "（咚咚锵）",

	["~keheguoxun"] = "杀身成仁，矢志不移。",


	--二虎
	["keheerhu"] = "孙鲁班＆孙鲁育[合]", 
	["&keheerhu"] = "孙鲁班孙鲁育",
	["#keheerhu"] = "恶紫夺朱",
	["designer:keheerhu"] = "官方",
	["cv:keheerhu"] = "官方",
	["illustrator:keheerhu"] = "鬼画府，悦君歌",

	["keheerhuone"] = "弃置蓄谋牌【%src】",
	["keheerhutwo"] = "弃置蓄谋牌【%src】",
	["keheerhuthree"] = "弃置蓄谋牌【%src】",
	["keheerhufour"] = "弃置蓄谋牌【%src】",
	["keheerhufive"] = "弃置蓄谋牌【%src】",
	
	["kehedaimou"] = "殆谋",
	[":kehedaimou"] = "<font color='green'><b>每回合各限一次，</b></font>当一名角色使用【杀】指定其他角色/你为目标时，你可以将牌堆顶的牌蓄谋/你弃置你判定区内的一张蓄谋牌。",
	["kehedaimouone"] = "殆谋：将牌堆顶的牌蓄谋",
	["kehedaimoutwo"] = "殆谋",

	["kehefangjie"] = "芳洁",
	["kehefangjiedis"] = "芳洁：弃置任意张蓄谋牌",
	[":kehefangjie"] = "<font color='green'><b>准备阶段，</b></font>若你的判定区内没有蓄谋牌，你回复1点体力并摸一张牌，否则你可以弃置任意张你判定区内的蓄谋牌并失去“芳洁”。",

	["$kehedaimou1"] = "哼，真以为我能饶过你？",
	["$kehedaimou2"] = "哼，定叫你吃不了兜着走！",
	["$kehedaimou3"] = "你疯了，我可是长公主！",
	["$kehedaimou4"] = "姐妹敦睦，家国和睦。",
	["$kehefangjie1"] = "素性贞淑，穆穆春山。",
	["$kehefangjie2"] = "贵胄之身，岂能轻折",
	["$kehefangjie3"] = "慕清兴荣，太平祥和。",
	["$kehefangjie4"] = "雍穆融治，吾之所愿。",
	["~keheerhu"] = "姐姐，你太狠心了。/你们居然敢治我的罪！",

	--卫温诸葛直
	["keheweiwenzhugezhi"] = "卫温＆诸葛直[合]", 
	["&keheweiwenzhugezhi"] = "卫温诸葛直",
	["#keheweiwenzhugezhi"] = "帆至夷州",
	["designer:keheweiwenzhugezhi"] = "官方",
	["cv:keheweiwenzhugezhi"] = "官方",
	["illustrator:keheweiwenzhugezhi"] = "聚一@LEK-D3",

	["kehefuhai"] = "浮海",
	["kehefuhai-ask"] = "浮海：请选择展示的牌",
	
	["kehefuhai:nsz"] = "逆时针",
	["kehefuhai:ssz"] = "顺时针",
	[":kehefuhai"] = "出牌阶段限一次，你可以令所有有手牌的其他角色同时展示一张手牌，然后你选择一个方向（顺时针或逆时针）并摸X张牌（X为从你开始该方向上的这些角色展示的牌的点数连续严格递增或严格递减的牌数且至少为1）。",
	
	["$kehefuhai1"] = "苦海茫茫，渡心无边。",
	["$kehefuhai2"] = "此征艰险，万事小心为慎。",
	["~keheweiwenzhugezhi"] = "吾死不足惜，只愿四海升平。",
	
	--郭照
	["keheguozhao"] = "郭照[合]", 
	["&keheguozhao"] = "郭照",
	["#keheguozhao"] = "碧海青天",
	["designer:keheguozhao"] = "官方",
	["cv:keheguozhao"] = "官方",
	["illustrator:keheguozhao"] = "杨杨和夏季",

	["kehepianchongred"] = "偏宠红",
	["kehepianchongblack"] = "偏宠黑",
	["kehepianchong"] = "偏宠",

	[":kehepianchong"] = "锁定技，一名角色的<font color='green'><b>结束阶段，</b></font>若你于此回合内失去过牌，你进行判定，若本回合进入弃牌堆的牌中，与判定牌颜色相同的牌的数量不小于与判定牌颜色不同的牌，你摸一张牌，否则你弃置一张牌。",
	
	["$kehepianchong1"] = "得陛下怜爱，恩宠不衰",
	["$kehepianchong2"] = "谬蒙圣恩，光授殊宠",
	["~keheguozhao"] = "我的出身，不配为后？",



	--诸葛亮
	["kehezhugeliang"] = "诸葛亮[合]", 
	["&kehezhugeliang"] = "诸葛亮",
	["#kehezhugeliang"] = "炎汉忠魂",
	["designer:kehezhugeliang"] = "官方",
	["cv:kehezhugeliang"] = "官方",
	["illustrator:kehezhugeliang"] = "鬼画府",
	["information:kehezhugeliang"] = "ᅟᅠᅟᅠ<i>建兴六年春，汉丞相诸葛亮使赵云、邓芝为先锋，马谡为副将拒箕谷，牵制曹真主力。自率三十万大军攻祁山，三郡叛魏应亮，关中响震。\
	ᅟᅠᅟᅠ曹叡命张郃拒亮，亮使定军山降将姜维与郃战于街亭。张郃久攻不下，曹真主动出击，强攻赵云军，赵云死战，坚守箕谷，马谡、邓芝当场战死忠勇殉国。……既克张郃，曹真溃逃，曹叡弃守长安，迁都邺城。十月，司马懿击退孙权，回援曹真。而后三年，丞相所到之处无不望风而降，百姓皆革食壶浆以迎汉军。尽收豫、徐、兖、并之地，建兴十年春，司马懿父子三人死于诸葛武侯火计，同年，孙权上表称臣，至此四海清平，大汉一统。\
	ᅟᅠᅟᅠ而后诸葛亮荐蒋琬为丞相，姜维为大将军，自回隆中归隐，后主挽留再三，皆不受。魏延亦辞官相随，侍奉左右。后主时有不决之事，便往隆中拜访相父，均未得面，童子答曰外出云游，留下锦囊数个，拆开视之，皆治国良策也。</i>",


	["kehezhugeliangpre"] = "诸葛亮[合]-初版", 
	["&kehezhugeliangpre"] = "诸葛亮",
	["#kehezhugeliangpre"] = "炎汉忠魂",
	["designer:kehezhugeliangpre"] = "官方",
	["cv:kehezhugeliangpre"] = "官方",
	["illustrator:kehezhugeliangpre"] = "鬼画府",
	["information:kehezhugeliangpre"] = "ᅟᅠᅟᅠ<i>建兴六年春，汉丞相诸葛亮使赵云、邓芝为先锋，马谡为副将拒箕谷，牵制曹真主力。自率三十万大军攻祁山，三郡叛魏应亮，关中响震。\
	ᅟᅠᅟᅠ曹叡命张郃拒亮，亮使定军山降将姜维与郃战于街亭。张郃久攻不下，曹真主动出击，强攻赵云军，赵云死战，坚守箕谷，马谡、邓芝当场战死忠勇殉国。……既克张郃，曹真溃逃，曹叡弃守长安，迁都邺城。十月，司马懿击退孙权，回援曹真。而后三年，丞相所到之处无不望风而降，百姓皆革食壶浆以迎汉军。尽收豫、徐、兖、并之地，建兴十年春，司马懿父子三人死于诸葛武侯火计，同年，孙权上表称臣，至此四海清平，大汉一统。\
	ᅟᅠᅟᅠ而后诸葛亮荐蒋琬为丞相，姜维为大将军，自回隆中归隐，后主挽留再三，皆不受。魏延亦辞官相随，侍奉左右。后主时有不决之事，便往隆中拜访相父，均未得面，童子答曰外出云游，留下锦囊数个，拆开视之，皆治国良策也。</i>",


	["kehewentian"] = "问天",
	["kehewentianpre"] = "问天",
	[":kehewentian"] = "每个回合限一次，你的阶段开始时，你可以观看牌堆顶的X张牌（X为7-你以此法观看过牌的次数且X至少为1）且可以将其中一张交给一名其他角色，然后将其余牌以任意顺序置于牌堆顶或牌堆底；你可以将牌堆顶的牌当【无懈可击】/【火攻】使用，若以此法使用的牌不为黑色/红色，本轮“问天”失效。",
	[":kehewentianpre"] = "每个回合限一次，你的阶段开始时，你可以观看牌堆顶的五张牌，且可以将其中一张交给一名其他角色，然后将其余牌以任意顺序置于牌堆顶或牌堆底；你可以将牌堆顶的牌当【无懈可击】/【火攻】使用，若以此法使用的牌不为黑色/红色，本轮“问天”失效。",

	["kehechushi"] = "出师",
	[":kehechushi"] = "出牌阶段限一次，你可以与主公议事，若结果为：红色，你与其各摸一张牌，若你的手牌数与其手牌数之和小于7，重复此摸牌流程；黑色，你本轮造成的属性伤害+1。",

	["keheyinlue"] = "隐略",
	["keheyinluepre"] = "隐略",
	["keheyinluedisleidian"] = "你可以弃置一张牌发动“隐略”防止 %src 受到的雷电伤害",
	["keheyinluedishuoyan"] = "你可以弃置一张牌发动“隐略”防止 %src 受到的火焰伤害",
	[":keheyinlue"] = "<font color='green'><b>每轮每项限一次，</b></font>当一名角色受到火焰/雷电伤害时，你可以弃置一张牌防止之，然后当前回合结束后，你执行一个仅包含摸牌阶段/弃牌阶段的额外回合。",
	[":keheyinluepre"] = "<font color='green'><b>每轮每项限一次，</b></font>当一名角色受到火焰/雷电伤害时，你可以防止之，然后当前回合结束后，你执行一个仅包含摸牌阶段/弃牌阶段的额外回合。",


	["bankehewentian_lun"] = "问天失效",
	["kehewentianchoose-ask"] = "请选择交给其他角色的牌，或点击确定跳过",
	["kehewentian-ask"] = "请将此牌交给一名其他角色",
	["kehechushi_lun"] = "出师伤害",
	["keheyinluemp"] = "隐略摸牌",
	["keheyinlueqp"] = "隐略弃牌",
	["bankehewentian"] = "问天失效",

	["$kehewentian1"] = "七星北斗，布阵如棋。",
	["$kehewentian2"] = "问天用奇术，洞敌于机先。",
	["$kehewentianpre1"] = "七星北斗，布阵如棋。",
	["$kehewentianpre2"] = "问天用奇术，洞敌于机先。",
	["$kehechushi1"] = "半生韶华付社稷，一枕清梦压星河。",
	["$kehechushi2"] = "繁星四百八十万，颗颗鉴照老臣心。",
	["$keheyinlue1"] = "亮，且以星为子，天为局。",
	["$keheyinlue2"] = "眼底星河进，何日太平归？",
	["$keheyinluepre1"] = "亮，且以星为子，天为局。",
	["$keheyinluepre2"] = "眼底星河进，何日太平归？",
	["~kehezhugeliang"] = "回天有术，奈何难寻破局良方。",
	["~kehezhugeliangpre"] = "回天有术，奈何难寻破局良方。",
	

	--姜维
	["kehejiangwei"] = "姜维[合]", 
	["&kehejiangwei"] = "姜维",
	["#kehejiangwei"] = "赤血化龙",
	["designer:kehejiangwei"] = "官方",
	["cv:kehejiangwei"] = "官方",
	["illustrator:kehejiangwei"] = "鬼画府，极乐",

	["kehejinfa"] = "矜伐",
	["kehejinfa-ask"] = "你可以令至多两名角色将手牌摸至其体力上限（至多五张）",
	[":kehejinfa"] = "出牌阶段限一次，你可以展示一张手牌并令所有体力上限不大于你的角色议事，若结果与你展示的牌颜色：相同，你令其中至多两名角色将手牌摸至其体力上限（至多五张）；不同，你从游戏外获得两张【影】，若没有其他角色的意见与你相同，你可以变更势力。",

	["kehefumou"] = "复谋",
	["kehefumoucpby-ask"] = "你可以将一张【影】当【出其不意】对与你意见不同的角色使用",
	[":kehefumou"] = "魏势力技，当你参与的议事结束后，与你意见不同的角色当前回合不能使用或打出其意见对应颜色的牌，然后你可以将一张【影】当【出其不意】对其中一名角色使用。",
	["$kehefumou_color"] = "%to 本回合不能使用或打出 %arg 牌",

	["kehexuanfeng"] = "选锋",
	[":kehexuanfeng"] = "蜀势力技，你可以将一张【影】当无距离和次数限制的刺【杀】使用。",
	
	["$kehejinfa1"] = "古来圣贤为道而死，道之存焉何惜身入九渊。",
	["$kehejinfa2"] = "炎阳在悬，岂因乌云障日而弃金光于野？",
	["$kehefumou1"] = "我辈沐光而行，不为浮云障目。",
	["$kehefumou2"] = "烛焰灼长剑，待裁万里江山。",
	["$kehexuanfeng1"] = "炎阳将坠，可为者，唯舍生擎天！",
	["$kehexuanfeng2"] = "此生未止，志随先烈之遗风！",
	["~kehejiangwei"] = "这八阵天机，我也难以看破。",

	--曹芳
	["kehecaofang"] = "曹芳[合]", 
	["&kehecaofang"] = "曹芳",
	["#kehecaofang"] = "引狼入庙",
	["designer:kehecaofang"] = "官方",
	["cv:kehecaofang"] = "寂镜",
	["illustrator:kehecaofang"] = "鬼画府，极乐",
	
	["keheweizhuiask"] = "危坠：你可以将一张黑色手牌当【过河拆桥】对 %src 使用",

	["kehezhaotu"] = "诏图",
	[":kehezhaotu"] = "每轮限一次，你可以将一张红色非锦囊牌当【乐不思蜀】使用，当前回合结束后，此牌的目标角色执行一个手牌上限-2的额外回合。",

	["kehejingju"] = "惊惧",
	["kehejingju0"] = "请选择发动“惊惧”移动牌的角色",
	[":kehejingju"] = "你可以将其他角色判定区的一张牌移至你的判定区，视为你使用一张基本牌。",

	["keheweizhui"] = "危坠",
	[":keheweizhui"] = "主公技，其他魏势力角色的结束阶段，其可以将一张黑色手牌当【过河拆桥】对你使用。",

	["$kehezhaotu1"] = "卿持此诏，惟盈惟谨，勿蹈山阳公覆辙。",
	["$kehezhaotu2"] = "司马师觑百官如草芥，社稷早晚必归此人矣。",
	["$kehejingju1"] = "朕有罪…求大将军饶恕…",
	["$kehejingju2"] = "朕本无此心、绝无此心！",
	["$keheweizhui1"] = "大魏高楼百尺，竟无一栋梁。",
	["$keheweizhui2"] = "高飞入危云，簌簌兮如坠。",
	["~kehecaofang"] = "报应不爽，司马家亦有今日。",

	--赵云
	["kehezhaoyun"] = "赵云[合]", 
	["&kehezhaoyun"] = "赵云",
	["#kehezhaoyun"] = "北伐之柱",
	["designer:kehezhaoyun"] = "官方",
	["cv:kehezhaoyun"] = "官方",
	["illustrator:kehezhaoyun"] = "鬼画府",

	["kehelonglin"] = "龙临",
	[":kehelonglin"] = "当其他角色在其出牌阶段首次使用【杀】指定目标后，你可以弃置一张牌令此【杀】无效，然后其可以视为对你使用一张【决斗】，你因此【决斗】造成伤害后，其本阶段不能使用和打出手牌。",
	["kehelonglinjuedou"] = "龙临：视为对其使用一张【决斗】",
	["kehelonglin-ask"] = "你可以发动“龙临”弃置一张牌令此【杀】无效",

	["kehezhendan"] = "镇胆",
	[":kehezhendan"] = "你可以将一张非基本手牌当任意基本牌使用或打出；当你受到伤害后或每轮结束时，你摸X张牌且本轮“镇胆”失效（X为本轮所有角色行动过的总回合数且至多为5）。",

	["$kehelonglin1"] = "不图功略盖天地，愿以义勇冠三军！",
	["$kehelonglin2"] = "一腔忠勇匡时难，勇熄狼烟汉祚兴。",

	["$kehezhendan1"] = "银枪所至，千夫不敌！",
	["$kehezhendan2"] = "踏遍天下谁敌手，自杖银枪辨雌雄。",
	["$kehezhendan3"] = "宇内安有无双将，且与子龙试高低！",

	["~kehezhaoyun"] = "北伐大业未定，末将实难心安。",

	--司马懿
	["kehesimayi"] = "司马懿[合]", 
	["&kehesimayi"] = "司马懿",
	["#kehesimayi"] = "危崖隐羽",
	["designer:kehesimayi"] = "官方",
	["cv:kehesimayi"] = "官方",
	["illustrator:kehesimayi"] = "鬼画府，极乐",

	["keheyingshi"] = "鹰眎",
	["keheyingshi:keheyingshiuse-ask"] = "你可以发动“鹰眎”观看牌堆底的 %src 张牌。",
	[":keheyingshi"] = "当你翻面时，你可以观看牌堆底的三张牌（若死亡角色数大于2，改为五张），然后将这些牌以任意顺序置于牌堆顶或牌堆底。",
	
	["kehetuigu"] = "蜕骨",
	[":kehetuigu"] = "<font color='green'><b>回合开始时，</b></font>你可以翻面令你本回合手牌上限+X（X为存活角色数的一半，向下取整）且你摸X张牌，然后你视为使用一张【解甲归田】且目标角色不能使用因此牌获得的牌直到其回合结束；每轮结束时，若你本轮没有行动过，你执行一个额外回合；当你失去装备区的牌后，你回复1点体力。",

	["kehetuiguxjgt_ask"] = "你可以视为使用【解甲归田】",
	["kehetuigu:kehetuiguuse-ask"] = "你可以发动“蜕骨”将武将牌翻面",
	["$kehetuigulog"] = "%from 执行一个额外的回合",

	["$keheyingshi1"] = "善谋者，鹰扬于九天之上！",
	["$keheyingshi2"] = "善瞻者，察微于九地之下。",

	["$kehetuigu1"] = "我本殿上君王客，如何甘为堂下臣？",
	["$kehetuigu2"] = "指点江山五十载，一朝化龙越金銮。",
	["$kehetuigu3"] = "以退为进，俗子焉能度之？",
	["$kehetuigu4"] = "应时而变，当行权宜之计。",

	["~kehesimayi"] = "吾梦贾逵、王凌为祟，甚恶之。",
	
	--孙峻
	["kehesunjun"] = "孙峻[合]", 
	["&kehesunjun"] = "孙峻",
	["#kehesunjun"] = "朋党执虎",
	["designer:kehesunjun"] = "官方",
	["cv:kehesunjun"] = "孙綝",
	["illustrator:kehesunjun"] = "鬼画府，极乐",

	["keheyaoyan"] = "邀宴",
	["keheyaoyan:join"] = "本回合结束阶段参与议事",
	["keheyaoyan:notjoin"] = "拒绝参与议事",
	["keheyaoyanget-ask"] = "邀宴：你可以获得任意名未参与本次议事的角色的各一张手牌",
	["keheyaoyandamage-ask"] = "邀宴：你可以对一名参与本次议事的角色造成2点伤害",
	[":keheyaoyan"] = "<font color='green'><b>准备阶段，</b></font>你可以令所有角色选择是否在本回合结束时议事，若如此做，本回合结束时，你令所有选择“是”的角色议事，若结果为：红色，你获得任意名未参与本次议事的角色的各一张手牌；黑色，你可以对一名参与本次议事的角色造成2点伤害。",
	["keheyaoyanjoin"] = "接受邀宴",

	["kehebazheng"] = "霸政",
	[":kehebazheng"] = "锁定技，当你对一名其他角色造成伤害后，直到当前回合结束，若参与议事的角色包含你与该角色，其此次议事的意见视为与你相同。",

	["$kehebazhengredlog"] = "%from 因<font color='yellow'><b> “霸政” </b></font>效果，本次议事的意见视为与 %to 相同",
	["$kehebazhengblacklog"] = "%from 因<font color='yellow'><b> “霸政” </b></font>效果，本次议事的意见视为与 %to 相同",

	["$keheyaoyan1"] = "当今天子乃我所立，他敢怎样？",
	["$keheyaoyan2"] = "我兄弟三人同掌禁军，有何所惧？",
	["$kehebazheng1"] = "以杀立威，谁敢反我？",
	["$kehebazheng2"] = "将这些乱臣贼子尽皆诛之！",

	["~kehesunjun"] = "愿陛下念臣昔日之功，陛下......陛下！",


	--陆逊
	["keheluxun"] = "陆逊[合]", 
	["&keheluxun"] = "陆逊",
	["#keheluxun"] = "却敌安疆",
	["designer:keheluxun"] = "官方",
	["cv:keheluxun"] = "官方",
	["illustrator:keheluxun"] = "鬼画府，极乐",

	["keheyoujin"] = "诱进",
	["keheyoujin-ask"] = "你可以发动“诱进”与一名角色拼点",
	
	["keheyoujinnum"] = "诱进点数",
	[":keheyoujin"] = "<font color='green'><b>出牌阶段开始时，</b></font>你可以与一名角色拼点，然后你与其本回合不能使用或打出点数小于本次各自拼点牌的牌，且赢的角色视为对没赢的角色使用一张【杀】。",

	["kehedailao"] = "待劳",
	[":kehedailao"] = "出牌阶段，若你没有可以使用的手牌，你可以展示所有手牌并摸两张牌，然后结束此回合。",
	["$kehedailaolog"] = "%from 结束了此回合",

	["kehezhubei"] = "逐北",
	["kehezhubeisp"] = "逐北失牌",
	["kehezhubeida"] = "逐北伤害",
	[":kehezhubei"] = "锁定技，你对当前回合受到过伤害的角色造成的伤害+1；你对当前回合失去过最后的手牌的角色使用牌无次数限制。",

	["$keheyoujin1"] = "谦恭守分，静待天时。",
	["$keheyoujin2"] = "夫唯不争，故天下莫能与之争。",
	["$kehedailao1"] = "揣度当世时局，以求少劳而多利。",
	["$kehedailao2"] = "静观世事，以待时变。",
	["$kehezhubei1"] = "克荆擒羽，不过举手之劳，有何难哉！",
	["$kehezhubei2"] = "烽火连绵，尽摧敌营。",

	["~keheluxun"] = "祸起萧墙，终及吾身。",

	--高翔
	["kehegaoxiang"] = "高翔[合]", 
	["&kehegaoxiang"] = "高翔",
	["#kehegaoxiang"] = "玄乡侯",
	["designer:kehegaoxiang"] = "官方",
	["cv:kehegaoxiang"] = "官方",
	["illustrator:kehegaoxiang"] = "黯荧岛",

	["kehechiying"] = "驰应",
	[":kehechiying"] = "出牌阶段限一次，你可以选择一名角色，该角色攻击范围内的其他角色各弃置一张牌，若其中弃置的基本牌数不大于其体力值，其获得这些基本牌。",

	["$kehechiying1"] = "今诱老贼来此，必折其父子于上方谷。",
	["$kehechiying2"] = "列柳城既失，当下唯死守阳平关。",

	["~kehegaoxiang"] = "老贼不死，实天意也。",

	--刘永
	["keheliuyong"] = "刘永[合]", 
	["&keheliuyong"] = "刘永",
	["#keheliuyong"] = "甘陵王",
	["designer:keheliuyong"] = "官方",
	["cv:keheliuyong"] = "官方",
	["illustrator:keheliuyong"] = "君桓文化",

	["kehedanxin"] = "丹心",
	[":kehedanxin"] = "你可以将一张牌当【推心置腹】使用，当你因以此法使用的【推心置腹】获得或给出牌时，你展示这些牌，且得到♥牌的角色回复1点体力，此牌结算完毕后，你本回合与此牌目标角色的距离+1。",

	["kehefengxiang"] = "封乡",
	[":kehefengxiang"] = "锁定技，当你受到伤害后，你与一名其他角色交换装备区的所有牌，然后你摸X张牌（X为你装备区因此减少的牌数且至少为0）。",
	["kehefengxiang-ask"] = "封乡：请选择一名角色与其交换装备区的所有牌",
	
	["$kehedanxin1"] = "吾父之基业，岂能亡于奸宦之手！",
	["$kehedanxin2"] = "纵与吾兄成隙，亦当除此蛀虫！",
	["$kehefengxiang1"] = "百年扶汉积万骨，十载相隙累半生。",
	["$kehefengxiang2"] = "一骑蓝翎魏旨到，王兄大梦可曾闻？",

	["~keheliuyong"] = "刘公嗣，你睁开眼看看这八百里蜀川吧！",

    --陈泰

    ["kehechentai"] = "陈泰[合]",
    ["&kehechentai"] = "陈泰",
    ["#kehechentai"] = "断围破蜀",
    ["designer:kehechentai"] = "官方",
	["cv:kehechentai"] = "官方",
	["illustrator:kehechentai"] = "画画的闻玉",

    ["kehejiuxian"] = "救陷",
    [":kehejiuxian"] = "出牌阶段限一次，你可以重铸一半数量的手牌（向上取整），然后视为使用一张【决斗】。此牌对目标角色造成伤害后，你可令其攻击范围内的一名其他角色回复1点体力。",
    ["@kehejiuxian"] = "你可以令 %src 攻击范围内的一名其他角色回复一点体力",
    ["kehechenyong"] = "沉勇",
    [":kehechenyong"] = "结束阶段，你可以摸x张牌。（x为本回合你使用过牌的类型数）",
    ["kehechenyong:draw"] = "你可以发动“沉勇”摸 %src 张牌",

    ["$kehejiuxian1"] = "救袍泽于水火，返清明于天下。",
    ["$kehejiuxian2"] = "与君共扼王旗，焉能见死不救。",
    ["$kehechenyong1"] = "将者，当泰山崩于前而不改色。",
    ["$kehechenyong2"] = "救将陷之城，焉求益兵之助。",

    ["~kehechentai"] = "公非旦，我非勃。",

    ["kehecaoshuang"] = "曹爽[合]",
    ["&kehecaoshuang"] = "曹爽",
    ["#kehecaoshuang"] = "骄奢跋扈",
    ["designer:kehecaoshuang"] = "官方",
	["cv:kehecaoshuang"] = "官方",
	["illustrator:kehecaoshuang"] = "画画的闻玉",
	["~kehecaoshuang"] = "悔不该降了司马懿！",

    ["kehezhangxuan"] = "张嫙[合]",
    ["&kehezhangxuan"] = "张嫙",
    ["#kehezhangxuan"] = "玉宇嫁蔷",
    ["designer:kehezhangxuan"] = "官方",
	["cv:kehezhangxuan"] = "官方",
	["illustrator:kehezhangxuan"] = "官方",
	["~kehezhangxuan"] = "陛下，臣妾绝无异心",
    
    ["kehewenqin"] = "文钦[合]",
    ["&kehewenqin"] = "文钦",
    ["#kehewenqin"] = "困兽鸱张",
    ["designer:kehewenqin"] = "官方",
	["cv:kehewenqin"] = "官方",
	["illustrator:kehewenqin"] = "官方",

	["keheguangao"] = "犷骜",
	[":keheguangao"] = "你使用【杀】的目标数限制+1；其他角色使用【杀】时，其可以令你成为此【杀】的额外目标；当一名角色使用【杀】时，若你是使用者或目标且你的手牌数为偶数，你摸一张牌，然后可以令此【杀】对任意名角色无效。",
    ["keheguangao:keheguangao-ask"] = "你可以发动“犷骜”令 %src 成为此【杀】的额外目标",

	["kehehuiqi"] = "慧企",
	[":kehehuiqi"] = "觉醒技，一个回合结束时，若此回合成为过牌的目标的角色数为3且包括你，你回复1点体力并获得“偕举”。",

	["kehexieju"] = "偕举",
	[":kehexieju"] = "出牌阶段限一次，你可以令任意名本回合成为过牌的目标的角色依次选择是否将一张黑色牌当【杀】使用。",
	["kehexiejuslashCard"] = "偕举",
	["kehexiejuCard"] = "偕举",

	["keheguangaominus-ask"] = "你可以发动“犷骜”令此【杀】对任意名目标角色无效",
	["kehexiejuslash-ask"] = "偕举：你可以将一张黑色牌当【杀】使用",
	
	["$keheguangao1"] = "大丈夫行事，焉能畏首畏尾。",
	["$keheguangao2"] = "策马觅封侯，长驱万里之数。",
	["$kehehuiqi1"] = "今大星西垂，此天降清君侧之证。",
	["$kehehuiqi2"] = "彗星竟于西北，此罚天狼之兆。",
	["$kehexieju1"] = "今举大义，誓与仲恭共死。",
	["$kehexieju2"] = "天降大任，当与志士同忾。",

	["~kehewenqin"] = "天不佑国魏，天不佑族文！",


}






extension_shuai = sgs.Package("kearjsrgushuai", sgs.Package_GeneralPack)


keshuaiyuanshao = sgs.General(extension_shuai, "keshuaiyuanshao$", "qun", 4)

keshuaizhimeng = sgs.CreateTriggerSkill{
	name = "keshuaizhimeng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Start) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local card_ids = room:showDrawPile(player,player:aliveCount(),self:objectName())
				local zss = {}
				--选牌，记录
				for _, q in sgs.qlist(room:getAllPlayers()) do   
					if q:isKongcheng() then continue end
					zss[q:objectName()] = room:askForExchange(q, "keshuaizhimeng", 1, 1, false, "keshuaizhimengask")
				end
				local allshows = sgs.CardList()
				--展示，记录大家展示的牌
				for _, q in sgs.qlist(room:getAllPlayers()) do   
					local dc = zss[q:objectName()]
					if dc then
						allshows:append(dc)
						room:showCard(q,dc:getEffectiveId())
						zss[q:objectName()] = dc:getSuit()
					end
				end
				room:getThread():delay(1200)
				--结算：若展示的牌里只有一张跟自己的符合，那么自己刚才展示的就是唯一的
				for _, q in sgs.qlist(room:getAllPlayers()) do   
					local same = 0
					local thesuit = -1
					for _,c in sgs.qlist(allshows) do
						local suitnum = c:getSuit()
						if (suitnum == zss[q:objectName()]) then
							same = same + 1
							thesuit = suitnum
							if same>1 then break end
						end
					end
					if (same == 1) then
						local dummy = sgs.Sanguosha:cloneCard("slash")
						for _,idd in sgs.qlist(card_ids) do
							if (sgs.Sanguosha:getCard(idd):getSuit() == thesuit) then
								--获得的牌从一开始的里面移除
								dummy:addSubcard(idd)
							end
						end
						if dummy:subcardsLength() > 0 then
							local log = sgs.LogMessage()
							log.type = "$keshuaizhimenglog"
							log.from = q
							room:sendLog(log)
							q:obtainCard(dummy)
							for _,idd in sgs.qlist(dummy:getSubcards()) do
								card_ids:removeOne(idd)
							end
						end
						dummy:deleteLater()
					end
				end
				--弃置其他亮出的牌
				local dummy = sgs.Sanguosha:cloneCard("slash")
				dummy:addSubcards(card_ids)
				room:throwCard(dummy,self:objectName(),nil)
				dummy:deleteLater()		
			end
		end
	end,
}
keshuaiyuanshao:addSkill(keshuaizhimeng)

keshuaitianyu = sgs.CreateTriggerSkill{
    name = "keshuaitianyu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging,sgs.CardsMoveOneTime},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.from then
				local tag = room:getTag("keshuaitianyutag"):toIntList()
				for i,card_id in sgs.qlist(move.card_ids) do
					if move.from_places:at(i)==sgs.Player_PlaceEquip
					or move.from_places:at(i)==sgs.Player_PlaceHand
					then tag:append(card_id) end
				end
				room:setTag("keshuaitianyutag", ToData(tag))
			end
			if (move.to_place == sgs.Player_DiscardPile) and player:hasSkill(self:objectName()) then
				local tag = room:getTag("keshuaitianyutag"):toIntList()
				for _,card_id in sgs.qlist(move.card_ids) do
					if tag:contains(card_id) then continue end
					local c = sgs.Sanguosha:getCard(card_id)
					if c:isKindOf("EquipCard") or c:isDamageCard() then
						if player:askForSkillInvoke(self,ToData("keshuaitianyuask:"..c:objectName())) then
							room:obtainCard(player,c)
						end
					end
				end
			end
		end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_NotActive then
				room:removeTag("keshuaitianyutag")
			end
		end
	end
}
keshuaiyuanshao:addSkill(keshuaitianyu)

keshuaizhuniCard = sgs.CreateSkillCard{
	name = "keshuaizhuniCard" ,
	target_fixed = true,
	will_throw = false,
	--[[filter = function(self, targets, to_select, from)
		return (#targets == 0) and (to_select:objectName() ~= from:objectName()) 
	end,]]
	on_use = function(self, room, player, targets)
		local record = {}
		local Lord = nil
		for _,p in sgs.qlist(room:getAllPlayers()) do
			local one = room:askForPlayerChosen(p, room:getOtherPlayers(player), self:getSkillName(), "keshuaizhuni_ask", false)
			if one then
				--先记录，等会展示
				--耦一个主公技
				if p:hasLordSkill("keshuaihezhi") then
					room:sendCompulsoryTriggerLog(p,"keshuaihezhi")
					Lord = p
				end
				record[p:objectName()] = one
			end
		end
		--更改其他角色的选择
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if (p:getKingdom() == "qun") and Lord and Lord~=p then 
				record[p:objectName()] = record[Lord:objectName()]
			end
		end
		--同时开始选择
		for _,p in sgs.qlist(room:getAllPlayers()) do
			local log = sgs.LogMessage()
			log.type = "$keshuaizhunilog"
			log.from = p
			log.to:append(record[p:objectName()])
			room:sendLog(log)
			room:doAnimate(1,p:objectName(),record[p:objectName()]:objectName())
			room:addPlayerMark(record[p:objectName()],"&keshuaizhunicount")
			room:getThread():delay(400)
		end
		room:getThread():delay(600)
		local themost = player
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("&keshuaizhunicount") > themost:getMark("&keshuaizhunicount") then
				themost = p
			end
		end
		--检查唯一
		local weiyi = 1
		for _,oth in sgs.qlist(room:getOtherPlayers(themost)) do
			if (oth:getMark("&keshuaizhunicount") >= themost:getMark("&keshuaizhunicount")) then
				weiyi = 0
				break
			end
		end
		if (weiyi == 1) then
			local log = sgs.LogMessage()
			log.type = "$keshuaizhunitarget"
			log.from = themost
			room:sendLog(log)
			room:setPlayerMark(themost,"&keshuaizhuni-Clear",1)
		end
		for _,p in sgs.qlist(room:getAllPlayers()) do
			room:setPlayerMark(p,"&keshuaizhunicount",0)
		end
	end
}

keshuaizhuni = sgs.CreateZeroCardViewAsSkill{
	name = "keshuaizhuni",
	enabled_at_play = function(self, player)
		return not player:hasUsed("#keshuaizhuniCard") 
	end ,
	view_as = function()
		return keshuaizhuniCard:clone()
	end
}
keshuaiyuanshao:addSkill(keshuaizhuni)

keshuaihezhi = sgs.CreateTriggerSkill{
	name = "keshuaihezhi$",
	frequency = sgs.Skill_Compulsory,
	events = {},
	on_trigger = function(self, event, player, data)
	
	end ,
	can_trigger = function(self, target)
		return false
	end
}
keshuaiyuanshao:addSkill(keshuaihezhi)


sgs.LoadTranslationTable{
    ["kearjsrgushuai"] = "江山如故·衰",

	["keshuaiyuanshao"] = "袁绍[衰]", 
	["&keshuaiyuanshao"] = "袁绍",
	["#keshuaiyuanshao"] = "号令天下",
	["designer:keshuaiyuanshao"] = "官方",
	["cv:keshuaiyuanshao"] = "官方",
	["illustrator:keshuaiyuanshao"] = "鬼画府",
	["information:keshuaiyuanshao"] = "ᅟᅠᅟᅠ<i>《旧陈书卷一圣武帝纪》\
	ᅟᅠᅟᅠ太祖圣武皇帝。汝南汝阳人也，姓袁，讳绍，字本初。太祖于黎阳梦有一神授一宝刀，及觉，果在卧所，铭曰思召。解之曰：思召，绍字也。\
	ᅟᅠᅟᅠ……灵帝崩，少帝继位。卓议欲废立，太祖拒之，卓案剑吆曰：“竖子敢然！天下之事，岂不在我？我欲为之，谁敢不从！”绍勃然曰：“天下健者，岂惟董乎！”横剑径出。世入方知太祖贤名非以权势取之，实乃英雄气也。\
	ᅟᅠᅟᅠ初平元年，太祖于勃海起兵，其从弟后将军术等十余位诸侯同时俱起，兴兵讨董。是时，豪杰既多附招，州郡蜂起，莫不以袁氏为名。……太祖既得冀州，尝出猎白登山，见一白鹿口含宝剑而来，获之，剑名中兴。或曰：汉失其鹿，陈逐而获之。\
	ᅟᅠᅟᅠ建安五年，太祖与曹操战于官渡，曹操欲夜袭乌巢，恰有流星如火。光长十余丈照于曹营，昼有云如坏山，当营而陨，不及地尺而散，吏士皆以为不详，太祖并兵俱攻大破之，操自军破后，头风病发，六年夏五月死。</i>",

	["keshuaizhimeng"] = "执盟",
	["keshuaizhimengask"] = "执盟：请选择一张手牌展示",
	[":keshuaizhimeng"] = "准备阶段，你可以亮出牌堆顶等同于存活角色数量的牌，所有角色同时展示一张手牌，然后展示花色唯一的角色获得亮出的牌中该花色的所有牌。",
	["$keshuaizhimengshowlog"] = "%from 发动<font color='yellow'><b>“执盟”</b></font>展示了 %card",
	["$keshuaizhimenglog"] = "%from 因<font color='yellow'><b>“执盟”</b></font>展示的牌花色唯一，将获得亮出的牌中该花色的所有牌",

	["keshuaitianyu"] = "天予",
	["keshuaitianyu:keshuaitianyuask"] = "你可以发动“天予”获得【%src】",
	[":keshuaitianyu"] = "当一张伤害类牌或装备牌进入弃牌堆时，若此牌当前回合内没有离开过任意一名角色的手牌区或装备区，你可以获得之。",

	["keshuaizhuni"] = "诛逆",
	["$keshuaizhunilog"] = "%from 因<font color='yellow'><b>“诛逆”</b></font> 选择了 %to",
	["$keshuaizhunitarget"] = "%from 被选择次数最多，成为本次<font color='yellow'><b>“诛逆”</b></font> 的目标",
	["keshuaizhunicount"] = "诛逆次数",
	[":keshuaizhuni"] = "出牌阶段限一次，你可以令所有角色同时选择一名除你以外的角色，然后你本回合对被以此法选择次数唯一最多的角色使用牌无距离和次数限制。",
	["keshuaizhuni_ask"] = "诛逆：请选择一名角色",

	["keshuaihezhi"] = "合志",
	[":keshuaihezhi"] = "主公技，锁定技，其他群势力角色因“诛逆”选择的角色改为与你相同。",

	["$keshuaizhimeng1"] = "",
	["$keshuaizhimeng2"] = "",


	["~keshuaiyuanshao"] = "",
}







keshuaizhangjiao = sgs.General(extension_shuai, "keshuaizhangjiao", "qun", 4)

keshuaixiangru = sgs.CreateTriggerSkill{
	name = "keshuaixiangru",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.DamageInflicted) then
			local damage = data:toDamage()
			if damage.from and damage.damage>=damage.to:getHp()+damage.to:getHujia() then
				--两种情况都可以触发，因为其他人也可能有本技能，所以逻辑不用else
				if damage.to:hasSkill(self:objectName()) then
					for _, oth in sgs.qlist(room:getOtherPlayers(damage.to)) do
						if damage.from~=oth and oth:isWounded() and oth:getCardCount()>1 then
							oth:setTag("keshuaixiangruTo",ToData(damage.to))
							local card = room:askForExchange(oth, self:objectName(), 2, 2, true, "keshuaixiangruchoose:"..damage.from:objectName()..":"..damage.to:objectName(),true)
							if card then
								oth:skillInvoked(self,-1,damage.to)
								room:obtainCard(damage.from, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, damage.from:objectName(), oth:objectName(), self:objectName(), ""), false)
								return true
							end
						end
					end
				elseif damage.to:isWounded() then
				    for _, zj in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
						if zj:getCardCount()<2 or damage.from==zj then continue end
						zj:setTag("keshuaixiangruTo",ToData(damage.to))
						local card = room:askForExchange(zj, self:objectName(), 2, 2, true, "keshuaixiangruchoose:"..damage.from:objectName()..":"..damage.to:objectName(),true)
						if card then
							zj:skillInvoked(self,-1)
							room:obtainCard(damage.from, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, damage.from:objectName(), zj:objectName(), self:objectName(), ""), false)
							return true
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
keshuaizhangjiao:addSkill(keshuaixiangru)

keshuaiwudao = sgs.CreateTriggerSkill{
	name = "keshuaiwudao",
	frequency = sgs.Skill_Wake,
	waked_skills = "keshuaijinglei",
	events = {sgs.EnterDying},
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EnterDying) then
			for _, zj in sgs.qlist(room:getAllPlayers())do
				if zj:getMark(self:objectName())<1 and zj:hasSkill(self)
				and (zj:isKongcheng() or zj:canWake(self:objectName())) then
					room:sendCompulsoryTriggerLog(zj,self)
					room:doSuperLightbox(zj, "keshuaiwudao")
					room:changeMaxHpForAwakenSkill(zj,1,self:objectName())
					room:recover(zj, sgs.RecoverStruct(self:objectName(),zj))
					room:setPlayerMark(zj, self:objectName(), 1)
					room:acquireSkill(zj, "keshuaijinglei")
				end
			end
		end
	end,
}
keshuaizhangjiao:addSkill(keshuaiwudao)

keshuaijingleiCard = sgs.CreateSkillCard{
	name = "keshuaijingleiCard",
	target_fixed = false,
	will_throw = false,
	skill_name = "_keshuaijinglei",
	filter = function(self, targets, to_select, player)
		local he = 0
		for _, p in ipairs(targets) do
			he = he + p:getHandcardNum()
		end
		return (he + to_select:getHandcardNum()) < player:getMark("keshuaijinglei")
	end,
	on_use = function(self, room, player, targets)
		local jltarget
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("&keshuaijinglei") > 0 then
				jltarget = p
				break
			end
		end
		for _, p in ipairs(targets) do
			room:getThread():delay(666)
			room:damage(sgs.DamageStruct("keshuaijinglei", p, jltarget, 1,sgs.DamageStruct_Thunder))
		end
	end
}

keshuaijingleiVS = sgs.CreateViewAsSkill{
	name = "keshuaijinglei",
	n = 0 ,
	view_filter = function(self, selected, to_select)
		return false
	end ,
	view_as = function(self, cards)
		return keshuaijingleiCard:clone()
	end ,
	enabled_at_response = function(self,player,pattern)
		return pattern=="@@keshuaijinglei"
	end,
	enabled_at_play = function(self, player)
		return false
	end
}
keshuaijinglei = sgs.CreateTriggerSkill{
	name = "keshuaijinglei",
	events = {sgs.EventPhaseStart},
	view_as_skill = keshuaijingleiVS,
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) 
		and (player:getPhase() == sgs.Player_Start) then
			local eny = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "keshuaijinglei-ask",true,true)
			if eny then
				room:setPlayerMark(player,"keshuaijinglei",eny:getHandcardNum())
				room:setPlayerMark(eny,"&keshuaijinglei",1)
			    room:askForUseCard(player, "@@keshuaijinglei", "keshuaijingleiask")
				room:setPlayerMark(eny,"&keshuaijinglei",0)
			end
		end
	end,
}
extension_shuai:addSkills(keshuaijinglei)


sgs.LoadTranslationTable{

	["keshuaizhangjiao"] = "张角[衰]", 
	["&keshuaizhangjiao"] = "张角",
	["#keshuaizhangjiao"] = "万蛾赴火",
	["designer:keshuaizhangjiao"] = "官方",
	["cv:keshuaizhangjiao"] = "官方",
	["illustrator:keshuaizhangjiao"] = "鬼画府",

	["keshuaixiangru"] = "相濡",
	["keshuaixiangruchoose"] = "你可以发动“相濡”交给 %src 两张牌，防止 %dest 受到的致命伤害",
	[":keshuaixiangru"] = "你/已受伤的其他角色可以交给伤害来源两张牌防止已受伤的其他角色/你受到的致命伤害。",

	["keshuaiwudao"] = "悟道",
	[":keshuaiwudao"] = "觉醒技，当一名角色进入濒死状态时，若你没有手牌，你加1点体力上限并回复1点体力，然后获得“惊雷”。",

	["keshuaijinglei"] = "惊雷",
	["keshuaijingleiask"] = "你可以选择任意名手牌数之和小于其的角色",
	["keshuaijinglei-ask"] = "你可以选择发动“惊雷”的角色",
	["keshuaijinglei"] = "惊雷",
	[":keshuaijinglei"] = "准备阶段，你可以选择一名角色，然后令任意名手牌数之和小于其的角色各对其造成1点雷电伤害。",

	["$keshuaixiangru1"] = "",
	["$keshuaixiangru2"] = "",


	["~keshuaizhangjiao"] = "",
}

keshuailiubiao = sgs.General(extension_shuai, "keshuailiubiao", "qun", 3)

keshuaiyanshavs = sgs.CreateViewAsSkill{
	name = "keshuaiyansha",
	n = 1,
	view_filter = function(self, selected, to_select)
		local slash = dummyCard()
		slash:setSkillName("_keshuaiyansha")
		slash:addSubcard(to_select)
		return to_select:isKindOf("EquipCard")
		and not sgs.Self:isLocked(slash)
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return end
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("_keshuaiyansha")
		slash:addSubcard(cards[1])
		return slash
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern:startsWith("@@keshuaiyansha")
	end
}
--extension_shuai:addSkills(keshuaiyanshavs)


keshuaiyansha = sgs.CreateTriggerSkill{
	name = "keshuaiyansha",
	view_as_skill = keshuaiyanshavs,
	waked_skills = "#keshuaiyanshaslashex",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Start) then
			local tos = sgs.SPlayerList()
			local wgfd = sgs.Sanguosha:cloneCard("amazing_grace")
			wgfd:setSkillName("keshuaiyansha")
			for _, oth in sgs.qlist(room:getAllPlayers()) do
				if player:canUse(wgfd,oth) then
					tos:append(oth)
				end
			end
			local wgs = room:askForPlayersChosen(player, tos, self:objectName(), 0, 99, "keshuaiyansha-ask", true, true)
			if wgs:length() > 0 then
				for _,oth in sgs.qlist(wgs) do
					room:setPlayerMark(oth,"&keshuaiyansha",1)
				end
				room:useCard(sgs.CardUseStruct(wgfd,player,wgs), true)
				for _,q in sgs.qlist(room:getAllPlayers()) do
					if wgs:contains(q) then continue end
				    room:askForUseCard(q, "@@keshuaiyansha", "keshuaiyanshaslash-ask")
				end
				for _,p in sgs.qlist(wgs) do
					room:setPlayerMark(p,"&keshuaiyansha",0)
				end
			end
			wgfd:deleteLater()
		end
	end,
}
keshuailiubiao:addSkill(keshuaiyansha)
keshuaiyanshaslashex = sgs.CreateProhibitSkill{
	name = "#keshuaiyanshaslashex",
	is_prohibited = function(self, from, to, card)
		if table.contains(card:getSkillNames(), "xingkuangjian") then return from==to end
		return table.contains(card:getSkillNames(), "keshuaiyansha") and card:isKindOf("Slash")
		and to and to:getMark("&keshuaiyansha")<1
	end
}
keshuailiubiao:addSkill(keshuaiyanshaslashex)

keshuaiqingping = sgs.CreateTriggerSkill{
	name = "keshuaiqingping",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Finish) then
			local num = 0
			local log = sgs.LogMessage()
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if player:inMyAttackRange(p) then
					if (p:getHandcardNum() > 0)
					and (p:getHandcardNum() <= player:getHandcardNum()) then
						num = num + 1
						log.to:append(p)
					else
						num = 0
						break
					end
				end
			end
			if num > 0 and player:askForSkillInvoke(self) then
				room:broadcastSkillInvoke(self:objectName())
				log.type = "$keshuaiqingpinglog"
				log.from = player
				room:sendLog(log)
			    player:drawCards(num,self:objectName())
			end
		end
	end,
}
keshuailiubiao:addSkill(keshuaiqingping)



sgs.LoadTranslationTable{

	["keshuailiubiao"] = "刘表[衰]", 
	["&keshuailiubiao"] = "刘表",
	["#keshuailiubiao"] = "单骑入荆",
	["designer:keshuailiubiao"] = "官方",
	["cv:keshuailiubiao"] = "官方",
	["illustrator:keshuailiubiao"] = "鬼画府",

	["keshuaiyansha"] = "宴杀",
	["keshuaiyanshaslash-ask"] = "你可以将一张装备牌当无距离限制的【杀】对一名“宴杀”角色使用",
	["keshuaiyansha-ask"] = "你可以选择发动“宴杀”使用【五谷丰登】的角色",
	[":keshuaiyansha"] = "准备阶段，你可以视为对任意名角色使用一张【五谷丰登】，此牌结算后，不是此牌目标的角色依次选择是否将一张装备牌当无距离限制的【杀】对其中一名目标角色使用。",

	["keshuaiqingping"] = "清平",
	["$keshuaiqingpinglog"] = "%from 满足<font color='yellow'><b>“清平”</b></font> 条件的角色有：%to",
	[":keshuaiqingping"] = "结束阶段，若你的攻击范围内的所有角色手牌数均大于0且不大于你，你可以摸等同于这些角色数量的牌。",

	["$keshuaiyansha1"] = "任行仁义之道，何愁人心不归？",
	["$keshuaiyansha2"] = "稳据江汉，坐观时变。",

	["$keshuaiqingping1"] = "普天之下，莫非汉土。",
	["$keshuaiqingping2"] = "汉室宗亲，同出一门，何须多礼？",

	["~keshuailiubiao"] = "人心已陷，如何固守？",

}

keshuaizhanghuan = sgs.General(extension_shuai, "keshuaizhanghuan", "qun", 4)

keshuaizhushou = sgs.CreateTriggerSkill{
    name = "keshuaizhushou",
	frequency = sgs.Skill_NotFrequent,
	priority = 2,
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseChanging},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				--先发动效果，下面再清除
				for _, zh in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do  
					if zh:getMark("&keshuaizhushoulose-Clear") > 0 then
						local card_ids = room:getTag("keshuaizhushou_distag"):toIntList()
						--找到最大的点数
						local biggest_number = -1
						for _,id in sgs.qlist(card_ids) do
							local thecard = sgs.Sanguosha:getCard(id)
							if (thecard:getNumber() > biggest_number) then
								biggest_number = thecard:getNumber()
							end
						end
						local disable_chooses = sgs.IntList()
						local ids = sgs.IntList()
						--最大的点数是否唯一
						for _,id in sgs.qlist(card_ids) do
							if (room:getCardPlace(id) ~= sgs.Player_DiscardPile) then continue end
							local thecard = sgs.Sanguosha:getCard(id)
							if (thecard:getNumber() == biggest_number) then
								ids:append(id)
								if ids:length()>1 then return end
							else
								--这些牌等会儿会显示成灰色，不能被选，让玩家看看有一个整体把握，看最大的牌是哪张
								--初版是没有限制“唯一”，是真的可以选的
								disable_chooses:append(id)
							end
						end
						room:fillAG(card_ids,zh,disable_chooses)
						local card_id = room:askForAG(zh, ids, true, self:objectName(),"keshuaizhushouagask")
						if card_id>-1 then
							--检查有失去过此牌的角色
							local daplayers = sgs.SPlayerList()
							for _, dmd in sgs.qlist(room:getAllPlayers()) do  
								local dmdtag = dmd:getTag("keshuaizhushoutag"):toIntList()
								if dmdtag:contains(card_id) then
									daplayers:append(dmd)
								end
							end
							--这个时候可以反悔，不选择角色以取消伤害
							local sb = room:askForPlayerChosen(zh, daplayers, self:objectName(), "keshuaizhanghuan-ask", true, true)
							if sb then
								room:damage(sgs.DamageStruct(self:objectName(), zh, sb))
							end
						end
						room:clearAG(zh)
					end
				end
				--开始清除
				for _,p in sgs.qlist(room:getAllPlayers()) do
					p:removeTag("keshuaizhushoutag")
				end
				room:removeTag("keshuaizhushou_distag")
			end
		elseif (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			--记录玩家失去的牌
			if move.from and player:hasSkill(self,true)
			and (move.from_places:contains(sgs.Player_PlaceEquip) or move.from_places:contains(sgs.Player_PlaceHand)) then
				if move.from:objectName() == player:objectName() then
					room:setPlayerMark(player,"&keshuaizhushoulose-Clear",1)
				end
				local tag = move.from:getTag("keshuaizhushoutag"):toIntList()
				for _,card_id in sgs.qlist(move.card_ids) do
					tag:append(card_id)
				end
				local d = sgs.QVariant()
				d:setValue(tag)
				move.from:setTag("keshuaizhushoutag", d)
			end
			--记录进入弃牌堆的牌
			if (move.to_place == sgs.Player_DiscardPile) then
				local tag = room:getTag("keshuaizhushou_distag"):toIntList()
				for _,card_id in sgs.qlist(move.card_ids) do
					if not tag:contains(card_id) then
						tag:append(card_id)
					end
				end
				local d = sgs.QVariant()
				d:setValue(tag)
				room:setTag("keshuaizhushou_distag", d)
			end
		end
	end
}
keshuaizhanghuan:addSkill(keshuaizhushou)

keshuaiyanggeCard = sgs.CreateSkillCard{
	name = "keshuaiyanggeCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if #targets == 0 then
			return (to_select:objectName() ~= player:objectName())
			and to_select:hasSkill("keshuaiyangge")
		end
		return false
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:setPlayerMark(player,"&usedkeshuaiyangge_lun",1)
		local card_use = sgs.CardUseStruct()
		card_use.from = player
		card_use.to:append(target)
		card_use.card = sgs.Card_Parse("@MizhaoCard=.")
		room:useCard(card_use, true)  	   
		player:drawCards(1,self:getSkillName())
	end
}

keshuaiyanggeex = sgs.CreateZeroCardViewAsSkill{
	name = "keshuaiyanggeex&",
	enabled_at_play = function(self, player)
		--次数判断
		if (player:getMark("&usedkeshuaiyangge_lun") > 0) then
			return false
		end
		for _,p in sgs.qlist(player:getAliveSiblings()) do
			if (p:getMark("&usedkeshuaiyangge_lun") > 0) then
				return false
			end
		end
		--体力最低判断，只要有人比你低，你就不是最低
		for _,q in sgs.qlist(player:getAliveSiblings()) do
			if q:getHp() < player:getHp() then
				return false
			end
		end
		return player:getHandcardNum()>0
	end ,
	view_as = function()
		return keshuaiyanggeCard:clone()
	end
}
extension_shuai:addSkills(keshuaiyanggeex)

keshuaiyangge = sgs.CreateTriggerSkill{
    name = "keshuaiyangge",
	waked_skills = "mizhao",
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd,sgs.RoundEnd},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.EventPhaseEnd) then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:hasSkill("keshuaiyanggeex",true) then
				    room:detachSkillFromPlayer(p, "keshuaiyanggeex",true,true,false)
				end
			end
		end
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Play) then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasSkill(self:objectName(),true) then
						room:attachSkillToPlayer(player, "keshuaiyanggeex")
						break
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
}
keshuaizhanghuan:addSkill(keshuaiyangge)

sgs.LoadTranslationTable{

	["keshuaizhanghuan"] = "张奂[衰]", 
	["&keshuaizhanghuan"] = "张奂",
	["#keshuaizhanghuan"] = "正身洁己",
	["designer:keshuaizhanghuan"] = "官方",
	["cv:keshuaizhanghuan"] = "官方",
	["illustrator:keshuaizhanghuan"] = "峰雨同程",

	["keshuaizhushou"] = "诛首",
	["keshuaizhushoulose"] = "诛首失去过牌",
	["keshuaizhushouagask"] = "诛首：请确认点数唯一最大的牌，或点击确定以取消",
	["keshuaizhanghuan-ask"] = "你可以对本回合失去过此牌的一名角色造成1点伤害",
	[":keshuaizhushou"] = "你失去过牌的一个回合结束时，若本回合置入弃牌堆的牌中有唯一点数最大且该牌在弃牌堆中，你可以对本回合失去过此牌的一名角色造成1点伤害。",

	["keshuaiyangge"] = "扬戈",
	["keshuaiyanggeex"] = "扬戈密诏",
	[":keshuaiyangge"] = "每轮限一次，体力值最低的其他角色可以于其出牌阶段对你发动“密诏”。",
	["usedkeshuaiyangge"] = "已发动扬戈",


	["$keshuaizhushou1"] = "",
	["$keshuaizhushou2"] = "",


	["~keshuaizhanghuan"] = "",
}

keshuaiyangqiu = sgs.General(extension_shuai, "keshuaiyangqiu", "qun", 4)

keshuaisaojianCard = sgs.CreateSkillCard{
	name = "keshuaisaojianCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets < 1) 
		and not to_select:isKongcheng()
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]		
		local card_id = room:askForCardChosen(player, target, "h", self:getSkillName(),true)
		for _, p in sgs.qlist(room:getOtherPlayers(target)) do 
		    room:showCard(target,card_id,p,false)
		end
		for i = 1, 5 do
			if target:canDiscard(target, "h") then
				local dc = room:askForDiscard(target, self:getSkillName(), 1, 1)
				if dc:getEffectiveId() == card_id then
					break
				end
			end
		end
		if (target:getHandcardNum() > player:getHandcardNum()) then
			room:loseHp(player,1,true,player,self:getSkillName())
		end
	end
}
--主技能
keshuaisaojian = sgs.CreateViewAsSkill{
	name = "keshuaisaojian",
	n = 0,
	view_as = function(self, cards)
		return keshuaisaojianCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#keshuaisaojianCard")
	end, 
}
keshuaiyangqiu:addSkill(keshuaisaojian)

sgs.LoadTranslationTable{

	["keshuaiyangqiu"] = "阳球[衰]", 
	["&keshuaiyangqiu"] = "阳球",
	["#keshuaiyangqiu"] = "身蹈水火",
	["designer:keshuaiyangqiu"] = "官方",
	["cv:keshuaiyangqiu"] = "泪何不寐，小珂酱",
	["illustrator:keshuaiyangqiu"] = "鬼画府",

	["keshuaisaojian"] = "埽奸",
	[":keshuaisaojian"] = "出牌阶段限一次，你可以观看一名其他角色的手牌并向除该角色外的所有角色展示其中一张，该角色重复执行弃置一张手牌，直到其弃置了该牌或弃牌数达到五张，然后若其手牌数大于你，你失去1点体力。",

	["$keshuaisaojian2"] = "从实招来，免受皮肉之苦！",
	["$keshuaisaojian1"] = "阉竖当道，非酷刑不可服之！",


	["~keshuaiyangqiu"] = "只恨未扫尽奸宦，反受其害矣！",
}




keshuaidongzhuo = sgs.General(extension_shuai, "keshuaidongzhuo", "qun", 4)

keshuaiguanshiVS = sgs.CreateViewAsSkill{
	name = "keshuaiguanshi",
	n = 1,
	view_filter = function(self, selected, to_select)
        return (not sgs.Self:isLocked(to_select))
		and to_select:isKindOf("Slash")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local suit = cards[1]:getSuit()
			local point = cards[1]:getNumber()
			local id = cards[1]:getId()
			local fireattack = sgs.Sanguosha:cloneCard("FireAttack", suit, point)
			fireattack:setSkillName("keshuaiguanshi")
			fireattack:addSubcard(id)
			return fireattack
		end
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("keshuaiguanshiused-PlayClear") == 0)
	end,
}

keshuaiguanshi = sgs.CreateTriggerSkill{
    name = "keshuaiguanshi",
	view_as_skill =  keshuaiguanshiVS,
	events = {sgs.PreCardUsed,sgs.Damage,sgs.CardEffect,sgs.PostCardEffected},
	can_trigger = function(self, target)
		return target 
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.PostCardEffected) then
			local effect = data:toCardEffect()
		    if table.contains(effect.card:getSkillNames(),"keshuaiguanshi")
			and not effect.card:hasFlag("keshuaiguanshida") then
			    room:setCardFlag(effect.card,"keshuaiguanshijd")
		    end	
		end
		if (event == sgs.CardEffect) then
			local effect = data:toCardEffect()
			if table.contains(effect.card:getSkillNames(),"keshuaiguanshi")
			and effect.card:hasFlag("keshuaiguanshijd") then
				local juedou = sgs.Sanguosha:cloneCard("duel")
				juedou:setSkillName(effect.card:getSkillName(false))
				juedou:addSubcard(effect.card)
				effect.card = juedou
				data:setValue(effect)
				juedou:deleteLater()
			end
		end
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			if damage.card and table.contains(damage.card:getSkillNames(),"keshuaiguanshi") then
				room:setCardFlag(damage.card,"keshuaiguanshida")
			end
		end
		if (event == sgs.PreCardUsed) then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"keshuaiguanshi") then
				room:setPlayerMark(use.from,"keshuaiguanshiused-PlayClear",1)
			end
		end
	end
}
keshuaidongzhuo:addSkill(keshuaiguanshi)

keshuaicangxiong = sgs.CreateTriggerSkill{
	name = "keshuaicangxiong",
	events = {sgs.CardsMoveOneTime},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName()
			and not move.from_places:contains(sgs.Player_PlaceJudge) and not move.from_places:contains(sgs.Player_PlaceDelayedTrick)
			and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD
			or (move.to_place == sgs.Player_PlaceHand and move.to:objectName() ~= move.from:objectName())) then
				for _, id in sgs.qlist(move.card_ids) do
					local cxcard = sgs.Sanguosha:getCard(id)
					player:setTag("keshuaicangxiongId",ToData(id))
					if player:askForSkillInvoke(self,ToData("keshuaicangxiong-ask:"..cxcard:objectName())) then
						xumouCard(player,cxcard)
						if (player:getPhase() == sgs.Player_Play) then
							player:drawCards(1,self:objectName())
						end
					end
				end
			end
		end
	end,
}
keshuaidongzhuo:addSkill(keshuaicangxiong)

keshuaijiebing = sgs.CreatePhaseChangeSkill{
	name = "keshuaijiebing" ,
	frequency = sgs.Skill_Wake ,
	waked_skills = "keshuaibaowei",
	on_phasechange = function(self, player)
		local room = player:getRoom()
        room:sendCompulsoryTriggerLog(player, self)
		room:doSuperLightbox(player, "keshuaijiebing")
		room:setPlayerMark(player, self:objectName(), 1)
		if room:changeMaxHpForAwakenSkill(player,2,self:objectName()) then
			room:recover(player, sgs.RecoverStruct(self:objectName(),player,2))
			room:acquireSkill(player, "keshuaibaowei")
		end
		return false
	end,
	can_trigger = function(self, target)
		if target and target:isAlive() and target:getPhase() == sgs.Player_Start
		and target:getMark(self:objectName())<1 and target:hasSkill(self:objectName()) then
			local n = 0
			for _,c in sgs.qlist(target:getJudgingArea())do
				if string.find(c:objectName(),"kehexumou")
				then n = n + 1 end
			end
			local Lord = target:getRoom():getLord()
			return Lord and Lord:getHp()<n or target:canWake(self:objectName())
		end
	end
}
keshuaidongzhuo:addSkill(keshuaijiebing)

keshuaibaowei = sgs.CreateTriggerSkill{
	name = "keshuaibaowei",
	events = {sgs.CardResponded,sgs.CardUsed,sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) 
		and player:hasSkill(self:objectName())
		and (player:getPhase() == sgs.Player_Finish) then
			local aps = sgs.SPlayerList()
			for _, dmd in sgs.qlist(room:getOtherPlayers(player)) do   
				if (dmd:getMark("&keshuaibaowei-Clear") > 0) then
					aps:append(dmd)
				end
			end
			if (aps:length() == 1) then
				room:sendCompulsoryTriggerLog(player, self)
				room:doAnimate(1, player:objectName(),aps:at(0):objectName())
				room:damage(sgs.DamageStruct(self:objectName(), player, aps:at(0), 2))
			elseif (aps:length() > 1) then 
				room:sendCompulsoryTriggerLog(player, self)
				room:loseHp(player,2,true,player,self:objectName())
			end
		end
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				local cp = room:getCurrent()
				if cp~=player and cp:hasSkill(self,true) then
					room:setPlayerMark(player,"&keshuaibaowei-Clear",1)
				end
			end
		end
		if (event == sgs.CardResponded) then
			local response = data:toCardResponse()
			if response.m_card:getTypeId()>0 then
				local cp = room:getCurrent()
				if cp~=player and cp:hasSkill(self,true) then
					room:setPlayerMark(player,"&keshuaibaowei-Clear",1)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
}
extension_shuai:addSkills(keshuaibaowei)


sgs.LoadTranslationTable{

	["keshuaidongzhuo"] = "董卓[衰]", 
	["&keshuaidongzhuo"] = "董卓",
	["#keshuaidongzhuo"] = "华夏震栗",
	["designer:keshuaidongzhuo"] = "官方",
	["cv:keshuaidongzhuo"] = "官方",
	["illustrator:keshuaidongzhuo"] = "鬼画府",

	["keshuaiguanshi"] = "观势",
	[":keshuaiguanshi"] = "出牌阶段限一次，你可以将一张【杀】当无目标数限制的【火攻】使用，当此牌对一名角色结算结束时，若此牌没有造成过伤害，此牌对剩余角色以【决斗】效果结算。",

	["keshuaicangxiong"] = "藏凶",
	["keshuaicangxiong:keshuaicangxiong-ask"] = "你可以发动“藏凶”将这张【%src】蓄谋",
	[":keshuaicangxiong"] = "当你的牌被弃置或被其他角色获得后，你可以将此牌蓄谋，若此时为你的出牌阶段，你摸一张牌。",

	["keshuaijiebing"] = "劫柄",
	[":keshuaijiebing"] = "觉醒技，准备阶段，若你判定区内的蓄谋牌数量大于主公的体力值，你加2点体力上限并回复2点体力，然后获得“暴威”。",

	["keshuaibaowei"] = "暴威",
	[":keshuaibaowei"] = "锁定技，结束阶段，若本回合使用或打出过牌的其他角色的数量：等于1，你对其造成2点伤害；大于1，你失去2点体力。",

	["$keshuaiguanshi1"] = "挡我者死！",
	["$keshuaiguanshi2"] = "看尔等骄狂到几时！",
	["$keshuaicangxiong1"] = "汝甚得吾心，杀得好！",
	["$keshuaicangxiong2"] = "忠君护主，嗯，加官进爵！",
	["$keshuaijiebing1"] = "权势手中握，富贵梦里来。",
	["$keshuaijiebing2"] = "整个天下都要臣服于我！",
	["$keshuaibaowei1"] = "哪个敢反我？",
	["$keshuaibaowei2"] = "大汉天下，唯我独尊，哈哈哈哈哈哈哈！",

	["~keshuaidongzhuo"] = "胜者为王，败者为寇，我无话可说。",
}

keshuailuzhi = sgs.General(extension_shuai, "keshuailuzhi", "qun", 3)

keshuairuzong = sgs.CreateTriggerSkill{
	name = "keshuairuzong",
	events = {sgs.EventPhaseChanging, sgs.TargetSpecified},
	frequency = sgs.Skill_NotFrequent, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				local theone = {}
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("keshuairuzonguse-Clear")>0 then
						table.insert(theone,p)
					end
				end
				if #theone==1 then
					if theone[1] == player then
						local canchooses = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getAllPlayers()) do
							if (p:getHandcardNum() < player:getHandcardNum()) then
								canchooses:append(p)
							end
						end
						local rzs = room:askForPlayersChosen(player, canchooses, self:objectName(), 0, 99, "keshuairuzongask", true, true)
						for _, rz in sgs.qlist(rzs) do
							local cha = player:getHandcardNum() - rz:getHandcardNum()
							rz:drawCards(cha,self:objectName())
						end
					else
						local cha = theone[1]:getHandcardNum() - player:getHandcardNum()
						if cha>0 and player:askForSkillInvoke(self,ToData("keshuairuzong-ask:"..theone[1]:objectName())) then
							player:drawCards(cha,self:objectName())
						end
					end
				end
			end
		end
		if (event == sgs.TargetSpecified) then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				for _, t in sgs.qlist(use.to) do
					room:setPlayerMark(t,"keshuairuzonguse-Clear",1)
				end
			end
		end
	end
}
keshuailuzhi:addSkill(keshuairuzong)

keshuaidaorenCard = sgs.CreateSkillCard{
	name = "keshuaidaorenCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return (#targets < 1) and (to_select:objectName() ~= player:objectName())
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:giveCard(player,target,self,self:getSkillName())
		local log = sgs.LogMessage()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if player:inMyAttackRange(p) and target:inMyAttackRange(p) then
				log.to:append(p)
			end
		end
		log.type = "$keshuaidaorenlog"
		if (log.to:length() > 0) then
			room:sendLog(log)
		end
		for _, da in sgs.qlist(log.to) do
			room:damage(sgs.DamageStruct(self:getSkillName(), player, da, 1))
		end
	end
}

keshuaidaoren = sgs.CreateViewAsSkill{
    name = "keshuaidaoren",
    n = 1,
    view_filter = function(self, selected, to_select)
        return (not to_select:isEquipped())
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local card = keshuaidaorenCard:clone()
            for _,cc in ipairs(cards) do
                card:addSubcard(cc)
            end
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#keshuaidaorenCard")
    end
}
keshuailuzhi:addSkill(keshuaidaoren)

sgs.LoadTranslationTable{

	["keshuailuzhi"] = "卢植[衰]", 
	["&keshuailuzhi"] = "卢植",
	["#keshuailuzhi"] = "眸宿渊渟",
	["designer:keshuailuzhi"] = "官方",
	["cv:keshuailuzhi"] = "官方",
	["illustrator:keshuailuzhi"] = "峰雨同程",

	["keshuairuzong"] = "儒宗",
	["keshuairuzongask"] = "你可以令任意名角色将手牌数摸至与你相同",
	["keshuairuzong:keshuairuzong-ask"] = "你可以发动“儒宗”将手牌摸至与 %src 相同",

	[":keshuairuzong"] = "回合结束时，若你本回合使用牌仅指定过一名角色为目标，若这名角色：是你，你可以令任意名其他角色将手牌数摸至与你相同；不是你，你可以将手牌数摸至与其相同。",

	["keshuaidaoren"] = "蹈刃",
	["$keshuaidaorenlog"] = "满足<font color='yellow'><b>“蹈刃”</b></font>条件的角色有 %to",
	[":keshuaidaoren"] = "出牌阶段限一次，你可以交给一名角色一张手牌，然后你对你与其攻击范围内均包含的角色各造成1点伤害。",

	["$keshuairuzong1"] = "抱才育器，以效国家！",
	["$keshuairuzong2"] = "内举不避亲，外举不避仇！",
	["$keshuaidaoren1"] = "无君无父之辈，怎敢在此造次！",
	["$keshuaidaoren2"] = "召虎狼以平乱，无异饮鸩止渴！",

	["~keshuailuzhi"] = "朝廷重用这种人等，怎会不败...",
	
}

keshuaisonghuanghou = sgs.General(extension_shuai, "keshuaisonghuanghou", "qun", 3,false)

keshuaizhongzen = sgs.CreateTriggerSkill{
	name = "keshuaizhongzen",
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd,sgs.CardsMoveOneTime},
	frequency = sgs.Skill_NotFrequent, 
	can_trigger = function(self, target)
		return target and target:isAlive()
		and target:getPhase() == sgs.Player_Discard
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.to_place == sgs.Player_DiscardPile
			and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
				local tag = player:getTag("keshuaizhongzentag"):toIntList()
				for _,id in sgs.qlist(move.card_ids) do
					if not tag:contains(id) then
						tag:append(id)
					end
				end
				local d = sgs.QVariant()
				d:setValue(tag)
				player:setTag("keshuaizhongzentag", d)
			end
		end
		if event == sgs.EventPhaseStart and player:hasSkill(self) then
			local tos = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getHandcardNum() < player:getHandcardNum() then
					tos:append(p)
				end
			end
			if tos:length()>0 then
				room:sendCompulsoryTriggerLog(player,self)
			end
			for _, p in sgs.qlist(tos) do
				if p:getHandcardNum()>0 then
					local card = room:askForExchange(p, self:objectName(), 1, 1, false, "keshuaizhongzen_give:"..player:objectName())
					if card then
						room:giveCard(p, player, card, self:objectName())
					end
				end
			end
		end
		if event == sgs.EventPhaseEnd then
			local spades = 0
			for _,id in sgs.qlist(player:getTag("keshuaizhongzentag"):toIntList()) do
				if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Spade then
					spades = spades + 1
				end
			end
			player:removeTag("keshuaizhongzentag")
			if spades > player:getHp() and player:hasSkill(self) then
				room:sendCompulsoryTriggerLog(player,self)
				player:throwAllHandCardsAndEquips(self:objectName())
			end
		end
	end
}
keshuaisonghuanghou:addSkill(keshuaizhongzen)

keshuaixuchong = sgs.CreateTriggerSkill{
	name = "keshuaixuchong",
	events = {sgs.TargetConfirmed},
	frequency = sgs.Skill_NotFrequent, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.TargetConfirmed) then
			local use = data:toCardUse()
			if (not use.card:isKindOf("SkillCard"))
			and use.to:contains(player) and player:hasSkill(self:objectName()) then
				if player:askForSkillInvoke(self:objectName(), data) then
					if room:askForChoice(player,self:objectName(),"draw+add") == "draw" then
						player:drawCards(1,self:objectName())
					else
						local log = sgs.LogMessage()
						log.type = "$keshuaixuchongaddlog"
						log.from = room:getCurrent()
						room:sendLog(log)
						room:addMaxCards(room:getCurrent(), 2, true)
					end
					for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
						if sgs.Sanguosha:getEngineCard(id):isKindOf("Ying")
						and room:getCardOwner(id) == nil then
							player:obtainCard(sgs.Sanguosha:getCard(id), true)
							break
						end
					end
				end
			end
		end
	end
}
keshuaisonghuanghou:addSkill(keshuaixuchong)

sgs.LoadTranslationTable{

	["keshuaisonghuanghou"] = "宋皇后[衰]", 
	["&keshuaisonghuanghou"] = "宋皇后",
	["#keshuaisonghuanghou"] = "兰心蕙质",
	["designer:keshuaisonghuanghou"] = "官方",
	["cv:keshuaisonghuanghou"] = "官方",
	["illustrator:keshuaisonghuanghou"] = "峰雨同程",

	["keshuaizhongzen"] = "众谮",
	[":keshuaizhongzen"] = "锁定技，弃牌阶段开始时，手牌数小于你的角色各交给你一张手牌；弃牌阶段结束时，若你本阶段弃置的♠牌的数量大于体力值，你弃置所有牌。",
	["keshuaizhongzen_give"] = "众谮：请交给 %src 一张手牌",

	["keshuaixuchong"] = "虚宠",
	["$keshuaixuchongaddlog"] = "%from 本回合的手牌上限+2",
	["keshuaixuchong:draw"] = "摸一张牌",
	["keshuaixuchong:add"] = "当前回合角色本回合的手牌上限+2",
	[":keshuaixuchong"] = "当你成为牌的目标后，你可以摸一张牌或令当前回合角色本回合的手牌上限+2，然后你从游戏外获得一张【影】。",

	["$keshuaizhongzen1"] = "",
	["$keshuaizhongzen2"] = "",
	["$keshuaixuchong1"] = "",
	["$keshuaixuchong2"] = "",

	["~keshuaisonghuanghou"] = "",
}

keshuaichenfan = sgs.General(extension_shuai, "keshuaichenfan", "qun", 3)

keshuaigangfen = sgs.CreateTriggerSkill{
	name = "keshuaigangfen",
	events = {sgs.TargetSpecifying},
	frequency = sgs.Skill_NotFrequent, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.TargetSpecifying) then
			local use = data:toCardUse()
			if (use.card:isKindOf("Slash")) then
				room:setTag("keshuaigangfenData",data)
				for _,cf in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
					if use.to:contains(cf) then continue end
					if use.from:getHandcardNum() > cf:getHandcardNum()
					and cf:askForSkillInvoke(self,ToData("keshuaigangfenask:"..use.from:objectName())) then
						use.to:append(cf)
						local log = sgs.LogMessage()
						log.card_str = use.card:toString()
						log.type = "#keshuaigangfenask2"
						log.from = cf
						room:sendLog(log)
						for _,oth in sgs.qlist(room:getOtherPlayers(use.from)) do
							if use.to:contains(oth) then continue end
							if oth:askForSkillInvoke(self,ToData("keshuaigangfenask2:"..cf:objectName()),false) then
								use.to:append(oth)
								log.from = oth
								room:sendLog(log)
							end
						end
						room:showAllCards(use.from)
						local blacks = 0
						for _,c in sgs.qlist(use.from:getCards("h")) do
							if c:isBlack() then blacks = blacks+1 end
						end
						if (blacks < use.to:length()) then
							use.to = sgs.SPlayerList()
						end
						room:sortByActionOrder(use.to)
						data:setValue(use)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
keshuaichenfan:addSkill(keshuaigangfen)


keshuaidangrenVS = sgs.CreateViewAsSkill{
	name = "keshuaidangren",
	n = 0,
	view_filter = function(self, selected, to_select)
		return false
	end ,
	view_as = function(self, cards)
		local pichi = sgs.Sanguosha:cloneCard("Peach")
		pichi:setSkillName("keshuaidangren")
		return pichi
	end,
	enabled_at_play = function(self, player)
		if player:getChangeSkillState("keshuaidangren")~=1 then return end
		local pichi = sgs.Sanguosha:cloneCard("Peach")
		pichi:setSkillName("keshuaidangren")
		pichi:deleteLater()
		return pichi:isAvailable(player)
	end
}

keshuaidangren = sgs.CreateTriggerSkill{
	name = "keshuaidangren",
	change_skill = true,
	view_as_skill = keshuaidangrenVS,
	events = {sgs.AskForPeaches,sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.AskForPeaches) then
			local dying = data:toDying()
			local pichi = sgs.Sanguosha:cloneCard("Peach")
			pichi:setSkillName("keshuaidangren")
			if dying.who == player then
				if player:getChangeSkillState("keshuaidangren")==1
				and player:canUse(pichi,dying.who) and player:askForSkillInvoke(self,ToData("keshuaidangrenself"),false) then
					room:useCard(sgs.CardUseStruct(pichi,player))
				end
			else
				if player:getChangeSkillState("keshuaidangren")==2 and player:canUse(pichi,dying.who) then
					room:sendCompulsoryTriggerLog(player,self:objectName())
					room:useCard(sgs.CardUseStruct(pichi,player,dying.who))
				end
			end
			pichi:deleteLater() 
		elseif (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),self:objectName()) then
				if (player:getChangeSkillState("keshuaidangren") == 1) then
				    room:setChangeSkillState(player, "keshuaidangren", 2)
				elseif (player:getChangeSkillState("keshuaidangren") == 2) then
					room:setChangeSkillState(player, "keshuaidangren", 1)
				end
			end
		end
	end,
}
keshuaichenfan:addSkill(keshuaidangren)

sgs.LoadTranslationTable{

	["keshuaichenfan"] = "陈蕃[衰]", 
	["&keshuaichenfan"] = "陈蕃",
	["#keshuaichenfan"] = "不畏强御",
	["designer:keshuaichenfan"] = "官方",
	["cv:keshuaichenfan"] = "官方",
	["illustrator:keshuaichenfan"] = "峰雨同程",

	["keshuaigangfen"] = "刚忿",
	["keshuaigangfen:keshuaigangfenask"] = "你可以对 %src 发动“刚忿”成为此【杀】的额外目标",
	["keshuaigangfen:keshuaigangfenask2"] = "%src 发动了“刚忿”，你可以成为此【杀】的额外目标",
	[":keshuaigangfen"] = "当手牌数大于你的角色使用【杀】指定目标后，若目标不包括你，你可以成为此【杀】的额外目标，且其他非目标角色也可以如此做，然后使用者展示所有手牌，若其中黑色牌小于目标数，取消此【杀】的所有目标。",
	["#keshuaigangfenask2"] = "%from 选择成为此 %card 的目标",

	["keshuaidangren"] = "当仁",
	[":keshuaidangren"] = "转换技，①当你需要对你使用【桃】时，你可以视为使用之；②当其他角色处于濒死状态时，你视为对其使用一张【桃】。",
	[":keshuaidangren1"] = "转换技，①当你需要对你使用【桃】时，你可以视为使用之；<font color=\"#01A5AF\"><s>②当其他角色处于濒死状态时，你视为对其使用一张【桃】</s></font>。",
	[":keshuaidangren2"] = "转换技，<font color=\"#01A5AF\"><s>①当你需要对你使用【桃】时，你可以视为使用之</s></font>；②当其他角色处于濒死状态时，你视为对其使用一张【桃】。",
	["keshuaidangren:keshuaidangrenself"] = "你可以发动“当仁”，视为使用【桃】",

	["$keshuaizhongzen1"] = "",
	["$keshuaizhongzen2"] = "",
	["$keshuaixuchong1"] = "",
	["$keshuaixuchong2"] = "",

	["~keshuaichenfan"] = "",
}

keshuaizhangju = sgs.General(extension_shuai, "keshuaizhangju", "qun", 4)

keshuaiqiluanCard = sgs.CreateSkillCard{
	name = "keshuaiqiluanCard",
	filter = function(self, targets, to_select, player)
		local pattern = self:getUserString()
		local slash = dummyCard(pattern)
		if not slash or slash:targetFixed()
		then return false end
		local plist = sgs.PlayerList()
		for i = 1, #targets do
			plist:append(targets[i])
		end
		return slash:targetFilter(plist, to_select, player)
	end,
	feasible = function(self,targets)
		local pattern = self:getUserString()
		local slash = dummyCard(pattern)
		return slash and (slash:targetFixed() or #targets>0)
	end,
	on_validate_in_response = function(self,from)
		local room = from:getRoom()
		local num = self:subcardsLength()
		local fris = room:askForPlayersChosen(from, room:getOtherPlayers(from), self:getSkillName(), 1, num, "keshuaiqiluan_ask_slash", true, true)
		room:throwCard(self,self:getSkillName(),from)
		local pattern = self:getUserString()
		room:addPlayerMark(from,"keshuaiqiluanUse-Clear")
		for _, fri in sgs.qlist(fris) do
			local sha = room:askForCard(fri,pattern,"keshuaiqiluan-slash", ToData(from),sgs.Card_MethodResponse,from,false,"",true)
			if sha then
				from:drawCards(num,self:getSkillName())
				return sha
			end
		end
		return nil
	end,
	on_validate = function(self,use)
		local room = use.from:getRoom()
		local num = self:subcardsLength()
		local fris = room:askForPlayersChosen(use.from, room:getOtherPlayers(use.from), self:getSkillName(), 1, num, "keshuaiqiluan_ask_slash", true, true)
		room:throwCard(self,self:getSkillName(),use.from)
		local pattern = self:getUserString()
		room:addPlayerMark(use.from,"keshuaiqiluanUse-Clear")
		for _, fri in sgs.qlist(fris) do
			local sha = room:askForCard(fri,pattern,"keshuaiqiluan-slash", ToData(use.from),sgs.Card_MethodResponse,use.from,false,"",true)
			if sha then
				use.from:drawCards(num,self:getSkillName())
				return sha
			end
		end
		return nil
	end,
}
keshuaiqiluan = sgs.CreateViewAsSkill{
	name = "keshuaiqiluan",
	n = 999,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
        return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards >= 1 then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern=="" then pattern = "slash" end
			local card = keshuaiqiluanCard:clone()
			card:setUserString(pattern)
			for _,c in pairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("keshuaiqiluanUse-Clear")<2
		and sgs.Slash_IsAvailable(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash" or pattern == "jink") and player:getMark("keshuaiqiluanUse-Clear")<2
		and sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
	end
}
keshuaizhangju:addSkill(keshuaiqiluan)

--[[keshuaiqiluanCard = sgs.CreateSkillCard{
	name = "keshuaiqiluanCard",
	filter = function(self, targets, to_select, player)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local plist = sgs.PlayerList()
		for i = 1, #targets, 1 do
			plist:append(targets[i])
		end
		return slash:targetFilter(plist, to_select, sgs.Self)
	end,
	on_use = function(self, room, player, targets)
		local num = self:getSubcards():length()
		local slashtars = sgs.SPlayerList()
		for _, p in ipairs(targets) do
			slashtars:append(p)
		end
		local fris = room:askForPlayersChosen(player, room:getOtherPlayers(player), self:objectName(), 0, num, "keshuaiqiluanplayerask_slash", true, true)
		for _, fri in sgs.qlist(fris) do	
			local sha = room:askForExchange(player, self:objectName(), 1, 1, false, "keshuaiqiluan-slash",true,"Slash")
			--local sha = room:askForCard(fri,"slash","keshuaiqiluan-slash", data,sgs.Card_MethodResponse)
			if sha then
				local slash = sgs.Sanguosha:cloneCard("slash")
				slash:addSubcard(sha)
				slash:setSkillName("_keshuaiqiluan")
				local card_use = sgs.CardUseStruct()
				card_use.from = player
				card_use.to = slashtars
				card_use.card = slash
				room:useCard(card_use, true)
				slash:deleteLater()  
			end
		end
	end
}

keshuaiqiluanVS = sgs.CreateViewAsSkill{
	name = "keshuaiqiluan",
	n = 999,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
        return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards >= 1 then
			local card = keshuaiqiluanCard:clone()
			for _,c in pairs(cards) do
				card:addSubcard(c)
			end
			return card
		else
			return nil
		end
	end,
	enabled_at_play = function(self, player)
		return not (player:hasUsed("#keshuaiqiluanCard")) 
	end, 
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash")
	end
}

keshuaiqiluan = sgs.CreateTriggerSkill{
	name = "keshuaiqiluan",
	events = {sgs.CardAsked},
	view_as_skill = keshuaiqiluanVS,
	frequency = sgs.Skill_NotFrequent, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardAsked) then
			local pattern = data:toStringList()
			if (pattern[1] == "jink") then 
				local xxx = room:askForDiscard(player, self:objectName(), 999, 0, true, true, "keshuaiqiluanask")
				if xxx then
					local fris = room:askForPlayersChosen(player, room:getOtherPlayers(player), self:objectName(), 0, xxx:getSubcards():length(), "keshuaiqiluanplayerask_jink", true, true)
					for _, fri in sgs.qlist(fris) do	
						local shan = room:askForCard(fri,"jink","keshuaiqiluan-jink", data,sgs.Card_MethodResponse)
						if shan then
							room:provide(shan)
							player:drawCards(xxx:getSubcards():length(),self:objectName())
							return true
						end
					end
				end
			end
			if (pattern[3]=="response") and string.find(pattern[1], "slash") then 
				local xxx = room:askForDiscard(player, self:objectName(), 999, 0, true, true, "keshuaiqiluanask")
				if xxx then
					local fris = room:askForPlayersChosen(player, room:getOtherPlayers(player), self:objectName(), 0, xxx:getSubcards():length(), "keshuaiqiluanplayerask_slash", true, true)
					for _, fri in sgs.qlist(fris) do	
						local sha = room:askForCard(fri,"slash","keshuaiqiluan-slash", data,sgs.Card_MethodResponse)
						if sha then
							room:provide(sha)
							player:drawCards(xxx:getSubcards():length(),self:objectName())
							return true
						end
					end
				end
			end
		end
	end
}
keshuaizhangju:addSkill(keshuaiqiluan)]]

keshuaixiangjiaVS = sgs.CreateZeroCardViewAsSkill{
	name = "keshuaixiangjia",
	enabled_at_play = function(self, player)
		return player:getWeapon() and player:getMark("keshuaixiangjiaUse-Clear")<1
	end ,
	view_as = function()
		local jdsr = sgs.Sanguosha:cloneCard("Collateral")
		jdsr:setSkillName("keshuaixiangjia")
		return jdsr
	end
}

keshuaixiangjia = sgs.CreateTriggerSkill{
	name = "keshuaixiangjia",
	view_as_skill = keshuaixiangjiaVS,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"keshuaixiangjia")
			and use.card:isKindOf("Collateral")  then
				room:addPlayerMark(player,"keshuaixiangjiaUse-Clear")
				local slashones = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if use.from:canSlash(p) then
						slashones:append(p)
					end
				end
				if slashones:length()>0 and use.to:at(0):askForSkillInvoke(self,data,false) then
					local jdsr = sgs.Sanguosha:cloneCard("Collateral")
					jdsr:setSkillName("_keshuaixiangjia")
					local card_use = sgs.CardUseStruct()
					card_use.from = use.to:at(0)
					card_use.to:append(use.from)
					card_use.card = jdsr
					room:useCard(card_use, false)
					jdsr:deleteLater()
				end
			end
		end
	end,
	--[[can_trigger = function(self,target)
		return target
	end]]
}
keshuaizhangju:addSkill(keshuaixiangjia)

sgs.LoadTranslationTable{

	["keshuaizhangju"] = "张举[衰]", 
	["&keshuaizhangju"] = "张举",
	["#keshuaizhangju"] = "草头天子",
	["designer:keshuaizhangju"] = "官方",
	["cv:keshuaizhangju"] = "官方",
	["illustrator:keshuaizhangju"] = "峰雨同程",

	["keshuaiqiluan"] = "起乱",
	["keshuaiqiluan_ask_slash"] = "你可以令等量的角色选择是否打出一张【杀】（【闪】）",
	["keshuaiqiluan-slash"] = "你可以打出一张【杀】令其使用之",
	[":keshuaiqiluan"] = "每回合限两次，当你需要使用【杀】/【闪】时，你可以弃置任意张牌并令至多X名角色选择是否打出一张【杀】/【闪】直到有角色响应（X为你弃置的牌数），你摸X张牌并使用此牌。",

	["keshuaixiangjia"] = "相假",
	[":keshuaixiangjia"] = "出牌阶段限一次，若你的装备区内有武器牌，你可以视为对一名角色使用【借刀杀人】，此牌结算后，其可以视为对你使用一张【借刀杀人】。",

	["$keshuaiqiluan1"] = "",
	["$keshuaiqiluan2"] = "",
	["$keshuaixiangjia1"] = "",
	["$keshuaixiangjia2"] = "",

	["~keshuaizhangju"] = "",
}



keshuaicaojiewangfu = sgs.General(extension_shuai, "keshuaicaojiewangfu", "qun", 3)

keshuaizonghai = sgs.CreateTriggerSkill{
	name = "keshuaizonghai",
    frequency = sgs.Skill_NotFrequent,
	events = {sgs.EnterDying,sgs.QuitDying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.QuitDying) then
			local dying = data:toDying()
			for _, dmd in sgs.qlist(room:getAllPlayers()) do 
				for _, p in sgs.qlist(room:getAllPlayers()) do 
					if dmd:getMark("&keshuaizonghai+#"..p:objectName())>0 then
						room:setPlayerMark(dmd,"&keshuaizonghai+#"..p:objectName(),0)
						room:damage(sgs.DamageStruct(self:objectName(),p,dmd))
					end
				end
				if dmd:hasFlag("keshuaizonghai") then
					dmd:setFlags("-keshuaizonghai")
					room:removePlayerCardLimitation(dmd,"use",".")
				end
			end
		end
		if (event == sgs.EnterDying) then
			local dying = data:toDying()
			for _, cw in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do 
				if cw:getMark("&usedkeshuaizonghai_lun")<1
				and cw~=dying.who and dying.who:isAlive() then
					local to_data = sgs.QVariant()
					to_data:setValue(dying.who)
					if cw:askForSkillInvoke(self, to_data) then
						room:setPlayerMark(cw,"&usedkeshuaizonghai_lun",1)
						local daomeidans = room:askForPlayersChosen(dying.who, room:getAllPlayers(), self:objectName(), 0, 2, "keshuaizonghai-ask", false, true)
						for _,dmd in sgs.qlist(room:getAllPlayers()) do 
							if daomeidans:contains(dmd) then
								room:doAnimate(1,dying.who:objectName(),dmd:objectName())
								room:setPlayerMark(dmd,"&keshuaizonghai+#"..cw:objectName(),1)
							else
								dmd:setFlags("keshuaizonghai")
								room:setPlayerCardLimitation(dmd,"use",".",false)
							end
						end
					end
				end
			end
		end
	end ,
	can_trigger = function(self, player)
		return player
	end,
}
keshuaicaojiewangfu:addSkill(keshuaizonghai)

keshuaijueyin = sgs.CreateTriggerSkill{
	name = "keshuaijueyin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged,sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.ConfirmDamage) then
			local damage = data:toDamage()
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if (p:getMark("&keshuaijueyinda-Clear") > 0) then
					room:sendCompulsoryTriggerLog(p,self)
					damage.damage = damage.damage + 1
				end
			end
			data:setValue(damage)
		end
		if (event == sgs.Damaged) 
		and player:hasSkill(self:objectName())
		and player:getMark("keshuaijueyin-Clear")<1 then
			room:addPlayerMark(player,"keshuaijueyin-Clear")
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:setPlayerMark(player,"&keshuaijueyinda-Clear",1)
				player:drawCards(3,self:objectName())
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
keshuaicaojiewangfu:addSkill(keshuaijueyin)

sgs.LoadTranslationTable{

	["keshuaicaojiewangfu"] = "曹节&王甫[衰]", 
	["&keshuaicaojiewangfu"] = "曹节王甫",
	["#keshuaicaojiewangfu"] = "独乱海内",
	["designer:keshuaicaojiewangfu"] = "官方",
	["cv:keshuaicaojiewangfu"] = "官方",
	["illustrator:keshuaicaojiewangfu"] = "峰雨同程",

	["keshuaizonghai"] = "纵害",
	["usedkeshuaizonghai"] = "已使用纵害",
	["keshuaizonghai-ask"] = "请选择至多两名角色（只有这些角色才能使用牌直到你脱离濒死状态）",
	[":keshuaizonghai"] = "每轮限一次，当其他角色进入濒死状态时，你可以令其选择至多两名角色，没有被选择的角色不能使用牌直到其脱离濒死状态后，你对其选择的角色各造成1点伤害。",

	["keshuaijueyin"] = "绝禋",
	["keshuaijueyinda"] = "绝禋伤害",
	[":keshuaijueyin"] = "当你每回合首次受到伤害后，你可以摸三张牌，然后本回合所有角色受到的伤害+1。",

	["$keshuaiqiluan1"] = "",
	["$keshuaiqiluan2"] = "",
	["$keshuaixiangjia1"] = "",
	["$keshuaixiangjia2"] = "",

	["~keshuaizhangju"] = "",
}




extension_xing = sgs.Package("jsrgxing", sgs.Package_GeneralPack)


xing_simazhao = sgs.General(extension_xing, "xing_simazhao", "wei", 4)
xingqiantunCard = sgs.CreateSkillCard{
	name = "xingqiantunCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < 1 and to_select ~= player
		and to_select:getHandcardNum()>0
	end,
	on_use = function(self, room, player, targets)
		local tos = {}
		for _, p in sgs.list(targets) do
			local dc = room:askForExchange(p,self:getSkillName(),999,1,false,"xingqiantun0:")
			if dc then
				room:showCard(p,dc:getSubcards())
				p:setTag("xingqiantunIds",ToData(dc:getSubcards()))
				table.insert(tos,p)
			end
		end
		for _, p in sgs.list(tos) do
			local dc = dummyCard()
			local ids = p:getTag("xingqiantunIds"):toIntList()
			if player:pindian(p,self:getSkillName()) then
				for _, id in sgs.list(ids) do
					if p:handCards():contains(id) then
						dc:addSubcard(id)
					end
				end
			else
				for _, id in sgs.list(p:handCards()) do
					if not ids:contains(id) then
						dc:addSubcard(id)
					end
				end
			end
			player:obtainCard(dc)
		end
		room:showAllCards(player)
	end
}
xingqiantunvs = sgs.CreateViewAsSkill{
    name = "xingqiantun",
    view_as = function(self, cards)
        return xingqiantunCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#xingqiantunCard")
    end
}
xingqiantun = sgs.CreateTriggerSkill{
	name = "xingqiantun",
	view_as_skill = xingqiantunvs,
	events = {sgs.AskforPindianCard},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.AskforPindianCard) then
			local pd = data:toPindian()
			if pd.from==player and pd.reason==self:objectName() then
				local dc = sgs.QList2Table(pd.to:getTag("xingqiantunIds"):toIntList())
				dc = room:askForExchange(pd.to,"xingqiantun_pd",1,1,false,"xingqiantun_pd:"..player:objectName(),false,table.concat(dc,","))
				if dc then
					pd.to_card = sgs.Sanguosha:getCard(dc:getEffectiveId())
					data:setValue(pd)
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
xing_simazhao:addSkill(xingqiantun)
xingxiezhengvs = sgs.CreateViewAsSkill{
    name = "xingxiezheng",
    view_as = function(self, cards)
		local dc = sgs.Sanguosha:cloneCard("_ov_binglinchengxia")
		dc:setSkillName("_"..self:objectName())
        return dc
    end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@xingxiezheng!"
	end,
    enabled_at_play = function(self, player)
        return false
    end
}
xingxiezheng = sgs.CreateTriggerSkill{
	name = "xingxiezheng",
	view_as_skill = xingxiezhengvs,
	events = {sgs.EventPhaseStart,sgs.DamageDone},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.DamageDone) then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				damage.from:setFlags("xingxiezhengDamage")
			end
		elseif player:getPhase()==sgs.Player_Finish and player:hasSkill(self) then
			local tos = room:askForPlayersChosen(player,room:getAlivePlayers(),self:objectName(),0,3,"xingxiezheng0",true)
			if tos:length()>0 then
				player:peiyin(self)
				for _, p in sgs.list(tos) do
					local dc = room:askForExchange(p,self:objectName(),1,1,false,"xingxiezheng1:")
					if dc then
						room:moveCardTo(dc,nil,sgs.Player_DrawPile,false)
					end
				end
				player:setFlags("-xingxiezhengDamage")
				local dc = dummyCard("_ov_binglinchengxia")
				if dc and dc:isAvailable(player) then
					room:askForUseCard(player,"@@xingxiezheng!","xingxiezheng2")
				end
				if not player:hasFlag("xingxiezhengDamage") then
					room:loseHp(player,1,true,player,self:objectName())
				end
				player:addMark("xingxiezhengUse")
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
xing_simazhao:addSkill(xingxiezheng)
xingzhaoxiong = sgs.CreateTriggerSkill{
	name = "xingzhaoxiong",
	frequency = sgs.Skill_Limited,
	limit_mark = "@xingzhaoxiong",
	events = {sgs.EventPhaseStart},
	waked_skills = "xingweisi,xingdangyi",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase()==sgs.Player_Start and player:getMark("@xingzhaoxiong")>0 then
			if player:isWounded() and player:getMark("xingxiezhengUse")>0 and player:askForSkillInvoke(self) then
				room:removePlayerMark(player,"@xingzhaoxiong")
				player:peiyin(self)
				room:doSuperLightbox(player,self:objectName())
				room:changeKingdom(player,"jin")
				if player:getGeneralName():contains("simazhao") then
					player:setAvatarIcon("xing_simazhao2")
				end
				room:handleAcquireDetachSkills(player,"-xingqiantun|xingweisi|xingdangyi")
			end
		end
	end,
}
xing_simazhao:addSkill(xingzhaoxiong)
xingweisiCard = sgs.CreateSkillCard{
	name = "xingweisiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < 1 and to_select ~= player
	end,
	on_use = function(self, room, player, targets)
		for _, p in sgs.list(targets) do
			local dc = room:askForExchange(p,self:getSkillName(),999,1,false,"xingweisi0:",true)
			if dc then
				p:addToPile(self:getSkillName(),dc,false)
			end
			dc = dummyCard("duel")
			dc:setSkillName("_"..self:getSkillName())
			if player:canUse(dc,p) then
				room:useCard(sgs.CardUseStruct(dc,player,p))
			end
		end
	end
}
xingweisivs = sgs.CreateViewAsSkill{
    name = "xingweisi",
    view_as = function(self, cards)
        return xingweisiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#xingweisiCard")
    end
}
xingweisi = sgs.CreateTriggerSkill{
	name = "xingweisi",
	view_as_skill = xingweisivs,
	events = {sgs.Damage,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			if damage.card and table.contains(damage.card:getSkillNames(),self:objectName()) then
				player:obtainCard(damage.to:wholeHandCards(),false)
			end
		elseif (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				for _, p in sgs.list(room:getAllPlayers()) do
					local dc = dummyCard()
					dc:addSubcards(p:getPile(self:objectName()))
					if dc:subcardsLength()>0 then
						p:obtainCard(dc,false)
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
extension_xing:addSkills(xingweisi)
xingdangyi = sgs.CreateTriggerSkill{
	name = "xingdangyi$",
	events = {sgs.DamageCaused,sgs.EventAcquireSkill},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.DamageCaused) then
			local damage = data:toDamage()
			if player:getMark("&xingdangyi")>0 and player:askForSkillInvoke(self,ToData("xingdangyi:"..damage.to:objectName())) then
				room:removePlayerMark(player,"&xingdangyi")
				player:peiyin(self)
				player:damageRevises(data,1)
			end
		elseif (event == sgs.EventAcquireSkill) then
			if data:toString()==self:objectName() then
				room:setPlayerMark(player,"&xingdangyi",player:getLostHp()+1)
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
		and target:hasLordSkill(self)
	end
}
extension_xing:addSkills(xingdangyi)

xing_simaliang = sgs.General(extension_xing, "xing_simaliang", "jin", 4)
xing_simaliang:setStartHp(3)
xingsheju = sgs.CreateTriggerSkill{
	name = "xingsheju",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed,sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local from
		if (event == sgs.TargetSpecified) then
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") or use.to:length()~=1 then
				return
			end
			from = use.to:first()
		else
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") or use.to:length()~=1 or not use.to:contains(player) then
				return
			end
			from = use.from
		end
		if player:isKongcheng() and from:isKongcheng() then
			return
		end
		room:sendCompulsoryTriggerLog(player,self)
		local ys = {}
		ys.reason = self:objectName()
		ys.from = player
		ys.tos = {player,from}
		ys.effect = function(ys_data)
			if ys_data.result == "black" then
				room:loseMaxHp(player,1,self:objectName())
				room:loseMaxHp(from,1,self:objectName())
			else
				if ys_data.to2color[player:objectName()]:contains("black") then
					player:drawCards(2,self:objectName())
				end
				if ys_data.to2color[from:objectName()]:contains("black") then
					from:drawCards(2,self:objectName())
				end
			end
		end
		askYishi(ys)
	end,
}
xing_simaliang:addSkill(xingsheju)
xingzuwang = sgs.CreateTriggerSkill{
	name = "xingzuwang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase()==sgs.Player_Start
		or player:getPhase()==sgs.Player_Finish then
			if player:getHandcardNum()<player:getMaxHp() then
				room:sendCompulsoryTriggerLog(player,self)
				player:drawCards(player:getMaxHp()-player:getHandcardNum(),self:objectName())
			end
		end
	end,
}
xing_simaliang:addSkill(xingzuwang)

xing_wangjun = sgs.General(extension_xing, "xing_wangjun", "jin", 4)
xingchengliu = sgs.CreateTriggerSkill{
	name = "xingchengliu",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase()==sgs.Player_Start then
			repeat
				local tos = sgs.SPlayerList()
				for _, p in sgs.list(room:getAlivePlayers()) do
					if p:getMark("xingchengliuTo-Clear")<1
					and p:getEquips():length()<player:getEquips():length() then
						tos:append(p)
					end
				end
				local to = room:askForPlayerChosen(player,tos,self:objectName(),"xingchengliu0",true,true)
				if to then
					player:peiyin(self)
					room:damage(sgs.DamageStruct(self:objectName(),player,to))
					to:addMark("xingchengliuTo-Clear")
				else
					break
				end
			until not player:hasEquip() or not room:askForCard(player,".|.|.|equipped","xingchengliu1",data)
		end
	end,
}
xing_wangjun:addSkill(xingchengliu)
xingjianchuan = sgs.CreateTriggerSkill{
	name = "xingjianchuan",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_DiscardPile and player:getMark("xingjianchuanUse-Clear")<1 then
				local ids = sgs.IntList()
				for _, id in sgs.list(move.card_ids) do
					if not room:getCardOwner(id) and sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
						ids:append(id)
					end
				end
				if ids:length()>0 and player:canDiscard(player,"he") then
					room:fillAG(ids,player)
					player:addMark("xingjianchuanUse-Clear")
					if room:askForCard(player,"..","xingjianchuan0",ToData(ids),self:objectName()) then
						player:addMark("xingjianchuanUse-Clear")
						local id = room:askForAG(player,ids,false,self:objectName())
						if id<0 then id = ids:first() end
						room:obtainCard(player,id)
						local c = sgs.Sanguosha:getCard(id)
						if player:hasCard(c) and c:isAvailable(player) then
							id = c:getRealCard():toEquipCard():location()
							if not player:getEquip(id) then
								room:useCard(sgs.CardUseStruct(c,player))
							end
						end
					end
					player:removeMark("xingjianchuanUse-Clear")
					room:clearAG(player)
				end
			end
		end
	end,
}
xing_wangjun:addSkill(xingjianchuan)

xing_malong = sgs.General(extension_xing, "xing_malong", "jin", 4)
xingfennanCard = sgs.CreateSkillCard{
	name = "xingfennanCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < 1
	end,
	on_use = function(self, room, player, targets)
		for _, p in sgs.list(targets) do
			local choice = room:askForChoice(p,self:getSkillName(),"xingfennan1+xingfennan2="..player:getEquips():length(),ToData(player))
			if choice=="xingfennan1" then
				player:turnOver()
				local ids = sgs.IntList()
				for _,c in sgs.list(p:getCards("ej"))do
					if player:getMark(c:toString().."xingfennanId-Clear")>0 then
						ids:append(c:getId())
					else
						choice = 0
						for _,q in sgs.list(room:getAlivePlayers())do
							if player:isProhibited(q,c) then continue end
							if c:isKindOf("EquipCard") then
								local n = c:getRealCard():toEquipCard():location()
								if q:getEquip(n) then continue end
							end
							choice = 1
							break
						end
						if choice==0 then
							ids:append(c:getId())
						end
					end
				end
				if ids:length()<p:getCards("ej"):length() then
					local id = room:askForCardChosen(player,p,"ej",self:getSkillName(),false,sgs.Card_MethodNone,ids)
					local c = sgs.Sanguosha:getCard(id)
					local tos = sgs.SPlayerList()
					for _,q in sgs.list(room:getAlivePlayers())do
						if player:isProhibited(q,c) then continue end
						if c:isKindOf("EquipCard") then
							local n = c:getRealCard():toEquipCard():location()
							if q:getEquip(n) then continue end
						end
						tos:append(q)
					end
					local to = room:askForPlayerChosen(player,tos,self:getSkillName(),"xingfennan0:"..c:objectName())
					room:moveCardTo(c,to,room:getCardPlace(id),true)
					player:getMark(id.."xingfennanId-Clear")
				end
			else
				local dc = dummyCard()
				for i=1,player:getEquips():length() do
					local id = room:askForCardChosen(player,p,"h",self:getSkillName(),false,sgs.Card_MethodRecast,dc:getSubcards(),true)
					if id>-1 then dc:addSubcard(id) else break end
				end
				if dc:getEffectiveId()>-1 then
					UseCardRecast(p,dc,self:getSkillName(),dc:subcardsLength())
				end
			end
		end
	end
}
xingfennan = sgs.CreateViewAsSkill{
    name = "xingfennan",
    view_as = function(self, cards)
        return xingfennanCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:usedTimes("#xingfennanCard")<player:getEquips():length()
    end
}
xing_malong:addSkill(xingfennan)
xingxunjiCard = sgs.CreateSkillCard{
	name = "xingxunjiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < self:subcardsLength()
	end,
	feasible = function(self,targets)
		return #targets==self:subcardsLength()
	end,
	about_to_use = function(self,room,use)
		room:setTag("xingxunjiUse",ToData(use))
		self:cardOnUse(room,use)
	end,
	on_use = function(self, room, player, targets)
		local use = room:getTag("xingxunjiUse"):toCardUse()
		local ids = self:getSubcards()
		for i, p in sgs.list(use.to) do
			room:giveCard(player,p,sgs.Sanguosha:getCard(ids:at(i)),self:getSkillName())
		end
	end
}
xingxunjivs = sgs.CreateViewAsSkill{
	name = "xingxunji",
	n = 999,
	expand_pile = "#xingxunji",
	view_filter = function(self, selected, to_select)
        return sgs.Self:getPileName(to_select:getEffectiveId())=="#xingxunji"
	end,
	view_as = function(self, cards)
		if #cards>0 then
			local card = xingxunjiCard:clone()
			for _,c in pairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@xingxunji"
	end
}
xingxunji = sgs.CreateTriggerSkill{
	name = "xingxunji",
	view_as_skill = xingxunjivs,
	events = {sgs.EventPhaseStart,sgs.Damage,sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.Damage then
			local damage = data:toDamage()
			player:addMark(damage.to:objectName().."xingxunjiDamage-Clear")
		elseif event==sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				for _, p in sgs.list(use.to) do
					player:addMark(p:objectName().."xingxunjiUse-Clear")
				end
				if use.card:hasFlag("DamageDone") then
					player:addMark(use.card:getId().."xingxunjiId-Clear")
				end
			end
		elseif player:getPhase()==sgs.Player_Finish and player:hasSkill(self) then
			for _, p in sgs.list(room:getOtherPlayers(player)) do
				if player:getMark(p:objectName().."xingxunjiUse-Clear")>0 and player:getMark(p:objectName().."xingxunjiDamage-Clear")<1 then
					return
				end
			end
			local ids = sgs.IntList()
			for _, id in sgs.list(room:getDiscardPile()) do
				for _, p in sgs.list(room:getAlivePlayers()) do
					if p:getMark(id.."xingxunjiId-Clear")>0 then
						ids:append(id)
						break
					end
				end
			end
			if ids:length()>0 then
				room:notifyMoveToPile(player,ids,"xingxunji",sgs.Player_DiscardPile,true)
				room:askForUseCard(player,"@@xingxunji","xingxunji0",-1,sgs.Card_MethodNone)
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
xing_malong:addSkill(xingxunji)

xing_jiananfeng = sgs.General(extension_xing, "xing_jiananfeng", "jin", 3, false)
xingshanzhengCard = sgs.CreateSkillCard{
	name = "xingshanzhengCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return player~=to_select
	end,
	on_use = function(self, room, player, targets)
		local ys = {}
		ys.reason = self:getSkillName()
		ys.from = player
		ys.tos = {player}
		for _, p in sgs.list(targets) do
			table.insert(ys.tos,p)
		end
		ys.effect = function(ys_data)
			if ys_data.result == "black" then
				for _, id in sgs.list(ys_data.ids) do
					room:obtainCard(player,sgs.Card_Parse(id),false)
				end
			elseif ys_data.result == "red" then
				local tos = sgs.SPlayerList()
				for _, p in sgs.list(room:getOtherPlayers(player)) do
					if table.contains(ys.tos,p:objectName()) then continue end
					tos:append(p)
				end
				local to = room:askForPlayerChosen(player,tos,self:getSkillName(),"xingshanzheng0")
				if to then
					room:doAnimate(1,player:objectName(),to:objectName())
					room:damage(sgs.DamageStruct(self:getSkillName(),player,to))
				end
			end
		end
		askYishi(ys)
	end
}
xingshanzheng = sgs.CreateViewAsSkill{
    name = "xingshanzheng",
    view_as = function(self, cards)
        return xingshanzhengCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:usedTimes("#xingshanzhengCard")<1
    end
}
xing_jiananfeng:addSkill(xingshanzheng)
xingxiongbao = sgs.CreateTriggerSkill{
	name = "xingxiongbao",
	events = {sgs.EventForDiy},
	priority = {3},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventForDiy) then
			local str = data:toString()
			if str:startsWith("askyishicard:") and player:getHandcardNum()>1
			and player:askForSkillInvoke(self) then
				local strs = str:split(":")
				player:setFlags("xingxiongbaoFrom")
				for _, p in sgs.list(room:getOtherPlayers(player)) do
					if table.contains(strs[4]:split("+"),p:objectName()) then
						p:setFlags("xingxiongbaoTo")
					end
				end
			end
		end
	end ,
}
xing_jiananfeng:addSkill(xingxiongbao)
xingxiongbaobf = sgs.CreateTriggerSkill{
	name = "#xingxiongbaobf",
	events = {sgs.EventForDiy},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventForDiy) then
			local str = data:toString()
			if str:startsWith("askyishicard:") then
				if player:hasFlag("xingxiongbaoFrom") then
					player:setFlags("-xingxiongbaoFrom")
					data:setValue(str..":-1:2")
				end
				if player:hasFlag("xingxiongbaoTo") then
					player:setFlags("-xingxiongbaoTo")
					data:setValue(str..":"..player:getRandomHandCardId())
				end
			end
		end
	end ,
}
xing_jiananfeng:addSkill(xingxiongbaobf)
xingliedu = sgs.CreateTriggerSkill{
	name = "xingliedu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				local list = use.no_respond_list
				local log = sgs.LogMessage()
				for _, p in sgs.list(room:getAlivePlayers()) do
					if p:isFemale() or p:getHandcardNum()>player:getHandcardNum() then
						table.insert(list,p:objectName())
						log.to:append(p)
					end
				end
				if log.to:length()>0 then
					room:sendCompulsoryTriggerLog(player,self)
					log.card_str = use.card:toString()
					log.type = "#xinglieduLog"
					log.from = player
					room:sendLog(log)
					use.no_respond_list = list
					data:setValue(use)
				end
			end
		end
	end,
}
xing_jiananfeng:addSkill(xingliedu)

xing_tufashujineng = sgs.General(extension_xing, "xing_tufashujineng", "qun", 4)
xingqinrao = sgs.CreateTriggerSkill{
	name = "xingqinrao",
	events = {sgs.EventPhaseStart,sgs.CardEffected},
	priority = {2,0},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("Duel") and table.contains(effect.card:getSkillNames(),self:objectName()) then
				if effect.nullified then
					local log = sgs.LogMessage()
					log.type = "#CardNullified"
					log.from = effect.to
					log.card_str = effect.card:toString()
					room:sendLog(log)
					return true
				end
				if not effect.offset_card then
					effect.offset_card = room:isCanceled(effect)
				end
				if effect.offset_card then
					data:setValue(effect)
					if not room:getThread():trigger(sgs.CardOffset, room, effect.from, data) then
						effect.to:setFlags("Global_NonSkillNullify")
						return true
					end
				end
				room:getThread():trigger(sgs.CardOnEffect, room, effect.to, data)
				if effect.to:isAlive() then
					local second = effect.from
					local first = effect.to
					room:setEmotion(second,"duel")
					room:setEmotion(first,"duel")
					while first:isAlive() do
						local slash = "slash"
						if first==effect.to then
							for _, c in sgs.list(first:getHandcards()) do
								if c:isKindOf("Slash") and not first:isCardLimited(c,sgs.Card_MethodResponse,true) then
									slash = "Slash!"
									break
								end
							end
							if slash~="Slash!" then
								room:showAllCards(first)
							end
						end
						slash = room:askForCard(first,slash,"duel-slash:"..second:objectName(),data,sgs.Card_MethodResponse,second,false,"duel",false,effect.card)
						if slash==nil then break end
						local temp = first
						first = second
						second = temp
					end
			    	local damage = sgs.DamageStruct(effect.card,second,first)
				   	damage.by_user = second==effect.from
				   	room:damage(damage)
				end
				room:setTag("SkipGameRule",sgs.QVariant(event))
			end
		elseif player:getPhase()==sgs.Player_Play then
			for _,p in sgs.list(room:getOtherPlayers(player)) do
				if p:hasSkill(self)	then
					local ids = {}
					local dc = dummyCard("duel")
					dc:setSkillName(self:objectName())
					for _, c in sgs.list(p:getCards("he")) do
						dc:addSubcard(c)
						if p:canUse(dc,player) then
							table.insert(ids,c:getId())
						end
						dc:clearSubcards()
					end
					if #ids>0 then
						ids = room:askForExchange(p,self:objectName(),1,1,true,"xingqinrao0:"..player:objectName(),true,table.concat(ids,","))
						if ids then
							dc:addSubcard(ids:getEffectiveId())
							room:useCard(sgs.CardUseStruct(dc,p,player))
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
xing_tufashujineng:addSkill(xingqinrao)
xingfuran = sgs.CreateTriggerSkill{
	name = "xingfuran",
	events = {sgs.EventPhaseChanging,sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.Damaged then
			local damage = data:toDamage()
			if damage.from and not damage.from:inMyAttackRange(player) and player:hasSkill(self) then
				room:setPlayerMark(player,"&xingfuran-Clear",1)
			end
		else
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				for _,p in sgs.list(room:getAllPlayers()) do
					if p:getMark("&xingfuran-Clear")>0 and p:askForSkillInvoke(self) then
						p:peiyin(self)
						room:recover(p,sgs.RecoverStruct(self:objectName(),p))
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
xing_tufashujineng:addSkill(xingfuran)

xing_limi = sgs.General(extension_xing, "xing_limi", "shu", 3)
xingciyingvs = sgs.CreateViewAsSkill{
	name = "xingciying",
	n = 999,
	view_filter = function(self, selected, to_select)
        return true
	end,
	view_as = function(self, cards)
		local n = 4
		for _,m in ipairs(sgs.Self:getMarkNames()) do
			if m:startsWith("&xingciying+") and sgs.Self:getMark(m)>0 then
				n = 1+n-#m:split("+")
				break
			end
		end
		if #cards>=math.max(1,n) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern=="" then
				local dc = sgs.Self:getTag("xingciying"):toCard()
				if dc==nil then return end
				pattern = dc:objectName()
			end
			for _,pn in ipairs(pattern:split("+")) do
				local card = sgs.Sanguosha:cloneCard(pn)
				card:setSkillName(self:objectName())
				for _,c in ipairs(cards) do
					card:addSubcard(c)
				end
				if sgs.Self:isLocked(card) then card:deleteLater() continue end
				return card
			end
		end
	end,
	enabled_at_play = function(self, player)
		if player:getMark("xingciyingUse-Clear")>0 then return end
		local n = 4
		for _,m in ipairs(player:getMarkNames()) do
			if m:startsWith("&xingciying+") and player:getMark(m)>0 then
				n = 1+n-#m:split("+")
				break
			end
		end
		return player:getCardCount()>=math.max(1,n)
	end,
	enabled_at_response = function(self, player, pattern)
		if player:getMark("xingciyingUse-Clear")>0 then return end
		local n = 4
		for _,m in ipairs(player:getMarkNames()) do
			if m:startsWith("&xingciying+") and player:getMark(m)>0 then
				n = 1+n-#m:split("+")
				break
			end
		end
		if player:getCardCount()<math.max(1,n) then return end
		for _,pn in ipairs(pattern:split("+")) do
			local dc = dummyCard(pn)
			if dc and dc:isKindOf("Slash") then
				return true
			end
		end
	end
}
xingciying = sgs.CreateTriggerSkill{
	name = "xingciying",
	guhuo_type = "l",
	view_as_skill = xingciyingvs,
	events = {sgs.PreCardUsed,sgs.CardsMoveOneTime,sgs.CardFinished,sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_DiscardPile then
				for _,id in sgs.list(move.card_ids)do
					local s = sgs.Sanguosha:getCard(id):getSuitString()
					if player:getMark(s.."xingciyingSuit-Clear")>0 then continue end
					player:addMark(s.."xingciyingSuit-Clear")
					MarkRevises(player,"&xingciying-Clear",s.."_char")
				end
			end
		elseif event==sgs.CardFinished then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),self:objectName()) then
				for _,m in ipairs(player:getMarkNames()) do
					if m:startsWith("&xingciying+") and player:getMark(m)>0 then
						if #m:split("+")>4 and player:getHandcardNum()<player:getMaxHp() then
							player:drawCards(player:getMaxHp()-player:getHandcardNum(),self:objectName())
						end
						break
					end
				end
			end
		elseif (event == sgs.CardResponded) then
			local response = data:toCardResponse()
			if table.contains(response.m_card:getSkillNames(),self:objectName()) then
				room:addPlayerMark(player,"xingciyingUse-Clear")
				for _,m in ipairs(player:getMarkNames()) do
					if m:startsWith("&xingciying+") and player:getMark(m)>0 then
						if #m:split("+")>4 and player:getHandcardNum()<player:getMaxHp() then
							player:drawCards(player:getMaxHp()-player:getHandcardNum(),self:objectName())
						end
						break
					end
				end
			end
		else
			local use = data:toCardUse()
			if use.card:getSkillName()==self:objectName() then
				room:addPlayerMark(player,"xingciyingUse-Clear")
			end
		end
	end,
}
xing_limi:addSkill(xingciying)
xingchendu = sgs.CreateTriggerSkill{
	name = "xingchendu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_DiscardPile and move.card_ids:length()>player:getHp()
			and move.from and move.from:objectName()==player:objectName() then
				if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD
				or move.reason.m_reason==sgs.CardMoveReason_S_REASON_RESPONSE or move.reason.m_reason==sgs.CardMoveReason_S_REASON_USE then
					local ids = sgs.IntList()
					for _,id in sgs.list(move.card_ids)do
						if room:getCardOwner(id) then continue end
						ids:append(id)
					end
					if ids:isEmpty() then return end
					room:sendCompulsoryTriggerLog(player,self)
					local mr = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW,player:objectName(),self:objectName(),"")
					local _guojia = sgs.SPlayerList()
					_guojia:append(player)
					local moves = sgs.CardsMoveList()
					moves:append(sgs.CardsMoveStruct(ids,nil,player,sgs.Player_PlaceTable,sgs.Player_PlaceHand,mr))
					room:notifyMoveCards(true,moves,false,_guojia)
					room:notifyMoveCards(false,moves,false,_guojia)
					local tos = room:getOtherPlayers(player)
					local moves2 = sgs.CardsMoveList()
					local cp = room:getCurrent()
					if cp~=player then
						tos = sgs.SPlayerList()
						tos:append(cp)
					end
					while ids:length()>0 do
						local yj = room:askForYijiStruct(player,ids,self:objectName(),true,false,false,-1,tos,mr,"",false,false)
						if not yj.to then continue end
						yj.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,player:objectName(),self:objectName(),yj.to:objectName(),"")
						moves2:append(yj)
						for _,id in sgs.qlist(yj.card_ids) do
							ids:removeOne(id)
						end
						moves = sgs.CardsMoveList()
						moves:append(sgs.CardsMoveStruct(yj.card_ids,player,nil,sgs.Player_PlaceHand,sgs.Player_PlaceTable,mr))
						room:notifyMoveCards(true,moves,false,_guojia)
						room:notifyMoveCards(false,moves,false,_guojia)
						tos = room:getOtherPlayers(player)
					end
					room:moveCardsAtomic(moves2,false)
				end
			end
		end
	end,
}
xing_limi:addSkill(xingchendu)

xing_dengai = sgs.General(extension_xing, "xing_dengai", "wei", 4)
xingpiqiCard = sgs.CreateSkillCard{
	name = "xingpiqiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if to_select:getMark("&xingpiqiUse-PlayClear")>0 then return end
		local dc = dummyCard("snatch")
		dc:setSkillName(self:getSkillName())
		if #targets>sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,player,dc,to_select)
		or player:isProhibited(to_select,dc) then return end
		return player~=to_select
	end,
	about_to_use = function(self,room,use)
		local dc = dummyCard("snatch")
		dc:setSkillName(self:getSkillName())
		use.card = dc
		for _,p in sgs.list(room:getAlivePlayers())do
			if use.to:contains(p) then
				room:addPlayerMark(p,"&xingpiqiUse-PlayClear")
				for _,q in sgs.list(room:getAlivePlayers())do
					if q:distanceTo(p)<2 and not q:hasSkill("xingpiqivs",true) then
						room:attachSkillToPlayer(q,"xingpiqivs")
					end
				end
			else
				room:removePlayerMark(p,"&xingpiqiUse-PlayClear")
			end
		end
		self:cardOnUse(room,use)
	end,
}
xingpiqivs = sgs.CreateViewAsSkill{
    name = "xingpiqi",
    view_as = function(self, cards)
        return xingpiqiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:usedTimes("#xingpiqiCard")<2
    end
}
xingpiqi = sgs.CreateTriggerSkill{
	name = "xingpiqi",
	view_as_skill = xingpiqivs,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if (change.to == sgs.Player_NotActive) then
			for _,p in sgs.list(room:getAlivePlayers()) do
				if p:hasSkill("xingpiqivs") then
					room:detachSkillFromPlayer(p,"xingpiqivs",true)
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
xing_dengai:addSkill(xingpiqi)
xingpiqivst = sgs.CreateViewAsSkill{
	name = "xingpiqivs&",
	n = 1,
	view_filter = function(self, selected, to_select)
        return to_select:isKindOf("Jink")
	end,
	view_as = function(self, cards)
		if #cards>0 then
			local card = sgs.Sanguosha:cloneCard("nullification")
			card:setSkillName("_"..self:objectName())
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern=="nullification"
	end
}
extension_xing:addSkills(xingpiqivst)
xingzhoulin = sgs.CreateTriggerSkill{
	name = "xingzhoulin",
	events = {sgs.EventPhaseChanging,sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and player:hasSkill(self) and damage.to:getMark(player:objectName().."xingzhoulinbf-Clear")>0 then
				room:sendCompulsoryTriggerLog(player,self)
				player:damageRevises(data,1)
			end
		else
			local change = data:toPhaseChange()
			if (change.from == sgs.Player_NotActive) then
				for _,p in sgs.list(room:getAlivePlayers()) do
					if p:hasSkill(self,true) then
						--local aps = sgs.SPlayerList()
						--aps:append(p)
						for _,q in sgs.list(room:getAlivePlayers()) do
							if p:inMyAttackRange(q) then continue end
							q:addMark(p:objectName().."xingzhoulinbf-Clear")
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
xing_dengai:addSkill(xingzhoulin)

xing_zhugedan = sgs.General(extension_xing, "xing_zhugedan", "wei", 4)
xingzuodan = sgs.CreateTriggerSkill{
	name = "xingzuodan",
	events = {sgs.Death,sgs.GameStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.Death then
			local death = data:toDeath()
			if death.who:getMark("&xingzuodan+#"..player:objectName())>0 then
				local tos = sgs.SPlayerList()
				local n = player:getHp()
				for _,p in sgs.list(room:getAlivePlayers()) do
					if p:getMark("&xingzuodan+#"..player:objectName())>0 then
						if p:getHp()>n then n = p:getHp() end
						tos:append(p)
					end
				end
				local to = room:askForPlayerChosen(player,tos,self:objectName(),"xingzuodan1:",false,true)
				if to then
					local ids,dp = sgs.IntList(),room:getDiscardPile()
					for _,id in sgs.list(dp) do
						if sgs.Sanguosha:getCard(id):isKindOf("BasicCard")
						then ids:append(id) end
					end
					room:fillAG(ids,to)
					local dc = dummyCard()
					for i=1,math.min(5,n) do
						if ids:isEmpty() then break end
						local id = room:askForAG(to,ids,true,self:objectName())
						if id<0 then break end
						dc:addSubcard(id)
						id = sgs.Sanguosha:getCard(id)
						for _,t in sgs.list(dp) do
							if sgs.Sanguosha:getCard(t):sameNameWith(id)
							then ids:removeOne(t) end
						end
					end
					room:clearAG(to)
					to:obtainCard(dc)
				end
			end
		else
			local tos = room:askForPlayersChosen(player,room:getOtherPlayers(player),self:objectName(),0,2,"xingzuodan0:",false,false)
			tos:append(player)
			for _,p in sgs.list(tos) do
				room:doAnimate(1,player:objectName(),p:objectName())
				room:setPlayerMark(p,"&xingzuodan+#"..player:objectName(),1)
			end
		end
	end,
}
xing_zhugedan:addSkill(xingzuodan)
xingcuibing = sgs.CreateTriggerSkill{
	name = "xingcuibing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase()==sgs.Player_Play then
			room:sendCompulsoryTriggerLog(player,self)
			local n = 0
			for _,p in sgs.list(room:getAlivePlayers()) do
				if player:inMyAttackRange(p) then
					n = n+1
				end
			end
			n = math.min(n,5)
			n = player:getHandcardNum()-n
			if n>0 then
				n = room:askForDiscard(player,self:objectName(),n,n)
				if n then
					n = n:subcardsLength()
					local has = false
					while n>0 and player:isAlive() do
						local aps = sgs.SPlayerList()
						for _,p in sgs.list(room:getAlivePlayers()) do
							if player:canDiscard(p,"ej") then
								aps:append(p)
							end
						end
						player:setMark("xingcuibing0",n)
						local to = room:askForPlayerChosen(player,aps,self:objectName(),"xingcuibing0:"..n,true)
						if to then
							room:doAnimate(1,player:objectName(),to:objectName())
							local id = room:askForCardChosen(player,to,"ej",self:objectName(),false,sgs.Card_MethodDiscard)
							if id<0 then break end
							room:throwCard(id,self:objectName(),to,player)
							has = true
							n = n-1
						else
							break
						end
					end
					if not has then player:skip(sgs.Player_Discard) end
				end
			elseif n<0 then
				player:drawCards(-n,self:objectName())
			end
		end
	end,
}
xing_zhugedan:addSkill(xingcuibing)
xinglangan = sgs.CreateTriggerSkill{
	name = "xinglangan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.Death then
			local death = data:toDeath()
			room:sendCompulsoryTriggerLog(player,self)
			room:recover(player,sgs.RecoverStruct(self:objectName(),player))
			player:drawCards(2,self:objectName())
			if player:getMark("&xinglangan")<3 then
				room:addPlayerMark(player,"&xinglangan")
			end
		end
	end,
}
xing_zhugedan:addSkill(xinglangan)

xing_wenyang = sgs.General(extension_xing, "xing_wenyang", "wei", 4)
xingfuzhen = sgs.CreateTriggerSkill{
	name = "xingfuzhen",
	events = {sgs.EventPhaseStart,sgs.CardFinished,sgs.PreCardUsed,sgs.DamageDone},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:hasFlag("xingfuzhenBf") then
				local n = use.card:getMark("xingfuzhenDamage")
				player:drawCards(n,self:objectName())
				for _,p in sgs.list(use.to) do
					if p:getMark("&xingfuzhenTo")>0 and not use.card:hasFlag("DamageDone_"..p:objectName()) and player:isAlive() then
						local tos = sgs.SPlayerList()
						for _,q in sgs.list(room:getAlivePlayers()) do
							if use.to:contains(q) then
								tos:append(q)
							end
						end
						local dc = dummyCard("thunder_slash")
						dc:setSkillName(self:objectName())
						room:useCard(sgs.CardUseStruct(dc,player,tos))
					end
					room:setPlayerMark(p,"&xingfuzhenTo",0)
				end
			end
		elseif event==sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:hasFlag("xingfuzhenBf") then
				local to = room:askForPlayerChosen(player,use.to,self:objectName(),"xingfuzhen1:")
				if to then
					local aps = sgs.SPlayerList()
					aps:append(player)
					room:doAnimate(1,player:objectName(),to:objectName(),aps)
					room:setPlayerMark(to,"&xingfuzhenTo",1,aps)
				end
			end
		elseif event==sgs.DamageDone then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("xingfuzhenBf") then
				damage.card:addMark("xingfuzhenDamage",damage.damage)
			end
		else
			if player:getPhase()==sgs.Player_Start and player:hasSkill(self) then
				local tos = sgs.SPlayerList()
				local dc = dummyCard("thunder_slash")
				dc:setSkillName(self:objectName())
				for _,p in sgs.list(room:getAlivePlayers()) do
					if player:canSlash(p,dc,false) then
						tos:append(p)
					end
				end
				tos = room:askForPlayersChosen(player,tos,self:objectName(),0,3,"xingfuzhen0:",false,false)
				if tos:length()>0 then
					room:loseHp(player,1,true,player,self:objectName())
					if player:isAlive() then
						dc:setFlags("xingfuzhenBf")
						room:useCard(sgs.CardUseStruct(dc,player,tos))
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
xing_wenyang:addSkill(xingfuzhen)

xing_lukang = sgs.General(extension_xing, "xing_lukang", "wu", 4)
xingzhuweiCard = sgs.CreateSkillCard{
	name = "xingzhuweiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if #targets>0 then return end
		local aps = to_select:getAliveSiblings()
		for _,e in sgs.list(to_select:getEquips())do
			local n = e:getRealCard():toEquipCard():location()
			for _,p in sgs.list(aps)do
				if not(p:getEquip(n) or player:isProhibited(p,e)) then
					return true
				end
			end
		end
		return false
	end,
	on_use = function(self, room, player, targets)
		for _,target in sgs.list(targets)do
			local aps = room:getOtherPlayers(target)
			local ids = sgs.IntList()
			for _,e in sgs.list(target:getEquips())do
				local n = e:getRealCard():toEquipCard():location()
				local has = true
				for _,p in sgs.list(aps)do
					if not(p:getEquip(n) or player:isProhibited(p,e)) then
						has = false
						break
					end
				end
				if has then ids:append(e:getEffectiveId()) end
			end
			local id = room:askForCardChosen(player,target,"e",self:getSkillName(),false,sgs.Card_MethodNone,ids)
			if id<0 then continue end
			local c = sgs.Sanguosha:getCard(id)
			local tos = sgs.SPlayerList()
			for _,p in sgs.list(aps)do
				if player:isProhibited(p,c) then continue end
				local n = c:getRealCard():toEquipCard():location()
				if p:getEquip(n) then continue end
				tos:append(p)
			end
			local to = room:askForPlayerChosen(player,tos,self:getSkillName(),"xingzhuwei0:"..c:objectName())
			for _,p in sgs.list(room:getAlivePlayers())do
				local n = 0
				for _,q in sgs.list(room:getAlivePlayers())do
					if p:inMyAttackRange(q) then
						n = n+1
					end
				end
				p:setMark("xingzhuweiNum",n)
			end
			if to then
				room:doAnimate(1,player:objectName(),to:objectName())
				room:moveCardTo(c,to,room:getCardPlace(id),true)
			end
			tos = sgs.SPlayerList()
			for _,p in sgs.list(room:getAlivePlayers())do
				local n = 0
				for _,q in sgs.list(room:getAlivePlayers())do
					if p:inMyAttackRange(q) then
						n = n+1
					end
				end
				if n==0 and p:getMark("xingzhuweiNum")~=0 then
					tos:append(p)
				end
			end
			to = room:askForPlayerChosen(player,tos,"xingzhuwei1","xingzhuwei1:",true)
			if to then
				room:doAnimate(1,player:objectName(),to:objectName())
				room:loseHp(to,2,true,player,self:getSkillName())
			end
		end
	end
}
xingzhuwei = sgs.CreateViewAsSkill{
    name = "xingzhuwei",
    view_as = function(self, cards)
        return xingzhuweiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:usedTimes("#xingzhuweiCard")<1
    end
}
xing_lukang:addSkill(xingzhuwei)
xingkuangjianvs = sgs.CreateViewAsSkill{
	name = "xingkuangjian",
	n = 1,
	view_filter = function(self, selected, to_select)
        return to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, cards)
		if #cards>0 then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern=="" then
				local dc = sgs.Self:getTag("xingkuangjian"):toCard()
				if dc==nil then return end
				pattern = dc:objectName()
			end
			for _,pn in ipairs(pattern:split("+")) do
				local card = sgs.Sanguosha:cloneCard(pn)
				card:setSkillName(self:objectName())
				card:addSubcard(cards[1])
				if sgs.Self:isLocked(card) then card:deleteLater() continue end
				return card
			end
		end
	end,
	enabled_at_play = function(self, player)
		return player:getCardCount()>0
	end,
	enabled_at_response = function(self, player, pattern)
		if sgs.Sanguosha:getCurrentCardUseReason()~=sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
		or player:getCardCount()<1 then return end
		for _,pn in ipairs(pattern:split("+")) do
			local dc = dummyCard(pn)
			if dc and dc:isKindOf("BasicCard") then
				return true
			end
		end
	end
}
xingkuangjian = sgs.CreateTriggerSkill{
	name = "xingkuangjian",
	view_as_skill = xingkuangjianvs,
	events = {sgs.CardFinished},
	guhuo_type = "l",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if table.contains(use.card:getSkillNames(),self:objectName()) then
			for _,p in sgs.list(use.to) do
				if room:getCardOwner(use.card:getEffectiveId()) then break end
				if p:isAlive() then
					local c = sgs.Sanguosha:getCard(use.card:getEffectiveId())
					if p:canUse(c,p) then
						room:useCard(sgs.CardUseStruct(c,p))
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
xing_lukang:addSkill(xingkuangjian)


sgs.LoadTranslationTable{
	["jsrgxing"] = "江山如故·兴",


	["xing_lukang"] = "陆抗[兴]", 
	["&xing_lukang"] = "陆抗",
	["#xing_lukang"] = "架海金梁",
	["illustrator:xing_lukang"] = "小罗没想好",

	["xingzhuwei"] = "筑围",
	[":xingzhuwei"] = "出牌阶段限一次，你可以移动场上一张装备，然后你可以令一名攻击范围内角色变为0的角色失去2点体力。",
	["xingkuangjian"] = "匡谏",
	[":xingkuangjian"] = "你可以将装备牌当做任意基本牌使用（目标不能为你且无次数限制），结算后目标角色使用弃牌堆中的此装备牌。",
	["xingzhuwei0"] = "筑围：请选择【%src】的移动目标",
	["xingzhuwei1"] = "筑围：你可以选择令一名角色失去2点体力",

	["xing_wenyang"] = "文鸯[兴]", 
	["&xing_wenyang"] = "文鸯",
	["#xing_wenyang"] = "貔貅若拒",
	["illustrator:xing_wenyang"] = "town",

	["xingfuzhen"] = "覆阵",
	[":xingfuzhen"] = "准备阶段，你可以失去1点体力并视为使用一张无距离限制的雷【杀】，此【杀】目标数+2，然后你秘密选择其中一名目标。此【杀】结算后：你摸造成伤害数张牌；若未对秘密选择的目标造成伤害，你视为对所有目标再使用一张雷【杀】。",
	["xingfuzhen0"] = "你可以发动“覆阵”失去1点体力并视为使用一张无距离限制的雷【杀】（目标数+2）",
	["xingfuzhen1"] = "覆阵：请秘密选择其中一名目标",
	["xingfuzhenTo"] = "覆阵选择",

	["xing_zhugedan"] = "诸葛诞[兴]", 
	["&xing_zhugedan"] = "诸葛诞",
	["#xing_zhugedan"] = "护国孤獒",
	["illustrator:xing_zhugedan"] = "特特肉",

	["xingzuodan"] = "坐胆",
	[":xingzuodan"] = "游戏开始时，你选择你与至多两名其他角色。你的攻击范围+X（X为选择角色中最大体力值且至多为5）。当选择角色死亡后，你令一名存活的选择角色从弃牌堆中获得至多x张牌名各不同的基本牌。",
	["xingcuibing"] = "摧冰",
	[":xingcuibing"] = "锁定技，出牌阶段结束时，你将手牌摸或弃至X张（X为你攻击范围内的角色数）。若你因此弃置了牌，你选择弃置场上至多等量张牌或跳过弃牌阶段。",
	["xinglangan"] = "阑干",
	[":xinglangan"] = "锁定技，当其他角色死亡后，你回复1点体力并摸两张牌，然后你的攻击范围-1（至多减3）。",
	["xingzuodan0"] = "坐胆：请选择至多两名其他角色",
	["xingzuodan1"] = "坐胆：请选择一名存活的选择角色从弃牌堆中获得基本牌",
	["xingcuibing0"] = "摧冰：你可以选择一名角色弃置其场上的牌（剩余%src次）",

	["xing_dengai"] = "邓艾[兴]", 
	["&xing_dengai"] = "邓艾",
	["#xing_dengai"] = "策袭鼎迁",
	["illustrator:xing_dengai"] = "小罗没想好",

	["xingpiqi"] = "辟奇",
	[":xingpiqi"] = "出牌阶段限两次，你可以视为使用一张无距离限制的【顺手牵羊】（两次目标不能相同），与目标距离1以内的角色本回合可以将【闪】当做【无懈可击】使用。",
	["xingzhoulin"] = "骤临",
	[":xingzhoulin"] = "当你使用【杀】对一名角色造成伤害时，若本回合开始时其不在你的攻击范围内，此伤害+1。",
	["xingpiqivs"] = "辟奇",
	[":xingpiqivs"] = "你可以将【闪】当做【无懈可击】使用。",
	["xingpiqiUse"] = "辟奇禁用目标",

	["xing_limi"] = "李密[兴]", 
	["&xing_limi"] = "李密",
	["#xing_limi"] = "情切哺乌",
	["illustrator:xing_limi"] = "小罗没想好",

	["xingciying"] = "辞应",
	[":xingciying"] = "每回合限一次，你可以将至少X张牌当做任意基本牌使用或打出（X为本回合未进入过弃牌堆的花色数且至少为1）。此牌结算后，若本回合所有花色均进入过弃牌堆，你将手牌摸至体力上限数。",
	["xingchendu"] = "陈笃",
	[":xingchendu"] = "锁定技，当你的牌因使用、打出或弃置而进入弃牌堆后，若数量大于你的体力值，你将这些牌分配给其他角色（若不为你的回合，分配的角色须包含当前回合角色）。",

	["xing_tufashujineng"] = "秃发树机能[兴]", 
	["&xing_tufashujineng"] = "秃发树机能",
	["#xing_tufashujineng"] = "朔西扰壤",
	["illustrator:xing_tufashujineng"] = "荆芥",

	["xingqinrao"] = "侵扰",
	[":xingqinrao"] = "其他角色出牌阶段开始时，你可以将一张牌当做【决斗】对其使用，结算中若其手牌中有可以打出的【杀】，其须打出响应，否则其展示所有手牌。",
	["xingfuran"] = "复燃",
	[":xingfuran"] = "当你受到伤害后，若你不在伤害来源攻击范围内，你可以于此回合结束时回复1点体力。",
	["xingqinrao0"] = "侵扰：你可以将一张牌当做【决斗】对%src使用",

	["xing_jiananfeng"] = "贾南风[兴]", 
	["&xing_jiananfeng"] = "贾南风",
	["#xing_jiananfeng"] = "凤啸峻旹",
	["illustrator:xing_jiananfeng"] = "小罗没想好",

	["xingshanzheng"] = "擅政",
	[":xingshanzheng"] = "出牌阶段限一次，你可以与任意角色议事，若结果为：红色，你对一名未参与议事的角色造成1点伤害；黑色，你获得所有意见牌。",
	["xingxiongbao"] = "凶暴",
	[":xingxiongbao"] = "你参与议事时，你可以额外展示一张手牌，若如此做，其他角色改为随机展示手牌。",
	["xingliedu"] = "烈妒",
	[":xingliedu"] = "锁定技，女性角色和手牌数大于你的角色不能响应你使用的牌。",
	["xingshanzheng0"] = "擅政：请对一名未参与议事的角色造成1点伤害",
	["#xinglieduLog"] = "%from 使用的 %card 不能被 %to 响应",

	["xing_malong"] = "马隆[兴]", 
	["&xing_malong"] = "马隆",
	["#xing_malong"] = "困局诡阵",
	["illustrator:xing_malong"] = "荆芥",

	["xingfennan"] = "奋难",
	[":xingfennan"] = "出牌阶段限X次，你可以令一角色选择一项：1.令你翻面，然后你移动其场上一张本回合未移动过的牌；2.你观看并重铸其至多X张手牌（X为你装备区牌数量）。",
	["xingxunji"] = "勋济",
	[":xingxunji"] = "结束阶段，若你于本回合对回合内你使用牌指定过的其他角色均造成过伤害，你可以将弃牌堆中本回合造成过伤害的牌分配给至多等量角色各一张。",
	["xingfennan0"] = "奋难：请选择【%src】的移动目标",
	["xingfennan1"] = "令其翻面，然后其移动你场上一张本回合未移动过的牌",
	["xingfennan2"] = "其观看并重铸你至多%src张手牌",
	["#xingxunji"] = "造成伤害牌",
	["xingxunji0"] = "勋济：你可以分配这些牌（每人一张）",

	["xing_wangjun"] = "王濬[兴]", 
	["&xing_wangjun"] = "王濬",
	["#xing_wangjun"] = "顺流长驱",
	["illustrator:xing_wangjun"] = "荆芥",

	["xingchengliu"] = "乘流",
	[":xingchengliu"] = "准备阶段，你可以对一名装备区牌数小于你的角色造成1点伤害，然后你可以弃置装备区一张牌，对一名本回合未选择过的角色重复此流程。",
	["xingjianchuan"] = "舰船",
	[":xingjianchuan"] = "每回合限一次，当一张装备牌进入弃牌堆时，你可以弃置一张牌并获得之，然后若此牌对应的装备栏无装备，你使用之。",
	["xingchengliu0"] = "乘流：你可以对一名装备区牌数小于你的角色造成1点伤害",
	["xingchengliu1"] = "乘流：你可以弃置装备区一张牌重复此流程",
	["xingjianchuan0"] = "舰船：你可以弃置一张牌选择获得其中一张装备",

	["xing_simaliang"] = "司马亮[兴]", 
	["&xing_simaliang"] = "司马亮",
	["#xing_simaliang"] = "冲粹的蒲牢",
	["illustrator:xing_simaliang"] = "小罗没想好",

	["xingsheju"] = "摄惧",
	[":xingsheju"] = "锁定技，当你使用【杀】指定唯一目标后或成为【杀】的唯一目标后，你与对方议事：若结果为黑色，双方各扣减1点体力上限；否则意见为黑色的角色摸两张牌。",
	["xingzuwang"] = "族望",
	[":xingzuwang"] = "锁定技，准备阶段和结束阶段，你将手牌补至体力上限数。",

	["xing_simazhao"] = "司马昭[兴]", 
	["&xing_simazhao"] = "司马昭",
	["#xing_simazhao"] = "堕节肇业",--独袄吞天
	["illustrator:xing_simazhao"] = "M云涯",
	["information:xing_simazhao"] = "ᅟᅠᅟᅠ<i>司马昭，字子上，早年受荫庇于父兄，不慕霸业。及父兄殂谢，昭承继家业，负谋魏自立之责，野心渐起，虽心气才学不及父兄，仍殚竭经营大业，宠人心，除异己，欲令百官贵胄俯首。\
	ᅟᅠᅟᅠ唯诸葛诞拥兵自重，独据淮南，昭恐其不利于宗族大业，欲除之以建战功，威服四方。昭乃使计逼反诸葛诞，又担忧曹髦为乱后方，乃挟之以同征淮南，临戎除逆。\
	ᅟᅠᅟᅠ昭惯施权谋，建高墙于寿春城外，围而不攻，为彰显恩德，围城期间每有归降者，皆宽救旧罪。昭收服判逃倒戈者众，诞、鸯等屡次突围皆大败而归。\
	ᅟᅠᅟᅠ昭自觉宗族夙愿将成之际，雷声滚滚，大雨倾盆，围墙塌落，魏军困于泥沼，诸葛诞趁势突围，文鸯乘乱欲劫天子。昭恐宗族大业尽毁于己手，积怨缠身，方寸惊乱，亲率三军攻城，誓荡平淮南，讨灭天下不臣，成大业，慰父兄。</i>",

	["xingqiantun"] = "谦吞",
	[":xingqiantun"] = "出牌阶段限一次，你可以令一名其他角色展示至少一张手牌，并与其拼点，其本次拼点牌只能从展示牌中选择。若你赢，你获得其展示的手牌；若你没赢，你获得其未展示的手牌；然后你展示所有手牌。",
	["xingxiezheng"] = "挟征",
	[":xingxiezheng"] = "结束阶段，你可以令至多三名角色依次将一张手牌置于牌堆顶，然后你视为使用一张【兵临城下】，结算后若未造成过伤害，你失去1点体力。",
	["xingzhaoxiong"] = "昭凶",
	[":xingzhaoxiong"] = "限定技，准备阶段，若你已受伤且发动过“挟征”，你可以变更势力至晋，失去“谦吞”并获得“威肆”和“荡异”。",
	["xingweisi"] = "威肆",
	[":xingweisi"] = "出牌阶段限一次，你可以选择一名其他角色，令其将任意手牌扣置于武将牌上（回合结束时收回），然后视为对其使用一张【决斗】，此牌对其造成伤害后，你获得其所有手牌。",
	["xingdangyi"] = "荡异",
	[":xingdangyi"] = "主公技，当你造成伤害时，你可以令伤害+1，本局游戏限X次（X为获此技能时你已损失体力值+1）。",
	["xingqiantun0"] = "谦吞：请选择至少一张手牌展示",
	["xingqiantun_pd"] = "%src 对你发起拼点，请选择一张手牌拼点",
	["xingxiezheng0"] = "挟征：你可以选择至多三名角色依次将一张手牌置于牌堆顶",
	["xingxiezheng1"] = "挟征：请选择一张手牌置于牌堆顶",
	["xingxiezheng2"] = "挟征：请视为使用一张【兵临城下】",
	["xingweisi0"] = "威肆：请选择将任意手牌扣置于武将牌上",
	["xingdangyi:xingdangyi"] = "荡异：你可以令对%src的伤害+1",
	["xing_simazhao2"] = "司马昭",

	["$xingxiezheng1"] = "烈祖明皇帝乘舆仍出，陛下何妨效之。",
	["$xingxiezheng2"] = "陛下宜誓临戎，使将士得凭天威。",
	["$xingxiezheng3"] = "既得众将之力，何愁贼不得平？",--挟征（第二形态）
	["$xingxiezheng4"] = "逆贼起兵作乱，诸位无心报国乎？",--挟征（第二形态）
	["$xingqiantun1"] = "辅国臣之本分，何敢图于禄勋。",
	["$xingqiantun2"] = "蜀贼吴寇未灭，臣未可受此殊荣。",
	["$xingqiantun3"] = "陛下一国之君，不可使以小性。",--谦吞（赢）	
	["$xingqiantun4"] = "讲经宴筵，实非治国之道也。",--谦吞（没赢）
	["$xingzhaoxiong1"] = "若得灭蜀之功，何不可受禅为帝。",
	["$xingzhaoxiong2"] = "已极人臣之贵，当一尝人主之威。",
	["$xingdangyi1"] = "哼！斩首示众，以儆效尤。",
	["$xingdangyi2"] = "汝等仍存异心，可见心存魏阙。",
	["$xingweisi1"] = "上者慑敌以威，灭敌以势。",
	["$xingweisi2"] = "哼，求存者多，未见求死者也。",
	["$xingweisi3"] = "未想逆贼区区，竟然好物甚巨。", --威肆（获得手牌）
	
	["$xing_simazhao"] = "明日正为吉日，当举禅位之典。",
	["~xing_simazhao"] = "曹髦小儿竟有如此肝胆……我实不甘。",
	["$xing2_simazhao"] = "万里山河，终至我司马一家。",
	["~xing2_simazhao"] = "愿我晋祚，万世不易，国运永昌。",

}


return {extension_qi,extension_cheng,extension_zhuan,extension_he,extension_shuai,extension_xing}