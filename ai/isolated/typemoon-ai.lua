-- Fixed Typemoon policies; colliding Jiuzi bodies route by captured native source origin.
local function known(value,key)
    if value==nil then ai_unsupported("Typemoon fact is not projected",key) end
    return value
end

local function has_skill(self,player,name,multiple)
    local value=AIValue.callKnown(player, multiple and "hasSkills" or "hasSkill", name)
    local view=type(player)=="table" and rawget(player,"_view")
    if value or not view or view.skills_complete==true then return value end
    if player:objectName()==self.player:objectName() then ai_unsupported("Typemoon owner skill roster incomplete",name) end
    return self:useKnowledgeEstimate({status="estimate",value=false,player=player:objectName(),
        basis="typemoon.undisclosed_skill_uses_visible_roster"},name)
end
local function sort_in_place(self,list,key)
    local ordered=self:sort(list, key)
    for i,value in ipairs(ordered) do list[i]=value end
end
local function source_global_slash(self)
    -- The donor reads an undeclared global `slash` of the gameplay VM; that VM's
    -- globals are not projected.
    ai_unsupported("Typemoon source global slash is not projected","global slash")
end
sgs.ai_skill_invoke["yinyang"] = function(self, data)
	local counter
	if self.player:isFemale() then
		counter = self.player:getPile("maleshiki"):length()
	else
		counter = self.player:getPile("femaleshiki"):length()
	end
	if has_skill(self,self.player,"lianying|noslianying|sijian",true) or (has_skill(self,self.player,"shangshi|nosshangshi",true) and self.player:isWounded()) then
		return true
	end
	if self.player:containsTrick("indulgence") then
		if counter <= self.player:getHandcardNum() then return true else return false end
	end
	if self.player:isFemale() then
		if self.player:getHandcardNum() > math.max(counter, 4) then
			return true
		end
	elseif counter > math.max(self.player:getHandcardNum(), 4) then
		return false
	end
	if counter >= self.player:getHandcardNum() then return true else return false end
end

sgs.ai_need_damaged["jialan"] = function(self, attacker, player)
	if has_skill(self,player,"jialan",false) and player:getStrategyMark("jialan") == 0 and not has_skill(self,player,"chanyuan",false)
		and self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < player:getHp()
		and (player:getHp() > 0 or (player:getHp() == 1 and (player:faceUp() or has_skill(self,player,"guixin",false)))) then
		return true
	end
	return false
end

function sgs.ai_cardneed.sinzhisi(to, card, self)
	for _, enemy in ipairs(self.enemies) do
		if card:isKindOf("Slash") and to:canSlash(enemy, nil, true) and self:slashIsEffective(card, enemy)
			and not (has_skill(self,enemy,"kongcheng",false) and enemy:isKongcheng())
			and self:isGoodTarget(enemy, self.enemies, source_global_slash(self)) and not self:slashProhibit(card, enemy) and enemy:getStrategyMark("@sharengui") == 1 then
			return getKnownCard(to, self.player, "Slash", true) == 0
		end
	end
end

sgs.ai_skill_invoke["Tohnozhisi"] = function(self, data)
	sort_in_place(self,self.enemies,"defense")
	local slash = self:getEvaluationCard("slash")
	if self:getCardsNum("Slash") > 0 then
		for _, enemy in ipairs(self.enemies) do
			if not self:slashProhibit(slash, enemy) and self.player:canSlash(enemy, slash, false) and self:isGoodTarget(enemy, self.enemies, nil)
				and self.player:distanceTo(enemy) <= self.player:getAttackRange() and not self:isWeak(self.player) then
				return true
			end
		end
	end
	return false
end

sgs.ai_fill_skill.jisha = function(self,inclusive,request)
	if not self.player:getStrategyHasUsed("#jishaCard") then
		return self:legacySkillSeed("jisha", "#jishaCard", request)
	end
	return nil
end

sgs.ai_skill_use_func["#jishaCard"] = function(card, use, self,request)
	sort_in_place(self,self.enemies,"defense")
	local slash = self:getEvaluationCard("slash")
	if self:getCardsNum("Slash") ~= 0 then
		for _, enemy in ipairs(self.enemies) do
			if not self:slashProhibit(card, enemy) and self:slashIsEffective(card, enemy) and self:isGoodTarget(enemy, self.enemies, slash) then
				use.card = self:bindSkillCard("jisha", {}, request, nil, "#jishaCard")
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not self:slashProhibit(card, enemy) and self:isGoodTarget(enemy, self.enemies, slash) then
				use.card = self:bindSkillCard("jisha", {}, request, nil, "#jishaCard")
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
	else
		for _, friend in ipairs(self.friends) do
			if has_skill(self,friend,"tiandu",false) then
				use.card = self:bindSkillCard("jisha", {}, request, nil, "#jishaCard")
				if use.to then
					use.to:append(friend)
				end
				return
			end
		end
		sort_in_place(self,self.friends,"handcard")
		for _, friend in ipairs(self.friends) do
			use.card = self:bindSkillCard("jisha", {}, request, nil, "#jishaCard")
			if use.to then
				use.to:append(friend)
			end
			return
		end
	end
end

sgs.ai_card_intention.jishaCard = 100
sgs.ai_use_value.jishaCard = 10
sgs.ai_use_priority.jishaCard = 10

sgs.ai_skill_invoke["#jishamod"] = function(self, data)
	return true
end

-- Jiuzi has two distinct live bodies under the fixed package load order.
-- Select each key from the immutable startup origin, never ai_skills aliases.
local function jiuzi_variant(self, registry, key)
    -- Which package's donor body won the gameplay VM's load order is that VM's
    -- registry state, not projected.
    ai_unsupported("Jiuzi effective callback origin is not projected", registry .. "." .. key)
end
local function jiuzi_seed(self,request)
    return self:legacySkillSeed("Jiuzi", "#JiuziCard", request)
end
local function jiuzi_select(self,use,enemy,request)
    use.card=self:bindSkillCard("Jiuzi", {}, request, nil, "#JiuziCard")
    if use.to then use.to:append(enemy) end
end
sgs.ai_fill_skill.Jiuzi = function(self,inclusive,request)
    local variant = jiuzi_variant(self,"ai_fill_skill","Jiuzi")
    if not variant then return nil end
    local player=self.player
    local used=player:usedTimes("#JiuziCard")
    if variant=="touhou" then
        for _,enemy in ipairs(self.enemies) do
            if player:canSlash(enemy, nil, false) and player:getStrategyMark("@jianding")>0
                and used<player:getHp() then return jiuzi_seed(self,request) end
        end
        return nil
    end
    local slash=self:getEvaluationCard("slash")
    if player:getStrategyMark("@jianding")>0 and used<player:getHp() then
        sort_in_place(self,self.enemies,"defense")
        for _,enemy in ipairs(self.enemies) do
            if has_skill(self,player,"sinzhisi",false) and player:canSlash(enemy, slash, false)
                and enemy:getStrategyMark("@sharengui")==1 then
                return jiuzi_seed(self,request)
            elseif player:getStrategyMark("@jianding")>3 and used<3 and not self:slashProhibit(slash,enemy)
                and self:slashIsEffective(slash,enemy) and self:isGoodTarget(enemy,self.enemies,slash) then
                if (has_skill(self,player,"CixiongSkill",false) and enemy:isMale()~=player:isMale())
                    or (has_skill(self,player,"HuoshanSkill",false) and enemy:hasArmorEffect("vine"))
                    or (has_skill(self,player,"BaojiSkill",false) and enemy:isKongcheng())
                    or has_skill(self,player,"moukui",false) then return jiuzi_seed(self,request) end
                if used<1 or self:isWeak(enemy) then return jiuzi_seed(self,request) end
            end
        end
    end
    return nil
end
sgs.ai_skill_use_func["#JiuziCard"] = function(card,use,self,request)
    local variant=jiuzi_variant(self,"ai_skill_use_func","#JiuziCard")
    if not variant then return end
    sort_in_place(self,self.enemies,"defense")
    if variant=="touhou" then
        local function eligible(enemy,marked)
            return self.player:canSlash(enemy, nil, false) and self:slashIsEffective(card,enemy)
                and (not marked or enemy:getStrategyFlag("zhisi_lost"))
                and not(has_skill(self,enemy,"kongcheng",false) and enemy:isKongcheng())
                and not(has_skill(self,enemy,"xiangle",false) and self:getCardsNum("BasicCard")==0)
                and not self:canLiuli(enemy,self.friends_noself)
                and not self:findLeijiTarget(enemy,50,self.player)
        end
        for _,enemy in ipairs(self.enemies) do
            if eligible(enemy,true) then jiuzi_select(self,use,enemy,request);return end
        end
        for _,enemy in ipairs(self.enemies) do
            if eligible(enemy,false) then jiuzi_select(self,use,enemy,request);return end
        end
        return
    end
    local slash=self:getEvaluationCard("slash")
    for _,enemy in ipairs(self.enemies) do
        if not self:slashProhibit(card,enemy) and self:slashIsEffective(card,enemy)
            and self:isGoodTarget(enemy,self.enemies,slash) and enemy:getStrategyMark("@sharengui")==1 then
            jiuzi_select(self,use,enemy,request);return
        end
    end
    for _,enemy in ipairs(self.enemies) do
        if not self:slashProhibit(card,enemy) and self:slashIsEffective(card,enemy)
            and self:isGoodTarget(enemy,self.enemies,slash) then
            jiuzi_select(self,use,enemy,request);return
        end
    end
end
