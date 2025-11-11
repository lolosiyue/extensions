--深度思考
sgs.ai_skill_invoke.deep_seek = function(self, data)
    local target = data:toDamage().to
	if  sgs.ai_role[target:objectName()] ~= "neutral" or target:isLord()  then
        return true
	end
	return false
end

sgs.ai_skill_choice.deep_seek = function(self, choices, data)
    local target = data:toPlayer()
	local items = choices:split("+")
	
	if sgs.ai_role[target:objectName()]== "rebel" and table.contains(items, "rebel")  then
		return "rebel"	
	elseif target:isLord() and table.contains(items, "lord")  then 
		return "lord"	
	elseif sgs.ai_role[target:objectName()]== "loyalist" and table.contains(items, "loyalist")  then
		return "loyalist"	
	elseif sgs.ai_role[target:objectName()]== "renegade" and table.contains(items, "renegade")  then
		return "renegade"	
	end
	return items[1]
end

sgs.ai_event_callback[sgs.ChoiceMade].KaiyuanShengshi = function(self,player,data)
	local datastr = data:toString()
	if string.startsWith(datastr, "peach:") then
		local target = self.room:findPlayerByObjectName(datastr:split(":")[2])
        if target then
            for _, sb in sgs.qlist(self.room:findPlayersBySkillName("KaiyuanShengshi")) do
                if sb:hasFlag("KaiyuanShengshi") then
                    sgs.roleValue[target:objectName()]["renegade"] = 0
                    sgs.roleValue[target:objectName()]["loyalist"] = 0
                    local role, value = sb:getRole(), 1000
                    if role == "rebel" then role = "loyalist" value = -1000 end
                    sgs.roleValue[target:objectName()][sb:getRole()] = 1000
                    sgs.ai_role[target:objectName()] = target:getRole()
                    self:updatePlayers()
                end
            end
        end
	end
end

local tieba_zhili_skill = {}
tieba_zhili_skill.name = "tieba_zhili"
table.insert(sgs.ai_skills, tieba_zhili_skill)
tieba_zhili_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#tieba_zhiliCard:.:")
end

sgs.ai_skill_use_func["#tieba_zhiliCard"] = function(card, use, self)
	self:sort(self.enemies,"handcard",true)
	local target
	for _,enemy in sgs.list(self.enemies)do
		if enemy:getHp()<self.player:getHp() then
			if not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, "N", self.player) and self:canDamage(enemy,self.player,nil) and not self:cantDamageMore(self.player, enemy) then
				target = enemy
                break
			end
		end
	end
    if not target then
        for _,enemy in sgs.list(self.enemies)do
            if enemy:getHp()<self.player:getHp() then
                if not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, "N", self.player) and self:canDamage(enemy,self.player,nil) then
                    target = enemy
                    break
                end
            end
        end
    end
    if target then
        use.card = sgs.Card_Parse("#tieba_zhiliCard:.:")
        use.to:append(target)
	return
    end
end

--会员神力
sgs.ai_target_revises.huiyuanshenli = function(to,card,self,use)
	if not card:isKindOf("SkillCard")
	and self.player:getHandcardNum()-self:getCardsNum("Peach")<1
	then return true end
end

sgs.ai_skill_cardask["@huiyuanshenli"] = function(self, data)
	local use = data:toCardUse()
	local current = self.room:getCurrent()
	for _, p in sgs.qlist(use.to) do
		if p:getMark("huiyuanshenli-Clear") > 0 then
			if self:isFriend(p) then
				if use.card:isKindOf("AmazingGrace") and
					(p:getSeat() - current:getSeat()) % (global_room:alivePlayerCount()) < global_room:alivePlayerCount() / 2 then
					local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
					if #to_discard > 0 then return "$" .. to_discard[1] end
				end
				if use.card:isKindOf("GodSalvation") and p:isWounded() or use.card:isKindOf("ExNihilo") then
					local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")

					if #to_discard > 0 then return "$" .. to_discard[1] end
				end
				if use.card:isKindOf("IronChain") then
					if p:isChained() and not self:isGoodChainTarget(p) then
						local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
						if #to_discard > 0 then return "$" .. to_discard[1] end
					end
				end
                if use.card:isKindOf("Peach") then
                    return true
                end
			end
			if self:isEnemy(p) or (self:isFriend(p) and p:getRole() == "loyalist" and not hasJueqingEffect(self.player, p, sgs.card_damage_nature[use.card:getClassName()]) and self.player:isLord() and p:getHp() == 1) then
				if use.card:isKindOf("AOE") then
					local from = use.from
					if use.card:isKindOf("SavageAssault") then
						local menghuo = self.room:findPlayerBySkillName("huoshou")
						if menghuo then from = menghuo end
					end

					local friend_null = 0
					for _, q in sgs.qlist(self.room:getOtherPlayers(self.player)) do
						if self:isFriend(q) then friend_null = friend_null + getCardsNum("Nullification", q, self.player) end
						if self:isEnemy(q) then friend_null = friend_null - getCardsNum("Nullification", q, self.player) end
					end
					friend_null = friend_null + self:getCardsNum("Nullification")
					local sj_num = self:getCardsNum(use.card:isKindOf("SavageAssault") and "Slash" or "Jink")

					if self:hasTrickEffective(use.card, p, from) then
						if self:damageIsEffective(p, sgs.DamageStruct_Normal, from) then
							if sj_num == 0 and friend_null <= 0 then
								if self:isEnemy(from) and hasJueqingEffect(from, p, sgs.card_damage_nature[use.card:getClassName()]) then
				
									local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
									if #to_discard > 0 then return "$" .. to_discard[1] end
								end
								if self:isFriend(from) and p:getRole() == "loyalist" and from:isLord() and p:getHp() == 1 and not hasJueqingEffect(from, p, sgs.card_damage_nature[use.card:getClassName()]) then
									return "."
								end
								if (not (self:hasSkills(sgs.masochism_skill, p) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or hasJueqingEffect(use.from, p, sgs.card_damage_nature[use.card:getClassName()])) then
									return "."
								end
							end
						end
					end
				elseif self:isEnemy(p) then
					if use.card:isKindOf("FireAttack") then
						if self:hasTrickEffective(use.card, p) then
							if self:damageIsEffective(p, sgs.DamageStruct_Fire, self.player) then
								if (p:hasArmorEffect("vine") or p:getMark("@gale") > 0) and self.player:getHandcardNum() > 3
									and not (self.player:hasSkill("hongyan") and getKnownCard(p, p, "spade") > 0) then
				
									return true
								elseif p:isChained() and not self:isGoodChainTarget(p, use.from) then
				
									return true
								end
							end
						end
					elseif (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement") or use.card:isKindOf("Zhujinqiyuan") or use.card:isKindOf("ZdShengdongjixi")) and not p:isKongcheng() then
						if self:hasTrickEffective(use.card, p) then
							return true
						end
					elseif use.card:isKindOf("Duel") or use.card:isKindOf("chuqibuyi") then
						if self:hasTrickEffective(use.card, p) then
							if self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then
								return true
							end
						end
					elseif use.card:isKindOf("IronChain") then
						if self:isGoodChainTarget(p) then
							return true
						end
                    elseif use.card:isDamageCard() then
                        return true
					end
				end
			end
		end
	end

	return "."
end

sgs.ai_skill_invoke.huiyuanshenli = function(self, data)
    local target = data:toPlayer()
    if self:isEnemy(target) and not self:cantbeHurt(target) and self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player) and not self:needToLoseHp(target, self.player, nil) then
        return true
    end
    if self:isFriend(target) and self:needToLoseHp(target, self.player, nil) then
        return true
    end
    return false
end

--通义

sgs.ai_skill_choice["tongyiAIWJ"]    = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
    if self.player:hasFlag("Jink") then
        if self.player:objectName() == target:objectName() and self:getCardsNum("Jink") > 0 then
            return "yes"
        elseif self.player:objectName() == target:objectName() and self:getCardsNum("Jink") == 0 then
            return "no"
        end
	    if getKnownCard(target, self.player, "Jink") > 0 then
            return "yes"
        end
    end
    if self.player:hasFlag("Nullification") then
        if self.player:objectName() == target:objectName() and self:getCardsNum("Nullification") > 0 then
            return "yes"
        elseif self.player:objectName() == target:objectName() and self:getCardsNum("Nullification") == 0 then
            return "no"
        end
	    if getKnownCard(target, self.player, "Nullification") > 0 then
            return "yes"
        end
    end
	return items[math.random(1,#items)]
end

sgs.ai_guhuo_card.tongyiTQ = function(self, toname, class_name)
    if class_name and self:getCardsNum(class_name) > 0 then return end
    if self.player:hasFlag("Global_tongyiAIWJ_Failed") then return false end
    if self.player:getMark("tongyiTQ-using") > 0 then return false end
    if self.player:getMark("tongyiTQ_allcard-Clear") > 0 then return false end
    local c = dummyCard(toname)
    c:setSkillName("tongyiAIWJ")
    if (not c) then return end
	if c:isKindOf("BasicCard") or c:isNDTrick() then
		for _, p in sgs.qlist(self.room:findPlayersBySkillName("tongyiAIWJ")) do
            if not self:isEnemy(p) then
			    return "#tongyiTQ:.:"..toname
            end
        end
	end
end




--千问
sgs.ai_skill_invoke.tiaojiaoCMT = function(self, data)
    local damage = data:toDamage()
    if damage.from and self.player:objectName() == damage.from:objectName() then
        if self:isFriend(damage.to) and damage.to:isWounded() and getBestHp(damage.to) < damage.to:getHp() then
            return true
        end
        if self:isEnemy(damage.to) then
			if damage.damage > 1 then return false end 
            if not damage.to:isWounded() then
                return self:doDisCard(damage.to, "h", true)
            end
            if self:isWeak(damage.to) then
                return false
            end
            return self:doDisCard(damage.to, "h", true) and math.random() < 0.5
        end
    end
    return false
end

sgs.ai_skill_invoke.daduanCMT = true

local tiaojiaoCMT_skill={}
tiaojiaoCMT_skill.name = "tiaojiaoCMT"
table.insert(sgs.ai_skills,tiaojiaoCMT_skill)
tiaojiaoCMT_skill.getTurnUseCard=function(self)
	if self.player:getHandcardNum() > 2 then return nil end
	if self:needBear() and not self.player:isWounded() and self:isWeak() then return nil end
    if #self.toUse < 2 then return nil end
	return sgs.Card_Parse("#tiaojiaoCMTCard:.:")
end
sgs.ai_skill_use_func["#tiaojiaoCMTCard"] = function(card,use,self)
	local arr1,arr2 = self:getWoundedFriend(false)
	local target = nil

	repeat
		if #arr1>0 and (self:isWeak(arr1[1]) or self:isWeak() or self:getOverflow()>=1) then
			target = arr1[1]
			break
		end
		if #arr2>0 and self:isWeak() then
			target = arr2[1]
			break
		end
	until true

	if not target then
		for _,friend in sgs.list(self.friends_noself)do
            if self:canDamageHp(self.player, nil, friend) or self:needToLoseHp(friend, self.player, nil, true, true) then
                target = friend
                break
            end
		end
	end

	if target then
		use.card = card
		use.to:append(target)
		return
	end
end

sgs.ai_use_priority.tiaojiaoCMTCard = 2.8