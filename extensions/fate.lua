module("extensions.fate", package.seeall)
extension = sgs.Package("fate")
fate_Kiritsugu=sgs.General(extension, "fate_Kiritsugu", "magic", "3", true) --切嗣
fate_Shirou=sgs.General(extension, "fate_Shirou", "magic", "3", true)  --土狗
fate_Saber =sgs.General(extension, "fate_Saber", "magic", "4", false)  --Saber
fate_Carene=sgs.General(extension, "fate_Carene", "magic", "3", false) --卡莲
fate_Medusa=sgs.General(extension, "fate_Medusa", "magic", "4", false)  --Rider
fate_Rin=sgs.General(extension, "fate_Rin", "magic", "3", false)  --凛
fate_Heracles=sgs.General(extension, "fate_Heracles", "magic", "6", true) -- Berserker
fate_Medea=sgs.General(extension, "fate_Medea", "magic", "3", false)  --Caster
fate_Sakura=sgs.General(extension, "fate_Sakura", "magic", "3", false)  --樱
fate_Gilgamesh=sgs.General(extension, "fate_Gilgamesh", "magic", "4", true)  --金闪闪
fate_Emiya_Archer=sgs.General(extension, "fate_Emiya_Archer", "magic", "4", true) --红A
fate_Iriya=sgs.General(extension, "fate_Iriya", "magic", "3", false)  --依莉雅
fate_Gilles=sgs.General(extension, "fate_Gilles", "magic", "4", true) --吉尔（Zero.Caster）
fate_Kojirou=sgs.General(extension, "fate_Kojirou", "magic", "2", true) --佐佐木小次郎
fate_Lancelot=sgs.General(extension, "fate_Lancelot", "magic", "4", true) --Zero.Berserker
fate_Kirei=sgs.General(extension, "fate_Kirei", "magic", "3", true) --神父
fate_Hassan_Sabbah=sgs.General(extension, "fate_Hassan_Sabbah", "magic", "3", true) --真.Assassin
fate_Irisviel=sgs.General(extension, "fate_Irisviel", "magic", "3", false)  --爱丽丝菲尔
fate_Tokiomi=sgs.General(extension, "fate_Tokiomi", "magic", "3", true) --时臣
fate_Alexander=sgs.General(extension, "fate_Alexander", "magic", "4", true) --大帝
fate_Diarmuid=sgs.General(extension, "fate_Diarmuid", "magic", "4", true) --双枪哥
fate_Chulainn=sgs.General(extension, "fate_Chulainn", "magic", "4", true) --蓝枪哥
fate_Shinji=sgs.General(extension, "fate_Shinji", "magic", "3", true) --2爷
fate_Kariya=sgs.General(extension, "fate_Kariya", "magic", "3", true) --雁夜

--竭智  每当场上即将有判定发生时，你可以观看牌顶的X张牌，并将这些牌以任意顺序置于牌堆顶。X为场上存活角色数与你的体力上限中的较大者且最多为5。
fatejiezhi=sgs.CreateTriggerSkill{ 
name="fatejiezhi",
frequency=sgs.Skill_Frequent,
events=sgs.StartJudge,
can_trigger = function(self, target)
    return target
end,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()
	local Kiritsugu = room:findPlayerBySkillName(self:objectName())
	if not Kiritsugu:isAlive() then return end
	if not room:askForSkillInvoke(Kiritsugu,self:objectName()) then return end
    local x = math.max(room:alivePlayerCount(),Kiritsugu:getMaxHp())
	if x > 5 then x = 5 end
--[[	local judge = data:toJudge() --这几句是为了写AI加上的
	if Kiritsugu:isFriend(judge.who) then 
		if judge.negative == false then
			Kiritsu:addMark("fatejiezhigood")
		else 
			Kiritsu:addMark("fatejiezhibad")
		end
	else 
		if judge.negative == false then
			Kiritsu:addMark("fatejiezhibad")
		else 
			Kiritsu:addMark("fatejiezhigood")
		end
	end
	]]
	room:askForGuanxing(Kiritsugu,room:getNCards(x),sgs.Room_GuanxingUpOnly)
end,
}

--夜战  回合开始阶段，你可以选择除你以外的一名角色，令其进行一次判定。若判定结果为黑桃，你对其造成1点无属性伤害。
fateyezhan=sgs.CreateTriggerSkill{ 
name="fateyezhan",
frequency=sgs.Skill_NotFrequent,
events=sgs.EventPhaseStart,
priority=3,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()
	if (player:getPhase() ~= sgs.Player_Start) then return end
	local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "fateyezhan-invoke", true, true)
			if target then
	local judge = sgs.JudgeStruct()
	judge.who = target
	judge.pattern = ".|spade"
	judge.good = false
	judge.reason = self:objectName()
	judge.play_animation = true
    judge.negative = true
	room:judge(judge)
	if not judge:isGood() then
		local damage = sgs.DamageStruct()
		damage.from = player
		damage.to = target
		damage.damage = 1
		damage.nature = sgs.DamageStruct_Normal
		room:damage(damage)
		end
	end
end,
}

--强运  锁定技，你的手牌上限+1。
fateqiangyun = sgs.CreateMaxCardsSkill{
	name = "fateqiangyun",
	extra_func = function(self, player)
		if player:hasSkill(self:objectName()) then return 1 end
		return 0
	end,
}

fatewangzheCard = sgs.CreateSkillCard{
	name = "fatewangzhe",
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets < 0
	end,
	feasible = function(self, targets)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@fatewangzhe" then
			for _,id in sgs.qlist(self:getSubcards()) do
				room:setCardFlag(sgs.Sanguosha:getCard(id), "fatewangzhe_get")
			end
		end
	end
}
fatewangzheVS = sgs.CreateViewAsSkill{
	name = "fatewangzhe",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:hasFlag("fatewangzhe")
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@fatewangzhe" then
			if #cards ~= 1 then return nil end
			local skillcard = fatewangzheCard:clone()
			for _, c in ipairs(cards) do
				skillcard:addSubcard(c)
			end
			return skillcard
		end
	end,
	enabled_at_play = function(self, target)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@fatewangzhe"
	end
}


--王者 每当你成为【杀】或非延时锦囊的目标时，你可观看牌堆顶的2张牌，并可以选其中一张收为手牌。
fatewangzhe=sgs.CreateTriggerSkill{
	name="fatewangzhe",
	--frequency=sgs.Skill_Frequent,
    view_as_skill = fatewangzheVS,
	events={sgs.CardEffected},
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
			local effect=data:toCardEffect()
			local card=effect.card
			if  effect.to:hasSkill(self:objectName()) == false then return end
			if (card:isNDTrick() or card:isKindOf("Slash")) then 
		if(room:askForSkillInvoke(player,"fatewangzhe") ==false) then return end
        local _guojia = sgs.SPlayerList()
        _guojia:append(player)
        local yiji_cards = room:getNCards(2, false)
        local move = sgs.CardsMoveStruct(yiji_cards, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
                        sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil))
        local moves = sgs.CardsMoveList()
        moves:append(move)
        room:notifyMoveCards(true, moves, false, _guojia)
        room:notifyMoveCards(false, moves, false, _guojia)
        
        for _,id in sgs.qlist(yiji_cards) do
            room:setCardFlag(sgs.Sanguosha:getCard(id), "fatewangzhe")
        end
        local tag = room:getTag("fatewangzhe")
        local guanxuToGet= tag:toString()
        if guanxuToGet == nil then
            guanxuToGet = ""
        end
        for _,card_id in sgs.qlist(yiji_cards) do
            if guanxuToGet == "" then
                guanxuToGet = tostring(card_id)
            else
                guanxuToGet = guanxuToGet.."+"..tostring(card_id)
            end
        end
        room:setTag("fatewangzhe", sgs.QVariant(guanxuToGet))
        
        
        
        local invoke = room:askForUseCard(player, "@fatewangzhe", "@fatewangzhe")
        
        room:setTag("fatewangzhe", sgs.QVariant())
        
        local move_to = sgs.CardsMoveStruct(yiji_cards, player, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason())
        local moves_to = sgs.CardsMoveList()
        moves_to:append(move_to)
        room:notifyMoveCards(true, moves_to, false, _guojia)
        room:notifyMoveCards(false, moves_to, false, _guojia)
        for _,id in sgs.qlist(yiji_cards) do
            room:setCardFlag(sgs.Sanguosha:getCard(id), "-fatewangzhe")
        end
        if invoke then
            local newdrawpile = sgs.IntList()
            for _,id in sgs.qlist(yiji_cards) do
                if sgs.Sanguosha:getCard(id):hasFlag("fatewangzhe_get") then
                    room:setCardFlag(sgs.Sanguosha:getCard(id), "-fatewangzhe_get")
                    room:obtainCard(player,sgs.Sanguosha:getCard(id))
                else
                    newdrawpile:append(id)
                end
            end
            if newdrawpile:length() > 0 then
                room:returnToTopDrawPile(newdrawpile)
            end
        end
		--[[local card_ids = room:getNCards(2) --生成一个sgs.IntList()，返回牌顶两张牌的ID。此方法将两张牌从牌顶移走。
		room:fillAG(card_ids, player)
		local choice_id = room:askForAG(player, card_ids, true, self:objectName())
		if choice_id == -1 then
		room:returnToTopDrawPile(card_ids)
		else
		player:obtainCard(sgs.Sanguosha:getCard(choice_id))
		room:takeAG(player,choice_id,false)
		card_ids:removeOne(choice_id)
		room:returnToTopDrawPile(card_ids)
		end]]
	--[[	if choice_id == -1 then --未选择，则将牌返回牌顶
			if card_ids:length() == 1 then --牌顶只有一张
				room:moveCardTo(sgs.Sanguosha:getCard(card_ids:first()), player, sgs.Player_DrawPile, true)
			else
				room:moveCardTo(sgs.Sanguosha:getCard(card_ids:last()), player, sgs.Player_DrawPile, true)
				room:moveCardTo(sgs.Sanguosha:getCard(card_ids:first()), player, sgs.Player_DrawPile, true)
			end
		elseif choice_id==card_ids:first() then --如果选择了第一张牌
			if card_ids:length() == 1 then room:moveCardTo(sgs.Sanguosha:getCard(card_ids:first()), player, sgs.Player_PlaceHand, false) --牌顶只有一张
			else
				room:moveCardTo(sgs.Sanguosha:getCard(card_ids:first()), player, sgs.Player_PlaceHand, false)
				room:moveCardTo(sgs.Sanguosha:getCard(card_ids:last()), player, sgs.Player_DrawPile, true) --这里如改成false，AI发动技能后就会无故跳出
			end
		else --选择了第二张
			room:moveCardTo(sgs.Sanguosha:getCard(card_ids:last()), player, sgs.Player_PlaceHand, false)
			room:moveCardTo(sgs.Sanguosha:getCard(card_ids:first()), player, sgs.Player_DrawPile, true)
		end]]
		--room:clearAG()
	end
		return false
	end,
}

--求战 出牌阶段，你可以令一名其他角色对你使用一张【杀】，该【杀】不受距离限制。若该角色不如此做，视为你对之打出了一张无色的【决斗】。每阶段限一次。
fateqiuzhan_card = sgs.CreateSkillCard
{
	name = "fateqiuzhan_card",
	once = true,
	will_throw = true,
	filter=function(self,targets,to_select,player)
		return (#targets < 1) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect=function(self,effect)
		local from = effect.from
		local to = effect.to
		local room = from:getRoom()
		local slash = room:askForCard(to, "slash", "@fateqzslash:",sgs.QVariant(data))
		if slash then 
			local use = sgs.CardUseStruct()
  			use.card = slash
			use.to:append(from)
			use.from = to 
			room:useCard(use,false)
			return false 
		end
		if (not slash) then
			local duel = sgs.Sanguosha:cloneCard("duel",sgs.Card_NoSuit, 0)
			duel:setSkillName("fateqiuzhan_card")
			duel:deleteLater()
			local use = sgs.CardUseStruct()
  			use.card = duel
			use.to : append(to)
			use.from = from
			room:useCard(use,false)
			return false
		end
	end,
}

fateqiuzhan = sgs.CreateViewAsSkill{
	name = "fateqiuzhan",
	n=0,
	view_filter=function()
		return false
	end,
	view_as=function(self, cards)        
		return fateqiuzhan_card:clone()
	end,
	enabled_at_play=function(self,player) 
		return (not player:hasUsed("#fateqiuzhan_card"))
	end,
	enabled_at_response=function(self,player,pattern)
		return false
	end,
}

--神剑 限定技，出牌阶段，若你不处于满血状态，你可以弃两张手牌并选择攻击范围内的最多两名角色，对他们分别造成X点无属性伤害。X为你已损失的体力值且最多为2。
fateshenjian_card = sgs.CreateSkillCard
{
	name = "fateshenjian_card",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
		return (#targets < 2) and sgs.Self:inMyAttackRange(to_select)
	end,
	on_effect = function(self,effect)
		local from = effect.from
		local to = effect.to
		local room = from:getRoom()	
		from:loseMark("@shenjian_mark")
		--room:broadcastSkillInvoke("fateshenjian_trs")  --音效
		if to:isAlive() then 		
			local damage = sgs.DamageStruct()
			local x = from:getLostHp()
			if x > 2 then x = 2 end
			damage.card = nil
			damage.damage = x
			damage.from = from
			damage.to=effect.to	
			damage.nature = sgs.DamageStruct_Normal
			room:damage(damage)
		    return false 
		end
	end,
}

fateshenjianVS = sgs.CreateViewAsSkill
{
	name = "fateshenjian",
	n =2,
	view_filter = function(self,selected,to_select)
		return  (#selected < 2)and(to_select:isEquipped() == false)
	end,
	view_as = function(self,cards)
		if #cards ~= 2 then return false end
		new_card = fateshenjian_card:clone()
		new_card:addSubcard(cards[1]:getId())
		new_card:addSubcard(cards[2]:getId())
		new_card:setSkillName("fateshenjian")
		return new_card
	end,
enabled_at_play= function(self, player)
	return (player:getMark("@shenjian_mark")>0) and player:isWounded()
end,
enabled_at_response=function(self, player, pattern)
	return false
end
}

fateshenjian=sgs.CreateTriggerSkill{
name="fateshenjian",
view_as_skill=fateshenjianVS,
events=sgs.GameStart,
frequency = sgs.Skill_Limited,
limit_mark = "@shenjian_mark",
--priority
on_trigger=function(self,event,player,data)
end,
}



lastcard = nil

--死战
fatesizhan = sgs.CreateTriggerSkill{
	name = "fatesizhan",
	frequency = sgs.Skill_Wake,
	events = {sgs.Dying},
	waked_skills = "buqu",
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.Dying then	
			local dying = data:toDying()
			if dying.who:objectName() == player:objectName() then
					local recover = sgs.RecoverStruct()
					recover.who = player
					recover.recover = 1 - player:getHp()
					room:recover(player, recover)
				if room:changeMaxHpForAwakenSkill(player, 1, self:objectName()) then
				player:drawCards(3)
				room:handleAcquireDetachSkills(player,"buqu")
				room:addPlayerMark(player, "fatesizhan")
				end
				end
		end
	end,
		can_trigger = function(self, player)
		return player:isAlive() and player:hasSkill(self:objectName()) and player:getMark("fatesizhan") < 1 
	end,
}

touyingcard = nil

--投影
--[[
fatetouying = sgs.CreateViewAsSkill
{
	name = "fatetouying",
	n = 1,
	
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() then return false end                        --装备不可以使用
		return true
	end,
	
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local ld_card
			if touyingcard==nil then
				touyingcard="peach"
			end
			ld_card = sgs.Sanguosha:cloneCard(touyingcard, cards[1]:getSuit(), cards[1]:getNumber())
			ld_card:addSubcard(cards[1])
			ld_card:setSkillName(self:objectName())
			return ld_card
		end
	end,
	
	enabled_at_play = function(self, player) 
		if player:getMark("@touyingused")==0 then
			if player:hasFlag("amazing_grace") then --五谷丰登
				touyingcard = "amazing_grace"
			elseif player:hasFlag("archery_attack") then --万箭齐发
				touyingcard = "archery_attack"
			elseif player:hasFlag("collateral") then --借刀杀人
				touyingcard = "collateral"
			elseif player:hasFlag("dismantlement") then --过河拆桥
				touyingcard = "dismantlement"
			elseif player:hasFlag("duel") then --决斗
				touyingcard = "duel"
			elseif player:hasFlag("ex_nihilo") then --无中生有
				touyingcard = "ex_nihilo"
			elseif player:hasFlag("fire_attack") then --火攻
				touyingcard = "fire_attack"
			elseif player:hasFlag("fire_slash") then --火杀
				touyingcard = "fire_slash"
			elseif player:hasFlag("fate_salvation") then --桃园结义
				touyingcard = "fate_salvation"
			elseif player:hasFlag("iron_chain") then --铁锁连环
				touyingcard = "iron_chain"
			elseif player:hasFlag("nullification") then --无懈可击
				touyingcard = "nullification"
			elseif player:hasFlag("peach") then --桃
				touyingcard = "peach"
			elseif player:hasFlag("savage_assault") then --南蛮入侵
				touyingcard = "savage_assault"
			elseif player:hasFlag("slash") then --杀
				touyingcard = "slash"
			elseif player:hasFlag("snatch") then --顺手牵羊
				touyingcard = "snatch"
			elseif player:hasFlag("thunder_slash") then --雷杀
				touyingcard = "thunder_slash"
			elseif player:hasFlag("analeptic") then --酒
				touyingcard = "analeptic"
			else
				return false
			end
		else
			return false
		end
		if touyingcard==nil then
			return false
		else
			return true
		end	
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}


fatetouying_trs = sgs.CreateTriggerSkill{
	name = "#fatetouying_trs",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart,sgs.CardUsed},
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			if player:getMark("@touyingused")>0 then
				player:loseMark("@touyingused")
		--	room:setPlayerMark(player,"@touyingused",0)
			end
			lastcard = nil
		elseif event==sgs.CardUsed and player:getPhase() == sgs.Player_Play and player:getMark("@touyingused")==0 then
			local card = data:toCardUse().card
			if table.contains(card:getSkillNames(), "fatetouying") then
				if card:isKindOf("BasicCard") then
					room:broadcastSkillInvoke("lexue",2)
				elseif card:isNDTrick() then
					room:broadcastSkillInvoke("lexue",3)
				end
				player:gainMark("@touyingused", 1)
		--		player:addMark("@touyingused")
			end
			if (card:isKindOf("BasicCard") or card:isNDTrick()) and player:getMark("@touyingused")==0 then 
			--	player:clearFlags() 这句会导致甚多bug！比如【酒】无效等等等
			
				if player:hasFlag("amazing_grace") then --五谷丰登
					player:setFlags("-amazing_grace")
				elseif player:hasFlag("archery_attack") then --万箭齐发
					player:setFlags("-archery_attack")
				elseif player:hasFlag("collateral") then --借刀杀人
					player:setFlags("-collateral")
				elseif player:hasFlag("dismantlement") then --过河拆桥
					player:setFlags("-dismantlement")
				elseif player:hasFlag("duel") then --决斗
					player:setFlags("-duel")
				elseif player:hasFlag("ex_nihilo") then --无中生有
					player:setFlags("-ex_nihilo")
				elseif player:hasFlag("fire_attack") then --火攻
					player:setFlags("-fire_attack")
				elseif player:hasFlag("fire_slash") then --火杀
					player:setFlags("-fire_slash")
				elseif player:hasFlag("fate_salvation") then --桃园结义
					player:setFlags("-fate_salvation")
				elseif player:hasFlag("iron_chain") then --铁锁连环
					player:setFlags("-iron_chain")
				elseif player:hasFlag("nullification") then --无懈可击
					player:setFlags("-nullification")
				elseif player:hasFlag("peach") then --桃
					player:setFlags("-peach")
				elseif player:hasFlag("savage_assault") then --南蛮入侵
					player:setFlags("-savage_assault")
				elseif player:hasFlag("slash") then --杀
					player:setFlags("-slash")
				elseif player:hasFlag("snatch") then --顺手牵羊
					player:setFlags("-snatch")
				elseif player:hasFlag("thunder_slash") then --雷杀
					player:setFlags("-thunder_slash")
				elseif player:hasFlag("analeptic") then --酒
					player:setFlags("-analeptic")
				end

				if lastcard~=nil then 
					room:setPlayerFlag(player,"-"..lastcard)
				end
				room:setPlayerFlag(player,card:objectName())
				lastcard = card:objectName()
			end
		--以下觉悟开始
		end
	end,
}
]]


fatetouyingVS=sgs.CreateViewAsSkill{
	name="fatetouying",
	n=1,
	response_or_use = true,
	view_filter=function(self,selected,to_select)
		local card_id=sgs.Self:getMark("fatetouyingskill")
		local card=sgs.Sanguosha:getCard(card_id)
		card:setSkillName("fatetouying")
		return not to_select:isEquipped() and card:isAvailable(sgs.Self)
	end,
view_as=function(self,cards)
	if #cards==0 then return nil end
		local card_id=sgs.Self:getMark("fatetouyingskill")
		local card=sgs.Sanguosha:getCard(card_id)
		local acard=cards[1]
		local new_card=sgs.Sanguosha:cloneCard(card:objectName(),acard:getSuit(),acard:getNumber())
		new_card:addSubcard(cards[1])
		new_card:setSkillName(self:objectName())
		return new_card
	end,
	enabled_at_play=function(self, player)
		local card_id=player:getMark("fatetouyingskill")
		local card=sgs.Sanguosha:getCard(card_id)
		card:setSkillName("fatetouying")
		return player:hasFlag("fatetouyingx") and card:isAvailable(player)
	end,
}


fatetouying = sgs.CreateTriggerSkill{
	name = "fatetouying",
	events = {sgs.CardUsed},
	view_as_skill = fatetouyingVS,
	on_trigger = function(self,event,player,data)
	local room = player:getRoom()
	local card = data:toCardUse().card
	if (player:getPhase() ~= sgs.Player_Play) then return false end
	if event==sgs.CardUsed and not player:hasFlag("fatetouyingused") and not card:isKindOf("Nullification")  then
		if  card:isNDTrick() or card:isKindOf("BasicCard")then
				room:setPlayerFlag(player,"fatetouyingx")
				if not card:isVirtualCard() then
				local card_id=card:getEffectiveId()
				room:setPlayerMark(player,"fatetouyingskill",card_id)
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, "fatetouying") and player:getMark(mark) > 0 then
						room:setPlayerMark(player, mark, 0)
					end
				end
				room:setPlayerMark(player, "&fatetouying+" .. card:objectName() .. "-".. player:getPhase() .."Clear", 1)
				end
				if table.contains(card:getSkillNames(), "fatetouying") then
					room:setPlayerFlag(player,"fatetouyingused")
					room:setPlayerFlag(player,"-fatetouyingx")
				end
			end
		end
	end
}
fatetouyingTargetMod = sgs.CreateTargetModSkill{
	name = "#fatetouying" ,
	pattern = "Slash",
	residue_func = function(self, player, card)
		if player:hasSkill("fatetouying") and table.contains(card:getSkillNames(), "fatetouying") then
			return 1
		else
			return 0
		end
	end,
}



--献身：受伤时观看X+3张牌，观星。X为已损失体力值.+圣骸触发技
fatexianshen=sgs.CreateTriggerSkill{ 
name="fatexianshen",
frequency=sgs.Skill_Frequent,
events=sgs.Damaged,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()
	if event==sgs.Damaged then
		if(room:askForSkillInvoke(player,"fatexianshen") ==false) then return end
  	 	local x = player:getLostHp()+3
		room:askForGuanxing(player,room:getNCards(x))
	end
end,
}

--圣骸: 每当你在其他角色的回合内进入了濒死状态，你可以在该角色回合结束后立刻获得一个额外回合。
fateshenghai = sgs.CreateTriggerSkill{
	name = "fateshenghai",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.Dying,sgs.DamageInflicted},
	can_trigger = function(self, target)
                return target
        end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.Dying then
		local dying = data:toDying()
		if dying.who:objectName() ~= player:objectName() then return false end
			if not player:hasSkill(self:objectName()) then return false end
			if player:getPhase()==sgs.Player_NotActive then
				player:gainMark("&fateshenghai",1)
			end
		end
		if((event == sgs.EventPhaseStart and player:getPhase()==sgs.Player_Finish)) then--结束阶段，确认发动
			for _, Carene in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if Carene:getMark("&fateshenghai")>0 then
					Carene:loseAllMarks("&fateshenghai")--丢失标记
					if room:askForSkillInvoke(Carene,"fateshenghai") then
						local playerdata = sgs.QVariant()
						playerdata:setValue(Carene)
						Carene:setTag("fateshenghai", playerdata)
					end
				end
			end
		end
		if (event == sgs.DamageInflicted) then
			if not player:hasSkill(self:objectName()) then return false end
			if player:getMark("&fateshenghai")==0 then return false end--没有标记，不可发动技能
			if room:askForSkillInvoke(player,"fateshenghai") then
				local log= sgs.LogMessage()
				log.type = "#fateshenghaiwudi"
				log.from = player
				log.arg = self:objectName()
				room:sendLog(log)
				return true
			end
		end
	end,
}	
fateshenghaiGive = sgs.CreateTriggerSkill{
	name = "#fateshenghaiGive" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, Carene in sgs.qlist(room:findPlayersBySkillName("fateshenghai")) do
			if Carene:getTag("fateshenghai") then
				local target = Carene:getTag("fateshenghai"):toPlayer()
				Carene:removeTag("fateshenghai")
				if target and target:isAlive() then
					target:gainAnExtraTurn()
				end
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end ,
	priority = 1
}

--广博：摸牌阶段，你可以选择获得技能“完杀”“强袭”“天义”“奇袭”“武圣”之中的一个直至回合结束。
fateguangbo = sgs.CreateTriggerSkill
{
	name = "fateguangbo",
	frequency = sgs.Skill_NotFrequent,
	events ={sgs.DrawNCards,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			if(room:askForSkillInvoke(player,"fateguangbo") ==false) then return end
			local choice = room:askForChoice(player, "fateguangbo", "fateguangbo1+fateguangbo2+fateguangbo3+fateguangbo4+fateguangbo5")
					if(choice == "fateguangbo1") then
						player:setFlags("gbwansha")
						room:handleAcquireDetachSkills(player,"wansha")
					elseif (choice == "fateguangbo2") then
						player:setFlags("gbqiangxi")
						room:handleAcquireDetachSkills(player,"qiangxi")
					elseif (choice == "fateguangbo3") then
						player:setFlags("gbtianyi")
						room:handleAcquireDetachSkills(player,"tianyi")
					elseif (choice == "fateguangbo4") then
						player:setFlags("gbqixi")
						room:handleAcquireDetachSkills(player,"qixi")
					elseif (choice == "fateguangbo5") then
						player:setFlags("gbwusheng")
						room:handleAcquireDetachSkills(player,"wusheng")
					end
					room:addPlayerMark(player, "&fateguangbo+"..choice .."-Clear")
		elseif  (event == sgs.EventPhaseStart and player:getPhase()==sgs.Player_Finish) then
			if player:hasFlag("gbwansha") then
				room:handleAcquireDetachSkills(player,"-wansha")
			elseif player:hasFlag("gbqiangxi") then
				room:handleAcquireDetachSkills(player,"-qiangxi")
			elseif player:hasFlag("gbtianyi") then
				room:handleAcquireDetachSkills(player,"-tianyi")
			elseif player:hasFlag("gbqixi") then
				room:handleAcquireDetachSkills(player,"-qixi")
			elseif player:hasFlag("gbwusheng") then 
				room:handleAcquireDetachSkills(player,"-wusheng")
			end
		end
	end
}

--突击：限定技，在回合结束阶段，你可以立即获得一个额外的回合。
fatetuji=sgs.CreateTriggerSkill{
	name="fatetuji",
	frequency = sgs.Skill_Limited,
	events={sgs.EventPhaseEnd},--阶段改变时发动
	limit_mark = "@fatetuji",
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()--获取房间
		if player:getMark("@fatetuji")==0 then return false end--没有标记，不可使用技能
		if((event == sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Finish) and room:askForSkillInvoke(player,"fatetuji")) then--结束阶段，确认发动
			player:loseAllMarks("@fatetuji")--丢失标记
			player:play()--重新开始回合
		end
	end,
}

--Rin 清醒：你可以弃一张红桃牌或【闪】使任意角色跳过判定阶段并使之回复一点体力。若以此法跳过了自己的判定阶段，你将获得你判定区中的所有牌。
fateqingxing=sgs.CreateTriggerSkill{ 
name="fateqingxing",
frequency=sgs.Skill_NotFrequent,
events=sgs.EventPhaseStart,
can_trigger = function(self, target)
                return target
        end,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()
	local Rin = room:findPlayerBySkillName(self:objectName())
	if not Rin then return end
	if not Rin:isAlive() then return end
	if player:getPhase() == sgs.Player_Start then
		local card = room:askForCard(Rin, ".|heart#Jink", "@fateqingxing1", data, sgs.CardDiscarded)
    	if card~=nil then
			local recov = sgs.RecoverStruct()
			recov.who = Rin
			room:recover(player, recov)
			player:skip(sgs.Player_Judge)
			if Rin:getPhase() == sgs.Player_Start then 
			 	local cards=player:getJudgingArea()
				for _,cd in sgs.qlist(cards) do
				player:obtainCard(cd)
			end
		end
		end
	end
end,
}

--机智 锁定技，当你的装备区内无防具时，你无法成为【过河拆桥】,【顺手牵羊】及【借刀杀人】的目标。
fatejizhi=sgs.CreateProhibitSkill{
name = "fatejizhi",
is_prohibited=function(self,from,to,card)
	if to:getArmor()  then return end
    if (to:hasSkill(self:objectName())) then
        return (card:isKindOf("Snatch") or card:isKindOf("Dismantlement") or card:isKindOf("Collateral")) 
    end
end,
}

--补魔 限定技，出牌阶段，若你不处于满血状态或你的手牌数小于你的体力上限，你可以选择一名不处于满血状态或手牌数小于其体力上限的异性角色，你们各回复一点体力，并将手牌数补至体力上限（最多为5）。
fatebumo_card = sgs.CreateSkillCard
{
	name = "fatebumo_card",
	filter = function(self,targets,to_select)
		return (#targets < 1) and (to_select:getLostHp()>0 or to_select:getHandcardNum() < to_select:getMaxHp()) and (to_select:getGender()~=sgs.Self:getGender())
	end,
	on_effect = function(self,effect)
		local from = effect.from
		local to = effect.to
		local room = from:getRoom()	
		from:loseMark("@bumo_mark")
		--room:broadcastSkillInvoke("fatebumo_trs")  --音效
		if to:isAlive() then 		
			if from:getLostHp()>0 then
				local recov = sgs.RecoverStruct()
				recov.who = from
				room:recover(from, recov)
			end
			if to:getLostHp()>0 then
				local recov = sgs.RecoverStruct()
				recov.who = to
				room:recover(to, recov)
			end
			local upper = math.min(5, from:getMaxHp())
			local x = upper - from:getHandcardNum()
			if x <= 0 then
			else
				from:drawCards(x)
			end
			local upper = math.min(5, to:getMaxHp())
			local x = upper - to:getHandcardNum()
			if x <= 0 then
			else
				to:drawCards(x)
			end
		    return false 
		end
	end,
}

fatebumoVS = sgs.CreateViewAsSkill
{
	name = "fatebumo",
	n =0,
	view_as = function(self,cards)
		if #cards==0 then
		new_card = fatebumo_card:clone()
		new_card:setSkillName("fatebumo")
		return new_card
		end
	end,
	enabled_at_play = function(self, player)
	return (player:getMark("@bumo_mark")>0) and (player:isWounded() or player:getHandcardNum() < player:getMaxHp())
end,
enabled_at_response=function(self, player, pattern)
	return false
end
}

fatebumo=sgs.CreateTriggerSkill{
name="fatebumo",
view_as_skill=fatebumoVS,
events=sgs.GameStart,
frequency = sgs.Skill_Limited,
limit_mark = "@bumo_mark",
--priority
on_trigger=function(self,event,player,data)
end,
}

--健壮:当你处于濒死状态时,若你的体力上限大于3，你可以减少一点体力上限并回复3点体力。
fateshilian=sgs.CreateTriggerSkill{
	name="fateshilian",
 	frequency = sgs.Skill_NotFrequent,
 	events = {sgs.Dying},
	on_trigger=function(self,event,player,data)
		local dying = data:toDying()
		if dying.who:objectName() == player:objectName() then
		if player:getMaxHp() < 4 then return end
		if not player:hasSkill(self:objectName()) then return false end 
		while (player:getHp() < 1 and player:getMaxHp() > 3) do
			local room = player:getRoom()
		    if not player:hasSkill(self:objectName()) then return false end
		    if not room:askForSkillInvoke(player, self:objectName()) then return false end
			room:loseMaxHp(player,1)
			local recover=sgs.RecoverStruct()
			recover.recover=3
			recover.who=player
			room:recover(player,recover)--回复	
		end
		end
   	end
}
local function getCardDamageNature(from, to, card)
    local nature = sgs.DamageStruct_Normal
    if card then
        if card:isKindOf("FireSlash") then
            nature = sgs.DamageStruct_Fire
        elseif card:isKindOf("ThunderSlash") then
            nature = sgs.DamageStruct_Thunder
        elseif card:isKindOf("IceSlash") then
            nature = sgs.DamageStruct_Ice
        end
    end
    return nature
end
--巨力 锁定技，当你使用【杀】指定一名角色为目标后，该角色需连续使用一张【杀】和一张【闪】才能抵消。
fatejuli = sgs.CreateTriggerSkill {
	name = "fatejuli",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		local dest = effect.to
		local source = effect.from
		if effect.card and effect.card:isKindOf("Slash") and source:hasSkill(self:objectName()) then
			room:notifySkillInvoked(source, self:objectName())
			effect.to:setFlags("Global_NonSkillNullify")
			local firstjink, secondjink = nil, nil
			local log= sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = effect.from
			log.arg = self:objectName()
			room:sendLog(log)
			local slasher = player:objectName()
			firstjink = room:askForCard(effect.to, "slash", "@fatejuli-jink-1:"..slasher, data,  sgs.Card_MethodResponse, effect.to, false,"", true)
			if firstjink then
				secondjink = room:askForCard(effect.to,"jink", "@fatejuli-jink-2:"..slasher, data ,sgs.Card_MethodResponse, effect.to, false,"", true)
			end
			local jink = nil
			if (firstjink and secondjink) then
				jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
				jink:addSubcard(firstjink)
				jink:addSubcard(secondjink)
				jink:deleteLater()
				effect.offset_card = jink
				data:setValue(effect)
				if not room:getThread():trigger(sgs.CardOffset,room,effect.from,data) then
					return true
				end
			else
				effect.offset_card = nil
				data:setValue(effect)
				room:getThread():trigger(sgs.CardOnEffect,room,effect.to,data)
				room:damage(sgs.DamageStruct(effect.card, effect.from, effect.to, 1, getCardDamageNature(effect.from, effect.to, effect.card)))
				return true
			end		
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

--Medea
--妖术:出牌阶段，你可以弃掉两张相同花色的手牌。根据花色有不同效果。
--红桃：使任意角色回复一点体力。黑桃：使任意角色翻面。方块：使任意角色摸3张牌。梅花：对任意角色造成一点雷属性伤害。每回合限一次。

fateyaoshucard = sgs.CreateSkillCard
{
	name = "fateyaoshu",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
	local suit = sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit()
	if suit == sgs.Card_Heart then
		return (#targets < 1) and to_select:isWounded()
		else 
		return (#targets < 1)
		end
	end,
	on_effect = function(self,effect)
		local from = effect.from
		local to = effect.to
		local room = from:getRoom()
		local suit = sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit()
		if suit == sgs.Card_Heart then
		if (to:isAlive()) then 		
			local recov = sgs.RecoverStruct()
			recov.who = from
			room:recover(to, recov)
		    return false 
			end
		elseif suit == sgs.Card_Spade then 
		if (to:isAlive()) then
			to:turnOver()
		    return false 
		end
		elseif suit == sgs.Card_Diamond then 
		if (to:isAlive()) then
			to:drawCards(3)
		    return false 
		end
		elseif suit == sgs.Card_Club then 
		if (to:isAlive()) then 		
			local damage = sgs.DamageStruct()
			damage.card = nil
			damage.damage = 1
			damage.from = from
			damage.to=effect.to	
			damage.nature = sgs.DamageStruct_Thunder
			room:damage(damage)
		    return false 
		end
		end
	end,
}

fateyaoshu = sgs.CreateViewAsSkill
{
	name = "fateyaoshu",
	n =2,
	view_filter = function(self,selected,to_select)
		if #selected ==0 then return not to_select:isEquipped() end --非装备
        if #selected == 1 then --限制两张花色一样
                        local cc = selected[1]:getSuit()
                        return (not to_select:isEquipped()) and to_select:getSuit() == cc
        else return false
        end
	end,
	view_as = function(self,cards)
		if #cards ~= 2 then return false end
			new_card = fateyaoshucard:clone()
			new_card:addSubcard(cards[1]:getId())
			new_card:addSubcard(cards[2]:getId())
			new_card:setSkillName("fateyaoshu")
			return new_card
	end,
enabled_at_play=function(self,player)
	return true
end,
enabled_at_response=function(self, player, pattern)
	return false
end
}

--法阵 回合开始阶段，你可以摸一张牌。
fateshenyan=sgs.CreateTriggerSkill{ 
name="fateshenyan",
frequency=sgs.Skill_Frequent,
events=sgs.EventPhaseStart,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()
	if (player:getPhase() ~= sgs.Player_Start) then return end
	if(room:askForSkillInvoke(player,self:objectName()) ==false) then return end
	player:drawCards(1)
	return false
end,
}

--法袍：锁定技，对你造成的属性伤害无效。
fatefapao = sgs.CreateTriggerSkill{
	name = "fatefapao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Predamage,sgs.DamageInflicted},--Predamage对应直接受到的伤害，DamageInflicted对应来自铁索的伤害
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if (event == sgs.Predamage or event == sgs.DamageInflicted) then
			if (damage.to:hasSkill("fatefapao") == false) then return end
			if ((damage.nature == sgs.DamageStruct_Thunder) or (damage.nature == sgs.DamageStruct_Fire)) then
				local log= sgs.LogMessage()
				log.type = "#TriggerSkill"
				log.from = damage.to
				log.arg = self:objectName()
				room:sendLog(log)
				return true
			end
		end
	end,
}

--厨艺 出牌阶段，你可以弃掉两张手牌，使除你以外的任意一名角色摸两张牌并回复一点体力。每回合限一次。
fatechuyi_card = sgs.CreateSkillCard
{
	name = "fatechuyi_card",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
		return (#targets < 1) and (to_select:hasSkill("fatechuyi_vs")==false) --这样的写法在双将中会出问题
	end,
	on_effect = function(self,effect)
		local from = effect.from
		local to = effect.to
		local room = from:getRoom()
		if (to:isAlive()) then
			to:drawCards(2)
			local recov = sgs.RecoverStruct()
			recov.who = from
			room:recover(to, recov)
		    return false 
		end
	end,
}

fatechuyi_vs = sgs.CreateViewAsSkill
{
	name = "fatechuyi_vs",
	n =2,
	view_filter = function(self,selected,to_select)
		return not to_select:isEquipped()  --非装备
	end,
	view_as = function(self,cards)
		if #cards ~= 2 then return false end
		new_card = fatechuyi_card:clone()
		new_card:addSubcard(cards[1]:getId())
		new_card:addSubcard(cards[2]:getId())
		new_card:setSkillName("fatechuyi_vs")
		return new_card		
	end,
enabled_at_play=function(self,player)
	return not player:hasUsed("#fatechuyi_card")
end,
enabled_at_response=function(self, player, pattern)
	return false
end
}

--吸能：锁定技，你在回合开始阶段强制获得下家的一张牌，并可以使其流失一点体力。
fatexineng=sgs.CreateTriggerSkill{ 
name="fatexineng",
frequency=sgs.Skill_Compulsory,
events=sgs.EventPhaseStart,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()
	if (player:getPhase() ~= sgs.Player_Start) then return end
	local target = player:getNextAlive()
	if not target:isAllNude() then
		local log= sgs.LogMessage()
		log.type = "#TriggerSkill"
		log.from = player
		log.arg = self:objectName()
		room:sendLog(log)
		local card_id = room:askForCardChosen(player, target, "hej", "@fatexineng")
		room:moveCardTo(sgs.Sanguosha:getCard(card_id), player, sgs.Player_PlaceHand, false)
	end
	--choice = room:askForChoice(player, "xnchoice", "xnchoice1+xnchoice2")
	--if(choice == "xnchoice1") then
	--	room:loseHp(target)
	--end
	if room:askForSkillInvoke(player,"fatexinengloseHP",data) then 
		room:loseHp(target, 1, true, player, self:objectName())
	end
	return false
end,
}

local skill=sgs.Sanguosha:getSkill("fatexineng")
if not skill then
        local skillList=sgs.SkillList()
        skillList:append(fatexineng)
        sgs.Sanguosha:addSkills(skillList)
end

--黑化 觉醒技，当你处于濒死状态时，弃置你的所有手牌，然后将你的武将牌翻至正面朝上，摸三张牌并使体力回复至3点。然后你失去技能【厨艺】，并永久获得技能【妖术】与【吸能】。

fateheihua = sgs.CreateTriggerSkill{
	name = "fateheihua",
	frequency = sgs.Skill_Wake,
	events = {sgs.Dying},
	waked_skills = "fateyaoshu,fatexineng",
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.Dying then	
			local dying = data:toDying()
			if dying.who:objectName() == player:objectName() then
			player:throwAllHandCards()
				if not player:faceUp() then player:turnOver() end
				player:drawCards(3)
					local recover = sgs.RecoverStruct()
					recover.who = from
					recover.recover = 3 - player:getHp()
					room:recover(player, recover)
				if room:changeMaxHpForAwakenSkill(player, 0, self:objectName()) then
					room:handleAcquireDetachSkills(player,"-fatechuyi_vs")
					room:handleAcquireDetachSkills(player,"fateyaoshu")
					room:handleAcquireDetachSkills(player,"fatexineng")
					room:addPlayerMark(player, "fateheihua")
				end
				end
		end
	end,
		can_trigger = function(self, player)
		return player:isAlive() and player:hasSkill(self:objectName()) and player:getMark("fateheihua") < 1 
	end,
}

--乱射 出牌阶段，你可以将任意一张红桃手牌当【万箭齐发】打出。每回合限一次。
fateluanshe_vs = sgs.CreateViewAsSkill
{
	name = "fateluanshe_vs",
	n =1,
	response_or_use = true,
	view_filter = function(self,selected,to_select)
		return  (to_select:getSuit()==sgs.Card_Heart) and (to_select:isEquipped() == false)
	end,
	view_as = function(self,cards)
		if #cards < 1 then return nil end
		local card = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_Heart, cards[1]:getNumber())
        card:addSubcard(cards[1]:getId())
		card:setSkillName("fateluanshe_vs")
		sgs.Self:setFlags("luansheused")--给予标志
		return card
	end,
enabled_at_play=function(self,player)
	return not player:hasFlag("luansheused")
end,
enabled_at_response=function(self, player, pattern)
	return false
end
}

--穿心 当你的【万箭齐发】结算完毕后,你可以弃一张手牌并选择除你以外的一名角色，视为你对其打出了X张无色的【杀】。X为场上存活角色数除以5（向上取整）。以此法打出的【杀】不计入出牌阶段限制。
fatechuanxin_trs=sgs.CreateTriggerSkill{
name="fatechuanxin_trs",
frequency = sgs.Skill_Frequent,
events=sgs.CardFinished,
on_trigger=function(self,event,player,data)		
    local room=player:getRoom()
    local use=data:toCardUse()
    local card =use.card
	local from =use.from
	if not card:isKindOf("ArcheryAttack") then return end
--上句也可以写作：	if not card:objectName() == "archery_attack" then return end
	if not from:hasSkill(self:objectName()) then return end
	if from:isKongcheng() then return end
	local x=(room:alivePlayerCount())/5
--	if x < 1 then return end
	local targets = sgs.SPlayerList()
	 for _,p in sgs.qlist(room:getOtherPlayers(from))do 
	 if from:canSlash(p,nil, false) then 
	 targets:append(p)
	 end
	 end
	 if targets:isEmpty() then return false end 
	 local card_dis=room:askForCard(from, ".|.|.|hand|.", "@fatechuanxin1", data, sgs.CardDiscarded)
	if card_dis == nil then return end
	local slashto=room:askForPlayerChosen(from, targets, "@fatechuanxin2")
	local i=1
	while(i<x+1 and slashto:isAlive()) do
		local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit, 0)
		slash:setSkillName("fatechuanxin_trs")
		slash:deleteLater()
		local slashuse = sgs.CardUseStruct()
		slashuse.from = from
		slashuse.to:append(slashto)
		slashuse.card = slash
		room:useCard(slashuse, false)
		i=i+1
	end
end,
}



--天弓 出牌阶段，你可以弃一张手牌然后选择一名角色或两名距离1以内的角色，视为对其打出了一张不计入出牌阶段限制的无色的【火杀】。每回合限一次。
fatetiangong_card = sgs.CreateSkillCard
{
	name = "fatetiangong_card",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
	if #targets ==0 then
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("fatetiangong_card")
		slash:deleteLater()
		return sgs.Self:canSlash(to_select,slash, false)
	elseif #targets ==1 then
			if sgs.Self:distanceTo(targets[1]) == 1 then 
			local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("fatetiangong_card")
		slash:deleteLater()
			return sgs.Self:distanceTo(to_select) == 1 and sgs.Self:canSlash(to_select,slash, false)
			end
		end
	end ,
	on_use = function(self, room, source, targets)		
			local slash = sgs.Sanguosha:cloneCard("fire_slash",sgs.Card_NoSuit, 0)
			slash:deleteLater()
		    slash:setSkillName("fatetiangong_card")
			local use = sgs.CardUseStruct()
			use.from = source
			for _, p in ipairs(targets) do
			use.to:append(p)
		end
			use.card = slash
			room:useCard(use, false)
	end,
}

fatetiangong_vs = sgs.CreateViewAsSkill
{
	name = "fatetiangong_vs",
	n = 1,
	
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped() 
	end,
	
	view_as = function(self, cards)
		if #cards == 0 then return end
		if #cards == 1 then
			local tgcard = fatetiangong_card:clone()
			tgcard:addSubcard(cards[1]:getId())
			return tgcard
		end
	end,
	
	enabled_at_play=function(self,player)
		return not player:hasUsed("#fatetiangong_card") 
	end,
	
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

--[[
fatetiangong_trs=sgs.CreateTriggerSkill{
name="fatetiangong_trs",
view_as_skill=fatetiangong_vs,
events={sgs.GameStart,sgs.Death},
can_trigger = function(self, target)
    return true
end,
frequency = sgs.Skill_NotFrequent,
--priorityelse
on_trigger=function(self,event,player,data)
	local room=player:getRoom()
	local Archer = room:findPlayerBySkillName(self:objectName())
	if not Archer:isAlive() then return end
if event == sgs.GameStart then
		playernum = room:alivePlayerCount()
		setMark("plnum", playernum)
			local log = sgs.LogMessage()
log.from = player
log.type = ("startnum=%d"):format(playernum)
room:sendLog(log)
	end
	if event == sgs.Death then
		playernum = room:alivePlayerCount()
					local log = sgs.LogMessage()
log.from = player
log.type = ("num=%d"):format(playernum)
room:sendLog(log)
	end

	local playernum = room:alivePlayerCount()
	Archer:setMark("plnum", playernum)
	return false
end,
}

]]
--剑冢 锁定技，【万箭齐发】对你无效；当其他角色使用【万箭齐发】，轮到你结算时，你可以弃掉一张牌并选择一名角色，视为对之打出了一张无色的【杀】。
fatejianzhong=sgs.CreateTriggerSkill{
name="fatejianzhong",
events=sgs.CardEffected,
frequency=sgs.Skill_Compulsory,
on_trigger=function(self,event,player,data)
	local effect=data:toCardEffect()
	local room=player:getRoom()
	local to=effect.to
	if effect.card:isKindOf("ArcheryAttack") and effect.to:hasSkill(self:objectName()) then			
		local log=sgs.LogMessage() --以下是无效的LOGTYPE
		log.type ="#SkillNullify"
		log.from=player
		log.arg=self:objectName() --技能名
		log.arg2="archery_attack" --卡名
		room:sendLog(log)
			local targets = sgs.SPlayerList()
	 for _,p in sgs.qlist(room:getOtherPlayers(to))do 
	 if to:canSlash(p,nil, false) then 
	 targets:append(p)
	 end
	 end
	 if targets:isEmpty() then return false end 
		if room:askForSkillInvoke(player,self:objectName()) then
			local card=room:askForCard(player, ".|.|.", "@fatejianzhong1", data, sgs.CardDiscarded)
			if card ~= nil then
				local slashto=room:askForPlayerChosen(player, targets, "@fatejianzhong2")
				local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit, 0)
				slash:setSkillName("fatejianzhong")
				slash:deleteLater()
				local slashuse = sgs.CardUseStruct()
				slashuse.from = player
				slashuse.to:append(slashto)
				slashuse.card = slash
				room:useCard(slashuse, false)
			end
		end
		return true
	end
end
}

--魔力 每当你使用或打出了一张基本牌或【五谷丰登】及【无中生有】之外的非延时锦囊牌，在结算后你可以进行一次判定。若结果为红色，你可以回收这张牌。
fatemoli=sgs.CreateTriggerSkill{
name="fatemoli",
frequency = sgs.Skill_Frequent,
events={sgs.CardFinished,sgs.CardResponsed},
on_trigger=function(self,event,player,data)		
    local room=player:getRoom()
	local card
    if event == sgs.CardFinished then
		local cu=data:toCardUse()
  	 	card = cu.card
  		if not card then return end
	end
	if event == sgs.CardResponsed then
		card = data:toCardResponse().m_card
		if not card then return end
	end
  if (card:isVirtualCard() and card:subcardsLength() > 0 or not card:isVirtualCard()) and  (card:isKindOf("BasicCard") or card:isNDTrick())  then   
	if (card:objectName() == "ex_nihilo" or card:objectName() == "amazing_grace" or card:isKindOf("SkillCard")) then return end
	if not room:askForSkillInvoke(player,self:objectName()) then return end
    local judge=sgs.JudgeStruct()
    judge.pattern=".|red"
    judge.good=true
    judge.reason=self:objectName()
   	judge.who=player
	judge.play_animation = true
   	room:judge(judge)
   	if judge:isGood() then
		local log=sgs.LogMessage()
		log.from =player
		log.type ="#fatemoli"
		room:sendLog(log)
        room:setEmotion(player, "good")
		room:moveCardTo(card, player, sgs.Player_PlaceHand, true)		
		end
		end
end,
}

--萝莉 出牌阶段，你可以观看任意一名角色的手牌，并可展示其中的一张然后将之置于牌堆顶。每回合限一次。
fateloli_card = sgs.CreateSkillCard
{
	name = "fateloli_card",
	once = true,
	will_throw = true,
	filter=function(self,targets,to_select,player)
		return (#targets < 1) and (to_select:isKongcheng()==false) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect=function(self,effect)
		local from = effect.from
		local to = effect.to
		local room = from:getRoom()
		local card_ids = to:handCards() --生成一个sgs.IntList()
		local cards = sgs.IntList()
		local dest = sgs.QVariant()
		dest:setValue(to)
		room:setTag("fateloli", dest)
		room:fillAG(card_ids, from)
		local choice_id = room:askForAG(from, card_ids, true, "fateloli_vs")
		if choice_id ~= -1 then
		cards:append(choice_id)
		room:showCard(to, choice_id)
		room:moveCardTo(sgs.Sanguosha:getCard(choice_id), effect.to, nil ,sgs.Player_DrawPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, effect.from:objectName(), "fateloli", ""), true)
		--room:returnToTopDrawPile(cards)
		--	room:moveCardTo(sgs.Sanguosha:getCard(choice_id), from, sgs.Player_DrawPile, true)
			--room:moveCardTo(sgs.Sanguosha:getCard(choice_id), from, sgs.Player_DrawPile, false) 这么写会跳出
		end
		room:clearAG()
		room:removeTag("fateloli")
	end,
}

fateloli_vs = sgs.CreateViewAsSkill{
	name = "fateloli_vs",
	n=0,
	view_filter=function()
		return false
	end,
	view_as=function(self, cards)        
		return fateloli_card:clone()
	end,
	enabled_at_play=function(self,player) 
		return (not player:hasUsed("#fateloli_card"))
	end,
	enabled_at_response=function(self,player,pattern)
		return false
	end,
}

--堕落：与你距离1以内的角色（包括你自己在内）在回合开始阶段须弃一张手牌，不弃牌或无法如此做者在摸牌阶段少摸一张牌。
fateduoluo = sgs.CreateTriggerSkill
{
	name = "fateduoluo",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart,sgs.DrawNCards},
	can_trigger = function(self, target)
                return target
        end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local Gilles = room:findPlayerBySkillName(self:objectName())
		if not Gilles:isAlive() then return end
		if Gilles:distanceTo(player)> 1 then return end
		if event == sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Start then
				local log= sgs.LogMessage()
				log.type = "#TriggerSkill"
				log.from = Gilles
				log.arg = self:objectName()
				room:sendLog(log)
				local choice = room:askForDiscard(player, "fateduoluo", 1, 1, true, false, "@fateduoluo")
				if choice then
					player:setFlags("qiguopai")
				end
			end
		end
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			if player:hasFlag("qiguopai") == false
				then 
					draw.num = draw.num - 1
					data:setValue(draw)
			end
		end
	end
}

--逆袭：摸牌阶段，若你没有手牌，你可以多摸3张牌并回复一点体力。
fatenixi = sgs.CreateTriggerSkill
{
	name = "fatenixi",
	frequency = sgs.Skill_Frequent,
	events =sgs.DrawNCards,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		if player:isKongcheng()==false then return end
		if(room:askForSkillInvoke(player,"fatenixi") ==false) then return end
		draw.num = draw.num + 3
		data:setValue(draw)
		local recover=sgs.RecoverStruct()
		recover.recover=1
		recover.who=player
		room:recover(player,recover)--回复	
	end
}

--宗和 弃牌阶段开始时，你可以将手牌数补充至体力上限+2。
fatezonghe=sgs.CreateTriggerSkill{
name="fatezonghe",
events={sgs.EventPhaseStart},
frequency = sgs.Skill_Frequent,
on_trigger=function(self,event,player,data)
        local room=player:getRoom()        
        if event==sgs.EventPhaseStart then
                if player:getPhase()==sgs.Player_Finish then
                        if player:getHandcardNum()<(player:getMaxHp()+2) then
                                if (room:askForSkillInvoke(player,self:objectName(),data)~=true) then return false end
                                player:drawCards(player:getMaxHp()-player:getHandcardNum()+2)
                        end
                end
        end
end,
}

--燕返 你可以将梅花手牌当【闪】使用或打出；将方块手牌当【杀】使用或打出。
yanfan_pattern = {} -- to control the card pattern
fateyanfan_vs = sgs.CreateViewAsSkill
{
	name = "fateyanfan_vs",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #yanfan_pattern == 0 then return false
		elseif #yanfan_pattern == 1 then
			if yanfan_pattern[1] == "slash" then return to_select:getSuit() == sgs.Card_Diamond
			elseif yanfan_pattern[1] == "jink" then return to_select:getSuit() == sgs.Card_Club
			end
		end
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = cards[1]
		local number = 0
		if #cards == 1 then number = cards[1]:getNumber() end
		if cards[1]:getSuit() == sgs.Card_Diamond then card = sgs.Sanguosha:cloneCard("slash", sgs.Card_Diamond, number)
		elseif cards[1]:getSuit() == sgs.Card_Club then card = sgs.Sanguosha:cloneCard("jink", sgs.Card_Club, number)
		end
		card:setSkillName("fateyanfan_vs")
		card:addSubcard(cards[1])
		return card
	end,
	
	
	enabled_at_play = function(self, player)
		table.remove(yanfan_pattern) -- reset the pattern
		local use_slash = false --这个只有在第一遍时赋值
		if player:canSlashWithoutCrossbow() or sgs.Slash_IsAvailable(player) then use_slash = true end  --注意写法，太阳神论坛里某人的神赵云的写法是错的
		if use_slash then table.insert(yanfan_pattern, "slash")
		end
		return #yanfan_pattern ~= 0
	end,
	
	enabled_at_response = function(self, player, pattern)
		table.remove(yanfan_pattern) -- reset the pattern
		if pattern == "slash" or pattern == "jink" then
			table.insert(yanfan_pattern, pattern)
		end
		return #yanfan_pattern ~= 0
	end,
}

--迅捷 锁定技，弃牌阶段结束后，你获得一个额外的出牌阶段。
fatexunjie = sgs.CreateTriggerSkill
{
name = "fatexunjie",
events = {sgs.EventPhaseChanging},
frequency=sgs.Skill_Compulsory,
on_trigger = function(self, event, player, data)
    local change=data:toPhaseChange()
	if change.to==sgs.Player_NotActive and change.from==sgs.Player_Finish then
		-- local room=player:getRoom()
 		-- local log= sgs.LogMessage()
		-- log.type = "#TriggerSkill"
		-- log.from = player
		-- log.arg = self:objectName()
		-- room:sendLog(log)
 		-- change.to=sgs.Player_Play
		-- data:setValue(change)
		-- player:insertPhase(sgs.Player_Play)
		PhaseExtra(player, sgs.Player_Play)
	end
return false
end,
}

--狂暴 出牌阶段，你可以向攻击范围内的一名角色展示你的手牌。若如此做，该角色流失1点体力。每回合限一次。
fatefanshi_card = sgs.CreateSkillCard
{
	name = "fatefanshi_card",
	once = true,
	will_throw = true,
	filter=function(self,targets,to_select,player)
		return (#targets < 1) and sgs.Self:inMyAttackRange(to_select)
	end,
	on_effect=function(self,effect)
		local from = effect.from
		local to = effect.to
		local room = from:getRoom()
		room:showAllCards(from,to)
		room:loseHp(to,1, true, from, "fatefanshi")
	end,
}

fatefanshi = sgs.CreateViewAsSkill{
	name = "fatefanshi",
	n=0,
	view_filter=function()
		return false
	end,
	view_as=function(self, cards)        
		return fatefanshi_card:clone()
	end,
	enabled_at_play=function(self,player) 
		return (not player:hasUsed("#fatefanshi_card"))
	end,
	enabled_at_response=function(self,player,pattern)
		return false
	end,
}

--反击 每当你使用或打出了一张【闪】，你可以立即对使用者打出一张【杀】。此【杀】无视防具且不计入出牌阶段限制。

fatefanji = sgs.CreateTriggerSkill{
	name = "fatefanji" ,
	events = {sgs.CardResponded,sgs.CardUsed} ,
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardResponded or event == sgs.CardUsed then 
			local card_star
			local target
			if event == sgs.CardResponded then
				card_star = data:toCardResponse().m_card
				target = data:toCardResponse().m_who
			elseif event == sgs.CardUsed then 
				local use  = data:toCardUse()
				if use.whocard and use.who then
					card_star = use.card
					target = use.who
				end
			end
			if card_star and card_star:isKindOf("Jink") and target and target:isAlive() then
				local prompt = string.format("fatefanji-slash:%s", target:objectName())
				local slash = room:askForUseSlashTo(player, target, prompt, false, false, false, nil, nil, "SlashIgnoreArmor")	
			end
		end
		return false
	end
}

--黑键 你可以在出牌阶段将一张黑色手牌（每回合限一次）或其他角色死亡时弃掉的黑色牌置于你的武将牌上，称为【键】。
--你每拥有一张【键】，手牌上限便+1。你受到伤害时，可以弃掉一张【键】使伤害-1；造成伤害时，可以弃掉一张【键】使伤害+1。你最多只能同时拥有五张【键】。

fateheijian_card = sgs.CreateSkillCard
{
	name = "fateheijian_card",	
	target_fixed = true,	
	will_throw = false,
on_use = function(self, room, source, targets)
        local room = source:getRoom()
	for _,card in sgs.qlist(self:getSubcards()) do
		source:addToPile("fateheijiancards", card, true)
    end		
end,
}

fateheijianVS=sgs.CreateViewAsSkill{
name="fateheijian",
n=1,
view_filter=function(self, selected, to_select)
	return to_select:isBlack() and (to_select:isEquipped() == false)
end,
view_as = function(self, cards)
   local x = #cards
		if #cards>0 then
		acard=fateheijian_card:clone()
		local y=0
		for var=1,x,1 do
		y=y+1
		acard:addSubcard(cards[y])
		end
		acard:setSkillName("fateheijian")
		return acard
	end
end,
enabled_at_play=function(self,player)
	return (player:hasUsed("#fateheijian_card")==false) and  (player:getPile("fateheijiancards"):length() < 5)
end,
enabled_at_response = function()
	return false
end,
}

fateheijian=sgs.CreateTriggerSkill{
	name="fateheijian",
	events={sgs.Predamage,sgs.DamageInflicted,sgs.EventPhaseStart,sgs.Death},
--	priority=2,
	view_as_skill=fateheijianVS,
	can_trigger=function(self,target)
		return target
	end,
	on_trigger=function(self,event,player,data)	
	local room=player:getRoom()
	if event == sgs.Predamage then
		if not player:hasSkill(self:objectName()) then return end
		local damage = data:toDamage()
		if not player:getPile("fateheijiancards"):isEmpty() and room:askForSkillInvoke(player, "fateheijianDamage", data) then
		--room:broadcastSkillInvoke("fateheijian")  --音效  ok
		--room:throwCard(player:getPile("fateheijiancards"):first(),player)
		--room:obtainCard(player, card_id)
		local card_ids = player:getPile("fateheijiancards") --生成一个sgs.IntList()
		room:fillAG(card_ids, player)
		local choice_id = room:askForAG(player, card_ids, false, self:objectName()) --不可拒绝
		--room:moveCardTo(sgs.Sanguosha:getCard(choice_id), player, sgs.Player_Discard, true)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "fateheijian", "");
				room:throwCard(sgs.Sanguosha:getCard(choice_id), reason, nil);
		room:clearAG()
		--room:throwCard(sgs.Sanguosha:getCard(choice_id),player)
		local log = sgs.LogMessage()
		log.type = "#fateheijianbuff1"
		log.from = player
		log.to:append(damage.to)
		log.arg = tonumber(damage.damage)
		log.arg2 = tonumber(damage.damage + 1)
		room:sendLog(log)
		damage.damage = damage.damage + 1
		data:setValue(damage)
		end
	elseif event == sgs.DamageInflicted then
		if not player:hasSkill(self:objectName()) then return end
		local damage = data:toDamage()
		if not player:getPile("fateheijiancards"):isEmpty() and room:askForSkillInvoke(player, "fateheijianDefense", data) then
		--room:broadcastSkillInvoke("fateheijian")  --音效  ok
		local card_ids = player:getPile("fateheijiancards") --生成一个sgs.IntList()
		room:fillAG(card_ids, player)
		local choice_id = room:askForAG(player, card_ids, false, self:objectName()) --不可拒绝
		--room:moveCardTo(sgs.Sanguosha:getCard(choice_id), player, sgs.Player_Discard, true)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "fateheijian", "");
				room:throwCard(sgs.Sanguosha:getCard(choice_id), reason, nil);
		room:clearAG()
		local log = sgs.LogMessage()
		log.type = "#fateheijianbuff2"
		log.from = player
		log.to:append(damage.to)
		log.arg = tonumber(damage.damage)
		log.arg2 = tonumber(damage.damage - 1)
		room:sendLog(log)
		damage.damage = damage.damage - 1
		if damage.damage == 0 then 
			return true
		end
		data:setValue(damage)
		end
	elseif event == sgs.Death then
		local death = data:toDeath()
		local Kirei = room:findPlayerBySkillName(self:objectName())
		if not Kirei or not Kirei:isAlive() then return end
		if player:objectName() == death.who:objectName()then
--		if player:hasSkill(self:objectName()) then return end
		if room:askForSkillInvoke(Kirei,"fateheijianJianpai",data) then 
            local cards = player:getCards("hej")
			local ids = sgs.IntList()
			for _,card in sgs.qlist(cards) do
				if card:isBlack() then
					ids:append(card:getEffectiveId())
				end
			end
			Kirei:addToPile("fateheijiancards", ids, true)
			while(Kirei:getPile("fateheijiancards"):length() > 5) do
				local card_ids = Kirei:getPile("fateheijiancards") --生成一个sgs.IntList()
				room:fillAG(card_ids, Kirei)
				local choice_id = room:askForAG(Kirei, card_ids, false, self:objectName()) --不可拒绝
				--room:moveCardTo(sgs.Sanguosha:getCard(choice_id), Kirei, sgs.Player_Discard, true)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "fateheijian", "");
				room:throwCard(sgs.Sanguosha:getCard(choice_id), reason, nil);
				room:clearAG()
				end
			end
		end
        return false
    end
end,
}
fateheijianKeep = sgs.CreateMaxCardsSkill{
	name = "#fateheijianKeep",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return target:getPile("fateheijiancards"):length()
		else
			return 0
		end
	end
}

--心音 出牌阶段，你可以使距离1以内的一名角色进行一次判定。若结果不为红桃，你可以对其造成一点伤害或者获得该角色的一张牌。每回合限一次。
fatexinyin_card = sgs.CreateSkillCard
{
	name = "fatexinyin_card",
	once = true,
	will_throw = true,
	filter=function(self,targets,to_select,player)
		return (#targets < 1)
	end,
	on_effect=function(self,effect)
		local from = effect.from
		local to = effect.to
		local room = from:getRoom()
		local judge = sgs.JudgeStruct()
		judge.who = to
		judge.pattern = ".|heart"
		judge.good = true
		judge.reason = self:objectName()
		judge.play_animation = true
		room:judge(judge)
		if not judge:isGood() then
		local choicelist = "xychoice1"
		if not to:isAllNude() then 
		choicelist  = string.format("%s+%s", choicelist, "xychoice2")
		end
			choice = room:askForChoice(from, "fatexinyin_card", choicelist)
			if(choice == "xychoice1") then
				local damage = sgs.DamageStruct()
				damage.from = from
				damage.to = to
				damage.damage = 1
				damage.nature = sgs.DamageStruct_Normal
				room:damage(damage)
			elseif (choice == "xychoice2") then
				if not to:isAllNude() then
					local card_id = room:askForCardChosen(from, to, "hej", "fatexinyin_card")
					room:moveCardTo(sgs.Sanguosha:getCard(card_id), from, sgs.Player_PlaceHand, false)
				end
			end
		end	
	end,
}

fatexinyin = sgs.CreateViewAsSkill{
	name = "fatexinyin",
	n=0,
	view_filter=function()
		return false
	end,
	view_as=function(self, cards)        
		return fatexinyin_card:clone()
	end,
	enabled_at_play=function(self,player) 
		return (not player:hasUsed("#fatexinyin_card"))
	end,
	enabled_at_response=function(self,player,pattern)
		return false
	end,
}

--吞噬 锁定技，你每杀死一名角色，你增加1点体力上限并回复2点体力。
fatetunshi=sgs.CreateTriggerSkill{
	name="fatetunshi",
	events=sgs.Death,
	frequency = sgs.Skill_Compulsory,
	can_trigger=function(self,target)
		return true
	end,
	on_trigger=function(self,event,player,data)	
	local room=player:getRoom()
	local log = sgs.LogMessage()
	local death = data:toDeath()
	local damage=death.damage
	local from=damage.from
	if death.who:objectName() ~= player:objectName() then return false end
	if(damage and damage.from and from:hasSkill(self:objectName())) then 
        local log= sgs.LogMessage()
		log.type = "#TriggerSkill"
		log.from = from
		log.arg = self:objectName()
		room:sendLog(log)
		room:setPlayerProperty(from,"maxhp",sgs.QVariant(from:getMaxHp() + 1))
		local recover=sgs.RecoverStruct()
		recover.recover=2
		recover.who=from
		room:recover(from,recover)	
	end
    return false
end,
}

--Irisviel 护佑 当你成为其他角色打出的非延时锦囊牌的目标时，你可让除你以外的一名角色替你结算。此角色不能是该锦囊牌的使用者。
fatehuyou = sgs.CreateTriggerSkill
{
	name = "fatehuyou",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardEffected},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect=data:toCardEffect()
		local card=effect.card
		if (card:isNDTrick() == false) then return end
		if effect.from:getSeat()==effect.to:getSeat() then return end
		local targets=room:getAlivePlayers()
		targets:removeOne(player)
		targets:removeOne(effect.from)
		room:setTag("fatehuyou", data)
		local pc=room:askForPlayerChosen(player,targets,"fatehuyou", "fatehuyou-invoke", true)
		room:removeTag("fatehuyou")
		if(not pc) then return false end
		effect.to = pc
		room:cardEffect(effect)
		return true
	end,
}

--圣器 在一名角色的判定牌生效前，你可以打出一张红色牌替换之。
fateshengqi = sgs.CreateTriggerSkill{
	name = "fateshengqi" ,
	events = {sgs.AskForRetrial} ,
	on_trigger = function(self, event, player, data)
		local judge = data:toJudge()
		--[[local prompt_list = {
			"@fateshengqi-card" ,
			judge.who:objectName() ,
			self:objectName() ,
			judge.reason ,
			string.format("%d", judge.card:getEffectiveId())
		}]]
		--local prompt = table.concat(prompt_list, ":")
		local room = player:getRoom()
		local prompt = string.format("@fateshengqi-card:%s:%s:%s",player:objectName(),judge.who:objectName(),judge.reason)
		local card = room:askForCard(player, ".|red", prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if card then
			room:retrial(card, player, judge, self:objectName(), true)
		end
		return false
	end ,
	can_trigger = function(self, target)
		if not (target and target:isAlive() and target:hasSkill(self:objectName())) then return false end
		if target:isKongcheng() then
			local has_red = false
			for i = 0, 3, 1 do
				local equip = target:getEquip(i)
				if equip and equip:isRed() then
					has_red = true
					break
				end
			end
			return has_red
		else
			return true
		end
	end
}

--Tokiomi
--魔术 出牌阶段，你可以弃一张手牌令一名角色进行一次判定，根据判定牌花色不同有如下效果：
--红桃：你获得该角色一张牌
--黑桃：若该武将牌正面向上，将其翻面
--方块：弃置该角色全部的装备牌，并将该角色武将牌横置
--梅花：令该角色弃置两张手牌
--每回合限一次。

fatemoshu_card = sgs.CreateSkillCard
{
	name = "fatemoshu_card",
	once = true,
	will_throw = true,
	filter=function(self,targets,to_select,player)
		return (#targets < 1)
	end,
	on_effect=function(self,effect)
		local from = effect.from
		local to = effect.to
		local room = from:getRoom()
		local judge = sgs.JudgeStruct()
		judge.who = to
		judge.pattern = "."
		judge.good = true
		judge.reason = self:objectName()
		judge.play_animation = false
		room:judge(judge)
		if judge.card:getSuit() == sgs.Card_Heart then
			if not to:isNude() then
				local card_id = room:askForCardChosen(from, to, "he", "fatexinyin_card")
				room:moveCardTo(sgs.Sanguosha:getCard(card_id), from, sgs.Player_PlaceHand, false)
			end
		elseif judge.card:getSuit() == sgs.Card_Spade then 
			if to:faceUp() then 
				to:turnOver()
			end
		elseif judge.card:getSuit() == sgs.Card_Diamond then 
			if not to:isChained() then 
				room:setPlayerProperty(to, "chained", sgs.QVariant(true))
			end
			if to:hasEquip() then 
				to:throwAllEquips()
			end
		elseif judge.card:getSuit() == sgs.Card_Club then
			if to:getHandcardNum() < 3 then 
				to:throwAllHandCards()
			else 
				room:askForDiscard(to, self:objectName(), 2, 2, false)
			end
		end
	end,
}

fatemoshu_vs = sgs.CreateViewAsSkill
{
	name = "fatemoshu_vs",
	n = 1,
	
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped() 
	end,
	
	view_as = function(self, cards)
		if #cards == 0 then return end
		if #cards == 1 then
			local tgcard = fatemoshu_card:clone()
			tgcard:addSubcard(cards[1]:getId())
			return tgcard
		end
	end,
	
	enabled_at_play = function(self, player)	
		return not player:hasUsed("#fatemoshu_card") 
	end,
	
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

--结界 当你成为【杀】的目标时，你可以展示牌堆顶的一张牌。若该牌花色是红桃或方块，将终止此【杀】的结算。之后此牌进入弃牌堆。
fatejiejie=sgs.CreateTriggerSkill{
	name="fatejiejie",
	frequency=sgs.Skill_NotFrequent,
	events=sgs.CardEffected,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local effect = data:toCardEffect()
		if not effect.card or not effect.card:isKindOf("Slash") then return end
		if(room:askForSkillInvoke(player, self:objectName(), data) ==false) then return end
	--	local card_id = room:drawCard()
	--	local card = sgs.Sanguosha:getCard(card_id)
	--	room:showCard(player, card_id)
		local ids = room:getNCards(1, false)
		local move = sgs.CardsMoveStruct()
		move.card_ids = ids
		move.to = player
		move.to_place = sgs.Player_PlaceTable
		move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), "")
		room:moveCardsAtomic(move, true)
		local id = ids:first()
		local card = sgs.Sanguosha:getCard(id)
		  local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), "")
                    room:throwCard(card, reason, nil)
		if (card:getSuit() == sgs.Card_Diamond or card:getSuit() == sgs.Card_Heart) then
			local log=sgs.LogMessage() --以下是无效的LOGTYPE
			log.type ="#SkillNullify"
			log.from=player
			log.arg=self:objectName() --技能名
			log.arg2="slash" --卡名
			room:sendLog(log)
			return true
		end
		return false
	end,
}

--Alexander 亚历山大
--军团 出牌阶段，你可以弃一张黑色手牌并指定距离1以内最多两名角色。他们需打出一张【杀】，否则受到你造成的1点无属性伤害。每回合限一次。
fatejuntuan_card = sgs.CreateSkillCard
{
	name = "fatejuntuan_card",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
		return (#targets < 2) and (sgs.Self:distanceTo(to_select) < 2)
	end,
	on_effect = function(self,effect)
		local from = effect.from
		local to = effect.to
		local room = from:getRoom()
		if to:isAlive() then 		
			local slash = room:askForCard(to, "slash", "@fateqzslash:",sgs.QVariant(data))
			if (not slash) then
				local damage = sgs.DamageStruct()
				damage.from = from
				damage.to = to
				damage.damage = 1
				damage.nature = sgs.DamageStruct_Normal
				room:damage(damage)
				return false
			end
		end
	end,
}

fatejuntuan_vs = sgs.CreateViewAsSkill
{
	name = "fatejuntuan_vs",
	n = 1,
	
	view_filter = function(self, selected, to_select)
		return (not to_select:isEquipped()) and to_select:isBlack()
	end,
	
	view_as = function(self, cards)
		if #cards == 0 then return end
		if #cards == 1 then
			local card = fatejuntuan_card:clone()
			card:addSubcard(cards[1]:getId())
			return card
		end
	end,
	
	enabled_at_play = function(self, player)
		return not player:hasUsed("#fatejuntuan_card") 
	end,
	
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

--护卫 锁定技，【南蛮入侵】对你无效，当任意角色打出【南蛮入侵】时，你可以使一名其他角色跳过【南蛮入侵】的结算。
fatehuwei=sgs.CreateTriggerSkill{
name="fatehuwei",
events={sgs.CardEffected,sgs.CardUsed,sgs.CardFinished},
frequency=sgs.Skill_Compulsory,
can_trigger = function(self, target)
    return true
end,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()
	if event == sgs.CardEffected then 
		local effect=data:toCardEffect()
		local to=effect.to
		if not effect.card:isKindOf("SavageAssault") then return end
		if to:getMark("@fthuwei")>0 or to:hasSkill(self:objectName()) then			
			local log=sgs.LogMessage() --以下是无效的LOGTYPE
			log.type ="#SkillNullify"
			log.from=player
			log.arg=self:objectName() --技能名
			log.arg2="savage_assault" --卡名
			room:sendLog(log)
			return true
		end
	elseif event ==  sgs.CardUsed then
		local card = data:toCardUse().card
		local from = data:toCardUse().from
		if not card:isKindOf("SavageAssault") then return end
		local Alexander	= room:findPlayerBySkillName(self:objectName())
		if not Alexander:isAlive() then return end
		if room:askForSkillInvoke(Alexander,self:objectName()) then
			local players = room:getOtherPlayers(Alexander)
			players:removeOne(from)
			local Waver = room:askForPlayerChosen(Alexander, players, "@fatehuwei")
			Waver:addMark("@fthuwei")
		end
		return false
	elseif  event ==  sgs.CardFinished then
   		local use=data:toCardUse()
    	local card =use.card
		if not card:isKindOf("SavageAssault") then return end
		local players=room:getAlivePlayers()
		players:removeOne(player)
		for _, target in sgs.qlist(players) do
        	while target:getMark("@fthuwei")>0 do
           		target:removeMark("@fthuwei")
			end
        end
		return false
	end	
end,
}

--Diarmuid 迪尔姆德•奥狄纳 
--破魔 回合开始阶段，你可以使一名其他角色失去所有技能和防具效果直至回合结束。
fatepomo=sgs.CreateTriggerSkill{
	name="fatepomo",
	frequency=sgs.Skill_NotFrequent,
	events={sgs.EventPhaseStart,sgs.Death,sgs.CardUsed},
	can_trigger = function(self, target) --这么写是为了防止player在自己回合内死亡后技能回不来
    	return true
	end,
	priority=3,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event == sgs.Death then
			if not player:hasSkill(self:objectName()) then return end
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then return end
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasFlag("fatepomotar") then
					room:setPlayerFlag(p,"-fatepomotar")
					for _,skill in ipairs(p:getTag("fatepomo"):toString():split("+")) do
						room:handleAcquireDetachSkills(p,skill)
					end
					p:setTag("fatepomo",sgs.QVariant())
					room:setPlayerMark(p, "Armor_Nullified", 0);
				end
			end
		end
		if event == sgs.EventPhaseStart and player:getPhase()==sgs.Player_Finish then
			if not player:hasSkill(self:objectName()) then return end
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasFlag("fatepomotar") then
					room:setPlayerFlag(p,"-fatepomotar")
					for _,skill in ipairs(p:getTag("fatepomo"):toString():split("+")) do
						room:handleAcquireDetachSkills(p,skill)
					end
					p:setTag("fatepomo",sgs.QVariant())
					room:setPlayerMark(p, "Armor_Nullified", 0);
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase()==sgs.Player_Start then
			if not player:hasSkill(self:objectName()) then return end
			if not room:askForSkillInvoke(player,self:objectName()) then return end
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "@fatepomo")
			room:addPlayerMark(target, "&fatepomo+to+#"..player:objectName().."-Clear")
			local skills={}
			for _,skill in sgs.qlist(target:getVisibleSkillList())do
				if not table.contains(skills,skill:objectName()) then
					table.insert(skills,skill:objectName())
					room:detachSkillFromPlayer(target,skill:objectName())
				end
			end
	--[[		for _,skill in sgs.qlist(target:getVisibleSkillList()) do
				local name=skill:objectName()
			    if(skill:getLocation() == sgs.Skill_Right) then
					if (skill:isLordSkill() and target:hasLordSkill(name)) or target:hasSkill(name) then
						room:detachSkillFromPlayer(target,name)
						table.insert(skills,name)
					end
				end
			end]]
			target:setTag("fatepomo",sgs.QVariant(table.concat(skills,"+")))
			room:addPlayerMark(target, "Armor_Nullified");
			room:setPlayerFlag(target,"fatepomotar")
			return false
		end
	end,
}

--必灭 锁定技，若你使用【杀】对一名角色造成了伤害，该角色将无法回复体力直至你死亡或游戏结束。--删去“在不处于濒死状态时”
fatebimie=sgs.CreateTriggerSkill{
	name="fatebimie",
	frequency=sgs.Skill_Compulsory,
	events={sgs.Damage,sgs.PreHpRecover,sgs.Death},
	can_trigger = function(self, target)
    	return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.Damage then
			local damage=data:toDamage()
			if not damage.card or (not damage.card:isKindOf("Slash")) then return end
			local to = damage.to
			local from=damage.from
			if not from:hasSkill(self:objectName()) then return false end
			if not to:isAlive() then return false end
			if to:getMark("@fatebimie")==0 then
				--to:addMark("@fatebimie") --这样不会显示出来
				to:gainMark("@fatebimie",1)
			end
			return false
		end
		if event==sgs.PreHpRecover then
			local recover=data:toRecover()
			if player:getMark("@fatebimie")>0 then--and player:getHp()>0 then
				local log = sgs.LogMessage()
				log.type = "#fatebimiebuff"
				log.from = player
				room:sendLog(log)
				return true
			end
		end
		if event == sgs.Death then
			local death = data:toDeath()
			if  not death.who:hasSkill(self:objectName()) then return end
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("@fatebimie")>0 then
					p:loseMark("@fatebimie")
				end
			end
		end
	end,
}



Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
--Chulainn Lancer
--突刺 当你使用【杀】指定一名角色为目标后，你可以弃一张手牌使此【杀】伤害+1且强制命中。
fatetuci=sgs.CreateTriggerSkill{
name="fatetuci",
events={sgs.TargetSpecified,sgs.DamageCaused},
on_trigger=function(self,event,player,data)
	local room=player:getRoom()
	if event==sgs.TargetSpecified then
	local use = data:toCardUse()
	if use.card:isKindOf("Slash") and not player:isKongcheng() and use.to:length() == 1  then 
		if not room:askForSkillInvoke(player,self:objectName(), data) then return end
		local card=room:askForCard(player, ".|.|.|hand|.", "@fatetuci", data, sgs.CardDiscarded)
		if card ~= nil then
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				jink_table[index] = 0
				index = index + 1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
			room:setCardFlag(use.card, "fatetuci_dmgenhaced")
			return false
		end
		end
	elseif event==sgs.DamageCaused then --防止寒冰剑诱导出bug
		local damage = data:toDamage()
		if not damage.card or (not damage.card:isKindOf("Slash")) then return end
		if damage.card:hasFlag("fatetuci_dmgenhaced") then
			local log = sgs.LogMessage()
			log.type = "#fatetucibuff"
			log.from = player
			log.to:append(damage.to)
			log.arg = tonumber(damage.damage)
			log.arg2 = tonumber(damage.damage + 1)
			room:sendLog(log)
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
	end
end,	
}

--死棘 出牌阶段，若你已损失2点或2点以上的体力，你可以弃掉一张武器牌使距离2以内的一名角色进行一次判定。
--若结果为【雷杀】或【闪电】，该角色直接死亡；否则视为你对其打出了一张无色的【杀】。此【杀】不计入出牌阶段限制。每回合限一次。
fatesiji_card = sgs.CreateSkillCard
{
	name = "fatesiji_card",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
		return (#targets < 1) and (sgs.Self:distanceTo(to_select) < 3)
		
	end,
	on_effect = function(self,effect)
		local from = effect.from
		local to = effect.to
		local room = from:getRoom()
		local judge = sgs.JudgeStruct()
		judge.who = to
		judge.pattern = "ThunderSlash,Lightning"
		judge.good = false
		judge.negative = true
		judge.reason = self:objectName()
		judge.play_animation = true
		room:judge(judge)
		if not judge:isGood() then
			room:killPlayer(to, from)
		end
		if to:isAlive() and from:canSlash(to,nil,false ) then 		
			local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit, 0)
		    slash:setSkillName("fatesiji_card")
			slash:deleteLater()
			local use = sgs.CardUseStruct()
			use.from = from
			use.to:append(to)
			use.card = slash
			room:useCard(use, false)
		end
	end,
}

fatesiji_vs = sgs.CreateViewAsSkill
{
	name = "fatesiji_vs",
	n = 1,
	
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("Weapon")
	end,
	
	view_as = function(self, cards)
		if #cards == 0 then return end
		if #cards == 1 then
			local tgcard = fatesiji_card:clone()
			tgcard:addSubcard(cards[1]:getId())
			return tgcard
		end
	end,
	
	enabled_at_play=function(self,player)
		return not player:hasUsed("#fatesiji_card") and player:getLostHp()>1
	end,
	
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

--怯懦 你可以将任意基本牌当【闪】使用或打出。
fateqienuo = sgs.CreateViewAsSkill
{
	name = "fateqienuo",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("BasicCard")
	end,
	
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local qn_card = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
			qn_card:addSubcard(card:getId())
			qn_card:setSkillName(self:objectName())
			return qn_card
		end
	end,
	
	enabled_at_play = function() 
		return false
	end,
	
	enabled_at_response = function(self, player, pattern)
		return pattern == "jink"
	end,
}

--强推 摸牌阶段，你可以少摸一张牌。若如此做，你可以获得一名相邻角色的一张手牌。若该角色为女性，你回复一点体力。
fateqiangtui = sgs.CreateTriggerSkill
{
	name = "fateqiangtui",
	frequency = sgs.Skill_NotFrequent,
	events =sgs.DrawNCards,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		if(room:askForSkillInvoke(player,"fateqiangtui") ==false) then return end
		local targets = room:getOtherPlayers(player)
		for _, target in sgs.qlist(targets) do --因为在此删掉了链表中一个元素之后，其下个元素将不参与for循环，对10人局必须进行3遍循环才行，我去！！！当然最好能直接在空表里插入，但不知道怎么写。
	      	if not (target:getSeat()==(player:getNextAlive()):getSeat() or player:getSeat()==(target:getNextAlive()):getSeat()) or target:isKongcheng() then
         		targets:removeOne(target)
			end
        end
		for _, target in sgs.qlist(targets) do
	      	if not (target:getSeat()==(player:getNextAlive()):getSeat() or player:getSeat()==(target:getNextAlive()):getSeat()) or target:isKongcheng() then
         		targets:removeOne(target)
			end
        end
		for _, target in sgs.qlist(targets) do
	      	if not (target:getSeat()==(player:getNextAlive()):getSeat() or player:getSeat()==(target:getNextAlive()):getSeat()) or target:isKongcheng() then
         		targets:removeOne(target)
			end
        end
		local target = room:askForPlayerChosen(player, targets, self:objectName())
		if not target:isKongcheng() then
			local card_id = room:askForCardChosen(player, target, "h", "@fateqiangtui")
			room:moveCardTo(sgs.Sanguosha:getCard(card_id), player, sgs.Player_PlaceHand, false)
			draw.num = draw.num - 1
			data:setValue(draw)
			if target:isFemale() then
				local recov = sgs.RecoverStruct()
				recov.who = target
				room:recover(player, recov)
			end
		end
		return false
	end
}

--Kariya
--虫术 出牌阶段，你可以弃一张手牌并选择一名其他角色。若该角色手牌数不小于2，其需弃置两张手牌；若其手牌数不足2，将受到你造成的1点无属性伤害。每回合限一次。若以此法杀死了一名角色，你可以回复1点体力并摸两张牌。
fatechongshu_card = sgs.CreateSkillCard
{
	name = "fatechongshu_card",
	once = true,
	will_throw = true,
	filter=function(self,targets,to_select,player)
		return (#targets < 1) and to_select:getSeat()~=sgs.Self:getSeat()
	end,
	on_effect=function(self,effect)
		local from = effect.from
		local to = effect.to
		local room = from:getRoom()
		if to:getHandcardNum() > 1 then 
			room:askForDiscard(to, self:objectName(), 2, 2, false)
		else 
			room:damage(sgs.DamageStruct("fatechongshu", from,to))
		end
	end,
}

fatechongshuVS = sgs.CreateViewAsSkill
{
	name = "fatechongshu",
	n = 1,
	
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped() 
	end,
	
	view_as = function(self, cards)
		if #cards == 0 then return end
		if #cards == 1 then
			local tgcard = fatechongshu_card:clone()
			tgcard:addSubcard(cards[1]:getId())
			return tgcard
		end
	end,
	
	enabled_at_play = function(self, player)
		return not player:hasUsed("#fatechongshu_card") 
	end,
	
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}


fatechongshu=sgs.CreateTriggerSkill{
	name="fatechongshu",
	view_as_skill=fatechongshuVS,
	events={sgs.Death},
	can_trigger=function(self,target)
		return true
	end,
	on_trigger=function(self,event,player,data)	
	local room=player:getRoom()
	if event == sgs.Death then
		local death = data:toDeath()
		local damage = death.damage
		if damage and damage.reason == "fatechongshu" then
		local Kariya = room:findPlayerBySkillName(self:objectName())
		if not Kariya:isAlive() then return end
		if Kariya:objectName() == player:objectName() then
		if room:askForSkillInvoke(Kariya,self:objectName(),data) then 
			Kariya:drawCards(2)
        	local recover=sgs.RecoverStruct()
			recover.recover=1
			recover.who=player
			room:recover(Kariya,recover)
			end
			end
		end
        return false
	end
end,
}

--救赎 限定技，回合开始阶段，你可以选择一名其他角色。在你死亡前，该角色不会受到除雷属性伤害之外的任何伤害。
fatejiushu = sgs.CreateTriggerSkill{
	name = "fatejiushu",
	frequency = sgs.Skill_Limited,
	events = {sgs.Predamage,sgs.DamageInflicted,sgs.EventPhaseStart,sgs.Death},
	limit_mark ="@fatejiushu_mark",
	can_trigger=function(self,target)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.EventPhaseStart then
			if not player:hasSkill(self:objectName()) then return end
			if (player:getPhase() ~= sgs.Player_Start) then return end
			if player:getMark("@fatejiushu_mark")==0 then return end
			if not room:askForSkillInvoke(player,self:objectName()) then return end
			local Sakura = room:askForPlayerChosen(player, room:getOtherPlayers(player), "@fatejiushu")
			Sakura:gainMark("@fatesakura_mark",1)
			player:loseMark("@fatejiushu_mark")
		elseif (event == sgs.Predamage or event == sgs.DamageInflicted) then
			local damage = data:toDamage()
			if (damage.to:getMark("@fatesakura_mark") == 0) then return end
			if not (damage.nature == sgs.DamageStruct_Thunder) then
				local log= sgs.LogMessage()
				log.type = "#TriggerSkill"
				log.from = damage.to
				log.arg = self:objectName()
				room:sendLog(log)
				return true
			end
		elseif event == sgs.Death then
			if not player:hasSkill(self:objectName()) then return end
            local death = data:toDeath()
            if death.who and death.who:hasSkill(self:objectName()) then 
                for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:getMark("@fatesakura_mark")>0 then
                        p:loseMark("@fatesakura_mark")
                    end
                end
            end
		end
	end,
}


fate_Kiritsugu:addSkill(fatejiezhi)
fate_Kiritsugu:addSkill(fateyezhan)
fate_Kiritsugu:addSkill(fateqiangyun)
fate_Saber:addSkill(fatewangzhe)
fate_Saber:addSkill(fateqiuzhan)
fate_Saber:addSkill(fateshenjian)
fate_Shirou:addSkill(fatetouying)
fate_Shirou:addSkill(fatetouyingTargetMod)
extension:insertRelatedSkills("fatetouying","#fatetouying")
fate_Shirou:addSkill(fatesizhan)
fate_Carene:addSkill(fatexianshen)
fate_Carene:addSkill(fateshenghai)
fate_Carene:addSkill(fateshenghaiGive)
extension:insertRelatedSkills("fateshenghai","#fateshenghaiGive")
fate_Medusa:addSkill(fateguangbo)
fate_Medusa:addSkill(fatetuji)
fate_Medusa:addSkill("mashu")
fate_Rin:addSkill(fateqingxing)
fate_Rin:addSkill(fatejizhi)
fate_Rin:addSkill(fatebumo)
fate_Heracles:addSkill(fateshilian)
fate_Heracles:addSkill(fatejuli)
fate_Medea:addSkill(fateyaoshu)
fate_Medea:addSkill(fateshenyan)
fate_Medea:addSkill(fatefapao)
fate_Sakura:addSkill(fatechuyi_vs)
fate_Sakura:addSkill(fateheihua)
fate_Gilgamesh:addSkill(fateluanshe_vs)
fate_Gilgamesh:addSkill(fatechuanxin_trs)
fate_Emiya_Archer:addSkill(fatetiangong_vs)
fate_Emiya_Archer:addSkill(fatejianzhong)
fate_Iriya:addSkill(fatemoli)
fate_Iriya:addSkill(fateloli_vs)
fate_Gilles:addSkill(fateduoluo)
fate_Gilles:addSkill(fatenixi)
fate_Kojirou:addSkill(fatezonghe)
fate_Kojirou:addSkill(fateyanfan_vs)
fate_Kojirou:addSkill(fatexunjie)
fate_Lancelot:addSkill(fatefanshi)
fate_Lancelot:addSkill(fatefanji)
fate_Kirei:addSkill(fateheijian)
fate_Kirei:addSkill(fateheijianKeep)
extension:insertRelatedSkills("fateheijian","#fateheijianKeep")
fate_Hassan_Sabbah:addSkill(fatexinyin)
fate_Hassan_Sabbah:addSkill(fatetunshi)
fate_Irisviel:addSkill(fateshengqi)
fate_Irisviel:addSkill(fatehuyou)
fate_Tokiomi:addSkill(fatemoshu_vs)
fate_Tokiomi:addSkill(fatejiejie)
fate_Alexander:addSkill(fatejuntuan_vs)
fate_Alexander:addSkill(fatehuwei)
fate_Alexander:addSkill("mashu")
fate_Diarmuid:addSkill(fatepomo)
fate_Diarmuid:addSkill(fatebimie)
fate_Chulainn:addSkill(fatetuci)
fate_Chulainn:addSkill(fatesiji_vs)
fate_Shinji:addSkill(fateqienuo)
fate_Shinji:addSkill(fateqiangtui)
fate_Kariya:addSkill(fatechongshu)
fate_Kariya:addSkill(fatejiushu)

sgs.LoadTranslationTable{
	["fate_Kiritsugu"]="卫宫切嗣",
	["fatejiezhi"] = "竭智",	
	["fatejiezhiPhase"] = "竭智",
	[":fatejiezhi"] = "每当一名角色进行判定时，你可以观看牌顶的X张牌，并将这些牌以任意顺序置于牌堆顶。X为场上存活角色数与你的体力上限中的较大者且最多为5。",
	["fateyezhan"] = "夜战",
	[":fateyezhan"] = "回合开始阶段，你可以令一名其他角色进行一次判定。若判定结果为黑桃，你对其造成1点无属性伤害。",
	["fateyezhan-invoke"] = "你可以发动“夜战”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["fateqiangyun"] = "强运",
	[":fateqiangyun"] = "<font color=\"blue\"><b>锁定技，</b></font>你的手牌上限始终+1。",
	
	
	["fate_Saber"]="Saber",
	["fatewangzhe"] = "王者",	
	[":fatewangzhe"] = "每当你成为【杀】或非延时锦囊的目标（或目标之一）时，你可以观看牌堆顶的2张牌，并可以获得其中一张。",
    ["@fatewangzhe"] = "你获得其中一张。",
    ["~fatewangzhe"] = "选择一张牌→点击确定",
	["fateqiuzhan_card"] = "求战",
	["fateqiuzhan"] = "求战",
	["fateqiuzhan_"] = "求战",
	[":fateqiuzhan"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令一名其他角色对你使用一张【杀】，该【杀】不受距离限制。否则视为你对该角色使用一张【决斗】。",	
	["@fateqzslash"] = "请打出一张【杀】",
	["fateshenjian_card"] = "神剑",	
	["fateshenjian"] = "神剑",
	["@shenjian_mark"] = "神剑",
	[":fateshenjian"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，若你已受伤，你可以弃置两张手牌并选择攻击范围内的最多两名其他角色，对其分别造成X点伤害。（X为你已损失的体力值且最多为2）。",	
	["fate_Shirou"]="卫宫士郎",
	["@touyingused"] = "投影",
	["fatetouying"] = "投影",	
	[":fatetouying"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张手牌当你本阶段上一张使用的基本牌或非延时锦囊使用，以此法使用的【杀】不受出牌阶段限制。",
	["fatesizhan"] = "死战",
	[":fatesizhan"] = "<font color=\"purple\"><b>觉醒技，</b></font>当你进入濒死状态时，你回复至1点体力，然后增加1点体力上限，摸三张牌，并获得技能【不屈】。",
	
	["fate_Carene"]="卡莲",
	["fatexianshen"] = "献身",
	[":fatexianshen"] = "每当你受到一次伤害，你可以观看牌堆顶 X+3 张牌，并将这些牌以任意顺序置于牌堆顶或牌堆底。（X为你已损失体力值）",
	["fateshenghai"]="圣骸",
	[":fateshenghai"]="若你在其他角色的回合内进入濒死状态，濒死结算后若你存活，你可以在当前回合内防止所有伤害。并且在该角色回合结束后，你可以获得一个额外回合。",
	["@fateshenghai"]="圣骸",
	["#fateshenghaiwudi"] = "%from 使用了技能【<font color='yellow'><b>圣骸</b></font>】 ，此伤害无效",
	
	["fate_Medusa"]="梅杜莎",
	["fateguangbo"] = "广博",
	[":fateguangbo"] = "摸牌阶段，你可以少摸一张牌。若如此做，你可以选择获得技能“完杀”“强袭”“天义”“奇袭”“武圣”之中的一个直至回合结束。",
	["fateguangbo1"] = "完杀",
	["fateguangbo2"] = "强袭",
	["fateguangbo3"] = "天义",
	["fateguangbo4"] = "奇袭",
	["fateguangbo5"] = "武圣",
	["fatetuji"]="突击",
	[":fatetuji"]="<font color=\"red\"><b>限定技，</b></font>在回合结束阶段，你可以获得一个额外的回合。",
	["@fatetuji"]="突击",
	
	["fate_Rin"]="远坂凛",
	["fateqingxing"]="清醒",
	[":fateqingxing"]="你可以弃置一张红桃牌或【闪】令一名角色跳过判定阶段并回复1点体力。若这名角色是你，你获得你判定区中的所有牌。",
	["@fateqingxing1"]="你可以弃置一张红桃牌或【闪】发动“清醒”。",
	["fatejizhi"]="机智",
	[":fatejizhi"]="<font color=\"blue\"><b>锁定技，</b></font>当你的装备区内无防具时，你不能被选择为【过河拆桥】,【顺手牵羊】及【借刀杀人】的目标。",
	["fatebumo_"] = "补魔",	
	["fatebumo"] = "补魔",
	["@bumo_mark"] = "补魔",
	[":fatebumo"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段，若你已受伤或你的手牌数小于你的体力上限，你可以选择一名其他已受伤或手牌数小于其体力上限的异性角色，你和该角色各回复1点体力，并将手牌数补至体力上限（最多为5）。",	
	
	["fate_Heracles"]="海格力斯",
	["fateshilian"]="试炼",
	[":fateshilian"]="当你处于濒死状态时，若你的体力上限大于3，你可以减1点体力上限并回复3点体力。",
	["fatejuli"] = "巨力",
	[":fatejuli"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你指定【杀】的目标后，目标角色需连续使用一张【闪】和一张【杀】抵消此【杀】。",
	["@fatejuli-jink-1"] = "%src 拥有【巨力】技能，你必须出一张【杀】和一张【闪】,才能抵消这张【杀】。请先出一张【杀】", 
	["@fatejuli-jink-2"] = "%src 拥有【巨力】技能，你还需出一张【闪】", 
	
	["fate_Medea"]="美狄亚",
	["fateyaoshu"]="妖术",
	["fateyaoshu_"] = "妖术",
	[":fateyaoshu"]="出牌阶段，你可以弃置两张相同花色的手牌，根据花色不同有如下效果：红桃：使一名角色回复一点体力。黑桃：使一名角色翻面。方块：使一名角色摸3张牌。梅花：对一名角色造成一点雷属性伤害。",	
	["fateshenyan"] = "神言",
	[":fateshenyan"]= "回合开始阶段，你可以摸一张牌。",
	["fatefapao"] = "法袍",
	[":fatefapao"] = "<font color=\"blue\"><b>锁定技，</b></font>对你造成的属性伤害无效。",
	
	["fate_Sakura"]="间桐樱",
	["fatechuyi_vs"]="厨艺",
	["fatechuyi_"] = "厨艺",
	[":fatechuyi_vs"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置两张手牌，令一名其他角色摸两张牌并回复一点体力。",	
	["fateheihua"] = "黑化",
	[":fateheihua"] = "<font color=\"purple\"><b>觉醒技，</b></font>当你处于濒死状态时，弃置你的所有手牌，将武将牌恢复至初始状态，摸三张牌并回复至3点体力，然后你失去技能【厨艺】，并获得技能【妖术】与【吸能】。",
	["fatexineng"] = "吸能",
	["@fatexineng"] = "吸能",
	[":fatexineng"] = "<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，你获得下家的一张牌，并可以令其失去一点体力。",
	["fatexinengloseHP"] = "吸能",
	["xnchoice"]="流失体力？",
	["xnchoice1"] = "是",
	["xnchoice2"] = "否",
	
	["fate_Gilgamesh"]="吉尔伽美什",
	["fateluanshe_vs"]="乱射",
	[":fateluanshe_vs"]="<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张红桃手牌当【万箭齐发】使用。",
	["fatechuanxin_trs"]="穿心",
	["fatechuanxin_card"]="穿心",
	["fatechuanxin_"]="穿心",
	["@fatechuanxin1"]="是否发动【穿心】？如发动，请弃掉一张手牌",
	["@fatechuanxin2"]="请选择一名角色",
	[":fatechuanxin_trs"]="当你的【万箭齐发】结算完毕后，你可以弃一张手牌并选择一名其他角色，视为你对其使用X张【杀】。X为场上存活角色数除以5（向上取整）。以此法使用的【杀】不计入出牌阶段限制。",
	["#fateluanshe"]="去死吧，杂种！",
	
	["fate_Emiya_Archer"]="英灵卫宫",
	["fatetiangong_card"] = "天弓",	
	["fatetiangong_vs"] = "天弓",
	["fatetiangong_trs"] = "天弓",
	["fatetiangong_"] = "天弓",
	[":fatetiangong_vs"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张手牌然后选择一名角色或两名距离1以内的角色，视为对其使用一张不计入出牌阶段限制的【火杀】。",	
	["fatejianzhong"] = "剑冢",
	[":fatejianzhong"] = "<font color=\"blue\"><b>锁定技，</b></font>【万箭齐发】对你无效；当其他角色使用【万箭齐发】，对你的效果改为你可以弃置一张牌并选择一名角色，视为对其使用一张【杀】。",
	["@fatejianzhong1"]="请弃掉一张牌",
	["@fatejianzhong2"]="请选择一名角色",
	
	["fate_Iriya"]="依莉雅",
	["fatemoli"] = "魔力",
	[":fatemoli"] = "每当你使用或打出一张基本牌或【五谷丰登】及【无中生有】之外的非延时锦囊牌，在结算后你可以进行一次判定。若结果为红色，你可以获得之。",
	["#fatemoli"]="技能<font color='yellow'><b>【魔力】</b></font> 判定成功",
	["fateloli_vs"] = "萝莉",
	["fateloli_"] = "萝莉",
	[":fateloli_vs"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以观看一名角色的手牌，并可以展示其中的一张然后将之置于牌堆顶。",
	["fateloli_card"] = "萝莉",
	["fate_Gilles"]="吉尔·德·莱斯",
	["fateduoluo"] = "堕落",
	[":fateduoluo"] = "<font color=\"blue\"><b>锁定技，</b></font>与你距离1以内的角色回合开始阶段须弃置一张手牌，否则该角色摸牌阶段少摸一张牌。",
	["@fateduoluo"] = "请弃掉一张手牌，否则你在摸牌阶段将少摸一张牌",
	["fatenixi"] = "逆袭",
	[":fatenixi"] = "摸牌阶段，若你没有手牌，你可以多摸3张牌并回复一点体力。",
	
	["fate_Kojirou"] = "佐佐木小次郎",
    ["fatezonghe"] = "宗和",
	[":fatezonghe"] = "结束阶段开始时，你可以将手牌数补充至体力上限+2。",
	["fateyanfan_vs"] = "燕返",
	[":fateyanfan_vs"] = "你可以将梅花牌当【闪】使用或打出；将方块牌当【杀】使用或打出。",
 	["fatexunjie"] = "迅捷",
	[":fatexunjie"] = "<font color=\"blue\"><b>锁定技，</b></font>回合结束时，你获得一个额外的出牌阶段。",
	
	["fate_Lancelot"] = "兰斯洛特",
    ["fatefanshi"] = "反噬",
	[":fatefanshi"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以对攻击范围内的一名角色展示你的手牌。若如此做，该角色失去1点体力。",
	["fatefanshi_card"] = "反噬",
	["fatefanshi_"] = "反噬",
	["fatefanji"] = "反击",
	[":fatefanji"] = "每当你使用或打出一张【闪】，你可以对使用者使用一张【杀】。此【杀】无视防具且不计入出牌阶段限制。",
	["fatefanji-slash"] = "你可以发动“反击”，对 %src 使用一张【杀】",
	["@myslash"] = "请打出一张【杀】",
	
	["fate_Kirei"] = "言峰绮礼",
	["fateheijian"] = "黑键",
	["fateheijianDamage"] = "黑键",
	["fateheijianDefense"] = "黑键",
	["fateheijianJianpai"] = "黑键",
	["fateheijian_card"] = "黑键",
	["fateheijian_"] = "黑键",
	["fateheijiancards"] = "键",
	[":fateheijian"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张黑色手牌置于你的武将牌上，称为“键”。其他角色死亡时，你可以将该角色弃置的黑色牌置于你的武将牌上，称为“键”。你手牌上限+X（X为“键”的数量） 。每当你受到伤害时，你可以弃置一张“键”：若如此做，此伤害-1；每当你造成伤害时，你可以弃置一张“键”：若如此做，此伤害+1。你最多只能同时拥有五张“键”。",
	["#fateheijianbuff1"] = "%from 弃掉了一张<font color='yellow'><b>“键”</b></font>，此伤害+1",
	["#fateheijianbuff2"] = "%from 弃掉了一张<font color='yellow'><b>“键”</b></font>，此伤害-1",
	
	["fate_Hassan_Sabbah"] = "哈桑•萨巴赫",
	["fatexinyin"] = "心音",
	[":fatexinyin"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令距离1以内的一名角色进行一次判定。若结果不为红桃，你可以对其造成一点伤害或者获得该角色的一张牌。",
	["fatexinyin_card"] = "心音",
	["fatexinyin_"] = "心音",
	["xychoice1"] = "造成1点伤害",
	["xychoice2"] = "获取1张牌",
	["fatetunshi"] = "吞噬",
	[":fatetunshi"] = "<font color=\"blue\"><b>锁定技，</b></font>你每杀死一名角色，你增加1点体力上限并回复2点体力。",
	
	["fate_Irisviel"] = "爱丽丝菲尔",
	["fatehuyou"] = "护佑",
	["fatehuyougood"] = "护佑",
	["fatehuyoubad"] = "护佑",
	[":fatehuyou"] = "当你成为其他角色使用的非延时锦囊牌的目标时，你可以令一名其他角色代替你成为此锦囊牌的目标。此角色不能是该锦囊牌的使用者。",
	["fatehuyou-invoke"] = "你可以发动“护佑”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["fateshengqi_card"] = "圣器",
	["fateshengqi_"] = "圣器",
	["fateshengqi_vs"] = "圣器",
	["@fateshengqi-card"] ="<font color = 'gold'><b>%src</b></font>可以发动<font color = 'gold'><b>圣器</b></font>打出一张红色牌修改<font color = 'gold'><b>%dest</b></font>的<font color = 'gold'><b>%arg</b></font>判定。",
	["fateshengqi"] = "圣器",
	[":fateshengqi"] = "每当一名角色的判定牌生效前，你可以打出一张红色牌替换之。",
	["~fateshengqi"] = "请打出一张红色牌替换判定牌",
	
	["fate_Tokiomi"] = "远坂时臣",
	["fatemoshu_vs"]="魔术",
	["fatemoshu_card"] = "魔术",
	["fatemoshu_"] = "魔术",
	[":fatemoshu_vs"]="<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张手牌令一名角色进行一次判定，根据判定牌花色不同有以下效果：红桃：你获得该角色一张牌；黑桃：若该角色武将牌正面向上，将其翻面；方块：弃置该角色全部的装备牌，并将该角色武将牌横置；梅花：令该角色弃置两张手牌。",	
	["fatejiejie"] = "结界",
	[":fatejiejie"] = "当你成为【杀】的目标时，你可以亮出牌堆顶的一张牌。若该牌为红色，此【杀】对你无效。",
	
	["fate_Alexander"] = "征服王",
	["fatejuntuan_vs"]="军团",
	["fatejuntuan_card"] = "军团",
	["fatejuntuan_"] = "军团",
	[":fatejuntuan_vs"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张黑色手牌并指定距离1以内最多两名角色。其需打出一张【杀】，否则受到你造成1点伤害。",
	["fatehuwei"]="护卫",
	[":fatehuwei"] = "<font color=\"blue\"><b>锁定技，</b></font>【南蛮入侵】对你无效。当一名角色使用【南蛮入侵】时，你可以令【南蛮入侵】对一名其他角色无效。",
	
	["fate_Diarmuid"] = "迪尔姆德",
	["fatepomo"]="破魔",
	[":fatepomo"] = "回合开始阶段，你可以令一名其他角色失去所有技能和防具效果直至回合结束。",
	["fatebimie"]="必灭",
	[":fatebimie"] = "<font color=\"blue\"><b>锁定技，</b></font>每当你使用【杀】造成伤害后，受伤角色将无法回复体力直至你死亡或游戏结束。",
	["@fatebimie"] = "必灭",
	["#fatebimiebuff"] = "%from 受到【<font color='yellow'><b>必灭</b></font>】的影响 ，无法回复体力！",
	
	["fate_Chulainn"] = "库丘林",
	["fatetuci"]="突刺",
	[":fatetuci"] = "当你使用【杀】指定一名角色为目标后，你可以弃置一张手牌令此【杀】不能被响应且造成的伤害+1。",	
	["#fatetucibuff"] = "%from 的 <font color='yellow'><b>杀</b></font> 受到【<font color='yellow'><b>突刺</b></font>】的影响，伤害 +1。",
	["@fatetuci"]="请弃掉一张手牌",
	["fatesiji_vs"]="死棘",
	["fatesiji_"] = "死棘",
	["fatesiji_card"] = "死棘",
	[":fatesiji_vs"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>若你已损失2点或以上的体力值，你可以弃置一张武器牌令距离2以内的一名角色进行一次判定。若结果为【雷杀】或【闪电】，该角色直接死亡；否则视为你对其使用一张【杀】。此【杀】不计入出牌阶段限制。",
	
	["fate_Shinji"] = "间桐慎二",
	["fateqienuo"]="怯懦",
	[":fateqienuo"] = "你可以将基本牌当【闪】使用或打出。",	
	["fateqiangtui"]="强推",
	["@fateqiangtui"]="请选择一名角色",
	[":fateqiangtui"] = "摸牌阶段，你可以少摸一张牌。若如此做，你可以获得距离1以内一名其他角色的一张手牌。若该角色为女性，你回复一点体力。",
	
	["fate_Kariya"] = "间桐雁夜",
	["fatechongshu"] = "虫术",
	["fatechongshu_"] = "虫术",
	[":fatechongshu"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张手牌并选择一名其他角色。若该角色手牌数不小于2，其需弃置两张手牌；若其手牌数不足2，将受到你造成的1点伤害。若以此法杀死了一名角色，你可以回复1点体力并摸两张牌。",
	["fatejiushu"] = "救赎",
	[":fatejiushu"] = "<font color=\"red\"><b>限定技，</b></font>回合开始阶段，你可以选择一名其他角色。在你死亡前，该角色不会受到除雷属性伤害之外的任何伤害。",
	["@fatejiushu_mark"] = "救赎",
	["@fatesakura_mark"] = "救赎",
	["@fatejiushu"] = "请选择一名角色",
	
--设计者(不写默认为官方)
	["designer:fate_Kiritsugu"] = "四阶张量",
	["designer:fate_Gilles"] = "四阶张量",
	["designer:fate_Shirou"] = "四阶张量",
	["designer:fate_Saber"] = "四阶张量",
	["designer:fate_Carene"] = "四阶张量",
	["designer:fate_Medusa"] = "四阶张量",
	["designer:fate_Rin"] = "四阶张量",
	["designer:fate_Heracles"] = "四阶张量",
	["designer:fate_Medea"] = "四阶张量",
	["designer:fate_Sakura"] = "四阶张量",
	["designer:fate_Gilgamesh"] = "四阶张量",
	["designer:fate_Emiya_Archer"] = "四阶张量",
	["designer:fate_Iriya"] = "四阶张量",
	["designer:fate_Kojirou"] = "四阶张量",
	["designer:fate_Lancelot"] = "四阶张量",
	["designer:fate_Kirei"] = "四阶张量",
	["designer:fate_Hassan_Sabbah"] = "四阶张量",
	["designer:fate_Irisviel"] = "四阶张量",
	["designer:fate_Irisviel"] = "四阶张量",
	["designer:fate_Tokiomi"] = "四阶张量",
	["designer:fate_Alexander"] = "四阶张量",
	["designer:fate_Diarmuid"] = "四阶张量",
	["designer:fate_Chulainn"] = "四阶张量",
	["designer:fate_Shinji"] = "四阶张量",
	["designer:fate_Kariya"] = "四阶张量",
	
--配音(不写默认为官方)
	["cv:fate_Kiritsugu"] = "暂无",
	["cv:fate_Gilles"] = "暂无",
	["cv:fate_Shirou"] = "暂无",
	["cv:fate_Saber"] = "暂无",
	["cv:fate_Carene"] = "暂无",
	["cv:fate_Medusa"] = "暂无",
	["cv:fate_Rin"] = "暂无",
	["cv:fate_Heracles"] = "暂无",
	["cv:fate_Medea"] = "暂无",
	["cv:fate_Sakura"] = "暂无",
	["cv:fate_Gilgamesh"] = "暂无",
	["cv:fate_Emiya_Archer"] = "暂无",
	["cv:fate_Iriya"] = "暂无",
	["cv:fate_Kojirou"] = "暂无",
	["cv:fate_Lancelot"] = "暂无",
	["cv:fate_Kirei"] = "暂无",
	["cv:fate_Hassan_Sabbah"] = "暂无",
	["cv:fate_Irisviel"] = "暂无",
	["cv:fate_Irisviel"] = "暂无",
	["cv:fate_Tokiomi"] = "暂无",
	["cv:fate_Alexander"] = "暂无",
	["cv:fate_Diarmuid"] = "暂无",
	["cv:fate_Chulainn"] = "暂无",
	["cv:fate_Shinji"] = "暂无",
	["cv:fate_Kariya"] = "暂无",

	}