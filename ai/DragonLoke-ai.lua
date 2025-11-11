
local dl_chaju_skill = {}
dl_chaju_skill.name = "dl_chaju"
table.insert(sgs.ai_skills,dl_chaju_skill)
dl_chaju_skill.getTurnUseCard = function(self, inclusive)
    local card_str = ("#dl_chaju:%d:")
    return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func["#dl_chaju"] = function(card, use, self)
    for _,friend in ipairs(self.friends_noself)do
        if friend:getHandcardNum() <= self.player:getHandcardNum() and self:doDisCard(friend, "h", true) and not friend:isKongcheng() then
            use.card = card
            if use.to then
                use.to:append(friend)
                return
            end
        end
    end
    for _,friend in ipairs(self.friends_noself)do
        if friend:getHandcardNum() <= self.player:getHandcardNum() and not friend:isKongcheng() then
            use.card = card
            if use.to then
                use.to:append(friend)
                return
            end
        end
    end
end
sgs.ai_use_priority["dl_chaju"] = sgs.ai_use_priority.RendeCard

sgs.ai_skill_choice.dl_chaju = function(self,choices,data)
    local target = data:toPlayer()
    local x = self.player:getMaxHp() - self.player:getHandcardNum()
    if target and self:isFriend(target) then
        x = x + target:getMaxHp() - target:getHandcardNum()
    end
    if x > 0 then
        return "2"
    end
    return "1"
end

local dl_pindi_skill={}
dl_pindi_skill.name="dl_pindi"
table.insert(sgs.ai_skills,dl_pindi_skill)
dl_pindi_skill.getTurnUseCard=function(self,inclusive)
	return sgs.Card_Parse("#dl_pindi:.:")
end

sgs.ai_skill_use_func["#dl_pindi"]=function(card,use,self)
	use.card=card
end
sgs.ai_use_priority["dl_pindi"] = 6.8


local dl_yanxiao_skill={}
dl_yanxiao_skill.name="dl_yanxiao"
table.insert(sgs.ai_skills,dl_yanxiao_skill)
dl_yanxiao_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)
	local use_card
	self:sortByUseValue(cards,true)

	for _,card in sgs.list(cards)  do
		if card:isRed() then
			use_card = card
			break
		end
	end

	if use_card then
		return sgs.Card_Parse("#dl_yanxiao:"..use_card:getEffectiveId()..":")
	end
end
sgs.ai_skill_use_func["#dl_yanxiao"] = function(card,use,self)
    if self.player:hasSkill("dl_liuli") then
        self:sort(self.friends_noself,"defense")
        if self:getOverflow()>0 then
            local lord = self.room:getLord()
            if lord and self:isFriend(lord)  then
                local can_invoke = true
                for _,c in sgs.qlist(lord:getJudgingArea())do
                    if string.find(c:objectName(),"kehexumou") then 
                        can_invoke = false
                        break
                    end
                end
                if can_invoke then
                    use.card = card
                    self.dl_liuli = lord
                    return
                end
            end

            for _,friend in sgs.list(self.friends_noself)do
                local can_invoke = true
                for _,c in sgs.qlist(friend:getJudgingArea())do
                    if string.find(c:objectName(),"kehexumou") then 
                        can_invoke = false
                        break
                    end
                end
                if can_invoke then
                    use.card = card
                    self.dl_liuli = friend
                    return
                end
            end
            local can_invoke = true
            for _,c in sgs.qlist(self.player:getJudgingArea())do
                if string.find(c:objectName(),"kehexumou") then 
                    can_invoke = false
                    break
                end
            end
            if can_invoke then
                use.card = card
                self.dl_liuli = nil
                return
            end
        end
    end
    use.card = card
end


sgs.ai_skill_use["@@dl_liuli"] = function(self,prompt,method)
	local others = self.room:getOtherPlayers(self.player)
    local use = self.room:getTag("dl_liuli"):toCardUse()
	local slash = use.card
	others = sgs.QList2Table(others)
	local source
	for _,player in ipairs(others)do
		if player:getMark("dl_liuli_usefrom") > 0 then
			source = player
			break
		end
	end
	self:sort(self.enemies,"defense")
    local doLiuli = function(who)
        if not self:isFriend(who) and who:hasSkills("leiji|nosleiji|olleiji")
            and (self:hasSuit("spade",true,who) or who:getHandcardNum()>=3)
            and (getKnownCard(who,self.player,"Jink",true)>=1 or self:hasEightDiagramEffect(who)) then
            return "."
        end

        local cards = self.player:getCards("h")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _,card in ipairs(cards)do
            if not self.player:isCardLimited(card,method) and self.player:canSlash(who) then
                if self:isFriend(who) and not (isCard("Peach",card,self.player) or isCard("Analeptic",card,self.player)) then
                    return "#dl_liuli:"..card:getEffectiveId()..":->"..who:objectName()
                else
                    return "#dl_liuli:"..card:getEffectiveId()..":->"..who:objectName()
                end
            end
        end

        local cards = self.player:getCards("e")
        cards=sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _,card in ipairs(cards)do
            local range_fix = 0
            if card:isKindOf("Weapon") then range_fix = range_fix+sgs.weapon_range[card:getClassName()]-self.player:getAttackRange(false) end
            if card:isKindOf("OffensiveHorse") then range_fix = range_fix+1 end
            if not self.player:isCardLimited(card,method) and self.player:canSlash(who,nil,true,range_fix) then
                return "#dl_liuli:"..card:getEffectiveId()..":->"..who:objectName()
            end
        end
        return "."
    end
    if slash and slash:isKindOf("Slash") then

        for _,enemy in ipairs(self.enemies)do
            if not (source and source:objectName()==enemy:objectName()) then
                local ret = doLiuli(enemy)
                if ret~="." then return ret end
            end
        end

        for _,player in ipairs(others)do
            if self:objectiveLevel(player)==0 and not (source and source:objectName()==player:objectName()) then
                local ret = doLiuli(player)
                if ret~="." then return ret end
            end
        end


        self:sort(self.friends_noself,"defense")
        self.friends_noself = sgs.reverse(self.friends_noself)


        for _,friend in ipairs(self.friends_noself)do
            if not self:slashIsEffective(slash,friend) or self:findLeijiTarget(friend,50,source) then
                if not (source and source:objectName()==friend:objectName()) then
                    local ret = doLiuli(friend)
                    if ret~="." then return ret end
                end
            end
        end

        for _,friend in ipairs(self.friends_noself)do
            if source~=friend and self:needToLoseHp(friend,source,dummyCard()) then
                local ret = doLiuli(friend)
                if ret~="." then return ret end
            end
        end

        if (self:isWeak() or self:ajustDamage(source,nil,1,slash)>1) and source:hasWeapon("axe") and source:getCards("he"):length()>2
        and not self:getCardId("Peach") and not self:getCardId("Analeptic") then
            for _,friend in ipairs(self.friends_noself)do
                if not self:isWeak(friend) then
                    if not (source and source:objectName()==friend:objectName()) then
                        local ret = doLiuli(friend)
                        if ret~="." then return ret end
                    end
                end
            end
        end

        if (self:isWeak() or self:ajustDamage(source,nil,1,slash)>1) and not self:getCardId("Jink") then
            for _,friend in ipairs(self.friends_noself)do
                if not self:isWeak(friend) or (self:hasEightDiagramEffect(friend) and getCardsNum("Jink",friend)>=1) then
                    if not (source and source:objectName()==friend:objectName()) then
                        local ret = doLiuli(friend)
                        if ret~="." then return ret end
                    end
                end
            end
        end
    else
        if self.dl_liuli then
            local ret = doLiuli(self.dl_liuli)
            if ret~="." then return ret end
        else
            return "."
        end
    end
	return "."
end
sgs.ai_slash_prohibit.dl_liuli = sgs.ai_slash_prohibit.liuli
sgs.ai_cardneed.dl_liuli = sgs.ai_cardneed.liuli







