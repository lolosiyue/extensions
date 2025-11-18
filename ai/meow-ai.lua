sgs.ai_skill_cardask["@MeowBeige"] = function(self, data)
    local damage = data:toDamage()
    if not self:isFriend(damage.to) or self:isFriend(damage.from) then return "." end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByUseValue(cards, true)

    if self:isFriend(damage.from)
    then
        for _, card in ipairs(cards) do
            if not self:toTurnOver(damage.from, 0)
                and card:getSuit() == sgs.Card_Spade
            then
                return "$" .. card:getEffectiveId()
            end
        end
    else
        for _, card in ipairs(cards) do
            if self:toTurnOver(damage.from, 0)
                and card:getSuit() == sgs.Card_Spade
            then
                return "$" .. card:getEffectiveId()
            end
        end
    end
    for _, card in ipairs(cards) do
        if (card:getSuit() == sgs.Card_Heart and damage.to:getHp() < getBestHp(damage.to) and self:isFriend(damage.to))
            or (card:getSuit() == sgs.Card_Diamond and self:isFriend(damage.to) and self:canDraw(damage.to))
            or (card:getSuit() == sgs.Card_Club and damage.from and self:doDisCard(damage.from, "he")) then
            return "$" .. card:getEffectiveId()
        end
    end

    local to_discard = self:askForDiscard("beige", 1, 1, false, true)
    if #to_discard > 0 then return "$" .. to_discard[1] else return "." end
end

function sgs.ai_cardneed.MeowBeige(to, card)
    return to:getCardCount() <= 2
end

sgs.ai_choicemade_filter.cardResponded["@MeowBeige"] = function(self, player, promptlist)
    local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
    if damage and damage.to and promptlist[#promptlist] ~= "" then
        sgs.updateIntention(player, damage.to, -80)
    end
end


sgs.ai_skill_choice["MeowBeige"] = function(self, choices, data)
    local items = choices:split("+")
    local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
    if damage and damage.from then
        if self:isFriend(damage.from)
        then
            if not self:toTurnOver(damage.from, 0)
            then
                return "Spade"
            else
            end
        else
            if self:toTurnOver(damage.from, 0)

            then
                return "Spade"
            end
            
        end
    end
    if damage.to:getHp() < getBestHp(damage.to) and self:isFriend(damage.to) then
        return "Heart"
    end
    if self:isFriend(damage.to) and self:canDraw(damage.to) then
        return "Diamond"
    end
    if damage.from and self:doDisCard(damage.from, "he") then
        return "Club"
    end
    return items[math.random(1, #items)]
end

sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .."|MeowBeige"

function sgs.ai_slash_prohibit.MeowDuanchang(self, from, to)
    if hasJueqingEffect(from, to) or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
    if from:hasFlag("NosJiefanUsed") then return false end
    if to:getHp() > 1 or #(self:getEnemies(from)) == 1 then return false end
    if from:getMaxHp() == 3 and from:getArmor() and from:getDefensiveHorse() then return false end
    if from:getMaxHp() <= 3 or (from:isLord() and self:isWeak(from)) then return true end
    if from:getMaxHp() <= 3 or (self.room:getLord() and from:getRole() == "renegade") then return true end
    return false
end

sgs.exclusive_skill = sgs.exclusive_skill .."|MeowDuanchang"


local Meowlijian_skill = {}
Meowlijian_skill.name = "Meowlijian"
table.insert(sgs.ai_skills,Meowlijian_skill)
Meowlijian_skill.getTurnUseCard = function(self)
	if self.player:isNude() or self.room:getAlivePlayers():length()<3 then
		return
	end
    local n = self.player:getHandcardNum() + self.player:getEquips():length()
    if not self.player:hasSkill("Meowdoumiao") then
        n = n + 1
    end
	if n > 1 then return sgs.Card_Parse("#MeowlijianCard:.:") end
end

sgs.ai_skill_use_func["#MeowlijianCard"] = function(card,use,self)
    local lord = self.room:getLord()
    local duel = dummyCard("duel")
    local findFriend_maxSlash = function(self,first)
		self:log("Looking for the friend!")
		local maxSlash = 0
		local friend_maxSlash
		local nos_fazheng,fazheng
		for _,friend in ipairs(self.friends_noself)do
			if self:hasTrickEffective(duel,first,friend) then
				if friend:hasSkill("nosenyuan") and friend:getHp()>1 then nos_fazheng = friend end
				if friend:hasSkill("enyuan") and friend:getHp()>1 then fazheng = friend end
				if (getCardsNum("Slash",friend)>maxSlash) then
					maxSlash = getCardsNum("Slash",friend)
					friend_maxSlash = friend
				end
			end
		end

		if friend_maxSlash then
			local safe = false
			if self:hasSkills("neoganglie|vsganglie|fankui|enyuan|ganglie|nosenyuan",first) and not self:hasSkills("wuyan|noswuyan",first) then
				if (first:getHp()<=1 and first:getHandcardNum()==0) then safe = true end
			elseif (getCardsNum("Slash",friend_maxSlash)>=getCardsNum("Slash",first)) then safe = true end
			if safe then return friend_maxSlash end
		else self:log("unfound")
		end
		if nos_fazheng or fazheng then  return nos_fazheng or fazheng end       --备用友方，各种恶心的法正
		return nil
	end
    local n = self.player:getHandcardNum() + self.player:getEquips():length()
    if not self.player:hasSkill("Meowdoumiao") then
        n = n + 1
    end
    if n < 2 then return end
    local targets = {}
	if self.role=="rebel" or (self.role=="renegade" and sgs.playerRoles["loyalist"]+1>sgs.playerRoles["rebel"]) then

		if lord and not lord:isNude() and lord:objectName()~=self.player:objectName() then      -- 优先离间1血忠和主
			self:sort(self.enemies,"handcard")
			local e_peaches = 0
			local loyalist

			for _,enemy in ipairs(self.enemies)do
				e_peaches = e_peaches+getCardsNum("Peach",enemy)
				if enemy:getHp()==1 and self:hasTrickEffective(duel,enemy,lord) and enemy:objectName()~=lord:objectName() and not loyalist then
					loyalist = enemy
					break
				end
			end

			if loyalist and e_peaches<1 then 
                table.insert(targets, loyalist) 
                table.insert(targets, lord) 
            end
		end
    end
    if #targets < n then
        local shenguanyu = self.room:findPlayerBySkillName("wuhun")
        if shenguanyu and shenguanyu:objectName()~=self.player:objectName() then
            if self.role=="rebel" and lord and lord:objectName()~=self.player:objectName() and shenguanyu:objectName()~=lord:objectName()
                and not hasJueqingEffect(lord,shenguanyu) and self:hasTrickEffective(duel,shenguanyu,lord) then
                table.insert(targets, shenguanyu) 
            elseif self:isEnemy(shenguanyu) and #self.enemies>=2 then
                for _,enemy in ipairs(self.enemies)do
                    if enemy:objectName()~=shenguanyu:objectName() and not enemy:isLocked(duel)
                        and self:hasTrickEffective(duel,shenguanyu,enemy) then
                        if not table.contains(targets,enemy) then
                            table.insert(targets, enemy)
                            if #targets >= n then
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    if #targets < n then
        self:sort(self.enemies,"defense")
		local males,others = {},{}
		local first,second
		local zhugeliang_kongcheng,xunyu

		for _,enemy in ipairs(self.enemies)do
			if  not enemy:hasSkills("wuyan|noswuyan") then
				if enemy:hasSkill("kongcheng") and enemy:isKongcheng() then zhugeliang_kongcheng = enemy
				elseif enemy:hasSkill("jieming") then xunyu = enemy
				else
					for _,anotherenemy in ipairs(self.enemies)do
						if  anotherenemy:objectName()~=enemy:objectName() then
							if #males==0 and self:hasTrickEffective(duel,enemy,anotherenemy) then
								if not (enemy:hasSkill("hunzi") and enemy:getMark("hunzi")<1 and enemy:getHp()==2) then
									table.insert(males,enemy)
								else
									table.insert(others,enemy)
								end
							end
							if #males==1 and self:hasTrickEffective(duel,males[1],anotherenemy) then
								if not anotherenemy:hasSkills("nosjizhi|jizhi|jiang") then
									table.insert(males,anotherenemy)
								else
									table.insert(others,anotherenemy)
								end
							end
						end
					end
				end
			end
		end

		if #males>0 then
			if isLord(males[1]) and sgs.turncount<=1 and self.role=="rebel" and self.player:aliveCount()>=3 then
				local p_slash,max_p,max_pp = 0,nil,nil
				for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
					if not self:isFriend(p) and p:objectName()~=males[1]:objectName() and self:hasTrickEffective(duel,males[1],p) and not p:isLocked(duel)
						and p_slash<getCardsNum("Slash",p) then
						if p:getKingdom()==males[1]:getKingdom() then
							max_p = p
							break
						elseif not max_pp then
							max_pp = p
						end
					end
				end
				if max_p then table.insert(males,max_p) end
				if max_pp and #males==1 then table.insert(males,max_pp) end
			end
		end

		if #males>0 then
			if #others>=1 and not others[1]:isLocked(duel) then
                for _,p in ipairs(others)do
                    if not table.contains(males,p) then
				        table.insert(males,p)
                    end
                end
			elseif xunyu and not xunyu:isLocked(duel) then
				if getCardsNum("Slash",males[1])<1 then
					table.insert(males,xunyu)
				else
					local drawcards = 0
					for _,enemy in ipairs(self.enemies)do
						local x = enemy:getMaxHp()>enemy:getHandcardNum() and math.min(5,enemy:getMaxHp()-enemy:getHandcardNum()) or 0
						if x>drawcards then drawcards = x end
					end
					if drawcards<=2 then
						table.insert(males,xunyu)
					end
				end
			end
		end

		if #males>0 and #self.friends_noself>0 then
			self:log("Only 1")
			first = males[1]
			if zhugeliang_kongcheng and self:hasTrickEffective(duel,first,zhugeliang_kongcheng) then
				table.insert(males,zhugeliang_kongcheng)
			else
				local friend_maxSlash = findFriend_maxSlash(self,first)
				if friend_maxSlash then table.insert(males,friend_maxSlash) end
			end
		end

		if #males>=2 then
            for _,p in ipairs(males)do
                if not table.contains(targets,p) then
			        table.insert(targets, p)
                    if #targets >= n then
                        break
                    end
                end
            end
        end
    end
	if #targets >= 2 and n >= #targets then
		use.card = card
        for _,p in ipairs(targets)do
		    use.to:append(p)
        end
	end
end

sgs.ai_use_value.MeowlijianCard = 8.5
sgs.ai_use_priority.MeowlijianCard = 4

sgs.ai_card_intention.MeowlijianCard = function(self,card,from,to)
	sgs.updateIntentions(from,to,40)
end

sgs.dynamic_value.damage_card.MeowlijianCard = true


sgs.ai_skill_invoke.MeowQieting = function(self, data)
    return true
end
sgs.ai_skill_choice.MeowQieting = function(self, choices, data)
    local target = data:toPlayer()
    local items = choices:split("+")
    if table.contains(items, "draw")
        and self:isFriend(target)
    then
        return "draw"
    end
    local Equip = getChoice(choices, "get")
    local HandCard = getChoice(choices, "getHCrad")
    if target:getHandcardNum() >= 2
    then
        return HandCard
    end
    if target:hasEquip()
    then
        return Equip
    end
    if table.contains(items, "draw")
    then
        return "draw"
    end
end


local Meowxianzhou_skill = {}
Meowxianzhou_skill.name = "Meowxianzhou"
table.insert(sgs.ai_skills, Meowxianzhou_skill)
Meowxianzhou_skill.getTurnUseCard = function(self)
    if self.player:getEquips():isEmpty() then return end
    if self.player:getMark("@handover") == 0 then return end
    return sgs.Card_Parse("#MeowxianzhouCard:.:")
end

sgs.ai_skill_use_func["#MeowxianzhouCard"] = function(card, use, self)
    local cards = sgs.QList2Table(self.player:getHandcards())
    local to_give = {}
    self:sortByUseValue(cards, true)
    for _, card in ipairs(cards) do
        if not isCard("Peach", card, self.player)
            and not isCard("ExNihilo", card, self.player)
        then
            table.insert(to_give, card:getId())
        end
        if #to_give >= 2 and self:getOverflow() - #to_give <= 0
        then
            break
        end
    end
    if #to_give > 0
    then
        if self:isWeak() then
            for _, friend in ipairs(self.friends_noself) do
                if not hasManjuanEffect(friend) and self:canDraw(friend, self.player) then
                    use.card = card
                    if use.to then use.to:append(friend) end
                    return
                end
            end
            self:sort(self.friends)
            for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
                local canUse = true
                for _, friend in ipairs(self.friends) do
                    if target:inMyAttackRange(friend) and self:damageIsEffective(friend, nil, target)
                        and not self:needToLoseHp(friend, target)
                    then
                        canUse = false
                        break
                    end
                end
                if canUse then
                    use.card = sgs.Card_Parse("#MeowxianzhouCard:" .. table.concat(to_give, "+") .. ":")
                    if use.to then use.to:append(target) end
                    return
                end
            end
        end
        if not self.player:isWounded() then
            local killer
            self:sort(self.friends_noself)
            for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
                local canUse = false
                for _, friend in ipairs(self.friends_noself) do
                    if friend:inMyAttackRange(target) and self:damageIsEffective(target, nil, friend)
                        and not self:needToLoseHp(target, friend) and self:isWeak(target) then
                        canUse = true
                        killer = friend
                        break
                    end
                end
                if canUse then
                    use.card = sgs.Card_Parse("#MeowxianzhouCard:" .. table.concat(to_give, "+") .. ":")
                    if use.to then use.to:append(killer) end
                    return
                end
            end
        end

        if #self.friends_noself == 0 then return end
        if self.player:getEquips():length() > 2 or self.player:getEquips():length() > #self.enemies and sgs.turncount > 2 then
            local function cmp_AttackRange(a, b)
                local ar_a = a:getAttackRange()
                local ar_b = b:getAttackRange()
                if ar_a == ar_b then
                    return sgs.getDefense(a) > sgs.getDefense(b)
                else
                    return ar_a > ar_b
                end
            end
            table.sort(self.friends_noself, cmp_AttackRange)
            use.card = sgs.Card_Parse("#MeowxianzhouCard:" .. table.concat(to_give, "+") .. ":")
            if use.to then use.to:append(self.friends_noself[1]) end
        end
    end
end

sgs.ai_use_priority.MeowxianzhouCard = 2


sgs.ai_skill_use["@@Meowxianzhou"] = function(self, prompt)
    local current = self.room:getCurrent()
    local num = self.player:getMark("Meowxianzhou_count")
    if self:isWeak(current) and self:isFriend(current) then return "." end
    local targets = {}
    self:sort(self.enemies, "hp")
    for _, enemy in ipairs(self.enemies) do
        if self.player:inMyAttackRange(enemy) and self:damageIsEffective(enemy, nil, self.player)
            and not self:needToLoseHp(enemy, self.player)
        then
            table.insert(targets, enemy:objectName())
            if #targets == tonumber(num) then break end
        end
    end
    if #targets < tonumber(num) then
        self:sort(self.friends_noself)
        self.friends_noself = sgs.reverse(self.friends_noself)
        for _, friend in ipairs(self.friends_noself) do
            if self.player:inMyAttackRange(friend) and self:damageIsEffective(friend, nil, self.player)
                and not self:needToLoseHp(friend, self.player)
            then
                table.insert(targets, friend:objectName())
                if #targets == tonumber(num) then break end
            end
        end
    end
    if #targets < tonumber(num) then
        for _, target in sgs.qlist(self.room:getAlivePlayers()) do
            if not self:isFriend(target) and self:isWeak(target) then
                table.insert(targets, target:objectName())
            end
        end
    end

    if #targets > 0 and #targets <= tonumber(num) then
        return "#MeowxianzhouCard:.:->" .. table.concat(targets, "+")
    end
    return "."
end

sgs.ai_card_intention.MeowxianzhouCard = function(self, card, from, tos)
    if from:hasFlag("Meowxianzhou_target") then
        for _, to in ipairs(tos) do
            if self:damageIsEffective(to, nil, from) and not self:needToLoseHp(to, from) then
                sgs.updateIntention(from, to, 10)
            end
        end
    else
        if not from:isWounded() then sgs.updateIntentions(from, tos, -10) end
    end
end

sgs.ai_skill_choice.Meowxianzhou = function(self, choices, data)
    local target = data:toPlayer()
    local items = choices:split("+")
    if table.contains(items, "damage") and sgs.ai_skill_use["@@Meowxianzhou"](self, "@Meowxianzhou") ~= "."
    then
        return "damage"
    end

    return "recover"
end

sgs.Active_cardneed_skill = sgs.Active_cardneed_skill.."|MeowQiangwu"

sgs.ai_cardneed.MeowQiangwu = sgs.ai_cardneed.slash



sgs.ai_target_revises.MeowJuxiang = function(to, card)
    if card:isKindOf("SavageAssault")
    then
        return true
    end
end


sgs.ai_cardneed.MeowLieren = function(to, card, self)
    return isCard("Slash", card, to) and getKnownCard(to, self.player, "Slash", true) == 0
end

sgs.ai_skill_invoke.MeowLieren = function(self, data)
    local use = data:toCardUse()
    for _, p in sgs.qlist(use.to) do
        if self.player:getHandcardNum() == 1 then
            if (self:needKongcheng() or not self:hasLoseHandcardEffective()) and not self:isWeak() then return true end
            local card = self.player:getHandcards():first()
            if card:isKindOf("Jink") or card:isKindOf("Peach") then return end
        end
        if self:doDisCard(p, "he", true) then return true end
    end
    if sgs.ai_skill_use["@@MeowLieren"](self, "@MeowLieren") ~= "." then
        return true
    end
    return false
end




sgs.ai_skill_use["@@MeowLieren"] = function(self, prompt)
    self:sort(self.enemies, "handcard")

    for _, enemy in ipairs(self.enemies) do
        if ((enemy:hasFlag("MeowLierenMarkto") and self.player:hasFlag("MeowLierenMarkfrom")) or not self.player:hasFlag("MeowLierenMarkfrom")) and self.player:canPindian(enemy)
        then
            if self.player:getHandcardNum() == 1 then
                if (self:needKongcheng() or not self:hasLoseHandcardEffective()) and not self:isWeak() then
                    return
                        "#MeowLierenCard:.:->" .. enemy:objectName()
                end
                local card = self.player:getHandcards():first()
                if card:isKindOf("Jink") or card:isKindOf("Peach") then return "." end
            end
            if self:doDisCard(enemy, "he", true, 2) then return "#MeowLierenCard:.:->" .. enemy:objectName() end
        end
    end
    return "."
end


function sgs.ai_skill_pindian.MeowLieren(minusecard, self, requestor)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    if requestor:objectName() == self.player:objectName() then
        return cards[1]:getId()
    end
    return self:getMaxCard(self.player):getId()
end

function sgs.ai_cardneed.MeowJizhi(to, card)
    return card:getTypeId() == sgs.Card_TypeTrick
end

local MeowGuose_skill = {}
MeowGuose_skill.name = "MeowGuose"
table.insert(sgs.ai_skills, MeowGuose_skill)
MeowGuose_skill.getTurnUseCard = function(self, inclusive)
    local cards = self:addHandPile("he")
    self:sortByUseValue(cards, true)
    local card = nil
    local has_weapon, has_armor = false, false

    for _, acard in ipairs(cards) do
        if acard:isKindOf("Weapon") and not acard:getSuit() == sgs.Card_Diamond then has_weapon = true end
    end

    for _, acard in ipairs(cards) do
        if acard:isKindOf("Armor") and not acard:getSuit() == sgs.Card_Diamond then has_armor = true end
    end

    for _, acard in ipairs(cards) do
        if acard:getSuit() == sgs.Card_Diamond
            and ((self:getUseValue(acard) < sgs.ai_use_value.Indulgence) or inclusive)
        then
            local shouldUse = true

            if acard:isKindOf("Armor") then
                if not self.player:getArmor() then
                    shouldUse = false
                elseif self.player:hasEquip(acard) and not has_armor and self:evaluateArmor() > 0
                then
                    shouldUse = false
                end
            end

            if acard:isKindOf("Weapon") then
                if not self.player:getWeapon() then
                    shouldUse = false
                elseif self.player:hasEquip(acard) and not has_weapon
                then
                    shouldUse = false
                end
            end

            if shouldUse then
                card = acard
                break
            end
        end
    end

    if (self.player:getMark("MeowGuoseUsed") >= 4) then return nil end
    if card then
        return sgs.Card_Parse("#MeowGuoseCard2:" .. card:getEffectiveId() .. ":")
    else
        return sgs.Card_Parse("#MeowGuoseCard:.:")
    end
end

sgs.ai_skill_use_func["#MeowGuoseCard"] = function(card, use, self)
    self:sort(self.friends)


    sgs.ai_use_priority["#MeowGuoseCard"] = 5.5
    for _, friend in ipairs(self.friends) do
        if friend:containsTrick("Indulgence")
            and self:willSkipPlayPhase(friend)
            and not friend:hasSkills("shensu|qingyi|qiaobian")
            and (self:isWeak(friend) or self:getOverflow(friend) > 1)
        then
            for _, c in sgs.list(friend:getJudgingArea()) do
                if c:isKindOf("Indulgence")
                    and self.player:canDiscard(friend, c:getEffectiveId())
                then
                    use.card = card
                    if use.to then use.to:append(friend) end
                    return
                end
            end
        end
    end

    sgs.ai_use_priority["#MeowGuoseCard"] = 5.5

    for _, friend in ipairs(self.friends) do
        if friend:containsTrick("Indulgence")
            and self:willSkipPlayPhase(friend)
        then
            for _, c in sgs.list(friend:getJudgingArea()) do
                if c:isKindOf("Indulgence") and self.player:canDiscard(friend, c:getEffectiveId())
                then
                    use.card = card
                    if use.to then use.to:append(friend) end
                    return
                end
            end
        end
    end



    for _, friend in ipairs(self.friends) do
        if friend:containsTrick("Indulgence") then
            for _, c in sgs.list(friend:getJudgingArea()) do
                if c:isKindOf("Indulgence") and self.player:canDiscard(friend, card:getEffectiveId()) then
                    use.card = card
                    if use.to then use.to:append(friend) end
                    return
                end
            end
        end
    end
end

sgs.ai_use_priority["#MeowGuoseCard"] = 5.5
sgs.ai_use_value["#MeowGuoseCard"] = 5
sgs.ai_card_intention["#MeowGuoseCard"] = -60

sgs.ai_skill_use_func["#MeowGuoseCard2"] = function(card, use, self)
    self:sort(self.friends)
    local id = card:getEffectiveId()

    local indulgence = sgs.Sanguosha:cloneCard("Indulgence")
    indulgence:addSubcard(id)
    indulgence:deleteLater()
    if not self.player:isLocked(indulgence) then
        local dummy = self:aiUseCard(indulgence)
        if dummy.card and dummy.to:length() > 0
        then
            use.card = card
            sgs.ai_use_priority["#MeowGuoseCard2"] = sgs.ai_use_priority.Indulgence
            if use.to then use.to = dummy.to end
            return
        end
    end
end

sgs.ai_use_priority["#MeowGuoseCard2"] = 5.5
sgs.ai_use_value["#MeowGuoseCard2"] = 5
sgs.ai_card_intention["#MeowGuoseCard2"] = -60

function sgs.ai_cardneed.MeowGuose(to, card)
    return card:getSuit() == sgs.Card_Diamond
end

sgs.MeowGuose_suit_value = {
    diamond = 3.9
}


sgs.ai_skill_use["@@MeowLiuli"] = function(self, prompt, method)
    local others = self.room:getOtherPlayers(self.player)
    --local slash = self.player:getTag("liuli-card"):toCard()
    local slash = self.room:getTag("MeowLiuli"):toCardUse().card
    others = sgs.QList2Table(others)
    local source
    for _, player in ipairs(others) do
        if player:hasFlag("MeowLiuliSlashSource") then
            source = player
            break
        end
    end
    self:sort(self.enemies, "defense")
    local doMeowLiuli = function(who)
        if not self:isFriend(who) and who:hasSkills("leiji|nosleiji|olleiji")
            and (self:hasSuit("spade", true, who) or who:getHandcardNum() >= 3)
            and (getKnownCard(who, self.player, "Jink", true) >= 1 or self:hasEightDiagramEffect(who)) then
            return "."
        end

        local cards = self.player:getCards("h")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _, card in ipairs(cards) do
            if not self.player:isCardLimited(card, method) and self.player:canSlash(who) then
                if self:isFriend(who) and not (isCard("Peach", card, self.player) or isCard("Analeptic", card, self.player)) then
                    return "#MeowLiuliCard:" .. card:getEffectiveId() .. ":->" .. who:objectName()
                else
                    return "#MeowLiuliCard:" .. card:getEffectiveId() .. ":->" .. who:objectName()
                end
            end
        end

        local cards = self.player:getCards("e")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _, card in ipairs(cards) do
            local range_fix = 0
            if card:isKindOf("Weapon") then
                range_fix = range_fix + sgs.weapon_range[card:getClassName()] -
                    self.player:getAttackRange(false)
            end
            if card:isKindOf("OffensiveHorse") then range_fix = range_fix + 1 end
            if not self.player:isCardLimited(card, method) and self.player:canSlash(who, nil, true, range_fix) then
                return "#MeowLiuliCard:" .. card:getEffectiveId() .. ":->" .. who:objectName()
            end
        end
        return "."
    end
    local targets = {}
    local n = 1
    if not self.player:hasSkill("Meowdoumiao") then
        n = 2
    end
    for _, enemy in ipairs(self.enemies) do
        if not (source and source:objectName() == enemy:objectName()) then
            local ret = doMeowLiuli(enemy)
            if ret ~= "." then
                if #targets < n and n > 1 then
                    table.insert(targets, enemy:objectName())
                else
                    return ret
                end
            end
        end
    end

    for _, player in ipairs(others) do
        if self:objectiveLevel(player) == 0 and not (source and source:objectName() == player:objectName()) then
            local ret = doMeowLiuli(player)
            if ret ~= "." then
                if #targets < n and n > 1 then
                    table.insert(targets, player:objectName())
                else
                    return ret
                end
            end
        end
    end

    self:sort(self.friends_noself, "defense")
    self.friends_noself = sgs.reverse(self.friends_noself)


    for _, friend in ipairs(self.friends_noself) do
        if not self:slashIsEffective(slash, friend) or self:findLeijiTarget(friend, 50, source) then
            if not (source and source:objectName() == friend:objectName()) then
                local ret = doMeowLiuli(friend)
                if ret ~= "." then
                    if #targets < n and n > 1 then
                        table.insert(targets, friend:objectName())
                    else
                        return ret
                    end
                end
            end
        end
    end

    for _, friend in ipairs(self.friends_noself) do
        if self:needToLoseHp(friend, source, dummyCard())
        then
            if not (source and source:objectName() == friend:objectName()) then
                local ret = doMeowLiuli(friend)
                if ret ~= "." then
                    if #targets < n and n > 1 then
                        table.insert(targets, friend:objectName())
                    else
                        return ret
                    end
                end
            end
        end
    end

    if (self:isWeak() or self:ajustDamage(source, nil, 1, slash) > 1) and source:hasWeapon("axe") and source:getCards("he"):length() > 2
        and not self:getCardId("Peach") and not self:getCardId("Analeptic") then
        for _, friend in ipairs(self.friends_noself) do
            if not self:isWeak(friend) then
                if not (source and source:objectName() == friend:objectName()) then
                    local ret = doMeowLiuli(friend)
                    if ret ~= "." then
                        if #targets < n and n > 1 then
                            table.insert(targets, friend:objectName())
                        else
                            return ret
                        end
                    end
                end
            end
        end
    end

    if (self:isWeak() or self:ajustDamage(source, nil, 1, slash) > 1) and not self:getCardId("Jink") then
        for _, friend in ipairs(self.friends_noself) do
            if not self:isWeak(friend) or (self:hasEightDiagramEffect(friend) and getCardsNum("Jink", friend) >= 1) then
                if not (source and source:objectName() == friend:objectName()) then
                    local ret = doMeowLiuli(friend)
                    if ret ~= "." then
                        if #targets < n and n > 1 then
                            table.insert(targets, friend:objectName())
                        else
                            return ret
                        end
                    end
                end
            end
        end
    end
    if #targets > 0 then
        local cards = self.player:getCards("h")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _, card in ipairs(cards) do
            if not self.player:isCardLimited(card, method) then
                return "#MeowLiuliCard:" .. card:getEffectiveId() .. ":->" .. table.concat(targets, "+")
            end
        end
        local cards = self.player:getCards("e")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _, card in ipairs(cards) do
            local range_fix = 0
            if card:isKindOf("Weapon") then
                range_fix = range_fix + sgs.weapon_range[card:getClassName()] -
                    self.player:getAttackRange(false)
            end
            if card:isKindOf("OffensiveHorse") then range_fix = range_fix + 1 end
            if not self.player:isCardLimited(card, method) then
                return "#MeowLiuliCard:" .. card:getEffectiveId() .. ":->" .. table.concat(targets, "+")
            end
        end
    end
    return "."
end

sgs.ai_card_intention.MeowLiuliCard = function(self, card, from, to)
    sgs.ai_liuli_effect = true
    if not self:hasExplicitRebel() then
        sgs.ai_liuli_user = from
    else
        sgs.ai_liuli_user = nil
    end
end

function sgs.ai_slash_prohibit.MeowLiuli(self, from, to, card)
    if self:isFriend(to, from) then return false end
    if from:hasFlag("NosJiefanUsed") then return false end
    if to:isNude() then return false end
    for _, friend in ipairs(self:getFriends(from, true)) do
        if to:canSlash(friend, card) and self:slashIsEffective(card, friend, from) then return true end
    end
end

function sgs.ai_cardneed.MeowLiuli(to, card)
    return to:getCards("he"):length() <= 2
end

sgs.ai_skill_use["@@MeowTianxiang"] = function(self, data, method)
    if not method then method = sgs.Card_MethodDiscard end
    local friend_lost_hp = 10
    local friend_hp = 0
    local card_id
    local target
    local cant_use_skill
    local dmg

    if data == "@tianxiang-card" then
        dmg = self.player:getTag("MeowTianxiangDamage"):toDamage()
    else
        dmg = data
    end

    if not dmg then
        self.room:writeToConsole(debug.traceback())
        return "."
    end

    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    for _, card in ipairs(cards) do
        if not self.player:isCardLimited(card, method) and card:getSuit() == sgs.Card_Heart and not card:isKindOf("Peach") then
            card_id = card:getId()
            break
        end
    end
    if not card_id then return "." end

    self:sort(self.enemies, "hp")

    for _, enemy in ipairs(self.enemies) do
        if (enemy:getHp() <= dmg.damage and enemy:isAlive() and enemy:getLostHp() + dmg.damage < 3) then
            if (enemy:getHandcardNum() <= 2 or enemy:hasSkills("guose|leiji|ganglie|enyuan|qingguo|wuyan|kongcheng") or enemy:containsTrick("indulgence"))
                and self:canAttack(enemy, dmg.from or self.room:getCurrent(), dmg.nature)
                and not (dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and enemy:hasSkill("wuyan")) then
                return "#MeowTianxiangCard:" .. card_id .. ":->" .. enemy:objectName()
            end
        end
    end

    for _, friend in ipairs(self.friends_noself) do
        if friend:getLostHp() + dmg.damage > 1 and friend:isAlive()
        then
            if friend:isChained() and dmg.nature ~= sgs.DamageStruct_Normal
                and not self:isGoodChainTarget(friend, dmg.card or dmg.nature, dmg.from, dmg.damage)
            then
            elseif friend:getHp() >= 2 and dmg.damage < 2
                and (friend:hasSkills("yiji|buqu|nosbuqu|shuangxiong|zaiqi|yinghun|jianxiong|fangzhu")
                    or self:needToLoseHp(friend)
                    or (friend:getHandcardNum() < 3 and (friend:hasSkill("nosrende") or (friend:hasSkill("rende") and not friend:hasUsed("RendeCard")))))
            then
                return "#MeowTianxiangCard:" .. card_id .. ":->" .. friend:objectName()
            elseif dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick
                and friend:hasSkill("wuyan") and friend:getLostHp() > 1
            then
                return "#MeowTianxiangCard:" .. card_id .. ":->" .. friend:objectName()
            elseif hasBuquEffect(friend)
            then
                return "#MeowTianxiangCard:" .. card_id .. ":->" .. friend:objectName()
            end
        end
    end

    for _, enemy in ipairs(self.enemies) do
        if (enemy:getLostHp() <= 1 or dmg.damage > 1) and enemy:isAlive() and enemy:getLostHp() + dmg.damage < 4 then
            if (enemy:getHandcardNum() <= 2)
                or enemy:containsTrick("indulgence") or enemy:hasSkills("guose|leiji|vsganglie|ganglie|enyuan|qingguo|wuyan|kongcheng")
                and self:canAttack(enemy, (dmg.from or self.room:getCurrent()), dmg.nature)
                and not (dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and enemy:hasSkill("wuyan")) then
                return "#MeowTianxiangCard:" .. card_id .. ":->" .. enemy:objectName()
            end
        end
    end

    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        if not enemy:isWounded() and not self:hasSkills(sgs.masochism_skill, enemy) and enemy:isAlive()
            and self:canAttack(enemy, dmg.from or self.room:getCurrent(), dmg.nature)
            and (not (dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and enemy:hasSkill("wuyan") and enemy:getLostHp() > 0) or self:isWeak()) then
            return "#MeowTianxiangCard:" .. card_id .. ":->" .. enemy:objectName()
        end
    end

    return "."
end

sgs.ai_card_intention["#MeowTianxiangCard"] = function(self, card, from, tos)
    local to = tos[1]
    if self:needToLoseHp(to) then return end
    local intention = 10
    if hasBuquEffect(to) then
        intention = 0
    elseif (to:getHp() >= 2 and to:hasSkills("yiji|shuangxiong|zaiqi|yinghun|jianxiong|fangzhu"))
        or (to:getHandcardNum() < 3 and (to:hasSkill("nosrende") or (to:hasSkill("rende") and not to:hasUsed("RendeCard")))) then
        intention = 0
    end
    sgs.updateIntention(from, to, intention)
end

function sgs.ai_slash_prohibit.MeowTianxiang(self, from, to)
    if hasJueqingEffect(from, to) or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
    if from:hasFlag("NosJiefanUsed") then return false end
    if self:isFriend(to, from) then return false end
    return self:cantbeHurt(to, from)
end

sgs.MeowTianxiang_suit_value = {
    heart = 4.9
}

function sgs.ai_cardneed.MeowTianxiang(to, card, self)
    return (card:getSuit() == sgs.Card_Heart or (to:hasSkill("MeowHongyan") and card:getSuit() == sgs.Card_Spade))
        and (getKnownCard(to, self.player, "heart", false) + getKnownCard(to, self.player, "spade", false)) < 2
end

function getMeowJieyinId(self, male, equips, cards)
    if #equips <= 0 and #cards <= 0 then return -1 end
    if self.player:hasSkills(sgs.lose_equip_skill) then
        self:sortByKeepValue(equips)
        for _, c in ipairs(equips) do
            local index = c:getRealCard():toEquipCard():location()
            if male:getEquip(index) or not male:hasEquipArea(index) or (c:isKindOf("Armor") and not male:getArmor() and male:hasSkills("bazhen|linglong|bossmanjia|yizhong")) then
                continue
            end
            return c:getEffectiveId()
        end
    end
    if self.player:getArmor() and self:needToThrowArmor() then
        local armor_id = self.player:getArmor():getEffectiveId()
        local armor = sgs.Sanguosha:getCard(armor_id)
        if not male:getEquip(1) and male:hasEquipArea(1) and not male:hasSkills("bazhen|linglong|bossmanjia|yizhong") then
            return armor_id
        end
    end
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if self.player:canDiscard(self.player, c:getEffectiveId()) then
            return c:getEffectiveId()
        end
    end
    return -1
end

local MeowJieyi_skill = {}
MeowJieyi_skill.name = "MeowJieyi"
table.insert(sgs.ai_skills, MeowJieyi_skill)
MeowJieyi_skill.getTurnUseCard = function(self)
    return sgs.Card_Parse("#MeowJieyiCard:.:")
end

sgs.ai_skill_use_func["#MeowJieyiCard"] = function(card, use, self)
    local cards, equips = {}, {}
    for _, c in sgs.qlist(self.player:getCards("h")) do
        if self.player:canDiscard(self.player, c:getEffectiveId()) then
            table.insert(cards, c)
        end
        if c:isKindOf("EquipCard") then
            table.insert(equips, c)
        end
    end
    for _, c in sgs.qlist(self.player:getCards("e")) do
        table.insert(equips, c)
    end
    if #cards <= 0 and #equips <= 0 then return end

    local weak_friends, recover_friends, draw_friends, not_friends, enemies = {}, {}, {}, {}, {}

    if self:isWeak() and self.player:getLostHp() > 0 then
        self:sort(self.friends_noself)
        for _, p in ipairs(self.friends_noself) do
            if p:getHp() > self.player:getHp() and self:canDraw(p) then
                table.insert(draw_friends, p)
            end
        end
        for _, p in ipairs(draw_friends) do
            local id = getMeowJieyinId(self, p, equips, cards)
            if id > 0 then
                use.card = sgs.Card_Parse("#MeowJieyiCard:" .. id .. ":")
                if use.to then use.to:append(p) end
                return
            end
        end

        for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
            if p:getHp() > self.player:getHp() and not self:isEnemy(p) then
                table.insert(not_friends, p)
            end
        end
        for _, p in ipairs(not_friends) do
            local id = getMeowJieyinId(self, p, equips, cards)
            if id > 0 then
                use.card = sgs.Card_Parse("#MeowJieyiCard:" .. id .. ":")
                if use.to then use.to:append(p) end
                return
            end
        end

        self:sort(self.enemies)
        for _, p in ipairs(self.enemies) do
            if p:getHp() > self.player:getHp() and not self:canDraw(p) then
                table.insert(enemies, p)
            end
        end
        for _, p in ipairs(enemies) do
            local id = getMeowJieyinId(self, p, equips, cards)
            if id > 0 then
                use.card = sgs.Card_Parse("#MeowJieyiCard:" .. id .. ":")
                if use.to then use.to:append(p) end
                return
            end
        end

        self.enemies = sgs.reverse(self.enemies)
        for _, p in ipairs(self.enemies) do
            if p:getHp() > self.player:getHp() then
                table.insert(enemies, p)
            end
        end
        for _, p in ipairs(enemies) do
            local id = getMeowJieyinId(self, p, equips, cards)
            if id > 0 then
                use.card = sgs.Card_Parse("#MeowJieyiCard:" .. id .. ":")
                if use.to then use.to:append(p) end
                return
            end
        end
    end

    for _, p in ipairs(self.friends_noself) do
        if self:isWeak(p) and p:getHp() < self.player:getHp() and p:getLostHp() > 0 then
            table.insert(weak_friends, p)
        end
    end
    if #weak_friends > 0 then
        self:sort(weak_friends, "hp")
        for _, p in ipairs(weak_friends) do
            local id = getMeowJieyinId(self, p, equips, cards)
            if id < 0 then continue end
            use.card = sgs.Card_Parse("#MeowJieyiCard:" .. id .. ":")
            if use.to then use.to:append(p) end
            return
        end
    end

    for _, p in ipairs(self.friends_noself) do
        if p:getHp() < self.player:getHp() and p:getLostHp() > 0 then
            table.insert(recover_friends, p)
        end
    end
    if #recover_friends > 0 then
        self:sort(recover_friends)
        for _, p in ipairs(recover_friends) do
            local id = getMeowJieyinId(self, p, equips, cards)
            if id < 0 then continue end
            use.card = sgs.Card_Parse("#MeowJieyiCard:" .. id .. ":")
            if use.to then use.to:append(p) end
            return
        end
    end
    self:sort(self.friends_noself)
    for _, p in ipairs(self.friends_noself) do
        if p:getHp() > self.player:getHp() and self:canDraw(p) then
            table.insert(draw_friends, p)
        end
    end
    for _, p in ipairs(draw_friends) do
        local id = getMeowJieyinId(self, p, equips, cards)
        if id > 0 then
            use.card = sgs.Card_Parse("#MeowJieyiCard:" .. id .. ":")
            if use.to then use.to:append(p) end
            return
        end
    end

    if self.player:getLostHp() > 0 then
        for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
            if p:getHp() > self.player:getHp() and not self:isEnemy(p) then
                table.insert(not_friends, p)
            end
        end
        for _, p in ipairs(not_friends) do
            local id = getMeowJieyinId(self, p, equips, cards)
            if id > 0 then
                use.card = sgs.Card_Parse("#MeowJieyiCard:" .. id .. ":")
                if use.to then use.to:append(p) end
                return
            end
        end

        self:sort(self.enemies)
        for _, p in ipairs(self.enemies) do
            if p:getHp() > self.player:getHp() and not self:canDraw(p) then
                table.insert(enemies, p)
            end
        end
        for _, p in ipairs(enemies) do
            local id = getMeowJieyinId(self, p, equips, cards)
            if id > 0 then
                use.card = sgs.Card_Parse("#MeowJieyiCard:" .. id .. ":")
                if use.to then use.to:append(p) end
                return
            end
        end
    end
end

sgs.ai_use_priority["#MeowJieyiCard"] = 0

sgs.ai_skill_choice.MeowJieyi = function(self, choices, data)
    local target = data:toPlayer()

    if self:isFriend(target) and target:getHp() < getBestHp(target) then
        self.room:setPlayerFlag(target, "MeowJieyi_Target")
        return "yes"
    end
    return "no"
end

sgs.ai_choicemade_filter.skillChoice["MeowJieyi"] = function(self, player, promptlist)
    local choice = promptlist[#promptlist]
    local target
    local list = self.room:getAlivePlayers()
    for _, p in sgs.qlist(list) do
        if p:hasFlag("MeowJieyi_Target") then
            target = p
            self.room:setPlayerFlag(p, "-MeowJieyi_Target")
        end
    end
    if choice == "yes" and target then
        sgs.updateIntention(player, target, -80)
    end
end

sgs.ai_skill_invoke.MeowXiaoji_dis = function(self, data)
    for _, enemy in ipairs(self.enemies) do
        if (self:doDisCard(enemy, "he") or self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and not enemy:isNude() and
            not (enemy:hasSkill("guzheng") and self.room:getCurrent():getPhase() == sgs.Player_Discard) then
            return true
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if (self:hasSkills(sgs.lose_equip_skill, friend) and not friend:getEquips():isEmpty())
            or (self:needToThrowArmor(friend) and friend:getArmor()) or self:doDisCard(friend, "he") then
            return true
        end
    end
    return false
end

sgs.ai_skill_playerchosen.MeowXiaoji = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
    for _, enemy in ipairs(self.enemies) do
        if (self:doDisCard(enemy, "je") or self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and not enemy:isNude() then
            return enemy
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if (self:hasSkills(sgs.lose_equip_skill, friend) and not friend:getEquips():isEmpty())
            or (self:needToThrowArmor(friend) and friend:getArmor()) or self:doDisCard(friend, "je") then
            return friend
        end
    end
    return nil
end

sgs.ai_choicemade_filter.cardChosen.MeowXiaoji = sgs.ai_choicemade_filter.cardChosen.dismantlement

sgs.ai_use_revises.MeowXiaoji = function(self,card,use)
	if card:isKindOf("EquipCard") and self:evaluateArmor(card)>-5
	then use.card = card return true end
end

sgs.lose_equip_skill = sgs.lose_equip_skill .."|MeowXiaoji"

local MeowQingguo_skill = {}
MeowQingguo_skill.name = "MeowQingguo"
table.insert(sgs.ai_skills, MeowQingguo_skill)
MeowQingguo_skill.getTurnUseCard = function(self)
    local cards = self:addHandPile()
    self:sortByUseValue(cards, true)
    if not self.player:hasSkill("Meowdoumiao") then
        for _, c in ipairs(cards) do
            if c:isKindOf("Jink") then
                return sgs.Card_Parse(("peach:MeowQingguo[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(),
                    c:getEffectiveId()))
            end
        end
    end
end

sgs.ai_view_as.MeowQingguo = function(card, player, card_place)
    local suit = card:getSuitString()
    local number = card:getNumberString()
    local card_id = card:getEffectiveId()
    if card:isBlack() and card_place == sgs.Player_PlaceHand then
        return ("jink:MeowQingguo[%s:%s]=%d"):format(suit, number, card_id)
    elseif card:isKindOf("Jink") and card_place == sgs.Player_PlaceHand and not player:hasSkill("Meowdoumiao") then
        return ("peach:MeowQingguo[%s:%s]=%d"):format(suit, number, card_id)
    end
end

function sgs.ai_cardneed.MeowQingguo(to, card)
    return to:getCards("h"):length() < 2 and (card:isBlack() or card:isKindOf("Jink"))
end

sgs.ai_skill_invoke.MeowJueqing = function(self, data)
    local damage = data:toDamage()
    if not damage or damage.to:isDead() or self:isFriend(damage.to) then return false end
    if self:cantDamageMore(self.player, damage.to) then return false end
    local n = damage.damage - self.player:getHp()
    if n < 0 or hasBuquEffect(self.player) or self:getSaveNum(true) >= n then return true end
    return false
end

sgs.ai_getLeastHandcardNum_skill.Meowshangshi = function(self, player, least)
	if least < player:getLostHp() then
		return math.max(player:getLostHp(), 1)
	end
end


function sgs.ai_skill_invoke.MeowZhenlie(self, data)
    local use = data:toCardUse()
    if not use.from or use.from:isDead() then return false end
    if self.role == "rebel" and sgs.ai_role[use.from:objectName()] == "rebel" and not use.from:hasSkill("jueqing")
        and self.player:getHp() == 1 and self:getAllPeachNum() < 1 then
        return false
    end

    if self:isEnemy(use.from) or (self:isFriend(use.from) and self.role == "loyalist" and not use.from:hasSkill("jueqing") and use.from:isLord() and self.player:getHp() == 1) then
        if use.card:isKindOf("Slash") then
            if not self:slashIsEffective(use.card, self.player, use.from) then return false end
            if self:ajustDamage(use.from, self.player, 1, use.card) > 1 then return true end
            local jink_num = self:getExpectedJinkNum(use)
            local hasHeart = false
            for _, card in ipairs(self:getCards("Jink")) do
                if card:getSuit() == sgs.Card_Heart then
                    hasHeart = true
                    break
                end
            end
            if self:getCardsNum("Jink") == 0
                or jink_num == 0
                or self:getCardsNum("Jink") < jink_num
                or (use.from:hasSkill("dahe") and self.player:hasFlag("dahe") and not hasHeart) then
                if use.card:isKindOf("NatureSlash") and self.player:isChained() and not self:isGoodChainTarget(self.player, use.card, use.from) then return true end
                if use.from:hasSkill("nosqianxi") and use.from:distanceTo(self.player) == 1 then return true end
                if self:isFriend(use.from) and self.role == "loyalist" and not hasJueqingEffect(use.from, self.player, sgs.card_damage_nature[use.card:getClassName()]) and use.from:isLord() and self.player:getHp() == 1 then return true end
                if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkill("tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or hasJueqingEffect(use.from, self.player, sgs.card_damage_nature[use.card:getClassName()]))
                    and self:doDisCard(use.from, "he") then
                    return true
                end
            end
        elseif use.card:isKindOf("AOE") then
            local from = use.from
            if use.card:isKindOf("SavageAssault") then
                local menghuo = self.room:findPlayerBySkillName("huoshou")
                if menghuo then from = menghuo end
            end

            local friend_null = 0
            for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
                if self:isFriend(p) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
                if self:isEnemy(p) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
            end
            friend_null = friend_null + self:getCardsNum("Nullification")
            local sj_num = self:getCardsNum(use.card:isKindOf("SavageAssault") and "Slash" or "Jink")

            if not self:hasTrickEffective(use.card, self.player, from) then return false end
            if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, from) then return false end
            if use.from:hasSkill("drwushuang") and self.player:getCardCount() == 1 and self:hasLoseHandcardEffective() then return true end
            if sj_num == 0 and friend_null <= 0 then
                if self:isEnemy(from) and hasJueqingEffect(from, self.player, sgs.card_damage_nature[use.card:getClassName()]) then
                    return self:doDisCard(from, "he")
                end
                if self:isFriend(from) and self.role == "loyalist" and from:isLord() and self.player:getHp() == 1 and not hasJueqingEffect(from, self.player, sgs.card_damage_nature[use.card:getClassName()]) then
                    return self:doDisCard(from, "he")
                end
                if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkill("tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or hasJueqingEffect(from, self.player, sgs.card_damage_nature[use.card:getClassName()])
                        and self:doDisCard(use.from, "he")) then
                    return true
                end
            end
        elseif self:isEnemy(use.from) then
            if use.card:isKindOf("FireAttack") and use.from:getHandcardNum() > 0 then
                if not self:hasTrickEffective(use.card, self.player) then return false end
                if not self:damageIsEffective(self.player, sgs.DamageStruct_Fire, use.from) then return false end
                if (self.player:hasArmorEffect("vine") or self.player:getMark("&kuangfeng") > 0) and use.from:getHandcardNum() > 3
                    and not (use.from:hasSkill("hongyan") and getKnownCard(self.player, self.player, "spade") > 0) then
                    return self:doDisCard(use.from, "he")
                elseif self.player:isChained() and not self:isGoodChainTarget(self.player, nil, use.from)
                then
                    return self:doDisCard(use.from, "he")
                end
            elseif (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement"))
                and self:getCardsNum("Peach") == self.player:getHandcardNum() and not self.player:isKongcheng()
            then
                if not self:hasTrickEffective(use.card, self.player) then return false end
                return self:doDisCard(use.from, "he")
            elseif use.card:isKindOf("Duel")
            then
                if self:getCardsNum("Slash") == 0 or self:getCardsNum("Slash") < getCardsNum("Slash", use.from, self.player)
                then
                    if not self:hasTrickEffective(use.card, self.player) then return false end
                    if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, use.from) then return false end
                    return self:doDisCard(use.from, "he")
                end
            elseif use.card:isKindOf("TrickCard") and not use.card:isKindOf("AmazingGrace")
            then
                if self:doDisCard(use.from, "he") and self:needToLoseHp(self.player, nil, use.card)
                then
                    return true
                end
            end
        end
    end
    return false
end

sgs.ai_skill_invoke.MeowMiji = function(self, data)
    return true
end

sgs.ai_skill_playerchosen.MeowMiji = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "hp")
    local max = 0
    for _, p in ipairs(targets) do
        if p:getLostHp() > max then
            max = p:getLostHp()
        end
    end
    for _, p in ipairs(targets) do
        if p:getLostHp() == max then
            return p
        end
    end
    return nil
end


sgs.ai_skill_use["@@MeowMiji"] = function(self, data, method)
    return "."
end

sgs.ai_skill_invoke.Meowdoumiao = function(self, data)
    return sgs.ai_skill_playerchosen.Meowdoumiao(self, self.room:getOtherPlayers(self.player)) ~= nil
end

sgs.ai_skill_playerchosen.Meowdoumiao = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
    for _, enemy in ipairs(self.enemies) do
        if (self:doDisCard(enemy, "h") or self:getDangerousCard(enemy) or self:getValuableCard(enemy) or self:hasSkills("MeowZhenlie|Meowshangshi|MeowJueqing|MeowQingguo|MeowXiaoji|MeowJizhi|MeowShenxian|MeowDuanchang|MeowBeige", enemy)) and not enemy:isNude() then
            return enemy
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if self:doDisCard(friend, "h") or self:hasSkills("Meowxianzhou|MeowQiangwu|MeowLieren", friend) then
            return friend
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if self:doDisCard(friend, "h") then
            return friend
        end
    end
    return nil
end
sgs.ai_skill_invoke.MeowGuowu = true
sgs.ai_cardneed.MeowGuowu = sgs.ai_cardneed.slash

