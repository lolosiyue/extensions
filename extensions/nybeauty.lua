extension = sgs.Package("nybeauty", sgs.Package_GeneralPack)
local packages = {}
table.insert(packages, extension)

local function getTypeString(card)
    local cardtype = nil
    local types = {"BasicCard","TrickCard","EquipCard"}
    for _,p in ipairs(types) do
        if card:isKindOf(p) then
            cardtype = p
            break
        end
    end
    return cardtype
end

local function CreateDamageLog(damage, changenum, reason, up)
    if up == nil then up = true end
    local log = sgs.LogMessage()
    if damage.from then
        log.type = "$nyarzdamagechange"
        log.from = damage.from
        log.arg5 = damage.to:getGeneralName()
    else
        log.type = "$nyarzdamagechangenofrom"
        log.from = damage.to
    end
    log.arg = reason
    log.arg2 = damage.damage
    if up then
        log.arg3 = "nyarzdamageup"
        log.arg4 = damage.damage + changenum
    else
        log.arg3 = "nyarzdamagedown"
        log.arg4 = damage.damage - changenum
    end
    return log
end

sgs.LoadTranslationTable 
{
    ["$nyarzdamagechange"] = "%from 对 %arg5 造成的伤害因 %arg 的效果由 %arg2 点 %arg3 到了 %arg4 点。",
    ["$nyarzdamagechangenofrom"] = "%from 受到的伤害因 %arg 的效果由 %arg2 点 %arg3 到了 %arg4 点。",
    ["nyarzdamageup"] = "增加",
    ["nyarzdamagedown"] = "减少",
}

nybeauty_winmusic = sgs.CreateTriggerSkill{
    name = "nybeauty_winmusic",
    events = {sgs.GameOver},
    frequency = sgs.Skill_NotFrequent,
    global = true,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local winner = data:toString():split("+")
        local nybeauty_heros = {"nyzhugeguo","nyshunhanhua"}
        for audio,target in sgs.qlist(room:getAlivePlayers()) do
            if (table.contains(winner, target:objectName()) or table.contains(winner, target:getRole())) 
            and table.contains(nybeauty_heros, target:getGeneralName()) then
                audio = "audio/system/"..target:getGeneralName().."-win.ogg"
                sgs.Sanguosha:playAudioEffect(audio)
                room:getThread():delay(500)
            end
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

nycaojinyu = sgs.General(extension, "nycaojinyu", "wei", 3, false, false, false)

nyyuqi = sgs.CreateViewAsSkill
{
    name = "nyyuqi",
    n = 1,
    expand_pile = "#nyyuqi",
    response_pattern = "@@nyyuqi",
    view_filter = function(self, selected, to_select)
        if sgs.Self:hasFlag("nyyuqiview") then
            if not to_select:isAvailable(sgs.Self) then return false end
            return #selected < 1 and sgs.Self:getPile("#nyyuqi"):contains(to_select:getId())
        end
        return false
    end,
    view_as = function(self, cards)
        if sgs.Self:hasFlag("nyyuqiview") then
            if #cards == 0 then return nil end
            return sgs.Sanguosha:getCard(cards[1]:getId())
        end
        return nyyuqiCard:clone()
    end,
    enabled_at_play = function(self, player)
        if player:getMark("nyyuqicant-PlayClear") > 0 then return false end
        return player:getMark("nyyuqi-PlayClear") < player:getMaxHp()
    end,
}

nyyuqiCard = sgs.CreateSkillCard
{
    name = "nyyuqi",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        local n = source:getMaxHp() - source:getMark("nyyuqi-PlayClear")
        local view_cards = room:getNCards(n)
        room:returnToTopDrawPile(view_cards)

        local log = sgs.LogMessage()
        log.type = "$nyyuqiview"
        log.from = source
        log.arg = n
        log.arg2 = self:objectName()
        room:sendLog(log)

        local se = sgs.LogMessage()
        local names = {}
        for _,id in sgs.qlist(view_cards) do
            table.insert(names,id)
        end
        se.type = "$nyyuqiselfview"
        se.arg = n
        se.card_str = table.concat(names, "+")
        room:sendLog(se, source)

        local tag = sgs.QVariant()
        tag:setValue(view_cards)
        source:setTag("nyyuqiuse", tag)

        room:setPlayerFlag(source, "nyyuqiview")
        room:notifyMoveToPile(source, view_cards, "nyyuqi", sgs.Player_DrawPile, true)
        local card = room:askForUseCard(source, "@@nyyuqi", "@nyyuqi")
        room:setPlayerFlag(source, "-nyyuqiview")
        room:notifyMoveToPile(source, view_cards, "nyyuqi", sgs.Player_DrawPile, false)

        if not card then
            room:setPlayerMark(source, "nyyuqicant-PlayClear", 1)
        end

    end,
}

nyyuqidamage = sgs.CreateTriggerSkill{
    name = "#nyyuqidamage",
    events = {sgs.CardFinished, sgs.Damage, sgs.PreCardUsed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card then
                local card_ids = player:getTag("nyyuqiuse"):toIntList()
                if card_ids:contains(damage.card:getId()) then
                    room:setCardFlag(damage.card, "nyyuqidamage")
                end
            end
        elseif event == sgs.CardFinished then
            local card = data:toCardUse().card
            local card_ids = player:getTag("nyyuqiuse"):toIntList()
            if card_ids:contains(card:getId()) and card:hasFlag("nyyuqidamage") then
                room:setPlayerMark(player, "nyyuqi-PlayClear", player:getMark("nyyuqi-PlayClear")+1)
            end
        elseif event == sgs.PreCardUsed then
            local card = data:toCardUse().card
            local card_ids = player:getTag("nyyuqiuse"):toIntList()
            if room:getCardPlace(card:getId()) == sgs.Player_PlaceHand and card_ids:length() > 0 then
                player:removeTag("nyyuqiuse")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("nyyuqi")
    end,
}

nyshanshen = sgs.CreateProhibitSkill{
    name = "nyshanshen",
    is_prohibited = function(self, from, to, card)
        if to:hasSkill("nyshanshen") and to:getMark("&nyshanshen-Clear") > 0 then
            return card:isKindOf("Slash") or card:isKindOf("TrickCard")
        end
        return false
    end,
}

nyshanshenbuff = sgs.CreateTriggerSkill{
    name = "#nyshanshenbuff",
    events = {sgs.Dying},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local dying = data:toDying()
        room:setPlayerFlag(dying.who, "nyshanshentarget")
        local prompt = string.format("dying:%s:",dying.who:getGeneralName())
        if room:askForSkillInvoke(player, "nyshanshen", sgs.QVariant(prompt)) then
            room:broadcastSkillInvoke("nyshanshen")
            room:setPlayerMark(player, "nyshanshenused_lun", 1)
            local recover = sgs.RecoverStruct(player, nil, 1)
            room:recover(dying.who, recover)
            if dying.who:objectName() == player:objectName() then
                room:setPlayerMark(player, "&nyshanshen-Clear", 1)
            end
        end
        room:setPlayerFlag(dying.who, "-nyshanshentarget")
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("nyshanshen") and target:getMark("nyshanshenused_lun") == 0
    end,
}

nyxianjing = sgs.CreateTriggerSkill{
    name = "nyxianjing",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local n = 3
        if not player:isWounded() then n = 5 end
        local prompt = string.format("view:%s:",n)
        if not room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then return false end
        room:broadcastSkillInvoke(self:objectName())
        local view_cards = room:getNCards(n)
        room:askForGuanxing(player, view_cards)
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Play
    end,
}

nycaojinyu:addSkill(nyyuqi)
nycaojinyu:addSkill(nyyuqidamage)
nycaojinyu:addSkill(nyshanshen)
nycaojinyu:addSkill(nyshanshenbuff)
nycaojinyu:addSkill(nyxianjing)
extension:insertRelatedSkills("nyyuqi", "#nyyuqidamage")
extension:insertRelatedSkills("nyshanshen", "#nyshanshenbuff")

nyshunhanhua = sgs.General(extension, "nyshunhanhua", "wu", 3, false, false, false)

function CanToCard(card,from,to,tos)
	local plist = sgs.PlayerList()
	tos = tos or sgs.SPlayerList()
	for _,p in sgs.list(tos)do
		plist:append(p)
	end
  	return card and card:targetFilter(plist,to,from)
  	and not from:isProhibited(to,card,plist)
	and not plist:contains(to)
end

stabs_slash = sgs.CreateBasicCard
{
    name = "_stabs_slash",
    class_name = "Slash",
    subtype = "attack_card",
    can_recast = false,
	damage_card = true,
    available = function(self,player)
    	for n,to in sgs.list(player:getAliveSiblings())do
			if self:cardIsAvailable(player)
			and CanToCard(self,player,to)
			then
				n = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,player,self)
				if player:hasWeapon("vscrossbow")
				then
					n = n+3
					if self:isVirtualCard()
					then
						for w,id in sgs.list(self:getSubcards())do
							w = player:getWeapon()
							if w and w:getEffectiveId()==id
							and w:objectName()=="vscrossbow"
							then n = n-3 break end
						end
					end
				end
				if player:hasWeapon("crossbow")
				then
					n = n+999
					if self:isVirtualCard()
					then
						for w,id in sgs.list(self:getSubcards())do
							w = player:getWeapon()
							if w and w:getEffectiveId()==id
							and w:objectName()=="crossbow"
							then n = n-999 break end
						end
					end
				end
				if player:getSlashCount()<=n
				or player:canSlashWithoutCrossbow()
				then return true end
				n = player:property("extra_slash_specific_assignee"):toString():split("+")
				if table.contains(n,to:objectName()) then return true end
			end
		end
    end,
	filter = function(self,targets,to_select,source)
		return source:canSlash(to_select,self)
	   	and #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self)
	end,
	on_effect = function(self,effect)
		local room = effect.to:getRoom()
		local se = sgs.SlashEffectStruct()
        se.from = effect.from
        se.nature = effect.card:property("DamageStruct"):toInt()
		se.nature = se.nature<1 and sgs.DamageStruct_Normal or se.nature
        se.slash = effect.card
        se.to = effect.to
        se.drank = effect.from:getMark("drank")
        se.nullified = effect.nullified
        se.no_offset = effect.no_offset
        se.no_respond = effect.no_respond
        se.multiple = effect.multiple
		local jn = effect.from:getTag("Jink_"..effect.card:toString()):toIntList()
		se.jink_num = jn:isEmpty() and 1 or jn:at(0)
        room:setPlayerMark(effect.from,"drank",0)
		room:slashEffect(se)
	end,
}
stabs_slash:setParent(extension)

stabs_slash_on_trigger = sgs.CreateTriggerSkill{
	name = "stabs_slash_on_trigger",
	frequency = sgs.Skill_Compulsory,
    priority = 4,
    global = true,
    --events = {sgs.SlashMissed},
    events = {sgs.CardOffset},
    can_trigger = function(self,target)
        return target and target:isAlive()
    end,
    on_trigger = function(self,event,player,data)
        local room = player:getRoom()
        --[[if event == sgs.SlashMissed then
			local effect = data:toSlashEffect()
			if effect.slash:objectName()=="_stabs_slash"
			and effect.jink
			then
				if room:askForDiscard(effect.to,"_stabs_slash",1,1,true,false,"_stabs_slash0")
				then else room:slashResult(effect,nil) end
			end
        end]]
		if event == sgs.CardOffset then
			local effect = data:toCardEffect()
			if effect.card:objectName()=="_stabs_slash"
			and effect.offset_card:isKindOf("Jink")
			--and effect.to:getHandcardNum()>0
			then
				Skill_msg("yj_stabs_slash",effect.from)
				if room:askForDiscard(effect.to,"_stabs_slash",1,1,true,false,"_stabs_slash0")
				then else return true end
			end
		end
    end,
}

nymiaojian = sgs.CreateZeroCardViewAsSkill
{
    name = "nymiaojian",
    view_as = function(self)
        return nymiaojianCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#nymiaojian")
    end,
}

nymiaojianCard = sgs.CreateSkillCard
{
    name = "nymiaojian",
    filter = function(self, targets, to_select)
        local player = sgs.Self
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
        local card = sgs.Sanguosha:cloneCard("_stabs_slash", sgs.Card_SuitToBeDecided, -1)
        card:setSkillName(self:objectName())
        card:deleteLater()
        return card and card:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, card, qtargets)
    end, 
    on_validate = function(self, cardUse)
        local source = cardUse.from
        local room = source:getRoom()
        local card = sgs.Sanguosha:cloneCard("_stabs_slash", sgs.Card_SuitToBeDecided, -1)
        card:setSkillName(self:objectName())
        room:setCardFlag(card, "RemoveFromHistory")
        return card
    end,
}

nymiaojianda = sgs.CreateTriggerSkill{
    name = "#nymiaojianda",
    events = {sgs.Damage},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.card:getSkillName() == "nymiaojian" and (not damage.to:isNude()) and (damage.to:isAlive()) then
            room:sendCompulsoryTriggerLog(player, "nymiaojian")
            local card = room:askForExchange(damage.to, "nymiaojian", 1, 1, true, "@nymiaojian:"..player:getGeneralName(), false)
            room:obtainCard(player, card, false)
        end  
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("nymiaojian")
    end,
}

nymiaojianbuff = sgs.CreateTargetModSkill{
    name = "#nymiaojianbuff",
    residue_func = function(self, from, card)
        if card:getSkillName() == "nymiaojian" then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if card:getSkillName() == "nymiaojian" then return 1000 end
        return 0
    end,
}

nylianhua = sgs.CreateTriggerSkill{
    name = "nylianhua",
    events = {sgs.Dying},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local dying = data:toDying()
        if dying.who:objectName() == player:objectName() then
            local rec = player:getMaxHp() - player:getHp()
            local n = 0
            if player:getHandcardNum() < player:getMaxHp() then
                n = player:getMaxHp() - player:getHandcardNum()
            end
            local prompt = string.format("dying:%s::%s:", rec, n)
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                room:setPlayerMark(player, "nylianhua_lun", 1)
                room:broadcastSkillInvoke(self:objectName())
                local recover = sgs.RecoverStruct(player, nil, rec)
                room:recover(player, recover)
                player:drawCards(n)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getMark("nylianhua_lun") == 0
    end,
}

nylianhuada = sgs.CreateTriggerSkill{
    name = "#nylianhuada",
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()

        local log = sgs.LogMessage()
        log.type = "$nylianhuadaup"
        log.from = player
        log.arg = "nylianhua"
        log.arg2 = damage.damage
        log.arg3 = damage.damage + 1
        room:sendLog(log)

        room:broadcastSkillInvoke("nylianhua")

        damage.damage = damage.damage + 1
        data:setValue(damage)
    end,
    can_trigger = function(self, target)
        return target and target:getMark("nylianhua_lun") > 0
    end,
}

nychongxu = sgs.CreateTriggerSkill{
    name = "nychongxu",
    events = {sgs.EnterDying},
    frequency = sgs.Skill_Compulsory,
    priority = 4,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local dying = data:toDying()
        if dying.damage and dying.damage.from and dying.damage.from:hasSkill(self:objectName()) then
            room:sendCompulsoryTriggerLog(dying.damage.from, self:objectName(), true, true)

            local log = sgs.LogMessage()
            log.type = "$nychongxukill"
            log.arg = dying.damage.from:getGeneralName()
            log.arg2 = dying.who:getGeneralName()
            log.arg3 = self:objectName()
            room:sendLog(log)
            room:getThread():delay(1000)

            room:killPlayer(dying.who, dying.damage)
            room:gainMaxHp(dying.damage.from, 1, self:objectName())
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyshunhanhua:addSkill(nymiaojian)
nyshunhanhua:addSkill(nymiaojianda)
nyshunhanhua:addSkill(nymiaojianbuff)
nyshunhanhua:addSkill(nylianhua)
nyshunhanhua:addSkill(nylianhuada)
nyshunhanhua:addSkill(nychongxu)
extension:insertRelatedSkills("nymiaojian", "#nymiaojianda")
extension:insertRelatedSkills("nymiaojian", "#nymiaojianbuff")
extension:insertRelatedSkills("nylianhua", "#nylianhuada")

nydaqiao = sgs.General(extension, "nydaqiao", "wu", 3, false, false, false)

nyguose = sgs.CreateZeroCardViewAsSkill
{
    name = "nyguose",
    view_as = function(self)
        return nyguoseCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:canPindian()
    end
}

nyguoseCard = sgs.CreateSkillCard
{
    name = "nyguose",
    filter = function(self, targets, to_select, player)
        if not player:canPindian(to_select) then return false end
        if to_select:isKongcheng() then return false end
        if to_select:objectName() == player:objectName() then return false end
        if to_select:getMark("nyguosefrom"..sgs.Self:objectName().."-PlayClear") > 0 then return false end
		return #targets == 0 and (not player:isPindianProhibited(to_select))
	end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local success = effect.from:pindian(effect.to, "nyguose", nil)
        if success then
            room:setPlayerMark(effect.to, "nyguosefrom"..effect.from:objectName().."-PlayClear", 1)
        end
    end
}

nyguoseelse = sgs.CreateTriggerSkill{
    name = "#nyguoseelse",
    events = {sgs.Pindian},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason == "nyguose" then
				local target = pindian.from
				if pindian.success then
					target:obtainCard(pindian.to_card)
                    local choices = {}
                    if pindian.to:getJudgingArea():length() > 0 then
                        table.insert(choices, string.format("get=%s", pindian.to:getGeneralName()))
                    end
                    if pindian.to:hasJudgeArea() and (not pindian.to:containsTrick("indulgence")) then
                        table.insert(choices, string.format("give=%s", pindian.to:getGeneralName()))
                    end
                    if #choices == 0 then return false end

                    room:setPlayerFlag(pindian.to, "nyguosetarget")

                    local choice = room:askForChoice(pindian.from, "nyguose", table.concat(choices, "+"))
                    
                    room:setPlayerFlag(pindian.to, "-nyguosetarget")

                    if string.find(choice, "get") then
                        local card = room:askForCardChosen(pindian.from, pindian.to, "j", "nyguose")
                        room:obtainCard(pindian.from, card, true)
                    end

                    if string.find(choice, "give") then
                        local card = pindian.from_card
                        room:obtainCard(pindian.from, card, false)

                        local id = card:getId()
                        local indulgence = sgs.Sanguosha:cloneCard("indulgence", card:getSuit(), card:getNumber())
                        indulgence:setSkillName("nyguose")
                        local ccc = sgs.Sanguosha:getWrappedCard(card:getId())
	                    ccc:takeOver(indulgence)
                        room:broadcastUpdateCard(room:getAllPlayers(true), id, ccc)

                        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, pindian.from:objectName(), "nyguose", "")
                        room:moveCardTo(ccc, nil, pindian.to, sgs.Player_PlaceDelayedTrick, reason)
                    end
				end
			end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("nyguose")
    end,
}

nyliuli = sgs.CreateTriggerSkill{
    name = "nyliuli",
    events = {sgs.TargetConfirming},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card:isKindOf("Slash") or use.card:isKindOf("Duel") then
            if player:getMark("nyliuli1-Clear") == 0 then
                local tran = string.format("tran:%s:", use.card:objectName())
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(tran)) then
                    room:broadcastSkillInvoke(self:objectName())
                    room:setPlayerFlag(player, "nyliulitarget")

                    if use.card:isKindOf("Slash") then
                        room:setPlayerFlag(player, "nyliulislash")
                    else
                        room:setPlayerFlag(player, "nyliuliduel")
                    end

                    local choices = {}
                    local prompt = string.format("replace=%s=%s", player:getGeneralName(), use.card:objectName())
                    table.insert(choices, prompt)
                    table.insert(choices, "cancel")

                    local target = nil
                    nextp = player:getNextAlive()
                    while(true) do
                        if (not use.to:contains(nextp)) and (use.from:objectName() ~= nextp:objectName())
                        and (not room:isProhibited(use.from, nextp, use.card)) then
                            local choice = room:askForChoice(nextp, self:objectName(), table.concat(choices, "+"))
                            if string.find(choice, "replace") then
                                target = nextp
                                break
                            end
                        end
                        nextp = nextp:getNextAlive()
                        if nextp:objectName() == player:objectName() then break end
                    end

                    room:setPlayerFlag(player, "-nyliulitarget")
                    if use.card:isKindOf("Slash") then
                        room:setPlayerFlag(player, "-nyliulislash")
                    else
                        room:setPlayerFlag(player, "-nyliuliduel")
                    end

                    if target then
                        player:drawCards(1)
                        target:drawCards(1)

                        local log = sgs.LogMessage()
                        log.type = "$nyliulireplace"
                        log.arg = target:getGeneralName()
                        log.arg2 = player:getGeneralName()
                        log.card_str = use.card:toString()
                        room:sendLog(log)

                        use.to:removeOne(player)
                        use.to:append(target)
				        room:sortByActionOrder(use.to)
				        data:setValue(use)
				        room:getThread():trigger(sgs.TargetConfirming, room, target, data)
                    else
                        player:drawCards(2)
                        room:setPlayerMark(player, "nyliuli1-Clear", 1)
                    end
                end
            end
            if player:getMark("nyliuli2-Clear") == 0 and player:getJudgingArea():length() > 0 then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("get")) then
                    room:broadcastSkillInvoke(self:objectName())
                    room:setPlayerMark(player, "nyliuli2-Clear", 1)
                    local card = room:askForCardChosen(player, player, "j", self:objectName())
                    room:obtainCard(player, card, true)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) 
    end,
}

nydaqiao:addSkill(nyguose)
nydaqiao:addSkill(nyguoseelse)
nydaqiao:addSkill(nyliuli)
extension:insertRelatedSkills("nyguose", "#nyguoseelse")

nyzhangxuan = sgs.General(extension, "nyzhangxuan", "wu", 4, false, false, false)

nytongli = sgs.CreateViewAsSkill
{
    name = "nytongli",
    n = 1,
    response_pattern = "@@nytongli",
    view_filter = function(self, selected, to_select)
        local suit = sgs.Self:property("nytonglisuit"):toString()
        if not sgs.Self:getHandcards():contains(to_select) then return false end
        return to_select:getSuitString() == suit and #selected < 1
    end,
    view_as = function(self, cards)
        if #cards == 0 then return nil end
        local pattern = sgs.Self:property("nytonglipattern"):toString()
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName("nytongli")
        card:addSubcard(cards[1])
        return card
    end,
    enabled_at_play = function(self, player)
        return false 
    end,
}

nytonglibuff = sgs.CreateTriggerSkill{
    name = "#nytonglibuff",
    events = {sgs.PreCardUsed, sgs.CardFinished},
    frequency = sgs.Skill_NotFrequent,
    priority = 10,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()

        if event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card:getSkillName() == "nytongli" then
                room:sendCompulsoryTriggerLog(player, "nytongli")
                player:drawCards(1)
            end
        end

        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:isKindOf("SkillCard") then return false end
            if use.card:isKindOf("EquipCard") then return false end
            if use.from:objectName() == player:objectName() then
                local card = sgs.Sanguosha:cloneCard(use.card:objectName(), sgs.Card_SuitToBeDecided, -1)
                card:setSkillName("nytongli")
                if card:isAvailable(player) then
                    card:deleteLater()
                    local prompt = string.format("nytongliuse:%s::%s:", use.card:getSuitString(), use.card:objectName())
                    room:setPlayerProperty(player, "nytonglisuit", sgs.QVariant(use.card:getSuitString()))
                    room:setPlayerProperty(player, "nytonglipattern", sgs.QVariant(use.card:objectName()))

                    local origin = player:getTag("nytongliorigin"):toCard()
                    if (not origin) or origin:objectName() ~= use.card:objectName() then
                        room:setPlayerMark(player, "nytonglitimes", 0)
                        local tag = sgs.QVariant()
                        tag:setValue(use.card)
                        player:setTag("nytongliorigin", tag)
                    else
                        room:setPlayerMark(player, "nytonglitimes", player:getMark("nytonglitimes")+1)
                    end

                    room:askForUseCard(player, "@@nytongli", prompt)
                else
                    card:deleteLater()
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("nytongli")
    end,
}

nytonglielse = sgs.CreateTargetModSkill{
    name = "#nytonglielse",
    pattern = "BasicCard,TrickCard",
    residue_func = function(self, from, card)
        if card:getSkillName() == "nytongli" then return 1000 end
        return 0
    end,
}

nyshezhang = sgs.CreateTriggerSkill{
    name = "nyshezhang",
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasSkill("nyshezhang") and p:getMark("nyshezhang-Clear") < 2 then
                local suits = {}
                for _,card in sgs.qlist(p:getHandcards()) do
                    if not table.contains(suits, card:getSuitString()) then
                        table.insert(suits, card:getSuitString())
                    end
                end
                local prompt 
                if #suits >= 4 then
                    prompt = "draw"
                else
                    prompt = string.format("get:%s:", 4 - #suits)
                end
                if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(prompt)) then
                    room:broadcastSkillInvoke(self:objectName())
                    if #suits >= 4 then
                        room:setPlayerMark(p, "nyshezhang-Clear", p:getMark("nyshezhang-Clear")+1)
                        p:drawCards(1)
                        if p:getMark("nyshezhang-Clear") == 1 then
                            local log = sgs.LogMessage()
                            log.type = "$nyshezhangtwice"
                            log.arg = p:getGeneralName()
                            log.arg2 = "nyshezhang"
                            room:sendLog(log)
                        end
                    else
                        room:setPlayerMark(p, "nyshezhang-Clear", 2)
                        local get = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                        for _,id in sgs.qlist(room:getDrawPile()) do
                            local card = sgs.Sanguosha:getCard(id)
                            if not table.contains(suits, card:getSuitString()) then
                                table.insert(suits, card:getSuitString())
                                get:addSubcard(card)
                                if #suits >= 4 then break end
                            end
                        end
                        room:obtainCard(p, get, true)
                        get:deleteLater()
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

nyzhangxuan:addSkill(nytongli)
nyzhangxuan:addSkill(nytonglibuff)
nyzhangxuan:addSkill(nytonglielse)
nyzhangxuan:addSkill(nyshezhang)
extension:insertRelatedSkills("nytongli", "#nytonglibuff")
extension:insertRelatedSkills("nytongli", "#nytonglielse")

nydiaochan = sgs.General(extension, "nydiaochan", "qun", 3, false, false, false)

nybiyue = sgs.CreateTriggerSkill{
    name = "nybiyue",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Start then
            if player:getMark("&nybiyue") > 0 then
                room:setPlayerMark(player, "&nybiyue", 0)
                if player:getHandcardNum() > player:getMaxHp() then
                    local n = player:getHandcardNum() - player:getMaxHp()
                    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                    room:askForDiscard(player, self:objectName(), n, n, false, false)
                end
            end
        end

        if player:getPhase() == sgs.Player_Finish then
            room:setPlayerMark(player, "&nybiyue", 0)
            local n = 1
            if player:isWounded() then n = n*2 end
            if player:getHandcardNum() >= player:getHp() then n = n*2 end
            if player:getMark("damage_point_round") == 0 then n = n*2 end
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            if n == 8 then
                local log = sgs.LogMessage()
                log.type = "$nybiyuediscard"
                log.from = player
                room:sendLog(log)
                room:setPlayerMark(player, "&nybiyue", 1)
            end
            player:drawCards(n)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nylijian = sgs.CreateZeroCardViewAsSkill
{
    name = "nylijian",
    view_as = function(self)
        return nylijianCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:usedTimes("#nylijian") < 2
    end
}

local function nylijiangetcard(pattern, cards)
    if not pattern then return nil end
    local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
    card:setSkillName("_nylijian")
    if #cards > 0 then
        local n = #cards
        for i = 1, n, 1 do
            card:addSubcard(cards[i])
        end
    end
    return card
end

local function nylijiancanuse(from, to, cards)
    local room = sgs.Sanguosha:currentRoom()
    local canuse = {}
    local slash = nylijiangetcard("slash", cards)
    if not room:isProhibited(from, to, slash) then
        table.insert(canuse, "slash")
        table.insert(canuse, "fire_slash")
        table.insert(canuse, "thunder_slash")
    end
    slash:deleteLater() 
    local duel = nylijiangetcard("duel", cards)
    if not room:isProhibited(from, to, duel) then
        duel:deleteLater() 
        table.insert(canuse, "duel")
    end
    duel:deleteLater() 
    return canuse
end

nylijianCard = sgs.CreateSkillCard{
    name = "nylijian",
    filter = function(self, targets, to_select, player)
        return #targets < 2
    end,
    feasible = function(self, targets, player)
        return #targets == 2
    end,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        local cards = {}
        for _,p in ipairs(targets) do
            if not p:isNude() then
                local id = room:askForCardChosen(source, p, "he", "nylijian")
                table.insert(cards, sgs.Sanguosha:getCard(id))
                room:throwCard(id, p, source)
            end
        end
        local players = sgs.SPlayerList()
        local a = targets[1]
        local b = targets[2]
        local atob = nylijiancanuse(a, b, cards)
        if #atob > 0 then
            players:append(a)
        end
        local btoa = nylijiancanuse(b, a, cards)
        if #btoa > 0 then
            players:append(b)
        end
        if players:length() > 0 then
            local n = #cards
            local ta = room:askForPlayerChosen(source, players, self:objectName(), "@nylijian:"..n, true, true)
            if ta then
                local pattern 
                local from 
                local to
                if ta:objectName() == a:objectName() then
                    from = a
                    to = b
                    room:setPlayerMark(from, "nylijian", 1)
                    room:setPlayerMark(to, "nylijian", 2)
                    pattern = room:askForChoice(source, self:objectName(), table.concat(atob, "+"))
                elseif ta:objectName() == b:objectName() then
                    from = b
                    to = a
                    room:setPlayerMark(from, "nylijian", 1)
                    room:setPlayerMark(to, "nylijian", 2)
                    pattern = room:askForChoice(source, self:objectName(), table.concat(btoa, "+"))
                end
                room:setPlayerMark(from, "nylijian", 0)
                room:setPlayerMark(to, "nylijian", 0)
                
                local card = nylijiangetcard(pattern, cards)
                room:setCardFlag(card, "nylijianfrom"..source:objectName())
                local use = sgs.CardUseStruct(card, from, to, false, self, source)
                room:useCard(use)
            end
        end
    end
}

nylijianbuff = sgs.CreateTriggerSkill{
    name = "#nylijianbuff",
    events = {sgs.Damage},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if (not damage.card) or (damage.card:getSkillName() ~= "nylijian") then return false end
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if damage.card:hasFlag("nylijianfrom"..p:objectName()) then
                room:addPlayerHistory(p, "#nylijian", 1)
            end
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

nydiaochan:addSkill(nybiyue)
nydiaochan:addSkill(nylijian)
nydiaochan:addSkill(nylijianbuff)
extension:insertRelatedSkills("nylijian", "#nylijianbuff")

nyxiahouzie = sgs.General(extension, "nyxiahouzie", "qun", 4, false, false, false, 3)

nyduoren = sgs.CreateTriggerSkill{
    name = "nyduoren",
    events = {sgs.EnterDying},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local dying = data:toDying()
        if dying.damage and dying.damage.from 
        and dying.damage.from:objectName() ~= dying.who:objectName() 
        and dying.damage.from:hasSkill(self:objectName()) then
            local source = dying.damage.from
            local to = dying.who
            local skills = to:getVisibleSkillList()
            local can = {}
            for _,p in sgs.qlist(skills) do
                local skillname = p:objectName()
                if (not source:hasSkill(skillname)) and (not string.find(skillname, "&")) then
                    table.insert(can, skillname)
                end
            end
            if #can == 0 then return false end
            local prompt = string.format("get:%s:", to:getGeneralName())
            if room:askForSkillInvoke(source, self:objectName(), sgs.QVariant(prompt)) then
                room:broadcastSkillInvoke(self:objectName())
                room:loseMaxHp(source, 1)

                local old = source:getTag("nyduorenskills"):toString():split("+")
                if old then
                    for _,skill in ipairs(old) do
                        if source:hasSkill(skill) then
                            room:detachSkillFromPlayer(source, skill)
                        end
                    end
                end

                can = {}
                for _,p in sgs.qlist(skills) do
                    local skillname = p:objectName()
                    if (not source:hasSkill(skillname)) and (not string.find(skillname, "&")) then
                        table.insert(can, skillname)
                    end
                end
                for _,skill in ipairs(can) do
                    room:acquireSkill(source, skill)
                end

                local oldtarget = source:property("nyduorentarget"):toString()
                if oldtarget then room:setPlayerMark(source, "&nyduoren+:+"..oldtarget, 0) end
                room:setPlayerMark(source, "&nyduoren+:+"..to:getGeneralName(), 1)

                source:setTag("nyduorenskills", sgs.QVariant(table.concat(can, "+")))
                room:setPlayerProperty(source, "nyduorentarget", sgs.QVariant(to:getGeneralName()))
            end
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

nyxuechang = sgs.CreateZeroCardViewAsSkill
{
    name = "nyxuechang",
    view_as = function(self)
        return nyxuechangCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("nyxuechangfailed-PlayClear") == 0
    end
}

nyxuechangCard = sgs.CreateSkillCard
{
    name = "nyxuechang",
    filter = function(self, targets, to_select, player)
        if not player:canPindian(to_select) then return false end
        --if to_select:isKongcheng() then return false end
        --if to_select:objectName() == player:objectName() then return false end
        if to_select:getMark("nyxuechangfrom"..player:objectName().."-PlayClear") > 0 then return false end
		return #targets == 0 and (not player:isPindianProhibited(to_select))
	end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local success = effect.from:pindian(effect.to, "nyxuechang", nil)
        room:setPlayerMark(effect.to, "nyxuechangfrom"..effect.from:objectName().."-PlayClear", 1)
        if not success then
            room:setPlayerMark(effect.from, "nyxuechangfailed-PlayClear", 1)
            room:setPlayerMark(effect.to, "&nyxuechang", effect.to:getMark("&nyxuechang")+1)
            room:setPlayerMark(effect.to, "nyxuechangtarget"..effect.from:objectName(), effect.to:getMark("nyxuechangtarget"..effect.from:objectName())+1)
        end
        if success then
            if not effect.to:isNude() then
                local card = room:askForCardChosen(effect.from, effect.to, "he", self:objectName())
                room:obtainCard(effect.from, card, false)
            else
                local log = sgs.LogMessage()
                log.type = "$nyxuechangnotcard"
                log.arg = effect.to:getGeneralName()
                room:sendLog(log)
            end
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
            slash:setSkillName("_nyxuechang")
            if room:isProhibited(effect.from, effect.to, slash) then
                slash:deleteLater()
                local log = sgs.LogMessage()
                log.type = "$nyxuechangnotslash"
                log.arg = effect.to:getGeneralName()
                room:sendLog(log)
            else
                room:setCardFlag(slash, "RemoveFromHistory")
                local use = sgs.CardUseStruct(slash, effect.from, effect.to)
                room:useCard(use)
            end
        end
    end
}

nyxuechangbuff = sgs.CreateTriggerSkill{
    name = "#nyxuechangbuff",
    events = {sgs.DamageCaused},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.to:getMark("nyxuechangtarget"..damage.from:objectName()) > 0 then
            local n = damage.to:getMark("nyxuechangtarget"..damage.from:objectName())
            room:sendCompulsoryTriggerLog(damage.from, "nyxuechang", true, true)
            local log = CreateDamageLog(damage, n, "nyxuechang", true)
            room:sendLog(log)
            damage.damage = damage.damage + n
            room:setPlayerMark(damage.to, "&nyxuechang", damage.to:getMark("&nyxuechang")-n)
            room:setPlayerMark(damage.to, "nyxuechangtarget"..damage.from:objectName(), 0)
            data:setValue(damage)
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

nyxiahouzie:addSkill(nyduoren)
nyxiahouzie:addSkill(nyxuechang)
nyxiahouzie:addSkill(nyxuechangbuff)
extension:insertRelatedSkills("nyxuechang", "#nyxuechangbuff")

nymusiccaiwenji = sgs.General(extension, "nymusiccaiwenji", "qun", 3, false, false, false) 

nyshuangjia = sgs.CreateTriggerSkill{
    name = "nyshuangjia",
    events = {sgs.RoundStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if not player:isAlive() then return false end
        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)

        if player:getPile("nyhujia"):length() > 0 then
            local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
            dummy:addSubcards(player:getPile("nyhujia"))
            room:obtainCard(player, dummy, true)
            dummy:deleteLater()
        end

        local suits = {}
        local new_cards = sgs.IntList()
        for _,id in sgs.qlist(room:getDrawPile()) do
            local card = sgs.Sanguosha:getCard(id)
            local suit = card:getSuitString()
            if not table.contains(suits, suit) then
                table.insert(suits, suit)
                new_cards:append(id)
            end
        end
        if new_cards:length() > 0 then
            player:addToPile("nyhujia", new_cards)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyshuangjiadistance = sgs.CreateDistanceSkill{
    name = "#nyshuangjiadistance",
    correct_func = function(self, from, to)
        if to:getPile("nyhujia"):length() > 0 then
            return 1
        end
        return 0
    end,
}

nybeifenVS = sgs.CreateViewAsSkill
{
    name = "nybeifen",
    expand_pile = "nyhujia",
    n = 1,
    response_pattern = "@@nybeifen",
    view_filter = function(self, selected, to_select)
        return #selected == 0 and sgs.Self:getPile("nyhujia"):contains(to_select:getId())
    end,
    view_as = function(self, cards)
        if #cards == 0 then return nil end
        local card = nybeifenCard:clone()
        card:addSubcard(cards[1])
        return card
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

nybeifenCard = sgs.CreateSkillCard
{
    name = "nybeifen",
    will_throw = false,
    filter = function(self, targets, to_select, player) 
        if not player:hasFlag("nybeifencan") then 
            return to_select:hasFlag("nybeifentarget")
        end
        return #targets == 0
    end,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        local card_id = self:getSubcards():first()
        local card = sgs.Sanguosha:getCard(card_id)
        targets[1]:obtainCard(self, true)
        room:setCardFlag(card_id, "nybeifen")
        room:setCardTip(card_id,"nyhujia")

        local tag1 = sgs.QVariant()
        tag1:setValue(source)
        local tag2 = sgs.QVariant()
        tag2:setValue(targets[1])

        card:setTag("nybeifen", tag1)
        card:setTag("nybeifendraw", tag2)
    end
}

nybeifen = sgs.CreateTriggerSkill{
    name = "nybeifen",
    events = {sgs.EventPhaseStart, sgs.Damaged, sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = nybeifenVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()

        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Play then return false end
            if player:getPile("nyhujia"):length() == 0 or (not player:hasSkill("nybeifen")) then return false end
            room:setPlayerFlag(player, "nybeifencan")
            room:askForUseCard(player, "@@nybeifen", "@nybeifen")
            room:setPlayerFlag(player, "-nybeifencan")
        end

        if event == sgs.Damaged then
            if not player:isAlive() then return false end
            local targets = room:findPlayersBySkillName("nybeifen")
            if targets:length() == 0 then return false end
            room:setPlayerFlag(player, "nybeifentarget")
            for _,p in sgs.qlist(targets) do
                if p:getPile("nyhujia"):length() > 0 then
                    room:askForUseCard(p, "@@nybeifen", "nybeifengive:"..player:getGeneralName())
                end
                if not player:isAlive() then 
                    room:setPlayerFlag(player, "-nybeifentarget")
                    return false 
                end
            end
            room:setPlayerFlag(player, "-nybeifentarget")
        end

        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if (not move.from) then return false end
            if not move.from_places:contains(sgs.Player_PlaceHand) then return false end
            local cards = {}
            for _,id in sgs.qlist(move.card_ids) do
                local card = sgs.Sanguosha:getCard(id)
                if card:hasFlag("nybeifen") or card:getTag("nybeifendraw"):toPlayer() then
                    table.insert(cards, card)
                end
            end
            for _,card in ipairs(cards) do
                local target = card:getTag("nybeifendraw"):toPlayer()
                card:removeTag("nybeifendraw")
                local source = card:getTag("nybeifen"):toPlayer()
                card:removeTag("nybeifen")
                if target and target:isAlive() then
                    room:sendCompulsoryTriggerLog(source, "nybeifen", true, true)
                    local suits = {}
                    table.insert(suits, card:getSuitString())
                    local get = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                    for _,id in sgs.qlist(room:getDrawPile()) do
                        local cc = sgs.Sanguosha:getCard(id)
                        if not table.contains(suits, cc:getSuitString()) then
                            table.insert(suits, cc:getSuitString())
                            get:addSubcard(cc)
                        end
                    end
                    room:obtainCard(target, get, true)
                    get:deleteLater()
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

nymusiccaiwenji:addSkill(nyshuangjia)
nymusiccaiwenji:addSkill(nyshuangjiadistance)
nymusiccaiwenji:addSkill(nybeifen)
nymusiccaiwenji:addSkill(nybeifenVS)
extension:insertRelatedSkills("nyshuangjia", "#nyshuangjiadistance")

nyzhangyao = sgs.General(extension, "nyzhangyao", "wu", 3, false, false, false)

nyyuanyu = sgs.CreateZeroCardViewAsSkill
{
    name = "nyyuanyu",
    view_as = function(self)
        return nyyuanyuCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#nyyuanyu")
    end,
}

nyyuanyuCard = sgs.CreateSkillCard
{
    name = "nyyuanyu",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        source:drawCards(1)
        if not source:isNude() and source:isAlive() then
            local card = room:askForExchange(source, self:objectName(), 1, 1, true, "nyzhangyaoput:1", false)
            source:addToPile("nyyuan", card)
            room:getThread():delay(300)
        end
        if source:isAlive() then
            local target = room:askForPlayerChosen(source, room:getOtherPlayers(source), self:objectName(), "@nyyuanyu", true, true)
            if not target then return false end
            if target:getMark("nyyuanyufrom"..source:objectName()) > 0 then
                local log = sgs.LogMessage()
                log.type = "$nyyuanyuremove"
                log.from = target
                log.arg = self:objectName()
                room:sendLog(log)
            else
                room:addPlayerMark(target, "nyyuanyufrom"..source:objectName())
                room:addPlayerMark(target, "&nyyuanyu")
            end
        end
    end
}

nyyuanyubuff = sgs.CreateTriggerSkill{
    name = "#nyyuanyubuff",
    events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Discard then return false end
            if player:getHandcardNum() <= player:getHp() then return false end
            local n = player:getHandcardNum() - player:getHp()
            local targets = room:findPlayersBySkillName("nyyuanyu")
            for _,p in sgs.qlist(targets) do
                if player:getMark("nyyuanyufrom"..p:objectName()) > 0 then
                    room:sendCompulsoryTriggerLog(p, "nyyuanyu", true, true)
                    local card = room:askForExchange(player, "nyyuanyu", n, n, true, "nyzhangyaoput:"..n, false)
                    p:addToPile("nyyuan", card)
                    n = player:getHandcardNum() - player:getHp()
                    room:getThread():delay(300)
                end
                if n <= 0 then return false end
            end
        end

        if event == sgs.CardUsed or event == sgs.CardResponded then
            if player:isNude() then return false end
            local card 
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            elseif event == sgs.CardResponded then
                local response = data:toCardResponse()
                if response.m_isUse then
                    card = response.m_card
                end
            end
            if (not card) or card:isKindOf("SkillCard") then return false end
            local targets = room:findPlayersBySkillName("nyyuanyu")
            for _,p in sgs.qlist(targets) do
                if player:getMark("nyyuanyufrom"..p:objectName()) > 0 then
                    local can = false
                    if p:getPile("nyyuan"):length() > 0 then
                        for _,id in sgs.qlist(p:getPile("nyyuan")) do
                            local compare = sgs.Sanguosha:getCard(id)
                            if compare:getSuitString() == card:getSuitString() then 
                                can = true
                                break
                            end
                        end
                        if can and (not player:isNude()) then
                            room:sendCompulsoryTriggerLog(p, "nyyuanyu", true, true)
                            local card = room:askForExchange(player, "nyyuanyu", 1, 1, true, "nyzhangyaoput:1", false)
                            p:addToPile("nyyuan", card)
                            room:getThread():delay(300)
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:getMark("&nyyuanyu") > 0
    end,
}

nyxiyanVS = sgs.CreateViewAsSkill
{
    name = "nyxiyan",
    n = 4,
    expand_pile = "nyyuan",
    response_pattern = "@@nyxiyan",
    view_filter = function(self, selected, to_select)
        for _,p in ipairs(selected) do
            if to_select:getSuitString() == p:getSuitString() then return false end
        end
        return #selected < 4 and sgs.Self:getPile("nyyuan"):contains(to_select:getEffectiveId())
    end,
    enabled_at_play = function(self)
        return false 
    end,
    view_as = function(self, cards)
        if #cards < 4 then return nil end
        local card = nyxiyanCard:clone()
        for _,cc in ipairs(cards) do
            card:addSubcard(cc)
        end
        return card
    end,
}

nyxiyanCard = sgs.CreateSkillCard
{
    name = "nyxiyan",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        room:obtainCard(source, self, true)
    end
}

nyxiyan = sgs.CreateTriggerSkill{
    name = "nyxiyan",
    events = {sgs.TargetConfirmed, sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = nyxiyanVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.to:contains(player) and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) then
                if not use.from:isNude() then
                    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                    local card = room:askForExchange(use.from, self:objectName(), 1, 1, true, "nyzhangyaoput:1", false)
                    player:addToPile("nyyuan", card)
                    room:getThread():delay(300)
                end
            end
        end

        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish then
                local suits = {}
                for _,id in sgs.qlist(player:getPile("nyyuan")) do
                    local card = sgs.Sanguosha:getCard(id)
                    if not table.contains(suits, card:getSuitString()) then
                        table.insert(suits, card:getSuitString())
                    end
                end
                if #suits >= 4 then
                    room:askForUseCard(player, "@@nyxiyan", "@nyxiyan")
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:isAlive()
    end,
}

nyzhangyao:addSkill(nyxiyan)
nyzhangyao:addSkill(nyxiyanVS)
nyzhangyao:addSkill(nyyuanyu)
nyzhangyao:addSkill(nyyuanyubuff)
extension:insertRelatedSkills("nyyuanyu", "#nyyuanyubuff")

nytangji = sgs.General(extension, "nytangji", "qun", 3, false, false, false)

nykangge = sgs.CreateTriggerSkill{
    name = "nykangge",
    events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start and player:getMark("nykanggefirst") == 0 then
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@nykangge", false, true)
                room:broadcastSkillInvoke(self:objectName())
                room:setPlayerMark(player, "nykanggefirst", 1)
                room:setPlayerMark(target, "&nykangge", target:getMark("&nykangge")+1)
                room:setPlayerMark(target, "nykanggefrom"..player:objectName(), 1)
            end
        end

        if event == sgs.CardsMoveOneTime then
            if player:getMark("nykanggefirst") == 0 then return false end
            if player:getMark("nykangfefailed_lun") > 0 then return false end
            if room:getTag("FirstRound"):toBool() then return false end
            local move = data:toMoveOneTime()
            if move.to and move.to:getMark("nykanggefrom"..player:objectName()) > 0 
            and move.to:getPhase() ~= sgs.Player_Draw and move.to_place == sgs.Player_PlaceHand then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                room:addPlayerMark(player, "nykanggerecord-Clear")
                player:drawCards(2)
                if player:getMark("nykanggerecord-Clear") >= 7 then
                    room:setPlayerMark(player, "nykangfefailed_lun", 1)
                    room:loseHp(player, 1, true, player, self:objectName())
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nykanggebuff = sgs.CreateTriggerSkill{
    name = "#nykanggebuff",
    events = {sgs.Dying},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local dying = data:toDying()
        local target = dying.who
        if player:getMark("nykanggeused"..target:objectName().."_lun") > 0 then return false end
        if player:getMark("nykanggefrom"..target:objectName()) > 0 or target:getMark("nykanggefrom"..player:objectName()) > 0 then
            local prompt = string.format("recover:%s:", target:getGeneralName())
            room:setPlayerFlag(target, "nykanggetarget")
            if room:askForSkillInvoke(player, "nykangge", sgs.QVariant(prompt)) then
                room:broadcastSkillInvoke("nykangge")
                if not player:hasSkill("nykangge") then
                    local log = sgs.LogMessage()
                    log.type = "#InvokeOthersSkill"
                    log.from = player
                    log.to:append(target)
                    log.arg = "nykangge"
                    room:sendLog(log)
                end
                room:setPlayerFlag(target, "-nykanggetarget")
                room:setPlayerMark(player, "nykanggeused"..target:objectName().."_lun", 1)
                room:recover(target, sgs.RecoverStruct(player, nil, 1-target:getHp()))
            else
                room:setPlayerFlag(target, "-nykanggetarget")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and ((target:hasSkill(self:objectName())) or (target:getMark("&nykangge") > 0))
    end,
}

nyjielie = sgs.CreateTriggerSkill{
    name = "nyjielie",
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        local prompt = string.format("@nyjielie:%s::%s:", player:getGeneralName(), damage.damage)
        room:setPlayerFlag(player, "nyjielietarget")
        if player:hasSkill("nyjielie") then
            local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), prompt, true, true)
            if target then
                room:setPlayerFlag(player, "-nyjielietarget")
                room:broadcastSkillInvoke(self:objectName())
                room:loseHp(player, 1, true, player, self:objectName())
                if target:isAlive() then
                    target:drawCards(damage.damage)
                end
                return true
            end
        else
            local targets = room:findPlayersBySkillName(self:objectName())
            for _,p in sgs.qlist(targets) do
                if player:getMark("nykanggefrom"..p:objectName()) > 0 then
                    local target = room:askForPlayerChosen(p, room:getAlivePlayers(), self:objectName(), prompt, true, true)
                    if target then
                        room:setPlayerFlag(player, "-nyjielietarget")
                        room:broadcastSkillInvoke(self:objectName())
                        room:loseHp(p, 1, true, p, self:objectName())
                        if target:isAlive() then
                            target:drawCards(damage.damage)
                        end
                        return true
                    end
                end
            end
        end
        room:setPlayerFlag(player, "-nyjielietarget")
    end,
    can_trigger = function(self, target)
        return target and ((target:hasSkill(self:objectName())) or (target:getMark("&nykangge") > 0))
    end,
}

nytangji:addSkill(nykangge)
nytangji:addSkill(nykanggebuff)
nytangji:addSkill(nyjielie)
extension:insertRelatedSkills("nykangge", "#nykanggebuff")

nyzhugeguo = sgs.General(extension, "nyzhugeguo", "shu", 3, false, false, false)

nyqirang = sgs.CreateTriggerSkill{
    name = "nyqirang",
    events = {sgs.CardUsed, sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("EquipCard") then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("equip")) then
                    room:broadcastSkillInvoke(self:objectName())
                    for _,id in sgs.qlist(room:getDrawPile()) do
                        if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
                            room:obtainCard(player, sgs.Sanguosha:getCard(id), true)
                            break
                        end
                    end
                end
            end
            if use.card:isKindOf("TrickCard") and (player:getMaxCards() > 0) then
                local prompt = string.format("trick:%s::%s:",use.card:objectName(),player:getMaxCards())
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                    room:broadcastSkillInvoke(self:objectName())
                    room:addPlayerMark(player, "nyqirang_max-SelfClear")
                    player:drawCards(2)

                    local log = sgs.LogMessage()
                    log.type = "$nyqirang_norespond"
                    log.from = player
                    log.arg = self:objectName()
                    log.card_str = use.card:toString()
                    room:sendLog(log)

                    local no_respond_list = use.no_respond_list
                    table.insert(no_respond_list, "_ALL_TARGETS")
                    use.no_respond_list = no_respond_list
                    data:setValue(use)
                end
            end
        end

        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then
                if player:getMaxCards() == player:getHp() then return false end
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                local max = math.max(player:getMaxCards(), player:getHp())
                local min = math.min(player:getMaxCards(), player:getHp())
                local x = max - min
                room:setPlayerMark(player, "&nyqirang", x)

                local log = sgs.LogMessage()
                log.type = "$nyqirang_distance"
                log.from = player
                log.arg = x
                room:sendLog(log)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyqirang_max = sgs.CreateMaxCardsSkill{
    name = "#nyqirang_max",
    extra_func = function(self, target)
        if target:getMark("nyqirang_max-SelfClear") > 0 then
            return (-1)*target:getMark("nyqirang_max-SelfClear")
        end
    end,
}

nyqirang_dist = sgs.CreateDistanceSkill{
    name = "#nyqirang_dist",
    correct_func = function(self, from, to)
        return to:getMark("&nyqirang")
    end,
}

nyqirang_clear = sgs.CreateTriggerSkill{
    name = "#nyqirang_clear",
    events = {sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local change = data:toPhaseChange()
        if change.from == sgs.Player_NotActive then
            room:setPlayerMark(player, "&nyqirang", 0)
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

nydengxian = sgs.CreateTriggerSkill{
    name = "nydengxian",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Wake,
    waked_skills = "nyjinghong",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
        room:setPlayerMark(player, "nydengxian_wake", 1)
        room:setPlayerMark(player, "nydengxian", 1)
        for _,id in sgs.qlist(room:getDrawPile()) do
            local card = sgs.Sanguosha:getCard(id)
            if card:isKindOf("EquipCard") then
                local n = -1
                if card:isKindOf("Weapon") then
                    n = 0
                elseif card:isKindOf("Armor") then
                    n = 1
                elseif card:isKindOf("DefensiveHorse") then
                    n = 2
                elseif card:isKindOf("OffensiveHorse") then
                    n = 3
                elseif card:isKindOf("Treasure") then
                    n = 4
                end
                if player:canUse(card, player, true) and (not player:getEquip(n)) then
                    can = false
                    local use = sgs.CardUseStruct(card, player, player)
                    room:useCard(use)
                    room:getThread():delay(800)
                end
            end
        end
        room:acquireSkill(player, "nyjinghong")
    end,
    can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Finish or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if player:getMaxCards() == 0 then
			return true
		end
		return false
	end,
    -- can_trigger = function(self, target)
    --     return target and target:hasSkill(self:objectName()) and (target:getMaxCards() == 0 or target:canWake(self:objectName()))
    --     and target:getPhase() == sgs.Player_Finish and target:getMark("nydengxian_wake") == 0
    -- end,
}

nyjinghong = sgs.CreateTriggerSkill{
    name = "nyjinghong",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Judge or player:getPhase() == sgs.Player_Discard then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
            local new_phase
            local prompt
            if player:getPhase() == sgs.Player_Judge then
                prompt = "nyjinghong_judge"
            else
                prompt = "nyjinghong_discard"
            end
            local choices = "draw+play"
            local choice = room:askForChoice(player, self:objectName(), choices, sgs.QVariant(), nil, prompt)
            if choice == "draw" then
                new_phase = sgs.Player_Draw
            else
                new_phase = sgs.Player_Play
            end

            local log = sgs.LogMessage()
            log.type = "$nyjinghong_change"
            log.from = player
            log.arg = self:objectName()
            log.arg2 = player:getPhaseString()
            log.arg3 = choice
            room:sendLog(log)

            local thread = room:getThread()
            local old_phase = player:getPhase()
			player:setPhase(new_phase)
			room:broadcastProperty(player, "phase")
			if not thread:trigger(sgs.EventPhaseStart, room, player) then
				thread:trigger(sgs.EventPhaseProceeding, room, player)
			end
			thread:trigger(sgs.EventPhaseEnd, room, player)
            player:setPhase(old_phase)
            room:broadcastProperty(player, "phase")
            return true
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyzhugeguo:addSkill(nyqirang)
nyzhugeguo:addSkill(nyqirang_max)
nyzhugeguo:addSkill(nyqirang_dist)
nyzhugeguo:addSkill(nyqirang_clear)
nyzhugeguo:addSkill(nydengxian)
extension:insertRelatedSkills("nyqirang", "#nyqirang_max")
extension:insertRelatedSkills("nyqirang", "#nyqirang_dist")
extension:insertRelatedSkills("nyqirang", "#nyqirang_clear")

nyhuaman = sgs.General(extension, "nyhuaman", "shu", 3, false, false, false)

nymansi = sgs.CreateTriggerSkill{
    name = "nymansi",
    events = {sgs.EventPhaseStart, sgs.TargetConfirmed, sgs.Damage},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Play then return false end
            local savage_assault = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_SuitToBeDecided, -1)
            savage_assault:setSkillName("_"..self:objectName())
            if savage_assault:isAvailable(player) then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("use")) then
                    room:broadcastSkillInvoke(self:objectName())
                    room:useCard(sgs.CardUseStruct(savage_assault, player, sgs.SPlayerList(), true), true)
                else
                    savage_assault:deleteLater()
                end
            else
                savage_assault:deleteLater()
            end
        end

        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card:objectName() == "savage_assault" and use.to:contains(player) then
                local log = sgs.LogMessage()
		        log.type = "#WuyanGooD"
		        log.from = player
		        log.to:append(use.from)
		        log.arg = "savage_assault"
		        log.arg2 = self:objectName()
		        room:sendLog(log)
		        room:notifySkillInvoked(player, self:objectName())
                room:broadcastSkillInvoke(self:objectName())

                player:drawCards(1)
                use.from:drawCards(1)

                local nullified_list = use.nullified_list
		        table.insert(nullified_list, player:objectName())
		        use.nullified_list = nullified_list
		        data:setValue(use)
            end
        end

        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:objectName() == "savage_assault" then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                player:drawCards(1)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyshouying = sgs.CreateTriggerSkill{
    name = "nyshouying",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card:isKindOf("SkillCard") or use.card:isKindOf("EquipCard") or use.card:isKindOf("DelayedTrick") then return false end
        if use.from:objectName() == player:objectName() then
            if use.card:isVirtualCard() then return false end
            local can_invoke = false
            for _,target in sgs.qlist(use.to) do
                if target:objectName() ~= player:objectName() then
                    can_invoke = true
                    break
                end
            end
            if not can_invoke then return false end
            local prompt = string.format("get:%s:",use.card:objectName())
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                room:setPlayerMark(player, "nyshouying-Clear", 1)
                room:broadcastSkillInvoke(self:objectName())
                room:obtainCard(player, use.card, true)
            end
        elseif use.from and use.from:objectName() ~= player:objectName() and use.to:contains(player) then
            local prompt = string.format("nullified:%s::%s:",use.card:objectName(),use.from:getGeneralName())
            room:setPlayerFlag(use.from, "nyshouying")
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                room:setPlayerMark(player, "nyshouying-Clear", 1)
                room:setPlayerFlag(use.from, "-nyshouying")
                room:broadcastSkillInvoke(self:objectName())

                if use.from:isAlive() and (not use.from:isNude()) then
                    room:throwCard(room:askForCardChosen(player, use.from, "he", self:objectName()), use.from, player)
                end

                local nullified_list = use.nullified_list
		        table.insert(nullified_list, player:objectName())
		        use.nullified_list = nullified_list
		        data:setValue(use)
            else
                room:setPlayerFlag(use.from, "-nyshouying")
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getMark("nyshouying-Clear") == 0
    end,
}

nyzhanyuan = sgs.CreateTriggerSkill{
    name = "nyzhanyuan",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Limited,
    waked_skills = "nyxili",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@nyzhanyuan", true, true)
        if target then
            room:broadcastSkillInvoke(self:objectName())
            room:setPlayerMark(player, "nyzhanyuan_used", 1)
            if player:getHandcardNum() > 0 then
                room:askForDiscard(player, self:objectName(), player:getHandcardNum(), player:getHandcardNum(), false, false)
            end
            local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
            duel:setSkillName("_"..self:objectName())
            if not player:isProhibited(target, duel) then
                room:useCard(sgs.CardUseStruct(duel, player, target, false), true)
            else
                duel:deleteLater()
            end

            if player:isAlive() then 
                room:gainMaxHp(player, 1, self:objectName())
                player:drawCards(2)
                room:acquireSkill(player, "nyxili") 
            end
            if target:isAlive() then room:acquireSkill(target, "nyxili") end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) 
        and target:getPhase() == sgs.Player_Start and target:getMark("nyzhanyuan_used") == 0
    end,
}

nyxili = sgs.CreateTriggerSkill{
    name = "nyxili",
    events = {sgs.CardFinished},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card:getSkillName() == self:objectName() then return false end
        if use.card:isKindOf("BasicCard") or use.card:isNDTrick() then else return false end
        if not use.from:objectName() == player:objectName() then return false end
        if use.to:length() ~= 1 then return false end
        local target = use.to:first()
        room:setPlayerFlag(player, "nyxili")
        for _,other in sgs.qlist(room:getOtherPlayers(player)) do
            if target:isDead() then 
                room:setPlayerFlag(player, "-nyxili") 
                return false 
            end
            if other:hasSkill(self:objectName()) and other:getMark("nyxili-Clear") == 0 then
                local card = sgs.Sanguosha:cloneCard(use.card:objectName(), sgs.Card_SuitToBeDecided, -1)
                card:setSkillName("_"..self:objectName())
                local prompt = string.format("use:%s::%s:", target:getGeneralName(), card:objectName())
                if (not other:isProhibited(target, card)) and other:canUse(card, target, true) then
                    if room:askForSkillInvoke(other, self:objectName(), sgs.QVariant(prompt)) then
                        room:setPlayerMark(other, "nyxili-Clear", 1)
                        room:useCard(sgs.CardUseStruct(card, other, target, true), false)
                    else
                        card:deleteLater()
                    end
                else
                    card:deleteLater()
                end
            end
        end
        room:setPlayerFlag(player, "-nyxili") 
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) 
    end,
}

nyxili_buff = sgs.CreateTargetModSkill{
    name = "#nyxili_buff",
    pattern = ".",
    residue_func = function(self, from, card)
        if card:getSkillName() == "nyxili" or card:getSkillName() == "_nyxili" then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if card:getSkillName() == "nyxili" or card:getSkillName() == "_nyxili" then return 1000 end
        return 0
    end,
}

nyhuaman:addSkill(nymansi)
nyhuaman:addSkill(nyshouying)
nyhuaman:addSkill(nyzhanyuan)
extension:insertRelatedSkills("nyxili", "#nyxili_buff")

nybaosanniang = sgs.General(extension, "nybaosanniang", "shu", 3, false, false, false)

nywuniang = sgs.CreateZeroCardViewAsSkill
{
    name = "nywuniang",
    view_as = function(self)
        return nywuniangCard:clone()
    end,
    enabled_at_play = function(self, player)
        if not sgs.Slash_IsAvailable(player) then return false end
        if player:getPhase() ~= sgs.Player_NotActive then
            return (player:getJudgingArea():length() + player:getEquips():length()) > 0
        end
        if (player:getJudgingArea():length() + player:getEquips():length()) > 0 then return true end
        local now_player
        for _,other in sgs.qlist(player:getAliveSiblings()) do
            if other:getPhase() ~= sgs.Player_NotActive then
                now_player = other
                break
            end
        end
        if now_player then return (now_player:getJudgingArea():length() + now_player:getEquips():length()) > 0 end
        return false 
    end,
    enabled_at_response = function(self, player, pattern)
		if not string.find(pattern, "slash") then return false end
        if player:getPhase() ~= sgs.Player_NotActive then
            return (player:getJudgingArea():length() + player:getEquips():length()) > 0
        end
        if (player:getJudgingArea():length() + player:getEquips():length()) > 0 then return true end
        local now_player
        for _,other in sgs.qlist(player:getAliveSiblings()) do
            if other:getPhase() ~= sgs.Player_NotActive then
                now_player = other
                break
            end
        end
        if now_player then return (now_player:getJudgingArea():length() + now_player:getEquips():length()) > 0 end
        return false 
	end
}

nywuniangCard = sgs.CreateSkillCard
{
    name = "nywuniang",
    filter = function(self, targets, to_select, player)
        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
    
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("nywuniang")
        slash:deleteLater()
        return slash and slash:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, slash, qtargets)
    end,
    feasible = function(self, targets, player)

        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("nywuniang")
        slash:deleteLater()

        local qtargets = sgs.PlayerList()
        for _,p in ipairs(targets) do
            qtargets:append(p)
        end
        return slash and slash:targetsFeasible(qtargets, player)
    end,
    on_validate = function(self, cardUse)
        local source = cardUse.from
        local room = source:getRoom()
        
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("nywuniang")

        local targets = sgs.SPlayerList()
        if source:getCards("ej"):length() > 0 then  targets:append(source) end
        if source:getPhase() == sgs.Player_NotActive then
            for _,other in sgs.qlist(room:getOtherPlayers(source)) do
                if other:getPhase() ~= sgs.Player_NotActive then
                    if other:getCards("ej"):length() > 0 then  targets:append(other) end
                    break
                end
            end
        end

        local target = room:askForPlayerChosen(source, targets, self:objectName(), "@nywuniang", false, true)
        room:throwCard(room:askForCardChosen(source, target, "ej", self:objectName()), self:objectName(), target, source)

        return slash
    end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()

        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("nywuniang")

        local targets = sgs.SPlayerList()
        if source:getCards("ej"):length() > 0 then  targets:append(source) end
        if source:getPhase() == sgs.Player_NotActive then
            for _,other in sgs.qlist(room:getOtherPlayers(source)) do
                if other:getPhase() ~= sgs.Player_NotActive then
                    if other:getCards("ej"):length() > 0 then  targets:append(other) end
                    break
                end
            end
        end

        local target = room:askForPlayerChosen(source, targets, self:objectName(), "@nywuniang", false, true)
        room:throwCard(room:askForCardChosen(source, target, "ej", self:objectName()), self:objectName(), target, source)

        return slash
    end
}

nywuniang_getcard = sgs.CreateTriggerSkill{
    name = "#nywuniang_getcard",
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card 
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if (not card:isKindOf("Slash")) or (not card) then return false end
        local targets = sgs.SPlayerList()
        for _,other in sgs.qlist(room:getOtherPlayers(player)) do
            if not other:isAllNude() then
                targets:append(other)
            end
        end
        if targets:length() == 0 then return false end
        room:setPlayerFlag(player, "nywuniangget")
        local target = room:askForPlayerChosen(player, targets, "nywuniang", "nywuniangget", true, true)
        room:setPlayerFlag(player, "-nywuniangget")

        if target then
            room:broadcastSkillInvoke("nywuniang")
            room:obtainCard(player, room:askForCardChosen(player, target, "hej", "nywuniang"), true)
            target:drawCards(1)
            if player:getMark("nyxushen_used") > 0 and player:getPhase() ~= sgs.Player_NotActive then
                local log = sgs.LogMessage()
                log.type = "$nywuniang_more"
                log.from = player
                room:sendLog(log)

                room:addSlashCishu(player, 1)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("nywuniang") and target:getMark("@skill_invalidity") == 0
    end,
}

nyxushen = sgs.CreateTriggerSkill{
    name = "nyxushen",
    events = {sgs.Dying},
    frequency = sgs.Skill_NotFrequent,
    waked_skills = "nyzhennan,tenyearwusheng,tenyearzhiman",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local dying = data:toDying()
        if dying.who:objectName() == player:objectName() then
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("prompt")) then
                room:broadcastSkillInvoke(self:objectName())
                room:setPlayerMark(player, "nyxushen_used", 1)
                room:recover(player, sgs.RecoverStruct(player, nil, 1-player:getHp()))
                room:acquireSkill(player, "nyzhennan")
                room:getThread():delay(800)
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@nyxushen", true, true)
                if target then
                    room:broadcastSkillInvoke(self:objectName())
                    room:acquireSkill(target, "tenyearwusheng")
                    room:acquireSkill(target, "tenyearzhiman")
                    target:drawCards(3)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName()) and target:getMark("nyxushen_used") == 0
    end,
}

nyzhennan = sgs.CreateTriggerSkill{
    name = "nyzhennan",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card:isKindOf("SkillCard") then return false end
            if use.to:length() > 1 then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true)
                room:setPlayerMark(player, "&nyzhennan-Clear", player:getMark("&nyzhennan-Clear")+1)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyzhennan_damage = sgs.CreateTriggerSkill{
    name = "#nyzhennan_damage",
    events = {sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local change = data:toPhaseChange()
        if change.to == sgs.Player_NotActive then
            local skillers = room:findPlayersBySkillName("nyzhennan")
            for _,skiller in sgs.qlist(skillers) do
                if skiller:isAlive() and skiller:getMark("&nyzhennan-Clear") > 0 then
                    local targets = sgs.SPlayerList()
                    
                    for i = 1, skiller:getMark("&nyzhennan-Clear"), 1 do
                        local target = room:askForPlayerChosen(skiller, room:getAlivePlayers(), "nyzhennan", "@nyzhennan:"..i, true, false)
                        if target then
                            local seer = sgs.SPlayerList()
                            seer:append(skiller)
                            room:addPlayerMark(target, "&nyzhennan_damage", 1, seer)
                            if not targets:contains(target) then targets:append(target) end
                        else
                            break
                        end
                    end
                    room:setPlayerMark(skiller, "&nyzhennan-Clear", 0)

                    if targets:length() > 0 then
                        room:sendCompulsoryTriggerLog(skiller, "nyzhennan", true)
                        for _,target in sgs.qlist(targets) do
                            room:broadcastSkillInvoke("nyzhennan")
                            local log = sgs.LogMessage()
                            log.type = "$nyzhennan_damage_count"
                            log.from = skiller
                            log.to:append(target)
                            log.arg = target:getMark("&nyzhennan_damage")
                            room:sendLog(log)

                            room:damage(sgs.DamageStruct("nyzhennan", skiller, target, target:getMark("&nyzhennan_damage"), sgs.DamageStruct_Normal))
                            room:removePlayerMark(target, "&nyzhennan_damage", target:getMark("&nyzhennan_damage"))
                            room:getThread():delay(800)
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

nyzhennan_more = sgs.CreateTriggerSkill{
    name = "#nyzhennan_more",
    events = {sgs.PreCardUsed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card:isKindOf("SkillCard") then return false end
        if use.card:isKindOf("EquipCard") then return false end
        if use.card:isKindOf("DelayedTrick") then return false end
        if use.card:objectName() == "collateral" then return false end
        if use.to:length() > 1 then return false end
        local targets = room:getCardTargets(player, use.card, use.to)
	    if targets:isEmpty() then return false end

        local tag = sgs.QVariant()
        tag:setValue(use.card)
        player:setTag("nyzhennan_card", tag)--ai

        room:setPlayerFlag(player, "nyzhennan_more")
        local target = room:askForPlayerChosen(player, targets, "nyzhennan", "nyzhennan_more:"..use.card:objectName(), true, false)
        room:setPlayerFlag(player, "-nyzhennan_more")

        if target then
            local log = sgs.LogMessage()
            log.type = "$nyzhennan_more_log"
            log.from = player
            log.to:append(target)
            log.arg = "nyzhennan"
            log.card_str = use.card:toString()
            room:sendLog(log)
            room:broadcastSkillInvoke("nyzhennan")

            use.to:append(target)
            room:sortByActionOrder(use.to)
            data:setValue(use)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("nyzhennan")
    end,
}

nybaosanniang:addSkill(nywuniang)
nybaosanniang:addSkill(nywuniang_getcard)
nybaosanniang:addSkill(nyxushen)
extension:insertRelatedSkills("nywuniang", "#nywuniang_getcard")
extension:insertRelatedSkills("nyzhennan", "#nyzhennan_damage")
extension:insertRelatedSkills("nyzhennan", "#nyzhennan_more")

ny_yanfuren = sgs.General(extension, "ny_yanfuren", "qun", 3, false, false, false)

ny_nifu = sgs.CreateProhibitSkill{
    name = "ny_nifu",
    is_prohibited = function(self, from, to, card)
        if card:isKindOf("Slash") or card:isNDTrick() then
            return to:hasSkill(self:objectName()) and (not from:inMyAttackRange(to)) and (from:objectName() ~= to:objectName())
        end
        return false
    end,
}

ny_nifu_distance = sgs.CreateDistanceSkill{
    name = "#ny_nifu_distance",
    correct_func = function(self, from, to)
        return to:getMark("&ny_nifu-SelfClear")
    end,
}

ny_nifu_buff = sgs.CreateTriggerSkill{
    name = "#ny_nifu_buff",
    events = {sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:isAlive() then
            room:sendCompulsoryTriggerLog(player, "ny_nifu", true, true)
            room:addPlayerMark(player, "&ny_nifu-SelfClear", 1)
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("ny_nifu")
    end,
}

ny_channi = sgs.CreateTriggerSkill{
    name = "ny_channi",
    events = {sgs.EventPhaseStart,sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Play then return false end
            
            for _,pl in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if player:isDead() then return false end
                if pl:isAlive() then
                    local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
                    duel:setSkillName("_"..self:objectName())
                    local targets = room:getCardTargets(player, duel)

                    if targets:isEmpty() then 
                        duel:deleteLater()
                        return false
                    end

                    local target = room:askForPlayerChosen(pl, targets, self:objectName(), "@ny_channi:"..player:getGeneralName(), true, false)
                    if target then
                        local log = sgs.LogMessage()
                        log.type = "#InvokeSkill"
                        log.from = pl
                        log.arg = self:objectName()
                        room:sendLog(log)

                        room:useCard(sgs.CardUseStruct(duel, player, target, false, nil, pl), false)

                        if player:isAlive() and pl:isAlive() and (not pl:isKongcheng()) and player:objectName() ~= pl:objectName() then
                            local n = 1
                            if player:getMark("ny_channi_damage-PlayClear") > 0 then
                                n = n + 1
                                room:setPlayerMark(player, "ny_channi_damage-PlayClear", 0)
                            end
                            if player:getHandcardNum() < player:getHp() then n = n + 1 end
                            local prompt = string.format("ny_channi_give:%s::%s:", player:getGeneralName(), n)
                            local give = room:askForExchange(pl, self:objectName(), 999, n, false, prompt, false)
                            room:obtainCard(player, give, false)
                            if player:isAlive() and pl:isAlive() and pl:getHandcardNum() < player:getHp() then
                                pl:drawCards(player:getHp() - pl:getHandcardNum(), self:objectName())
                            end
                        end
                    else
                        duel:deleteLater()
                    end
                end
            end
        end
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.card and damage.card:getSkillName() == self:objectName() then
                room:addPlayerMark(player, "ny_channi_damage-PlayClear", 1)
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_yanfuren:addSkill(ny_nifu)
ny_yanfuren:addSkill(ny_nifu_distance)
ny_yanfuren:addSkill(ny_nifu_buff)
ny_yanfuren:addSkill(ny_channi)
extension:insertRelatedSkills("ny_nifu", "#ny_nifu_distance")
extension:insertRelatedSkills("ny_nifu", "#ny_nifu_buff")

ny_wanniangz = sgs.General(extension, "ny_wanniangz", "qun", 3, false, false, false)

ny_zhengeVS = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_zhenge",
    response_pattern = "@@ny_zhenge",
    view_as = function(self)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("_ny_zhenge")
        return slash
    end,
    enabled_at_play = function(self, player)
        return false
    end,
}

ny_zhenge = sgs.CreateTriggerSkill{
    name = "ny_zhenge",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_zhengeVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Start then return false end
            local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "ny_zhenge_chosen", true, true)
            if target then
                room:broadcastSkillInvoke(self:objectName())
                room:setPlayerMark(target, "ny_xinghan_from"..player:objectName(), 1)
                if target:getMark("&ny_zhenge") < 3 then
                    room:addPlayerMark(target, "&ny_zhenge", 1)
                else
                    target:drawCards(2, self:objectName())
                end
                if target:isAlive() then
                    room:askForUseCard(target, "@@ny_zhenge", "@ny_zhenge")
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_zhenge_buff_first = sgs.CreateTargetModSkill{
    name = "#ny_zhenge_buff_first",
    residue_func = function(self, from, card)
        if from:getMark("&ny_zhenge") >= 2 then return 1 end
        return 0
    end,
}

ny_zhenge_buff_second = sgs.CreateAttackRangeSkill
{
    name = "#ny_zhenge_buff_second",
    extra_func = function(self, player, include_weapon)
        if player:getMark("&ny_zhenge") >= 1 then return 2 end
        return 0
    end
} 

ny_zhenge_buff_third = sgs.CreateMaxCardsSkill{
    name = "#ny_zhenge_buff_third",
    extra_func = function(self, target)
        if target:getMark("&ny_zhenge") >= 3 then return 2 end
        return 0
    end,
}

ny_xinghan = sgs.CreateTriggerSkill{
    name = "ny_xinghan",
    events = {sgs.CardFinished, sgs.Damage},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash")
            and use.from:objectName() == player:objectName() 
            and player:isAlive()
            and player:hasSkill(self:objectName()) then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
                    if not use.card:hasFlag("ny_xinghan"..player:objectName()) then
                        room:broadcastSkillInvoke(self:objectName())
                    end
                    player:drawCards(1, self:objectName())
                end
            end
        end
        if event == sgs.Damage then
            if player:getMark("&ny_zhenge") <= 0 then return false end
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") then
                local targets = room:findPlayersBySkillName(self:objectName())
                for _,target in sgs.qlist(targets) do
                    if target:isAlive() and player:getMark("ny_xinghan_from"..target:objectName()) > 0 then
                        if room:askForSkillInvoke(target, self:objectName(), sgs.QVariant("draw")) then
                            room:broadcastSkillInvoke(self:objectName())
                            room:setCardFlag(damage.card, "ny_xinghan"..target:objectName())
                            target:drawCards(1, self:objectName())
                            room:getThread():delay(100)
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and (target:hasSkill(self:objectName()) or target:getMark("&ny_zhenge") >= 1)
    end,
}

ny_wanniangz:addSkill(ny_zhenge)
ny_wanniangz:addSkill(ny_zhengeVS)
ny_wanniangz:addSkill(ny_zhenge_buff_first)
ny_wanniangz:addSkill(ny_zhenge_buff_second)
ny_wanniangz:addSkill(ny_zhenge_buff_third)
ny_wanniangz:addSkill(ny_xinghan)
extension:insertRelatedSkills("ny_zhenge", "#ny_zhenge_buff_first")
extension:insertRelatedSkills("ny_zhenge", "#ny_zhenge_buff_second")
extension:insertRelatedSkills("ny_zhenge", "#ny_zhenge_buff_third")

ny_xiahoushi = sgs.General(extension, "ny_xiahoushi", "shu", 3, false, false, false)

ny_qiaoshiVS = sgs.CreateViewAsSkill
{
    name = "ny_qiaoshi",
    n = 99,
    expand_pile = "#ny_qiaoshi",
    response_pattern = "@@ny_qiaoshi",
    view_filter = function(self, selected, to_select)
        if sgs.Self:hasFlag("ny_qiaoshi_get") then
            return #selected < 2 and sgs.Self:getPile("#ny_qiaoshi"):contains(to_select:getId())
        else
            return #selected < 1 and sgs.Self:getHandcards():contains(to_select)
            and to_select:isAvailable(sgs.Self) and to_select:hasFlag("ny_qiaoshi")
        end
    end,
    view_as = function(self, cards)
        if sgs.Self:hasFlag("ny_qiaoshi_get") then
            if #cards > 0 then
                local cc = ny_qiaoshiCard:clone()
                for _,card in ipairs(cards) do
                    cc:addSubcard(card)
                end
                return cc
            end
        else
            if #cards > 0 then return cards[1] end
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

ny_qiaoshiCard = sgs.CreateSkillCard
{
    name = "ny_qiaoshi",
    will_throw = false,
    target_fixed = true,
    on_use = function(self, room, source, targets)
        return false
    end,
}

ny_qiaoshi = sgs.CreateTriggerSkill{
    name = "ny_qiaoshi",
    events = {sgs.DamageInflicted,sgs.CardsMoveOneTime,sgs.EventPhaseStart,sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_qiaoshiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DamageInflicted then
            if not player:hasSkill(self:objectName()) then return false end
            if player:getMark("ny_qiaoshi-Clear") > 0 then return false end
            local damage = data:toDamage()
            player:setTag("ny_qiaoshi", data)
            local prompt = ""
            if damage.from and damage.from:isAlive() then
                prompt = string.format("draw:%s::%s:",damage.damage,damage.from:getGeneralName())
            else
                prompt = string.format("notdraw:%s:",damage.damage)
            end
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, "ny_qiaoshi-Clear", 1)
                local log  =CreateDamageLog(damage, damage.damage, self:objectName(), false)
                room:sendLog(log)
                if damage.from and damage.from:isAlive() then damage.from:drawCards(2, self:objectName()) end
                return true
            end
        end
        if event == sgs.CardsMoveOneTime then
            if not player:hasSkill(self:objectName()) then return false end
            if player:getMark("ny_qiaoshi-Clear") > 0 then return false end
            local move = data:toMoveOneTime()
            if move.to_place ~= sgs.Player_DiscardPile then return false end
            local all = player:getTag("ny_qiaoshi_cards"):toIntList()
            if not all then all = sgs.IntList() end
            for _,id in sgs.qlist(move.card_ids) do
                all:append(id)
            end
            local tag = sgs.QVariant()
            tag:setValue(all)
            player:setTag("ny_qiaoshi_cards", tag)
        end
        if event == sgs.Damaged then
            if not player:hasSkill(self:objectName()) then return false end
            if player:getMark("ny_qiaoshi-Clear") > 0 then return false end
            if player:isAlive() then
                room:addPlayerMark(player, "ny_qiaoshi_damage-Clear", 1)
            end
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_NotActive then
                for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    p:removeTag("ny_qiaoshi_cards")
                end
            end
            if player:getPhase() == sgs.Player_Finish then
                for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getMark("ny_qiaoshi_damage-Clear") > 0 
                    and p:getMark("ny_qiaoshi-Clear") == 0 and p:isAlive() then
                        local ids = sgs.IntList()
                        local all = p:getTag("ny_qiaoshi_cards"):toIntList()
                        if not all then all = sgs.IntList() end
                        for _,id in sgs.qlist(all) do
                            if room:getCardPlace(id) == sgs.Player_DiscardPile then
                                ids:append(id)
                            end
                        end
                        if not ids:isEmpty() then
                            local tag = sgs.QVariant()
                            tag:setValue(ids)
                            p:setTag("ny_qiaoshi_cards", tag)

                            room:setPlayerFlag(p, "ny_qiaoshi_get")
                            room:notifyMoveToPile(p, ids, "ny_qiaoshi", sgs.Player_DiscardPile, true)
                            local card = room:askForUseCard(p, "@@ny_qiaoshi", "@ny_qiaoshi")
                            room:notifyMoveToPile(p, ids, "ny_qiaoshi", sgs.Player_DiscardPile, false)
                            room:setPlayerFlag(p, "-ny_qiaoshi_get")

                            if card then
                                room:addPlayerMark(p, "ny_qiaoshi-Clear", 1)
                                room:obtainCard(p, card, true)
                                for _,id in sgs.qlist(card:getSubcards()) do
                                    room:setCardFlag(id, "ny_qiaoshi")
                                    room:setCardTip(id, "ny_qiaoshi")
                                end
                                for i = 1,card:subcardsLength(),1 do
                                    if not room:askForUseCard(p, "@@ny_qiaoshi", "ny_qiaoshi_usecard") then break end
                                    if p:isDead() then break end
                                end
                                for _,cc in sgs.qlist(p:getHandcards()) do
                                    room:setCardFlag(cc, "-ny_qiaoshi")
                                    room:setCardTip(cc:getId(), "-ny_qiaoshi")
                                end
                            end
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

ny_yanyu = sgs.CreateViewAsSkill
{
    name = "ny_yanyu",
    n = 1,
    view_filter = function(self, selected, to_select)
        return #selected < 1 and to_select:isKindOf("Slash")
    end,
    view_as = function(self,cards)
        if #cards == 1 then
            local card = ny_yanyuCard:clone()
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return true
    end
}

ny_yanyuCard = sgs.CreateSkillCard
{
    name = "ny_yanyu",
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    feasible = function(self, targets, player)
        return #targets <= 1
    end,
    on_use = function(self, room, source, targets)
        local target = nil
        if #targets == 0 then
            local log = sgs.LogMessage()
            log.type = "$RecastCard"
            log.from = source
            log.card_str = table.concat(sgs.QList2Table(self:getSubcards()), "+")
            room:sendLog(log)

            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, source:objectName(), self:objectName(), "")
            room:moveCardTo(self, nil, nil, sgs.Player_DiscardPile, reason)

            if source and source:isAlive() then source:drawCards(self:subcardsLength(), "recast") end
        else
            target = targets[1]
            if target and target:isAlive() then room:obtainCard(target, self, true) end
            if source and source:isAlive() then source:drawCards(1, self:objectName()) end
        end
        if source and source:isAlive() then source:drawCards(1, self:objectName()) end
        if target and target:isAlive() then target:drawCards(1, self:objectName()) end
    end,
}

ny_xiahoushi:addSkill(ny_qiaoshi)
ny_xiahoushi:addSkill(ny_qiaoshiVS)
ny_xiahoushi:addSkill(ny_yanyu)

ny_tengfanglan = sgs.General(extension, "ny_tengfanglan", "wu", 3, false, false, false)

local function ny_luochong_discard(player)
    if player:isDead() then return end
    local room = player:getRoom()
    for i = 1, 2, 1 do
        local targets = sgs.SPlayerList()
        for _,target in sgs.qlist(room:getAlivePlayers()) do
            if (not target:isAllNude()) then
                targets:append(target)
            end
        end
        if targets:isEmpty() then break end
        local target = room:askForPlayerChosen(player, targets, "ny_luochong", "@ny_luochong:"..i, true, true)
        if not target then break end
        if i == 1 then room:broadcastSkillInvoke("ny_luochong") end
        local card = room:askForCardChosen(player, target, "hej", "ny_luochong")
        room:throwCard(card, target, player)
        if player:isDead() then break end
    end
end

local function ny_luochong_judge(player)
    if player:isDead() then return false end
    if not player:isAllNude() then return true end
    for _,p in sgs.qlist(player:getAliveSiblings()) do
        if not p:isAllNude() then return true end
    end
    return false
end

ny_luochongVS = sgs.CreateZeroCardViewAsSkill
{
    name = "ny_luochong",
    view_as = function(self)
        return ny_luochongCard:clone()
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#ny_luochong")) 
        and ny_luochong_judge(player)
    end
}

ny_luochongCard = sgs.CreateSkillCard
{
    name = "ny_luochong",
    mute = true,
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        if ny_luochong_judge(source) then
            ny_luochong_discard(source)
        end
    end
}

ny_luochong = sgs.CreateTriggerSkill{
    name = "ny_luochong",
    events = {sgs.RoundStart,sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_luochongVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.RoundStart then
            if ny_luochong_judge(player) then
                if room:askForSkillInvoke(player, self:objectName(), data, false) then
                    ny_luochong_discard(player)
                end
            end
        end
        if event == sgs.Damaged then
            if player:isDead() then return false end
            local damage = data:toDamage()
            for i = 1, damage.damage, 1 do
                if ny_luochong_judge(player) then
                    if room:askForSkillInvoke(player, self:objectName(), data, false) then
                        ny_luochong_discard(player)
                    end
                end
                if player:isDead() then return false end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_aichen = sgs.CreateTriggerSkill{
    name = "ny_aichen",
    events = {sgs.CardsMoveOneTime,sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() and player:isAlive()
            and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
                if player:getMark("ny_aichen-Clear") > 0 then
                    if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw:1:")) then
                        room:broadcastSkillInvoke(self:objectName())
                        player:drawCards(1, self:objectName())
                    end
                else
                    if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw:2:")) then
                        room:broadcastSkillInvoke(self:objectName())
                        room:setPlayerMark(player, "ny_aichen-Clear", 1)
                        player:drawCards(2, self:objectName())
                    end
                end
            end
        end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Discard then
                if player:isSkipped(sgs.Player_Discard) then return false end
                if room:askForDiscard(player, self:objectName(), 1, 1, true, true, "@ny_aichen", ".", self:objectName()) then
                    player:skip(sgs.Player_Discard)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

ny_tengfanglan:addSkill(ny_luochong)
ny_tengfanglan:addSkill(ny_luochongVS)
ny_tengfanglan:addSkill(ny_aichen)

nyarz_caohua = sgs.General(extension, "nyarz_caohua", "wei", 3, false, false, false)

nyarz_guili = sgs.CreateTriggerSkill{
    name = "nyarz_guili",
    events = {sgs.Damage,sgs.EventPhaseStart,sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damage then
            room:setPlayerMark(player, "nyarz_guili_damage", 1)
        end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.from == sgs.Player_NotActive then
                room:setPlayerMark(player, "nyarz_guili_damage", 0)
            end
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_NotActive then return false end
            if player:getMark("nyarz_guili_damage") > 0 then
                room:setPlayerMark(player, "nyarz_guili_damage", 0)
                return false
            end
            if player:hasSkill(self:objectName()) and player:getMark("nyarz_guili_other_lun") == 0 then
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@nyarz_guili", true, true)
                if target then
                    room:setPlayerMark(player, "nyarz_guili_other_lun", 1)
                    room:broadcastSkillInvoke(self:objectName())

                    local log = sgs.LogMessage()
                    log.type = "$nyarz_guili_extra"
                    log.from = target
                    log.arg = self:objectName()
                    room:sendLog(log)

                    target:gainAnExtraTurn()
                end
            end
            for _,target in sgs.qlist(room:getOtherPlayers(player)) do
                if target:hasSkill(self:objectName()) and target:isAlive() and target:getMark("nyarz_guili_self_lun") == 0 then
                    if room:askForSkillInvoke(target, self:objectName(), sgs.QVariant("turn")) then
                        room:setPlayerMark(target, "nyarz_guili_self_lun", 1)
                        room:broadcastSkillInvoke(self:objectName())

                        local log = sgs.LogMessage()
                        log.type = "$nyarz_guili_extra"
                        log.from = target
                        log.arg = self:objectName()
                        room:sendLog(log)

                        target:gainAnExtraTurn()
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyarz_caiyiVS = sgs.CreateViewAsSkill
{
    name = "nyarz_caiyi",
    n = 99,
    response_pattern = "@@nyarz_caiyi",
    view_filter = function(self, selected, to_select)
        if #selected > 0 then
            for _,card in ipairs(selected) do
                if to_select:getSuit() == card:getSuit() then return false end
            end
        end
        return sgs.Self:getHandcards():contains(to_select)
    end,
    view_as = function(self,cards)
        if #cards > 0 then
            local cc = nyarz_caiyiCard:clone()
            for _,card in ipairs(cards) do
                cc:addSubcard(card)
            end
            return cc
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

nyarz_caiyiCard = sgs.CreateSkillCard
{
    name = "nyarz_caiyi",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        local room = source:getRoom()
        if source:isDead() then return false end
        local player = source
        room:setPlayerMark(player, "nyarz_caiyi-Clear", 1)
        local n = self:subcardsLength()
        local double = 2*n
        if player:getHandcardNum() < double then
            player:drawCards(double - player:getHandcardNum(), self:objectName())
        elseif player:getHandcardNum() > double then
            local dis = player:getHandcardNum() - double
            room:askForDiscard(player, self:objectName(), dis, dis, false, false)
            if player:isDead() then return false end

            room:setPlayerMark(player, "nyarz_caiyi_ai-Clear", n)

            local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "nyarz_caiyi_chosen", false, true)
            local choices = string.format("good=%s=%s+bad=%s=%s", target:getGeneralName(), n, target:getGeneralName(), n)
            local _data = sgs.QVariant()
            _data:setValue(target)
            local choice = room:askForChoice(player, self:objectName(), choices, _data)

            room:setPlayerMark(target, "nyarz_caiyi_ai-Clear", n)

            if string.find(choice, "good") then
                local all = string.format("recover=%s+draw=%s", n, double)
                local result = room:askForChoice(target, self:objectName(), all, sgs.QVariant(n))
                if string.find(result, "recover") and target:isWounded() then
                    local re = math.min(n, target:getLostHp())
                    room:recover(target, sgs.RecoverStruct(self:objectName(), player, re))
                elseif string.find(result, "draw") then
                    target:drawCards(double, self:objectName())
                end
            else
                local all = ""
                if target:getCardCount() >= double then
                    all = string.format("damage=%s+discard=%s", n, double)
                else
                    all = string.format("damage=%s+damage_nochoices", n)
                end
                local result = room:askForChoice(target, self:objectName(), all, sgs.QVariant(n))
                if string.find(result, "damage") then
                    room:damage(sgs.DamageStruct(self:objectName(), nil, target, n, sgs.DamageStruct_Normal))
                else
                    room:askForDiscard(target, self:objectName(), double, double, false, true)
                end
            end
        end
    end
}

nyarz_caiyi = sgs.CreateTriggerSkill{
    name = "nyarz_caiyi",
    events = {sgs.CardFinished},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = nyarz_caiyiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:isKindOf("SkillCard") then return false end
            if use.from:objectName() ~= player:objectName() then return false end
            if player:getMark("nyarz_caiyi-Clear") > 0 then return false end
            if player:isKongcheng() then return false end
            room:askForUseCard(player, "@@nyarz_caiyi", "@nyarz_caiyi")
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_caohua:addSkill(nyarz_guili)
nyarz_caohua:addSkill(nyarz_caiyi)
nyarz_caohua:addSkill(nyarz_caiyiVS)

nyarz_zhongyan = sgs.General(extension, "nyarz_zhongyan", "jin", 3, false, false, false)

local function chsize(tmp)
	if not tmp then
		return 0
    elseif tmp > 240 then
        return 4
    elseif tmp > 225 then
        return 3
    elseif tmp > 192 then
        return 2
    else
        return 1
    end
end

local function utf8len(str)
	local length = 0
	local currentIndex = 1
	while currentIndex <= #str do
		local tmp = string.byte(str, currentIndex)
		currentIndex  = currentIndex + chsize(tmp)
		length = length + 1
	end
	return length
end

nyarz_xiaoyong = sgs.CreateTriggerSkill{
    name = "nyarz_xiaoyong",
    events = {sgs.CardFinished,sgs.EventPhaseEnd},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            if player:isDead() then return false end
            if (not player:hasSkill(self:objectName())) then return false end
            if player:getMark("nyarz_xiaoyong") > 0 then return false end
            local use = data:toCardUse()
            if use.card:isKindOf("SkillCard") then return false end
            local num = utf8len(sgs.Sanguosha:translate(use.card:objectName()))
            if use.card:isKindOf("Slash") then num = 1 end
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("view:"..num)) then
                room:broadcastSkillInvoke(self:objectName())
                room:setPlayerMark(player, "nyarz_xiaoyong", 1)
                local card_ids = room:getNCards(num)
                room:askForGuanxing(player, card_ids)
            end
        end
        if event == sgs.EventPhaseEnd then
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerMark(p, "nyarz_xiaoyong", 0)
            end
        end

    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyarz_guanguVS = sgs.CreateViewAsSkill
{
    name = "nyarz_guangu",
    n = 99,
    expand_pile = "#nyarz_guangu",
    response_pattern = "@@nyarz_guangu",
    view_filter = function(self, selected, to_select)
        if (not sgs.Self:hasFlag("nyarz_guangu")) then return false end
        return sgs.Self:getPile("#nyarz_guangu"):contains(to_select:getEffectiveId())
        and #selected < 1 and to_select:isAvailable(sgs.Self)
    end,
    view_as = function(self, cards)
        if (not sgs.Self:hasFlag("nyarz_guangu")) then 
            return nyarz_guanguCard:clone() 
        else
            if #cards == 1 then
                local card = nyarz_guangu_useCard:clone()
                card:addSubcard(cards[1])
                return card
            end
        end
    end,
    enabled_at_play = function(self, player)
        return (player:getMark("&nyarz_guangu") == 0)
    end
}

nyarz_guanguCard = sgs.CreateSkillCard
{
    name = "nyarz_guangu",
    filter = function(self, targets, to_select)
        return (not to_select:isKongcheng())
        and #targets < 1 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    feasible = function(self, targets, player)
        return true
    end,
    on_use = function(self, room, player, targets)
        player:removeTag("nyarz_guangu_to")
        player:removeTag("nyarz_guangu")
        if #targets > 0 then
            local target = targets[1]
            local max = math.min(4, target:getHandcardNum())
            local choice = {}
            for i = 1, max, 1 do
                table.insert(choice, i)
            end

            local data = sgs.QVariant()
            data:setValue(target)
            player:setTag("nyarz_guangu", data)

            local n = tonumber(room:askForChoice(player, self:objectName(), table.concat(choice, "+"), sgs.QVariant()))
            room:setPlayerMark(player, "&nyarz_guangu", n)
            local card_ids = sgs.IntList()
            local cards = sgs.QList2Table(target:getHandcards())
            for i = 1, n, 1 do
                local card = cards[math.random(1,#cards)]
                card_ids:append(card:getEffectiveId())
                table.removeOne(cards, card)
            end
            room:setPlayerFlag(player, "nyarz_guangu")
            room:notifyMoveToPile(player, card_ids, "nyarz_guangu", sgs.Player_PlaceHand, true)
            local use_card = room:askForUseCard(player, "@@nyarz_guangu", "@nyarz_guangu-use")
            room:notifyMoveToPile(player, card_ids, "nyarz_guangu", sgs.Player_PlaceHand, false)
            room:setPlayerFlag(player, "-nyarz_guangu")

            if (not use_card) then return false end
            local real_card = sgs.Sanguosha:getCard(use_card:getSubcards():at(0))
            local to = sgs.SPlayerList()
            local tos = player:getTag("nyarz_guangu_to"):toString():split("+")
            for _,p in ipairs(tos) do
                local tt = room:findPlayerByObjectName(p)
                to:append(tt)
            end
            room:useCard(sgs.CardUseStruct(real_card, player, to))
        else
            local max = math.min(4, room:getDrawPile():length())
            local choice = {}
            for i = 1, max, 1 do
                table.insert(choice, i)
            end
            local n = tonumber(room:askForChoice(player, self:objectName(), table.concat(choice, "+"), sgs.QVariant()))
            room:setPlayerMark(player, "&nyarz_guangu", n)
            local card_ids = sgs.IntList()
            for _,id in sgs.qlist(room:getDrawPile()) do
                card_ids:append(id)
                n = n - 1
                if n <= 0 then break end
            end
            local log = sgs.LogMessage()
            log.type = "$ViewDrawPile"
            log.from = player
            log.card_str = table.concat(sgs.QList2Table(card_ids), "+")
            room:sendLog(log, player)

            room:setPlayerFlag(player, "nyarz_guangu")
            room:notifyMoveToPile(player, card_ids, "nyarz_guangu", sgs.Player_DrawPile, true)
            local use_card = room:askForUseCard(player, "@@nyarz_guangu", "@nyarz_guangu-use")
            room:notifyMoveToPile(player, card_ids, "nyarz_guangu", sgs.Player_DrawPile, false)
            room:setPlayerFlag(player, "-nyarz_guangu")

            if (not use_card) then return false end
            local real_card = sgs.Sanguosha:getCard(use_card:getSubcards():at(0))
            local to = sgs.SPlayerList()
            local tos = player:getTag("nyarz_guangu_to"):toString():split("+")
            for _,p in ipairs(tos) do
                local tt = room:findPlayerByObjectName(p)
                to:append(tt)
            end
            room:useCard(sgs.CardUseStruct(real_card, player, to))
        end
    end
}

nyarz_guangu_useCard = sgs.CreateSkillCard
{
    name = "nyarz_guangu_use",
    will_throw = false,
    filter = function(self, targets, to_select, player) 
        local card = self:getSubcards():first()
        card = sgs.Sanguosha:getCard(card)
		if card and card:targetFixed() then
			return false
		end

        local target = sgs.Self

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:targetFilter(qtargets, to_select, target) and not target:isProhibited(to_select, card, qtargets) then
            return true
        end
        return false 
	end,
    target_fixed = function(self)		
		local card = self:getSubcards():first()
        card = sgs.Sanguosha:getCard(card)
        if card and card:targetFixed() then
            return true
        end
        return false
	end,
	feasible = function(self, targets)	
		local card = self:getSubcards():first()
        card = sgs.Sanguosha:getCard(card)

        local target = sgs.Self

		local qtargets = sgs.PlayerList()
		for _,p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:targetsFeasible(qtargets, target) then
            return true
        end
        return false
	end,
    about_to_use = function(self,room,use)
        room:broadcastSkillInvoke(self:objectName())
        local source = use.from
        local tos = {}
        for _,to in sgs.qlist(use.to) do
            table.insert(tos, to:objectName())
        end
        source:setTag("nyarz_guangu_to", sgs.QVariant(table.concat(tos, "+")))
    end,
}

nyarz_guangu = sgs.CreateTriggerSkill{
    name = "nyarz_guangu",
    events = {sgs.Damaged,sgs.CardUsed,sgs.EventPhaseEnd},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = nyarz_guanguVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damaged then
            if player:isDead() then return false end
            if (not player:hasSkill(self:objectName())) then return false end
            if player:getMark("&nyarz_guangu") > 0 then return false end
            room:askForUseCard(player, "@@nyarz_guangu", "@nyarz_guangu-damaged")
        end
        if event == sgs.CardUsed then
            if player:isDead() then return false end
            if (not player:hasSkill(self:objectName())) then return false end
            local use = data:toCardUse()
            if use.card:isKindOf("SkillCard") then return false end
            local num = utf8len(sgs.Sanguosha:translate(use.card:objectName()))
            if use.card:isKindOf("Slash") then num = 1 end
            if num == player:getMark("&nyarz_guangu") then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true)
                room:setPlayerMark(player, "&nyarz_guangu", 0)
            end
        end
        if event == sgs.EventPhaseEnd then
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerMark(p, "&nyarz_guangu", 0)
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyarz_zhongyan:addSkill(nyarz_xiaoyong)
nyarz_zhongyan:addSkill(nyarz_guangu)
nyarz_zhongyan:addSkill(nyarz_guanguVS)

nyarz_caoying = sgs.General(extension, "nyarz_caoying", "wei", 4, false, false, false)

nyarz_fujian = sgs.CreateTriggerSkill{
    name = "nyarz_fujian",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:getTag("FirstRound"):toBool() then return false end
        local move = data:toMoveOneTime()
        if move.to and move.to:objectName() ~= player:objectName()
        and move.to_place == sgs.Player_PlaceHand then
            local target = room:findPlayerByObjectName(move.to:objectName())
            if target:getPhase() ~= sgs.Player_Draw then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
                --room:showCard(target, move.card_ids, player)

                local log = sgs.LogMessage()
                log.type = "$nyarz_lingren_view"
                log.from = player
                log.to:append(target)
                log.card_str = table.concat(sgs.QList2Table(move.card_ids), "+")
                room:sendLog(log, player)

                room:fillAG(move.card_ids, player)
                room:askForAG(player, sgs.IntList(), true, self:objectName(), "@nyarz_fujian:"..target:getGeneralName())
                room:clearAG(player)
                local draw = true
                for _,id in sgs.qlist(move.card_ids) do
                    local card = sgs.Sanguosha:getCard(id)
                    if player:getMark("nyarz_fujian_"..card:getTypeId().."-Clear") == 0 then
                        room:setPlayerMark(player, "nyarz_fujian_"..card:getTypeId().."-Clear", 1)
                        if draw then
                            player:drawCards(1, self:objectName())
                            draw = false
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_lingren = sgs.CreateTriggerSkill{
    name = "nyarz_lingren",
    events = {sgs.TargetConfirmed,sgs.CardFinished,sgs.DamageCaused},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if (use.card:isKindOf("BasicCard") or use.card:isNDTrick())
            and use.card:isDamageCard() and (use.from:objectName() == player:objectName())
            and player:getMark("nyarz_lingren-Clear") < 2 then
                local target = room:askForPlayerChosen(player, use.to, self:objectName(), "@nyarz_lingren:"..use.card:objectName(), true, true)
                if target then
                    room:addPlayerMark(player, "nyarz_lingren-Clear", 1)
                    room:broadcastSkillInvoke(self:objectName())
                    local first, second
                    if player:getHandcardNum() >= target:getHandcardNum() then
                        first = true
                        player:drawCards(2, self:objectName())
                    else first = false end
                    if player:getHp() >= target:getHp() then
                        second = true
                        room:setCardFlag(use.card, "nyarz_lingren+"..target:objectName())
                    else second = false end
                    if (first and second) or ((not first) and (not second)) then
                        local log = sgs.LogMessage()
                        log.type = "$nyarz_lingren_no_respond"
                        log.from = target
                        log.card_str = use.card:toString()
                        room:sendLog(log)

                        room:setCardFlag(use.card, "nyarz_lingren")

                        local no_respond_list = use.no_respond_list
                        table.insert(no_respond_list, target:objectName())
                        use.no_respond_list = no_respond_list
                        data:setValue(use)
                    end
                end
            end
        end
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("nyarz_lingren+"..damage.to:objectName()) then
                room:sendLog(CreateDamageLog(damage, 1, self:objectName(), true))
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:hasFlag("nyarz_lingren")
            and room:getCardPlace(use.card:getEffectiveId()) == sgs.Player_DiscardPile then
                room:obtainCard(player, use.card, true)
            end
        end

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_caoying:addSkill(nyarz_fujian)
nyarz_caoying:addSkill(nyarz_lingren)

nyarz_caoxian = sgs.General(extension, "nyarz_caoxian", "wei", 3, false, false, false)

nyarz_lingxi = sgs.CreateTriggerSkill{
    name = "nyarz_lingxi",
    events = {sgs.CardFinished},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if player:isDead() then return false end
        if (not use.card) or use.card:isKindOf("SkillCard") then return false end
        if use.card:isKindOf("DelayedTrick") then return false end
        local put = sgs.IntList()
        if (use.card:getSkillName() ~= "") then
            for _,id in sgs.qlist(use.card:getSubcards()) do
                if room:getCardPlace(id) ~= sgs.Player_PlaceHand then
                    put:append(id)
                end
            end
        else
            if room:getCardPlace(use.card:getEffectiveId()) ~= sgs.Player_PlaceHand then
                put:append(use.card:getEffectiveId())
            end
        end
        if put:isEmpty() then return false end
        player:setTag("nyarz_lingxi_use", data)
        local prompt = "put:"..use.card:objectName()
        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
            room:broadcastSkillInvoke(self:objectName())
            player:addToPile("nyarz_lingxi_yi", put)
            if player:isDead() then return false end
            local card = sgs.Sanguosha:getCard(player:getPile("nyarz_lingxi_yi"):at(0))
            local mark = string.format("&nyarz_lingxi+%s+%s_char+%s",card:objectName(), card:getSuitString(), card:getNumber())
            room:setPlayerMark(player, mark, 1)
            if player:getPile("nyarz_lingxi_yi"):length() > 4 then
                room:setPlayerMark(player, mark, 0)
                local discard = sgs.IntList()
                local n = player:getPile("nyarz_lingxi_yi"):length() - 4

                card = sgs.Sanguosha:getCard(player:getPile("nyarz_lingxi_yi"):at(n))
                mark = string.format("&nyarz_lingxi+%s+%s_char+%s",card:objectName(), card:getSuitString(), card:getNumber())
                room:setPlayerMark(player, mark, 1)

                for _,id in sgs.qlist(player:getPile("nyarz_lingxi_yi")) do
                    discard:append(id)
                    n = n - 1
                    if n <= 0 then break end
                end

                local log = sgs.LogMessage()
                log.type = "$EnterDiscardPile"
                log.card_str = table.concat(sgs.QList2Table(discard), "+")
                room:sendLog(log)

                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
                local move = sgs.CardsMoveStruct(discard, nil, sgs.Player_DiscardPile, reason)
                room:moveCardsAtomic(move, true)
            end
            if player:isDead() then return false end
            local suits = {}
            for _,id in sgs.qlist(player:getPile("nyarz_lingxi_yi")) do
                local suit = sgs.Sanguosha:getCard(id):getSuitString()
                if (not table.contains(suits, suit)) then
                    table.insert(suits, suit)
                end
            end
            local n = 2*(#suits)
            if player:getHandcardNum() < n then
                player:drawCards(n - player:getHandcardNum(), self:objectName())
            else
                if player:getHandcardNum() > n then
                    local dis = player:getHandcardNum() - n
                    room:askForDiscard(player, self:objectName(), dis, dis, false, false)
                    local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@nyarz_lingxi", true, true)
                    if target then
                        if target:isNude() then
                            room:loseHp(target, 1, true, player, self:objectName())
                        else
                            room:askForDiscard(target, self:objectName(), 2, 2, false, true)
                        end
                    end
                end
            end
        end
                            
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_zhifouVS = sgs.CreateZeroCardViewAsSkill
{
    name = "nyarz_zhifou",
    view_as = function(self)
        return nyarz_zhifouCard:clone()
    end,
    enabled_at_play = function(self, player)
        return (not player:isKongcheng()) and (player:getMark("nyarz_zhifou-Clear") == 0)
    end,
    enabled_at_response = function(self, player, pattern)
        if string.find(pattern, "peach") or string.find(pattern, "Peach") then
            return (not player:isKongcheng()) and (player:getMark("nyarz_zhifou-Clear") == 0)
        end
        return false 
    end
}

nyarz_zhifouCard = sgs.CreateSkillCard
{
    name = "nyarz_zhifou",
    will_throw = false,
    filter = function(self, targets, to_select)
        local pattern = "peach"

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_zhifou")
        for _,cc in sgs.qlist(sgs.Self:getHandcards()) do
            card:addSubcard(cc)
        end
        card:deleteLater()

		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets)
		local pattern = "peach"

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("nyarz_zhifou")
        for _,cc in sgs.qlist(sgs.Self:getHandcards()) do
            card:addSubcard(cc)
        end
        card:deleteLater()

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end

        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
        and (not card:isAvailable(sgs.Self)) then return false end

		return card and card:targetsFeasible(qtargets, sgs.Self) --and card:isAvailable(sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
        local room = player:getRoom()

        local pattern = "peach"
        room:setPlayerMark(player, "nyarz_zhifou-Clear", 1)

        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
        for _,cc in sgs.qlist(player:getHandcards()) do
            card:addSubcard(cc)
        end

		return card
	end,
    on_validate_in_response = function(self, player)
        local room = player:getRoom()

        local pattern = "peach"
        room:setPlayerMark(player, "nyarz_zhifou-Clear", 1)

        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
        for _,cc in sgs.qlist(player:getHandcards()) do
            card:addSubcard(cc)
        end

        return card
    end
}

nyarz_zhifou = sgs.CreateTriggerSkill{
    name = "nyarz_zhifou",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = nyarz_zhifouVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local move = data:toMoveOneTime()
        if move.from and move.from_places:contains(sgs.Player_PlaceHand) and move.is_last_handcard then
            local target = room:findPlayerByObjectName(move.from:objectName())
            if target and target:isAlive() and target:getPhase() == sgs.Player_NotActive then
                local _data = sgs.QVariant()
                _data:setValue(target)
                if room:askForSkillInvoke(player, self:objectName(), _data) then
                    room:broadcastSkillInvoke(self:objectName())
                    room:setPlayerMark(player, "nyarz_zhifou-Clear", 1)
                    local suits = {}
                    local get = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
                    for _,id in sgs.qlist(room:getDrawPile()) do
                        local card = sgs.Sanguosha:getCard(id)
                        local suit = card:getSuitString()
                        if (not table.contains(suits, suit)) then
                            table.insert(suits, suit)
                            get:addSubcard(card)
                        end
                    end
                    if #suits > 0 then
                        room:obtainCard(target, get, false)
                    end
                    get:deleteLater()
                end
            end
        end           
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:getMark("nyarz_zhifou-Clear") == 0
    end,
}

nyarz_caoxian:addSkill(nyarz_lingxi)
nyarz_caoxian:addSkill(nyarz_zhifou)
nyarz_caoxian:addSkill(nyarz_zhifouVS)

nyarz_xvelingyun = sgs.General(extension, "nyarz_xvelingyun", "wei", 3, false, false, false)

nyarz_xialei = sgs.CreateTriggerSkill{
    name = "nyarz_xialei",
    events = {sgs.EventPhaseStart,sgs.CardsMoveOneTime},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getMark("nyarz_xialei-Clear") > 0 then return false end
            if player:getPhase() ~= sgs.Player_Start then return false end
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                room:setPlayerMark(player, "nyarz_xialei-Clear", 1)
                local card_ids = room:getNCards(3)
                room:askForGuanxing(player, card_ids)
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw"), false) then
                    player:drawCards(1, self:objectName())
                end
            end
        end
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
            and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then
                local red = false
                for _,id in sgs.qlist(move.card_ids) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card:isRed() then 
                        red = true
                        if player:getMark("nyarz_xialei-Clear") > 0 then
                            room:setPlayerMark(player, "nyarz_xialei-Clear", 0)
                            return false
                        end
                        break
                    end
                end
                if player:getMark("nyarz_xialei-Clear") == 0 then
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        room:broadcastSkillInvoke(self:objectName())
                        if (not red) then room:setPlayerMark(player, "nyarz_xialei-Clear", 1) end
                        local card_ids = room:getNCards(3)
                        room:askForGuanxing(player, card_ids)
                        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw"), false) then
                            player:drawCards(1, self:objectName())
                        end
                    end
                end
            end
        end

    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_anzhiVS = sgs.CreateViewAsSkill
{
    name = "nyarz_anzhi",
    response_pattern = "@@nyarz_anzhi",
    n = 99,
    expand_pile = "#nyarz_anzhi",
    view_filter = function(self, selected, to_select)
        if sgs.Self:getMark("nyarz_anzhi") == 0 then return false end
        if sgs.Self:getMark("nyarz_anzhi") == 1 then
            return sgs.Self:getPile("#nyarz_anzhi"):contains(to_select:getEffectiveId())
        end
        if sgs.Self:getMark("nyarz_anzhi") == 2 then
            return sgs.Self:getPile("#nyarz_anzhi"):contains(to_select:getEffectiveId())
            and (#selected < 1)
        end
    end,
    view_as = function(self, cards)
        if sgs.Self:getMark("nyarz_anzhi") == 0 then return nyarz_anzhiCard:clone() end
        if sgs.Self:getMark("nyarz_anzhi") == 1 then
            if #cards > 0 then
                local card = nyarz_anzhi_disCard:clone()
                for _,cc in ipairs(cards) do
                    card:addSubcard(cc)
                end
                return
                card
            end
        end
        if sgs.Self:getMark("nyarz_anzhi") == 2 then
            if #cards == 1 then
                local card = nyarz_anzhi_giveCard:clone()
                for _,cc in ipairs(cards) do
                    card:addSubcard(cc)
                end
                return
                card
            end
        end
    end,
    enabled_at_play = function(self, player)
        return player:getMark("nyarz_anzhi_disable-Clear") == 0
    end
}

nyarz_anzhiCard = sgs.CreateSkillCard
{
    name = "nyarz_anzhi",
    target_fixed = true,
    on_use = function(self, room, player, targets)
        local room = player:getRoom()
        local ids = room:getNCards(3, true, false)
        room:returnToEndDrawPile(ids)

        room:setPlayerMark(player, "nyarz_anzhi", 1)
        room:notifyMoveToPile(player, ids, "nyarz_anzhi", sgs.Player_DrawPile, true)
        local first = room:askForUseCard(player, "@@nyarz_anzhi", "@nyarz_anzhi-discard")
        room:notifyMoveToPile(player, ids, "nyarz_anzhi", sgs.Player_DrawPile, false)

        if (not first) then 
            room:setPlayerMark(player, "nyarz_anzhi_disable-Clear", 1) 
            return false
        end

        if first then
            local log = sgs.LogMessage()
            log.type = "$DiscardCard"
            log.from = player
            log.card_str = table.concat(sgs.QList2Table(first:getSubcards()), "+")
            room:sendLog(log)

            local disable = true
            for _,id in sgs.qlist(first:getSubcards()) do
                local card = sgs.Sanguosha:getCard(id)
                local mark = string.format("@nyarz_anzhi_%s-Clear", card:getSuitString())
                if player:getMark(mark) == 0 then
                    disable = false
                end
                room:setPlayerMark(player, mark, 1)
            end
            if disable then
                room:setPlayerMark(player, "nyarz_anzhi_disable-Clear", 1) 
            end

            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
            local move = sgs.CardsMoveStruct(first:getSubcards(), nil, sgs.Player_DiscardPile, reason)
            room:moveCardsAtomic(move, true)
        end
        
        local card_ids = sgs.IntList()
        local list = room:getTag("nyarz_anzhi"):toIntList()
        if (not ids) or (ids:isEmpty()) then return false end
        for _,id in sgs.qlist(room:getDiscardPile()) do
            if list:contains(id) then
                card_ids:append(id)
            end
        end
        if card_ids:isEmpty() then return false end

        room:setPlayerMark(player, "nyarz_anzhi", 2)
        room:notifyMoveToPile(player, card_ids, "nyarz_anzhi", sgs.Player_DiscardPile, true)
        local second = room:askForUseCard(player, "@@nyarz_anzhi", "@nyarz_anzhi-give")
        room:notifyMoveToPile(player, card_ids, "nyarz_anzhi", sgs.Player_DiscardPile, false)
        
        room:setPlayerMark(player, "nyarz_anzhi", 0)
        if second then
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasFlag("nyarz_anzhi_target") then
                    room:setPlayerFlag(p, "-nyarz_anzhi_target")
                    room:obtainCard(p, second:getSubcards():at(0))
                    break
                end
            end
        end
    end

}

nyarz_anzhi_disCard = sgs.CreateSkillCard
{
    name = "nyarz_anzhi_dis",
    target_fixed = true,
    about_to_use = function(self,room,use)
        return
    end
}

nyarz_anzhi_giveCard = sgs.CreateSkillCard
{
    name = "nyarz_anzhi_give",
    filter = function(self, targets, to_select)
        return #targets < 1
    end,
    about_to_use = function(self,room,use)
        room:setPlayerFlag(use.to:at(0), "nyarz_anzhi_target")
        return
    end
}

nyarz_anzhi = sgs.CreateTriggerSkill{
    name = "nyarz_anzhi",
    events = {sgs.Damaged},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = nyarz_anzhiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getMark("nyarz_anzhi_disable-Clear") == 0 then
            room:setPlayerMark(player, "nyarz_anzhi", 0)
            room:askForUseCard(player, "@@nyarz_anzhi", "@nyarz_anzhi-view")
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:isAlive()
    end,
}

nyarz_anzhi_record = sgs.CreateTriggerSkill{
    name = "#nyarz_anzhi_record",
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            if (not player:hasSkill(self:objectName())) then return false end
            local move = data:toMoveOneTime()
            if move.to_place ~= sgs.Player_DiscardPile then return false end
            local ids = room:getTag("nyarz_anzhi"):toIntList()
            if (not ids) or (ids:isEmpty()) then ids = sgs.IntList() end
            for _,id in sgs.qlist(move.card_ids) do
                if (not ids:contains(id)) then
                    ids:append(id)
                end
            end
            local tag = sgs.QVariant()
            tag:setValue(ids)
            room:setTag("nyarz_anzhi", tag)
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_NotActive then return false end
            room:removeTag("nyarz_anzhi")
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyarz_xvelingyun:addSkill(nyarz_xialei)
nyarz_xvelingyun:addSkill(nyarz_anzhi)
nyarz_xvelingyun:addSkill(nyarz_anzhiVS)
nyarz_xvelingyun:addSkill(nyarz_anzhi_record)
extension:insertRelatedSkills("nyarz_anzhi", "#nyarz_anzhi_record")

nyarz_luyi = sgs.General(extension, "nyarz_luyi", "qun", 3, false, false, false)

nyarz_fuxve = sgs.CreateTriggerSkill{
    name = "nyarz_fuxve",
    events = {sgs.CardUsed,sgs.CardResponded,sgs.CardsMoveOneTime,sgs.EventPhaseEnd,sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardUsed or event == sgs.CardResponded then
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                local response = data:toCardResponse()
                if response.m_isUse then
                    card = response.m_card
                end
            end
            if (not card) or (card:isKindOf("SkillCard")) then return false end
            local mark = string.format("nyarz_fuxve_%s-SelfClear", card:objectName())
            if card:isKindOf("Slash") then
                mark = string.format("nyarz_fuxve_%s-SelfClear", "Slash")
            end
            if player:getMark(mark) == 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true)
                local flag = string.format("nyarz_yaoyi_%s", player:objectName())
                if not card:hasFlag(flag) then
                    room:broadcastSkillInvoke(self:objectName())
                end
                room:setPlayerMark(player, mark, 1)
            end
        end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Play then
                player:removeTag("nyarz_fuxve")
            end
            if change.to == sgs.Player_Discard then
                for _,card in sgs.qlist(player:getHandcards()) do
                    local mark = string.format("nyarz_fuxve_%s-SelfClear", card:objectName())
                    if card:isKindOf("Slash") then
                        mark = string.format("nyarz_fuxve_%s-SelfClear", "Slash")
                    end
                    if player:getMark(mark) > 0 then
                        room:ignoreCards(player, card) 
                    end
                end
            end
        end
        if event == sgs.CardsMoveOneTime then
            if player:getPhase() ~= sgs.Player_Play then return false end
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
            and (move.from_places:contains(sgs.Player_PlaceHand)
            or move.from_places:contains(sgs.Player_PlaceEquip)) then
                local tag = player:getTag("nyarz_fuxve"):toIntList()
                if (not tag) or (tag:isEmpty()) then
                    tag = sgs.IntList()
                end
                for _,id in sgs.qlist(move.card_ids) do
                    if (not tag:contains(id)) then
                        tag:append(id)
                    end
                end
                local new = sgs.QVariant()
                new:setValue(tag)
                player:setTag("nyarz_fuxve", new)
            end
        end
        if event == sgs.EventPhaseEnd then
            if player:getPhase() ~= sgs.Player_Play then return false end
            local tag = player:getTag("nyarz_fuxve"):toIntList()
            if (not tag) or (tag:isEmpty()) then return false end
            local get = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
            for _,id in sgs.qlist(room:getDiscardPile()) do
                if tag:contains(id) then
                    get:addSubcard(sgs.Sanguosha:getCard(id))
                end
            end
            if get:subcardsLength() > 0 then
                if room:askForSkillInvoke(player, self:objectName()) then
                    room:broadcastSkillInvoke(self:objectName())
                    room:obtainCard(player, get)
                end
            end
            get:deleteLater()
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

nyarz_yaoyiVS = sgs.CreateViewAsSkill
{
    name = "nyarz_yaoyi",
    n = 99,
    response_pattern = "@@nyarz_yaoyi",
    view_filter = function(self, selected, to_select)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            return #selected < 1 and to_select:isAvailable(sgs.Self) and sgs.Self:getHandcards():contains(to_select)
        end
        return false
    end,
    view_as = function(self, cards)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            if #cards == 1 then
                return cards[1]
            end
            return nil
        end
        return nyarz_yaoyiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return true
    end
}

nyarz_yaoyiCard = sgs.CreateSkillCard
{
    name = "nyarz_yaoyi",
    mute = true,
    target_fixed = true,
    about_to_use = function(self,room,use)
        local player = use.from
        room:setPlayerFlag(player, "nyarz_yaoyi")
        local prompt = string.format("@nyarz_yaoyi-use:%s", player:getGeneralName())
        local flag = string.format("nyarz_yaoyi_%s", player:objectName())
        if room:askForUseCard(player, "@@nyarz_yaoyi", prompt, -1, sgs.Card_MethodUse, false, player, nil, flag) then
            room:setPlayerFlag(player, "-nyarz_yaoyi")
            room:setPlayerMark(player, "nyarz_yaoyi_failed-PlayClear", 0)
            if player:isAlive() then
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@nyarz_yaoyi-target", false, true)
                room:setPlayerFlag(target, "nyarz_yaoyi")
                room:askForUseCard(target, "@@nyarz_yaoyi", prompt, -1, sgs.Card_MethodUse, false, player, nil, flag)
                room:setPlayerFlag(target, "-nyarz_yaoyi")
            end
        else
            room:setPlayerFlag(player, "-nyarz_yaoyi")
            room:setPlayerMark(player, "nyarz_yaoyi_failed-PlayClear", 1)
        end
    end
}

nyarz_yaoyi = sgs.CreateTriggerSkill{
    name = "nyarz_yaoyi",
    events = {sgs.PreCardUsed,sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = nyarz_yaoyiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.PreCardUsed then
            if player:hasFlag("nyarz_yaoyi") then
                room:setPlayerFlag(player, "-nyarz_yaoyi")
                if player:getPhase() == sgs.Player_Play then
                    local log = sgs.LogMessage()
                    log.type = "#InvokeSkill"
                    log.from = player
                    log.arg = self:objectName()
                    room:sendLog(log)
                    room:broadcastSkillInvoke(self:objectName())
                end
            end
        end
        if event == sgs.TargetConfirmed then
            if (not player:hasSkill(self:objectName())) then return false end
            local use = data:toCardUse()
            if (not use.card) or (use.card:isKindOf("SkillCard")) then return false end
            local flag = string.format("nyarz_yaoyi_%s", player:objectName())
            if use.to:contains(player) and use.card:hasFlag(flag) then
                room:sendCompulsoryTriggerLog(player, self:objectName(), true)
                player:drawCards(1, self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

nyarz_yaoyi_buff = sgs.CreateTargetModSkill{
    name = "#nyarz_yaoyi_buff",
    pattern = ".",
    residue_func = function(self, from, card)
        if from:hasFlag("nyarz_yaoyi") then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card)
        if from:hasFlag("nyarz_yaoyi") then return 1000 end
        return 0
    end,
}

nyarz_luyi:addSkill(nyarz_fuxve)
nyarz_luyi:addSkill(nyarz_yaoyi)
nyarz_luyi:addSkill(nyarz_yaoyiVS)
nyarz_luyi:addSkill(nyarz_yaoyi_buff)
extension:insertRelatedSkills("nyarz_yaoyi", "#nyarz_yaoyi_buff")

local skills = sgs.SkillList()

if not sgs.Sanguosha:getSkill("nyjinghong") then skills:append(nyjinghong) end
if not sgs.Sanguosha:getSkill("nybeauty_winmusic") then skills:append(nybeauty_winmusic) end
if not sgs.Sanguosha:getSkill("nyxili") then skills:append(nyxili) end
if not sgs.Sanguosha:getSkill("#nyxili_buff") then skills:append(nyxili_buff) end
if not sgs.Sanguosha:getSkill("nyzhennan") then skills:append(nyzhennan) end
if not sgs.Sanguosha:getSkill("#nyzhennan_damage") then skills:append(nyzhennan_damage) end
if not sgs.Sanguosha:getSkill("#nyzhennan_more") then skills:append(nyzhennan_more) end
if not sgs.Sanguosha:getSkill("stabs_slash_on_trigger") then skills:append(stabs_slash_on_trigger) end

sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable 
{
    ["nybeauty"] = "群阴荟萃·绝代佳人",
    

--曹金玉
    ["nycaojinyu"] = "群阴·曹金玉",
    ["&nycaojinyu"] = "曹金玉",
    ["#nycaojinyu"] = "惊鸿倩影",
    ["designer:nycaojinyu"] = "Nyarz",

    ["nyyuqi"] = "隅泣",
    [":nyyuqi"] = "出牌阶段，你可以观看牌堆顶的X张牌（X为你的体力上限），然后你可以使用其中一张牌。\
    ①若你未使用牌，此技能于本阶段内失效。\
    ②若你使用了牌且造成了伤害，本阶段内此技能观看数量-1。",
    ["@nyyuqi"] = "你可以使用其中一张牌",
    ["#nyyuqi"] = "隅泣",
    ["$nyyuqiview"] = "%from 发动 %arg2 观看了牌堆顶的 %arg 张牌。",
    ["$nyyuqiselfview"] = "牌堆顶的 %arg 张牌为 %card。",
    ["nyshanshen"] = "善身",
    [":nyshanshen"] = "每轮限一次，一名角色处于濒死状态时，你可以令其回复一点体力。若该角色为你，你本回合不能成为【杀】或锦囊牌的目标。",
    ["nyshanshen:dying"] = "你可以发动“善身”令 %src 回复一点体力",
    ["nyxianjing"] = "娴静",
    [":nyxianjing"] = "出牌阶段开始时，你可以观看牌堆顶的3张牌并以任意顺序放回牌堆顶或牌堆底。若你未受伤，改为观看5张。",
    ["nyxianjing:view"] = "你可以发动“娴静”观看牌堆顶的%src张牌并以任意顺序放回牌堆顶或牌堆底",

    ["$nyyuqi1"] = "隅泣",
    ["$nyyuqi2"] = "隅泣",
    ["$nyshanshen1"] = "善身",
    ["$nyshanshen2"] = "善身",
    ["$nyxianjing1"] = "娴静",
    ["$nyxianjing2"] = "娴静",
    ["~nycaojinyu"] = "群阴·曹金玉",

--孙寒华
    ["nyshunhanhua"] = "群阴·孙寒华",
    ["&nyshunhanhua"] = "孙寒华",
    ["#nyshunhanhua"] = "莲华熠熠",
    ["designer:nyshunhanhua"] = "Nyarz",

    ["nymiaojian"] = "妙剑",
    [":nymiaojian"] = "出牌阶段限一次，你可以视为使用了一张无距离和次数限制的【刺杀】。若此牌造成了伤害，令目标交给你一张牌。",
    ["@nymiaojian"] = "请交给 %src 一张牌",
    ["nylianhua"] = "莲华",
    [":nylianhua"] = "每轮限一次，当你处于濒死状态时，你可以将体力值回复至体力上限，将手牌摸至体力上限。本轮游戏中，你受到的伤害+1。",
    ["nylianhua:dying"] = "你可以发动“莲华”回复%src点体力并摸%arg张牌",
    ["$nylianhuadaup"] = "%from 受到的伤害因 %arg 由 %arg2 点增加到 %arg3 点。",
    ["nychongxu"] = "冲虚",
    [":nychongxu"] = "锁定技，在你造成的伤害令一名其他角色进入濒死状态后，令其跳过濒死结算，然后你加一点体力上限。",
    ["$nychongxukill"] = "%arg 击杀了 %arg2 , %arg2 因 %arg3 的效果无力回天。",

    ["$nymiaojian1"] = "妙剑",
    ["$nymiaojian2"] = "妙剑",
    ["$nylianhua1"] = "莲华",
    ["$nylianhua2"] = "莲华",
    ["$nychongxu1"] = "冲虚",
    ["$nychongxu2"] = "冲虚",
    ["~nyshunhanhua"] = "群阴·孙寒华",

    ["_stabs_slash"] = "刺杀",
    [":_stabs_slash"] = "基本牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：攻击范围内的一名其他角色<br /><b>效果</b>：对目标角色造成1点伤害。<br /><br /><b>额外效果</b>：目标使用【闪】抵消此【刺杀】时，其需弃置一张手牌，否则此【刺杀】依旧造成伤害。",
    ["_stabs_slash0"] = "刺杀:请弃置一张手牌，否则此【刺杀】依旧造成伤害",


--大乔
    ["nydaqiao"] = "群阴·大乔",
    ["&nydaqiao"] = "大乔",
    ["#nydaqiao"] = "清萧清丽",
    ["designer:nydaqiao"] = "Nyarz",

    ["nyguose"] = "国色",
    [":nyguose"] = "出牌阶段，你可以与一名其他角色拼点，若你赢，你获得对方拼点牌并选择一项：\
    ①获得对方判定区的一张牌；\
    ②将你的拼点牌当作【乐不思蜀】置入对方判定区。\
    选择完成后，你此阶段内不能再对该角色发动【国色】。",
    ["nyguose:get"] = "获得 %src 判定区的一张牌",
    ["nyguose:give"] = "将你的拼点牌当作【乐不思蜀】置入 %src 判定区",
    ["nyliuli"] = "流离",
    [":nyliuli"] = "当你成为【杀】或【决斗】的目标时，你可以\
    ①令其他角色依次选择是否代替你成为此牌目标并与你各摸一张牌。若无人响应，你摸两张牌然后你本回合不能再发动此效果。\
    ②每回合限一次，你可以获得你判定区内的一张牌。",
    ["nyliuli:replace"] = "代替%src成为【%arg】的目标并与其各摸一张牌",
    ["nyliuli:tran"] = "你可以发动“流离”令其他角色选择是否与你各摸一张牌并代替你成为【%src】的目标",
    ["nyliuli:get"] = "你可以发动“流离”获得你判定区的一张牌",
    ["$nyliulireplace"] = "%arg 代替 %arg2 成为了 %card 的目标。",

    ["$nyguose1"] = "国色",
    ["$nyguose2"] = "国色",
    ["$nyliuli1"] = "流离",
    ["$nyliuli2"] = "流离",
    ["~nydaqiao"] = "群阴·大乔",

--张嫙
    ["nyzhangxuan"] = "群阴·张嫙",
    ["&nyzhangxuan"] = "张嫙",
    ["#nyzhangxuan"] = "涟漪夏梦",
    ["designer:nyzhangxuan"] = "Nyarz",

    ["nytongli"] = "同礼",
    [":nytongli"] = "当你使用的牌结算后，你可以将一张相同花色的手牌当作这张牌使用并摸一张牌。",
    ["nytongliuse"] = "你可以将一张 %src 手牌当作【%arg】 使用并摸一张牌。",
    ["nyshezhang"] = "奢葬",
    [":nyshezhang"] = "每回合限一次，一名角色即将受到伤害时，你可以从牌堆获得你手牌中缺少的花色的牌各一张。若你的手牌包含全部四种花色，改为摸一张牌并令此技能于本回合内改为每回合限两次。",
    ["nyshezhang:draw"] = "你可以发动“奢葬”摸一张牌并令此技能于本回合内改为每回合限两次",
    ["nyshezhang:get"] = "你可以发动“奢葬”从牌堆获得你手牌中缺少的花色的牌各一张（共 %src 张）",
    ["$nyshezhangtwice"] = "%arg 的 %arg2 于本回合内改为了每回合限两次。",

    ["$nytongli1"] = "同礼",
    ["$nytongli2"] = "同礼",
    ["$nyshezhang1"] = "奢葬",
    ["$nyshezhang2"] = "奢葬",
    ["~nyzhangxuan"] = "群阴·张嫙",


--貂蝉
    ["nydiaochan"] = "群阴·貂蝉",
    ["&nydiaochan"] = "貂蝉",
    ["#nydiaochan"] = "舞惑群心",
    ["designer:nydiaochan"] = "Nyarz",

    ["nybiyue"] = "闭月",
    [":nybiyue"] = "锁定技，结束阶段，你摸1张牌。\
    以下条件每满足一项，摸牌数便增加一倍。\
    ①你已受伤。\
    ②本回合内未造成过伤害。\
    ③手牌数不小于体力值。\
    若全部满足，你的下个准备阶段须将手牌弃至体力上限。",
    ["$nybiyuediscard"] = "%from 于其下个准备阶段需将手牌弃至体力上限。",
    ["nylijian"] = "离间",
    [":nylijian"] = "出牌阶段限一次，你可以选择两名角色，你弃置这些角色各一张牌，然后你可以令其中一名角色将这两张牌当作【杀】或【决斗】对另一名角色使用。若没有角色因此受到伤害，此技能于本阶段内改为出牌阶段限两次。",
    ["@nylijian"] = "你可以令其中一名角色将这%src张牌当作【杀】或【决斗】对另一名角色使用",

    ["$nybiyue1"] = "闭月",
    ["$nybiyue2"] = "闭月",
    ["$nylijian1"] = "离间",
    ["$nylijian2"] = "离间",
    ["~nydiaochan"] = "群阴·貂蝉",


--夏侯紫萼
    ["nyxiahouzie"] = "群阴·夏侯紫萼",
    ["&nyxiahouzie"] = "夏侯紫萼",
    ["#nyxiahouzie"] = "孤草飘零",
    ["designer:nyxiahouzie"] = "Nyarz",

    ["nyduoren"] = "夺刃",
    [":nyduoren"] = "在你令一名其他角色进入濒死状态后，你可以减少1点体力上限并失去上次以此法获得的技能，然后获得该角色的所有技能。",
    ["nyduoren:get"] = "你可以发动“夺刃”减1点体力上限并获得%src的全部技能",
    ["nyxuechang"] = "血偿",
    [":nyxuechang"] = "出牌阶段每名其他角色限一次，你可以与一名其他角色拼点。\
    ①若你赢，你获得其一张牌并且视为对其使用了一张【杀】。\
    ②若你没赢，你对其造成的下次伤害+1，然后此技能于本阶段内失效。",
    ["$nyxuechangnotcard"] = "没有可以从 %arg 处获得的牌。",
    ["$nyxuechangnotslash"] = "不能对 %arg 使用【杀】。",

    ["$nyduoren1"] = "夺刃",
    ["$nyduoren2"] = "夺刃",
    ["$nyxuechang1"] = "血偿",
    ["$nyxuechang2"] = "血偿",
    ["~nyxiahouzie"] = "群阴·夏侯紫萼",


--乐蔡文姬
    ["nymusiccaiwenji"] = "群阴·乐蔡文姬",
    ["&nymusiccaiwenji"] = "蔡文姬",
    ["#nymusiccaiwenji"] = "姝丽风华",
    ["designer:nymusiccaiwenji"] = "Nyarz",

    ["nyshuangjia"] = "霜笳",
    [":nyshuangjia"] = "锁定技，每轮游戏开始时，你获得所有武将牌上的“胡笳”，然后从牌堆中将四张不同花色的牌置于你的武将牌上，称为“胡笳”。\
    若你的武将牌上有“胡笳”，其他角色与你计算距离时+1。",
    ["nyhujia"] = "胡笳",
    ["nybeifen"] = "悲愤",
    [":nybeifen"] = "出牌阶段开始时或一名角色受到伤害后，你可以令一名角色/受伤角色获得一张“胡笳”。\
    当该角色失去“胡笳”时，其从牌堆中获得三张花色各不相同且与失去的“胡笳”花色不同的牌。",
    ["@nybeifen"] = "你可以令一名角色获得一张“胡笳”",
    ["nybeifengive"] = "你可以令 %src 获得一张“胡笳”",

    ["$nyshuangjia1"] = "霜笳",
    ["$nyshuangjia2"] = "霜笳",
    ["$nybeifen1"] = "悲愤",
    ["$nybeifen2"] = "悲愤",
    ["~nymusiccaiwenji"] = "群阴·乐蔡文姬",


--张媱
    ["nyzhangyao"] = "群阴·张媱",
    ["&nyzhangyao"] = "张媱",
    ["#nyzhangyao"] = "琼楼孤蒂",
    ["designer:nyzhangyao"] = "Nyarz",

    ["nyxiyan"] = "夕颜",
    [":nyxiyan"] = "准备阶段或结束阶段，你可以获得四张花色各不相同的“怨”。\
    当你成为【杀】或【决斗】的目标时，使用者须放置一张“怨”。",
    ["nyzhangyaoput"] = "请放置 %src 张“怨”",
    ["@nyxiyan"] = "你可以获得四张花色各不相同的“怨”",
    ["nyyuan"] = "怨",
    ["nyyuanyu"] = "怨语",
    [":nyyuanyu"] = "出牌阶段限一次，你可以摸一张牌并将一张牌置于武将牌上，称为“怨”，然后你可以选择一名其他角色，令其获得或失去以下效果：\
    ①使用与“怨”花色相同的牌时，须放置一张“怨”。\
    ②弃牌阶段开始时，若手牌数大于体力值，须放置相当于超出数量的“怨”。",
    ["$nyyuanyuremove"] = "%from 现在不再受 %arg 影响。",
    ["@nyyuanyu"] = "你可以选择一名角色，使其受到或失去“怨语”影响。",

    ["$nyxiyan1"] = "夕颜",
    ["$nyxiyan2"] = "夕颜",
    ["$nyyuanyu1"] = "怨语",
    ["$nyyuanyu2"] = "怨语",
    ["~nyzhangyao"] = "群阴·张媱",


--唐姬
    ["nytangji"] = "群阴·唐姬",
    ["&nytangji"] = "唐姬",
    ["#nytangji"] = "水月镜缘",
    ["designer:nytangji"] = "Nyarz",

    ["nykangge"] = "抗歌",
    [":nykangge"] = "你的第一个准备阶段，你选择一名其他角色作为“抗歌”角色。\
    “抗歌”角色于其摸牌阶段外获得牌时，你摸两张牌。\
    当你因此技能于一回合内摸第7次牌时，你失去1点体力并令此技能于本轮内失效。\
    每轮各限一次，你或抗歌角色处于濒死状态时，另一名角色可以令其将体力值回复至1点。",
    ["nyjielie"] = "节烈",
    [":nyjielie"] = "当你或“抗歌”角色受到伤害时，你可以失去1点体力并防止此伤害，然后你选择一名角色摸等于伤害值的牌。",
    ["@nykangge"] = "请选择一名“抗歌”角色",
    ["nykangge:recover"] = "你可以令 %src 将体力值恢复至1点",
    ["@nyjielie"] = "你可以失去1点体力，防止%src即将受到的%arg点伤害，然后令一名角色摸%arg张牌",

    ["$nykangge1"] = "抗歌",
    ["$nykangge2"] = "抗歌",
    ["$nyjielie1"] = "节烈",
    ["$nyjielie2"] = "节烈",
    ["~nytangji"] = "群阴·唐姬",


--诸葛果
    ["nyzhugeguo"] = "群阴·诸葛果",
    ["&nyzhugeguo"] = "诸葛果",
    ["#nyzhugeguo"] = "凤阁乘烟",
    ["designer:nyzhugeguo"] = "Nyarz",

    ["nyqirang"] = "祈禳",
    [":nyqirang"] = "在你使用装备牌时，你可以从牌堆中获得一张锦囊牌。\
    当你使用锦囊牌时，若你的手牌上限大于0，你可以令你的手牌上限-1直到你的下一次回合结束，然后此牌不可被响应，你摸两张牌。\
    结束阶段，你令其他角色与你计算距离时+X直到你的下个回合开始。（X为你的手牌上限与体力值的差值）",
    ["nyqirang:equip"] = "你可以从牌堆中获得一张锦囊牌",
    ["nyqirang:trick"] = "你可以令你的手牌上限-1直到你的下一次回合结束，然后【%src】不可被响应，你摸两张牌<br/>当前手牌上限为 %arg",
    ["$nyqirang_norespond"] = "%from 使用的 %card 因 %arg 的效果不可被响应。",
    ["$nyqirang_distance"] = "其他角色与 %from 计算距离时须 +%arg 。",
    ["nydengxian"] = "登仙",
    [":nydengxian"] = "觉醒技，结束阶段，若你的手牌上限为0，你从牌堆中为你每个空置装备栏使用一张对应装备，然后获得“惊鸿”。",
    ["nyjinghong"] = "惊鸿",
    [":nyjinghong"] = "锁定技，你的判定阶段和弃牌阶段开始时，你选择将此阶段改为摸牌阶段或出牌阶段。",
    ["nyjinghong_judge"] = "你要将判定阶段修改为的阶段",
    ["nyjinghong_discard"] = "你要将弃牌阶段修改为的阶段",
    ["nyjinghong:draw"] = "摸牌阶段",
    ["nyjinghong:play"] = "出牌阶段",
    ["$nyjinghong_change"] = "%from 发动 %arg 将 %arg2 阶段改为了 %arg3 阶段。",

    ["$nyqirang1"] = "祈禳",
    ["$nyqirang2"] = "祈禳",
    ["$nydengxian1"] = "登仙",
    ["$nydengxian2"] = "登仙",
    ["$nyjinghong1"] = "惊鸿",
    ["$nyjinghong2"] = "惊鸿",
    ["~nyzhugeguo"] = "群阴·诸葛果",


--花鬘
    ["nyhuaman"] = "群阴·花鬘",
    ["&nyhuaman"] = "花鬘",
    ["#nyhuaman"] = "锋丽鬘影",
    ["designer:nyhuaman"] = "Nyarz",

    ["nymansi"] = "蛮嗣",
    [":nymansi"] = "出牌阶段开始时，你可以视为使用一张【南蛮入侵】。\
    你使用【南蛮入侵】造成伤害时，摸1张牌。\
    当你成为【南蛮入侵】的目标时，令此牌对你无效，你与此牌使用者各摸1张牌。",
    ["nymansi:use"] = "你可以视为使用一张【南蛮入侵】",
    ["nyshouying"] = "薮影",
    [":nyshouying"] = "每回合限一次，①当你使用基本牌或普通锦囊牌指定其他角色为目标后，你可以获得此牌。\
    ②当你成为其他角色使用基本牌或普通锦囊牌的目标后，你可以令此牌对你无效并弃置其一张牌。",
    ["nyshouying:get"] = "你可以获得你使用的 【%src】",
    ["nyshouying:nullified"] = "你可以令【%src】对你无效并弃置 %arg 一张牌",
    ["nyzhanyuan"] = "战缘",
    [":nyzhanyuan"] = "限定技，准备阶段，你可以选择一名其他角色，你弃置所有手牌并视为对其使用了一张【决斗】。此牌结算后，你加一点体力上限，你与该角色获得【系力】。",
    ["@nyzhanyuan"] = "你可以选择一名其他角色，你弃置所有手牌并视为对其使用了一张【决斗】。此牌结算后，你加一点体力上限并摸两张牌，你与该角色获得【系力】",
    ["nyxili"] = "系力",
    [":nyxili"] = "每回合限一次，当其他拥有“系力”的角色使用的仅指定唯一目标的基本牌或普通锦囊牌结算后，你可以视为对相同目标使用了一张相同牌名的牌。",
    ["nyxili:use"] = "你可以视为对%src使用了一张【%arg】",

    ["$nymansi1"] = "蛮嗣",
    ["$nymansi2"] = "蛮嗣",
    ["$nyshouying1"] = "薮影",
    ["$nyshouying2"] = "薮影",
    ["$nyzhanyuan1"] = "战缘",
    ["$nyzhanyuan2"] = "战缘",
    ["$nyxili1"] = "系力",
    ["$nyxili2"] = "系力",
    ["~nyhuaman"] = "群阴·花鬘",


--鲍三娘
    ["nybaosanniang"] = "群阴·鲍三娘",
    ["&nybaosanniang"] = "鲍三娘",
    ["#nybaosanniang"] = "鹊澜情夕",
    ["designer:nybaosanniang"] = "Nyarz",

    ["nywuniang"] = "武娘",
    [":nywuniang"] = "你可以弃置你或当前回合角色场上的一张牌，视为你使用或打出了一张【杀】。\
    当你使用或打出一张【杀】时，你可以获得一名其他角色区域内的一张牌并令该角色摸一张牌。若此时在你的回合内且“许身”已发动，你本回合可以多使用一张【杀】。",
    ["@nywuniang"] = "请弃置你或当前回合角色场上的一张牌",
    ["nywuniangget"] = "你可以获得一名其他角色区域内的一张牌并令该角色摸一张牌",
    ["$nywuniang_more"] = "%from 本回合可以多使用一张【杀】",
    ["nyxushen"] = "许身",
    [":nyxushen"] = "限定技，当你处于濒死状态时，你可以将体力值回复到1点并获得“镇南”，然后你可以令一名其他角色获得“武圣”和“制蛮”并摸三张牌。",
    ["@nyxushen"] = "你可以令一名其他角色获得“武圣”和“制蛮”并摸三张牌",
    ["nyxushen:prompt"] = "你可以将体力值回复到1点并获得“镇南”",
    ["nyzhennan"] = "镇南",
    [":nyzhennan"] = "每个回合结束时，你可以将至多X点伤害分配给场上的角色。（X为本回合内被使用过的目标数大于一的牌的数量）\
    你使用基本牌或普通锦囊牌仅指定一个目标时，你可以为此牌增加一个目标。",
    ["@nyzhennan"] = "请分配第%src点伤害",
    ["nyzhennan_more"] = "你可以为【%src】增加一个目标",
    ["nyzhennan_damage"] = "已分配伤害",
    ["$nyzhennan_damage_count"] = "%from 将 %arg 点伤害分配给了 %to ",
    ["$nyzhennan_more_log"] = "%from 发动 %arg 为 %card 增加了额外目标 %to",

    ["$nywuniang1"] = "武娘",
    ["$nywuniang2"] = "武娘",
    ["$nyxushen1"] = "许身",
    ["$nyxushen2"] = "许身",
    ["$nyzhennan1"] = "镇南",
    ["$nyzhennan2"] = "镇南",
    ["~nybaosanniang"] = "群阴·鲍三娘",

    --严夫人

    ["ny_yanfuren"] = "群阴·严夫人",
    ["&ny_yanfuren"] = "严夫人",
    ["#ny_yanfuren"] = "水月胧影",
    ["designer:ny_yanfuren"] = "Nyarz",

    ["ny_nifu"] = "匿伏",
    [":ny_nifu"] = "锁定技，攻击范围内不包含你的角色使用【杀】或锦囊牌不能指定你为目标。\
    当你受到伤害后，其他角色与你计算距离+1直到你的回合结束。",
    ["ny_channi"] = "谗逆",
    [":ny_channi"] = "一名角色的出牌阶段开始时，你可以令其视为对你选择的另一名角色使用了一张【决斗】。\
    若使用【决斗】的角色不为你，你需要交给其至少X+1张手牌，然后将手牌摸至与该角色体力值相同。\
    X为其满足的项数：①因此【决斗】受到伤害；②手牌数小于体力值。",
    ["@ny_channi"] = "你可以发动“谗逆”令 %src 视为对你选择的一名角色使用了【决斗】",
    ["ny_channi_give"] = "请交给 %src 至少 %arg 张手牌",

    ["$ny_nifu1"] = "春风融冷霜，藏冬之柔蓟可以亭亭矣。",
    ["$ny_nifu2"] = "君看枯木裹雪霜，春来一一焕荣光！",
    ["$ny_channi1"] = "细雨春风语七九，河开燕来芳菲流。",
    ["$ny_channi2"] = "莺语燕歌引春风，双瞳剪柳绿意浓。",
    ["~ny_yanfuren"] = "春寒料峭，此身不胜寒。",

    --万年公主

    ["ny_wanniangz"] = "群阴·万年公主",
    ["&ny_wanniangz"] = "万年公主",
    ["#ny_wanniangz"] = "剑心汉胆",
    ["designer:ny_wanniangz"] = "Nyarz",

    ["ny_zhenge"] = "枕戈",
    [":ny_zhenge"] = "准备阶段，你可以令一名角色执行以下第X项（X为其成为“枕戈”目标的次数）：\
    1.本局游戏内攻击范围+2；2.本局游戏内出牌阶段可以多使用1张【杀】；3.本局游戏内手牌上限+2；4及以上,摸两张牌。\
    那之后，该角色可以视为使用了一张【杀】。",
    ["@ny_zhenge"] = "你可以视为使用了一张【杀】",
    ["ny_zhenge_chosen"] = "你可以对一名角色发动“枕戈”",
    ["ny_xinghan"] = "兴汉",
    [":ny_xinghan"] = "你使用的【杀】结算后，或你对其发动过“枕戈”的角色使用【杀】造成伤害后，你可以摸1张牌。",
    ["ny_xinghan:draw"] = "你可以发动“兴汉”摸1张牌",

    ["$ny_zhenge1"] = "红颜坠红尘，半丈孤剑、多少断肠人。",
    ["$ny_zhenge2"] = "青霜扰清梦，一枕离绪、万千不眠夜。",
    ["$ny_xinghan1"] = "红袖葬黄花，心中炎汉逐却心上人。",
    ["$ny_xinghan2"] = "青丝映霜鬓，眸外故园催下眸中泪。",
    ["~ny_wanniangz"] = "今生已许汉，来世再许卿。",

    --夏侯氏

    ["ny_xiahoushi"] = "群阴·夏侯氏",
    ["&ny_xiahoushi"] = "夏侯氏",
    ["#ny_xiahoushi"] = "燕语呢喃",
    ["designer:ny_xiahoushi"] = "Nyarz",
    
    ["ny_qiaoshi"] = "樵拾",
    [":ny_qiaoshi"] = "这个技能的①②效果一回合只能使用其中1个1次：\
    ①当你受到伤害时，你可以防止此伤害，然后伤害来源摸2张牌。\
    ②你受到过伤害的回合结束阶段，你可以从弃牌堆中获得两张当前回合中进入弃牌堆的牌，然后可以依次使用之。",
    ["ny_qiaoshi:notdraw"] = "你可以发动“樵拾”防止你受到的 %src 点伤害",
    ["ny_qiaoshi:draw"] = "你可以发动“樵拾”防止你受到的 %src 点伤害，<br/>然后令 %arg 摸两张牌",
    ["@ny_qiaoshi"] = "你可以发动“樵拾”从弃牌堆中获得两张当前回合中进入弃牌堆的牌",
    ["ny_qiaoshi_usecard"] = "你可以发动“樵拾”使用一张牌",
    ["#ny_qiaoshi"] = "樵拾",
    ["ny_yanyu"] = "燕语",
    [":ny_yanyu"] = "出牌阶段，你可以重铸一张【杀】，或将一张【杀】交给一名其他角色并摸一张牌。你与因此获得【杀】的角色摸一张牌。",

    ["$ny_qiaoshi1"] = "樵前情窦开，君后寻迹来。",
    ["$ny_qiaoshi2"] = "樵心遇郎君，妾心涟漪生。",
    ["$ny_yanyu1"] = "伴君一生不寂寞。",
    ["$ny_yanyu2"] = "感君一回顾，思君朝与暮。",
    ["~ny_xiahoushi"] = "愿有来世，不负前缘。",

    --滕芳兰

    ["ny_tengfanglan"] = "群阴·滕芳兰",
    ["&ny_tengfanglan"] = "滕芳兰",
    ["#ny_tengfanglan"] = "皓露沁兰",
    ["designer:ny_tengfanglan"] = "Nyarz",

    ["ny_luochong"] = "落宠",
    [":ny_luochong"] = "你可以于以下时机发动此技能：①每轮游戏开始时；②出牌阶段限一次；③你受到1点伤害后。若如此做，你弃置至多两名角色区域内的至多共计2张牌。",
    ["@ny_luochong"] = "你可以弃置一名角色区域内的一张牌（第%src张）",
    ["ny_aichen"] = "哀尘",
    [":ny_aichen"] = "当你因弃置而失去区域内的牌时，你可以摸1张牌，若为本回合首次发动，改为摸2张。弃牌阶段开始时，你可以弃置一张牌并跳过弃牌阶段。",
    ["ny_aichen:draw"] = "你可以发动“哀尘”摸%src张牌",
    ["@ny_aichen"] = "你可以发动“哀尘”弃置一张牌并跳过弃牌阶段",

    ["$ny_luochong1"] = "彼采萧兮，一日不见，如三秋兮。",
    ["$ny_luochong2"] = "君投我以木桃，妾当报之以琼瑶。",
    ["$ny_aichen1"] = "葛生蒙楚，蔹蔓于野。予美亡此，谁与独处。",
    ["$ny_aichen2"] = "山有乔松，隰有游龙。不见子充，乃见狡童。",
    ["~ny_tengfanglan"] = "今生缘定，来生如是，生生亦如是。",

    --曹华

    ["nyarz_caohua"] = "群阴·曹华",
    ["&nyarz_caohua"] = "曹华",
    ["#nyarz_caohua"] = "曹华",
    ["designer:nyarz_caohua"] = "Nyarz",

    ["nyarz_guili"] = "归离",
    [":nyarz_guili"] = "每轮各限一次，\
    ①一名其他角色的回合结束时，若其本回合未造成过伤害，你可以执行一个额外回合。\
    ②你的回合结束时，若你本回合未造成过伤害，你可以令一名其他角色执行一个额外回合。",
    ["nyarz_guili:turn"] = "你可以发动“归离”执行一个额外回合",
    ["@nyarz_guili"] = "你可以发动“归离”令一名其他角色执行一个额外回合",
    ["$nyarz_guili_extra"] = "%from 因 %arg 的效果将执行一个额外回合",
    ["nyarz_caiyi"] = "彩翼",
    [":nyarz_caiyi"] = "每回合限一次，在你使用的牌结算后，你可以弃置任意张花色不同的手牌，然后将手牌调整至2X张。\
    若你因此技能调整手牌时失去了牌，你可以选择一名角色，你选择一项令其执行：①摸2X张牌或回复X点体力；②弃置2X张牌或受到X点无来源的伤害。\
    （X为你弃置的牌的花色数）",
    ["@nyarz_caiyi"] = "你可以发动“彩翼”弃置任意张花色不同的手牌",
    ["nyarz_caiyi_chosen"] = "请对一名角色发动“彩翼”",
    ["nyarz_caiyi:good"] = "令%src摸 2* %arg 张牌或回复 %arg 点体力",
    ["nyarz_caiyi:bad"] = "令%src弃置 2* %arg 张牌或受到 %arg 点无来源的伤害",
    ["nyarz_caiyi:recover"] = "回复 %src 点体力",
    ["nyarz_caiyi:draw"] = "摸 %src 张牌",
    ["nyarz_caiyi:damage"] = "受到 %src 点伤害",
    ["nyarz_caiyi:discard"] = "弃置 %src 张牌",
    ["nyarz_caiyi:damage_nochoices"] = "你无路可逃",

    ["$nyarz_guili1"] = "凤非梧桐不栖，小女遍寻城中未见一木。",
    ["$nyarz_guili2"] = "魏王与我相看两厌，不如归离、相忘江湖。",
    ["$nyarz_caiyi1"] = "身有彩鳞双飞翼，落羽紫微帝王家。",
    ["$nyarz_caiyi2"] = "与君有灵犀，一双彩翼，载得许多梦。",
    ["~nyarz_caohua"] = "妾虽生于曹家，然绝无异心！",

    --钟琰

    ["nyarz_zhongyan"] = "群阴·钟琰",
    ["&nyarz_zhongyan"] = "钟琰",
    ["#nyarz_zhongyan"] = "紫闼飞莺",
    ["designer:nyarz_zhongyan"] = "Nyarz",

    ["nyarz_xiaoyong"] = "啸咏",
    [":nyarz_xiaoyong"] = "每阶段限一次，你使用的牌结算后，可以观看牌堆顶牌名字数张牌，然后以任意顺序放回牌堆顶或牌堆底。",
    ["nyarz_xiaoyong:view"] = "你可以发动“啸咏”观看牌堆顶的 %src 张牌",
    ["nyarz_guangu"] = "观骨",
    ["#nyarz_guangu"] = "观骨",
    [":nyarz_guangu"] = "每阶段限一次，出牌阶段或当你受到伤害后，你可以观看：①牌堆顶的至多4张牌；②一名其他角色的至多4张手牌，然后你可以使用其中一张牌。你使用牌名字数为X的牌后，重置“观骨”（X为本阶段上次“观骨”观看牌数）。",
    ["@nyarz_guangu-damaged"] = "你可以发动“观骨”观看牌",
    ["@nyarz_guangu-use"] = "你可以使用其中一张牌",

    ["$nyarz_xiaoyong1"] = "凉风萧条，露沾我衣。",
    ["$nyarz_xiaoyong2"] = "忧来多方，慨然永怀。",
    ["$nyarz_guangu1"] = "此才拔萃，然观其形骨，恐早夭。",
    ["$nyarz_guangu2"] = "绯衣者，汝所拔乎？",
    ["~nyarz_zhongyan"] = "此间天下人，皆分一斗之才。",

    --曹婴

    ["nyarz_caoying"] = "群阴·曹婴",
    ["&nyarz_caoying"] = "曹婴",
    ["#nyarz_caoying"] = "长夜临曦",
    ["designer:nyarz_caoying"] = "Nyarz",

    ["nyarz_fujian"] = "伏间",
    [":nyarz_fujian"] = "锁定技，一名其他角色于其摸牌阶段外获得牌时，你观看这些牌。若其中包含你本回合未观看过的类型的牌，你摸一张牌。",
    ["@nyarz_fujian"] = "以上为 %src 获得的牌",
    ["nyarz_lingren"] = "凌人",
    [":nyarz_lingren"] = "每回合限两次，在你使用伤害类牌指定目标后，你可以选择其中一名目标角色，若你的：①手牌数不小于该角色：你摸两张牌；②体力值不小于该角色：你令此牌对其造成的伤害+1。若均满足或均不满足，令目标无法响应此牌且此牌结算后你获得之。",
    ["@nyarz_lingren"] = "你可以对此【%src】的其中一名目标角色发动“凌人”",
    ["$nyarz_lingren_no_respond"] = "%from 不能响应 %card",
    ["$nyarz_lingren_view"] = "%from 观看了 %to 获得的 %card",

    ["$nyarz_fujian1"] = "紫电耀魍魉之遁形，青霜斩魑魅之神魄。",
    ["$nyarz_fujian2"] = "纵汝亡命天涯海角，吾亦逐之负首而还。",
    ["$nyarz_lingren1"] = "秉凌人之盛气，试青锋于万里！",
    ["$nyarz_lingren2"] = "斩宵小于沙场，绝仇雠于疆野！",
    ["~nyarz_caoying"] = "袍泽捐躯在野，此仇怎可归冢？",

    --曹宪

    ["nyarz_caoxian"] = "群阴·曹宪",
    ["&nyarz_caoxian"] = "曹宪",
    ["#nyarz_caoxian"] = "元春呈祥",
    ["designer:nyarz_caoxian"] = "Nyarz",

    ["nyarz_lingxi"] = "灵犀",
    [":nyarz_lingxi"] = "当你使用的牌结算后，你可以将此牌当作“翼”置于武将牌上，然后将手牌数调整至“翼”花色的两倍。若你的“翼”多于四张，先移去最先置入的若干张。若你因此失去手牌，你可以令一名其他角色弃置两张牌，不能弃置时其失去一点体力。",
    ["nyarz_lingxi:put"] = "你可以发动“灵犀”将【%src】置于武将牌上",
    ["@nyarz_lingxi"] = "你可以令一名其他角色弃置两张牌",
    ["nyarz_lingxi_yi"] = "翼",
    [":&nyarz_lingxi"] = "第一张放置的“翼”为标记所示的那张牌",
    ["nyarz_zhifou"] = "知否",
    [":nyarz_zhifou"] = "每回合限一次，①你可以将全部手牌当作【桃】使用；②一名角色于其回合外失去最后的手牌后，你可以令其获得每种花色的牌各一张。",

    ["$nyarz_lingxi1"] = "火树绕东风，星雨绽彩翼，此日阖家团圆。",
    ["$nyarz_lingxi2"] = "熙攘人间气，最暖不夜城，今夕把酒达旦。",
    ["$nyarz_zhifou1"] = "名庐邀雪柳，此夜阑珊灯火，映万家欢颜。",
    ["$nyarz_zhifou2"] = "曈日换旧符，可知新岁鸿运，所愿所得。",
    ["~nyarz_caoxian"] = "清酒入喉苦，新岁无所忧。",

    --薛灵芸

    ["nyarz_xvelingyun"] = "群阴·薛灵芸",
    ["&nyarz_xvelingyun"] = "薛灵芸",
    ["#nyarz_xvelingyun"] = "金蛟巧刻",
    ["designer:nyarz_xvelingyun"] = "Nyarz",

    ["nyarz_xialei"] = "霞泪",
    [":nyarz_xialei"] = "准备阶段或当你失去牌后，你可以卜算3，然后可以摸一张牌。若你本次未失去红色牌，此技能本回合不能再发动直到你下次失去红色牌后。",
    ["nyarz_xialei:draw"] = "你可以摸一张牌",
    ["nyarz_anzhi"] = "暗织",
    ["#nyarz_anzhi"] = "暗织",
    [":nyarz_anzhi"] = "出牌阶段或当你受到伤害后，你可以观看牌堆底的三张牌，然后你可以弃置其中任意张，并令一名角色获得一张本回合进入弃牌堆的牌。若弃置的牌的花色均不为本回合首次以此法弃置，此技能失效直到回合结束。",
    ["@nyarz_anzhi-view"] = "你可以发动“暗织”观看牌堆底的三张牌",
    ["@nyarz_anzhi-discard"] = "你可以弃置其中任意张牌",
    ["@nyarz_anzhi-give"] = "你可以令一名角色获得一张本回合进入弃牌堆的牌",

    ["$nyarz_xialei1"] = "清泪映霞光，玉壶盛离绪，一曲人断肠。",
    ["$nyarz_xialei2"] = "挽指撷彩线，凭泪润寒衣，霞漫天苍苍。",
    ["$nyarz_anzhi1"] = "深帏可无烛，独凭明镜照，可作衣裳。",
    ["$nyarz_anzhi2"] = "月于空，星于海，镜于心，三者皆明。",
    ["~nyarz_xvelingyun"] = "子规啼寒，泪结成红冰。",

    --卢弈

    ["nyarz_luyi"] = "群阴·卢弈",
    ["&nyarz_luyi"] = "卢弈",
    ["#nyarz_luyi"] = "姝丽风华",
    ["designer:nyarz_luyi"] = "Nyarz",

    ["nyarz_fuxve"] = "复学",
    [":nyarz_fuxve"] = "出牌阶段结束时，你可以获得本阶段你失去的全部牌。你使用一张牌后，与之相同牌名的牌不计入你的手牌上限直到你的下个回合结束。",
    ["nyarz_yaoyi"] = "邀弈",
    [":nyarz_yaoyi"] = "出牌阶段，你可以使用一张手牌（无次数和距离限制），然后令一名其他角色也可以如此做。你以此法成为牌的目标后摸一张牌。",
    ["@nyarz_yaoyi-use"] = "你可以使用一张手牌（无距离和次数限制）<br/>若指定 %src 为目标，其摸一张牌",
    ["@nyarz_yaoyi-target"] = "请为“邀弈”选择一名目标",

    ["$nyarz_fuxve1"] = "今春风已至，万物可破坚冰而复生。",
    ["$nyarz_fuxve2"] = "可以此间琅琅书声，化江北之春风。",
    ["$nyarz_yaoyi1"] = "今以日月为棋、风雨作宫，邀君烂柯可乎？",
    ["$nyarz_yaoyi2"] = "千载之逆旅见万里之缺盈，但博小雅如何？",
    ["$nyarz_yaoyi3"] = "观棋而烂柯者，可解高山流水于交错。",
    ["$nyarz_yaoyi4"] = "相弈落子即可，无须杂言扰此间风雅。",
    ["~nyarz_luyi"] = "芳影随春风，落子定生死。",
}
return packages