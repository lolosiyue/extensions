-- Source: b6025acc ai/LuaOldEnemyGirls-ai.lua.
local function context(self)
    local c=self.request and self.request.options and self.request.options.context
    local row=c and c.lua_old_enemy_girls
    if type(row)~="table" then ai_unsupported("OldEnemyGirls request facts absent","lua_old_enemy_girls") end
    return row
end
local function mark(player,name)
    -- getStrategyMark records an explicit viewer prior when a public zero was not projected.
    return player:getStrategyMark(name)
end
local function getOEMark(player)
    if mark(player,"@LuaPublicEnemy")>0 then return nil end
    for n=0,8 do if mark(player,"@LuaOldEnemy"..n)>0 then return "@LuaOldEnemy"..n end end
end
local function others(player,room)
    -- All package callers use only membership/emptiness; room ordering has no effect.
    return room:getOtherPlayers(player)
end
local function findMyOE(player,room)
    local key=getOEMark(player)
    if not key then return nil end
    for _,p in ipairs(others(player,room)) do if mark(p,key)>0 then return p end end
end
local function getOEList(player,room)
    local list=AIList.new({})
    local roster=others(player,room)
    local key=getOEMark(player)
    for _,p in ipairs(roster) do
        if key and mark(p,key)>0 then list:append(p) end
        if mark(p,"@LuaPublicEnemy")>0 then list:append(p) end
    end
    return list
end
local function paid(self,skill,costs,request)
    return self:bindSkillCard(skill, costs, request, nil, "#"..skill.."Card")
end
local function answer(self,id,target,request)
    if request and type(request.getActivationSkillName)~="function" then request=AILegacyRequest.new(request,self.room) end
    local plan=AIUsePlan.new()
    plan.card=paid(self,"LuaHuowei",{id},request)
    plan.to=AIList.new({target})
    return plan:toAnswer()
end
local function yanling(self)
    local row=context(self)
    if row.targetlist_known_nil~=true then ai_unsupported("donor free targetlist is not known nil","LuaYanling.targetlist") end
    if row.yanling_card==false then return self:getEvaluationCard("slash") end
    if type(row.yanling_card)~="table" then ai_unsupported("owner LuaYanling card tag unknown","LuaYanling") end
    return CardView.new(row.yanling_card)
end
ai_fill_skill.LuaFengxi = function(self, options, request)
    local inclusive = options and options.inclusive

    if not getOEList(self.player,self.room):isEmpty() and not self.player:getStrategyHasUsed("#LuaFengxiCard") then
        return self:legacySkillSeed("LuaFengxi", "#LuaFengxiCard", request)
    end
end

ai_card_use["#LuaFengxiCard"] = function(self, card, use, request)
    self:sort(self.enemies, "handcard")
    for _, p in ipairs(self.enemies) do
        if getOEList(self.player,self.room):contains(p) and not p:isNude() then
            use.card = paid(self,"LuaFengxi",{},request)
            if use.to then use.to:append(p) end
            return
        end
    end
end

sgs.ai_use_priority["LuaFengxiCard"] = sgs.ai_use_priority.Dismantlement + 0.1
sgs.ai_use_value["LuaFengxiCard"] = 8.5

function ai_skill_invoke.LuaLinying(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return ((self:isWeak() and self.player:getMaxHp() - self.player:getHandcardNum() > 2) or
        sgs.ai_skill_playerchosen.LuaLinying(self, self.room:getOtherPlayers(self.player)) ~= nil) or false
end

sgs.ai_skill_playerchosen.LuaLinying = function(self, targets)
    self:updatePlayers()
    self:sort(self.friends_noself, "handcard")
    local target = nil
    local n = 1
    for _, friend in ipairs(self.friends_noself) do
        if not friend:faceUp() and getOEList(self.player,self.room):contains(friend) then
            target = friend
            break
        end
        if not target then
            if not self:toTurnOver(friend, n, "LuaLinying") and getOEList(self.player,self.room):contains(friend) then
                target = friend
                break
            end
        end
    end
    if not target then
        if n >= 3 then
            target = self:findPlayerToDraw(false, n)
            if not target then
                for _, enemy in ipairs(self.enemies) do
                    if self:toTurnOver(enemy, n, "LuaLinying") and hasManjuanEffect(enemy) and getOEList(self.player,self.room):contains(enemy) then
                        target = enemy
                        break
                    end
                end
            end
        else
            self:sort(self.enemies)
            for _, enemy in ipairs(self.enemies) do
                if self:toTurnOver(enemy, n, "LuaLinying") and hasManjuanEffect(enemy) and getOEList(self.player,self.room):contains(enemy) then
                    target = enemy
                    break
                end
            end
            if not target then
                for _, enemy in ipairs(self.enemies) do
                    if self:toTurnOver(enemy, n, "LuaLinying") and self:hasSkills(sgs.priority_skill, enemy) and getOEList(self.player,self.room):contains(enemy) then
                        target = enemy
                        break
                    end
                end
            end
            if not target then
                for _, enemy in ipairs(self.enemies) do
                    if self:toTurnOver(enemy, n, "LuaLinying") and getOEList(self.player,self.room):contains(enemy) then
                        target = enemy
                        break
                    end
                end
            end
        end
    end

    return target
end

sgs.ai_playerchosen_intention.LuaLinying = function(self, from, to)
    if hasManjuanEffect(to) then sgs.updateIntention(from, to, 80) end
    local intention = 80
    if not self:toTurnOver(to, 1) then intention = -intention end
    sgs.updateIntention(from, to, intention)
end

ai_fill_skill.LuaLinlu = function(self, options, request)
    local inclusive = options and options.inclusive

    if mark(self.player,"@LuaLinlu") == 0 then return end
    if self.player:getStrategyHasUsed("#LuaLinluCard") then return end
    if #self.enemies < 1 then return end
    return self:legacySkillSeed("LuaLinlu", "#LuaLinluCard", request)
end

ai_card_use["#LuaLinluCard"] = function(self, card, use, request)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    local to_discard_black = {}
    local to_discard_red = {}
    local to_discard = {}
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if card:isBlack() and #to_discard_black < 2 then
            table.insert(to_discard_black, card:getKnownEffectiveId())
        end
    end
    for _, card in ipairs(cards) do
        if card:isRed() and #to_discard_red < 2 then
            table.insert(to_discard_red, card:getKnownEffectiveId())
        end
    end
    if #to_discard_black == 2 or #to_discard_red == 2 then
        self:sort(self.enemies)
        local target
        for _, enemy in ipairs(self.enemies) do
            if self:objectiveLevel(enemy) > 3 and not self:canAttack(enemy, self.player) and self:damageIsEffective(enemy) and not getOEMark(enemy)  then
                target = enemy
                break
            end
        end
        if not target then
            for _, enemy in ipairs(self.enemies) do
                if self:objectiveLevel(enemy) > 3 and not self:canAttack(enemy, self.player) and self:damageIsEffective(enemy) then
                    target = enemy
                    break
                end
            end
        end
        if target then
            if #to_discard_red == 2 then
                to_discard = to_discard_red
            end
            if #to_discard_black == 2 then
                to_discard = to_discard_black
            end
            local card_str = string.format("#LuaLinluCard:%s:", table.concat(to_discard, "+"))
            use.card = paid(self,"LuaLinlu",to_discard,request)
            if use.to then use.to:append(target) end
            return
        end
    end
end

sgs.ai_use_value["LuaLinluCard"] = 2.5
sgs.ai_card_intention["LuaLinluCard"] = 80
sgs.dynamic_value.damage_card["LuaLinluCard"] = true
sgs.ai_use_priority["LuaLinluCard"] = sgs.ai_use_priority.Slash + 0.1

local function huowei(self, data, method, request)
    if not method then method = sgs.Card_MethodDiscard end
    local card_id
    local target
    local cant_use_skill
    local dmg

    if data == "@LuaHuowei" then
        dmg = context(self).damage
        if dmg==nil then ai_unsupported("owner Huowei damage missing","LuaHuoweiDamage") end
        if dmg==false then dmg=nil end
    else
        dmg = data
    end

    if not dmg then
        return "."
    end
    if dmg.to:objectName() ~= self.player:objectName() then return "." end

    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    for _, card in ipairs(cards) do
        if not self.player:isCardLimited(card, method) and card:isRed() and not card:isKindOf("Peach") then
            card_id = card:getKnownId()
            break
        end
    end
    if not card_id then return "." end

    self:sort(self.enemies, "hp")

    for _, enemy in ipairs(self.enemies) do
        if getOEList(self.player,self.room):contains(enemy) and (enemy:getHp() <= dmg.damage and enemy:isAlive()) then
            if (enemy:getHandcardNum() <= 2 or enemy:hasSkills("guose|leiji|ganglie|enyuan|qingguo|wuyan|kongcheng") or enemy:containsTrick("indulgence"))
                and self:canAttack(enemy, dmg.from or self.room:getCurrent(), dmg.nature)
                and not (dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and enemy:hasSkill("wuyan")) then
                return answer(self,card_id,enemy,request)
            end
        end
    end

    for _, enemy in ipairs(self.enemies) do
        if getOEList(self.player,self.room):contains(enemy) and (enemy:getLostHp() <= 1 or dmg.damage > 1) and enemy:isAlive() then
            if (enemy:getHandcardNum() <= 2)
                or enemy:containsTrick("indulgence") or enemy:hasSkills("guose|leiji|vsganglie|ganglie|enyuan|qingguo|wuyan|kongcheng")
                and self:canAttack(enemy, (dmg.from or self.room:getCurrent()), dmg.nature)
                and not (dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and enemy:hasSkill("wuyan")) then
                return answer(self,card_id,enemy,request)
            end
        end
    end

    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        if getOEList(self.player,self.room):contains(enemy) and not enemy:isWounded() and not self:hasSkills(sgs.masochism_skill, enemy) and enemy:isAlive()
            and self:canAttack(enemy, dmg.from or self.room:getCurrent(), dmg.nature)
            and (not (dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and enemy:hasSkill("wuyan") and enemy:getLostHp() > 0) or self:isWeak()) then
            return answer(self,card_id,enemy,request)
        end
    end

    return "."
end

function sgs.ai_cardneed.LuaHuowei(to,card,self)
	return (card:isRed())
	and (getKnownCard(to,self.player,"heart",false)+getKnownCard(to,self.player,"diamond",false))<2
end

function ai_skill_invoke.LuaYinyan(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = data:toPlayer()
    local maxcard = self:getMaxCard()
    local number = maxcard:getNumber()
    if target and self:isEnemy(target) and self.player:canPindian(target) and number >= 7
        and self:objectiveLevel(target) > 3 and not self:cantbeHurt(target)
        and self:damageIsEffective(target, sgs.DamageStruct_Fire, self.player) then
        return (true) or false
    end
    return (false) or false
end
sgs.ai_cardneed.LuaYinyan = sgs.ai_cardneed.bignumber

sgs.ai_skill_playerchosen.LuaYanling = function(self, targets)
    local slash = yanling(self)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "defenseSlash")
    for _, target in sgs.list(targets) do
        if self:isEnemy(target) and getOEList(self.player,self.room):contains(target)
            and not self:slashProhibit(slash, target)
            and self:isGoodTarget(target, nil, slash)
            and self:slashIsEffective(slash, target)
        then
            return target
        end
    end
    return nil
end

sgs.ai_cardneed.LuaYanling = sgs.ai_cardneed.slash


ai_fill_skill.LuaDuanjian = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:isNude() then return end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local card
	for _,c in ipairs(cards) do if c:isKindOf("Weapon") then card = c end end
	if card then return paid(self,"LuaDuanjian",{card:getKnownEffectiveId()},request) end
end

ai_card_use["#LuaDuanjianCard"] = function(self, card, use, request)
	local target1, target2
	local myoldenemy = findMyOE(self.player, self.room)
	if myoldenemy then
		target1 = self.player
		target2 = myoldenemy
	end
	if not (target1 and target2) then
		self:sort(self.enemies, "threat")
		for _, enemy in ipairs(self.enemies) do
			local theoldenemy = findMyOE(enemy, self.room)
			if theoldenemy then
				target1 = enemy
				target2 = theoldenemy
				break
			end
		end
	end
	if target1 and target2 then
		use.card = card
		if use.to then
			use.to:append(target1)
			use.to:append(target2)
		end
	end
end

sgs.ai_use_value["LuaDuanjianCard"] = 7.6
sgs.ai_use_priority["LuaDuanjianCard"] = 2.2

sgs.LuaDuanjian_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Weapon = 5
}
sgs.ai_cardneed.LuaDuanjian = sgs.ai_cardneed.weapon


ai_skill_use["@@LuaHuowei"]=function(self,prompt,request)
    local row=context(self)
    local damage=row.damage
    if type(damage)=="table" then
        local raw=damage;damage={}
        for _,key in ipairs({"damage","nature","from","to","card"}) do damage[key]=raw[key] end
        for _,key in ipairs({"from","to"}) do
            local value=damage[key]
            if type(value)=="string" then damage[key]=self.room:findPlayerByObjectName(value, true)
            elseif value==false then damage[key]=nil end
        end
        if damage.card==false then damage.card=nil
        elseif type(damage.card)=="table" and type(damage.card.getTypeId)~="function" then damage.card=CardView.new(damage.card) end
        if type(damage.damage)~="number" or damage.damage%1~=0 or damage.to==nil or damage.nature==nil then
            ai_unsupported("malformed owner Huowei damage","LuaHuoweiDamage")
        end
    end
    if damage==nil then ai_unsupported("owner Huowei damage missing","LuaHuoweiDamage") end
    return huowei(self,damage~=false and damage or nil,request and request.handling_method,request)
end
