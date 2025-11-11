sgs.ai_skill_invoke["modao"] = function(self, data)
	if #self.enemies == 0 then return false end
	return true
end

sgs.ai_skill_choice["modao"] = function(self, choices, data)
	local items = choices:split("+")
	if self.player:isKongcheng() then return "1" end
    for _, c in sgs.qlist(self.player:getHandcards()) do
    		if c:isKindOf("Duel") then
    			local dummy_use = self:aiUseCard(c)
				if not dummy_use.to:isEmpty() then
					return "2"
				end
    		end
    		if c:isKindOf("FireAttack") and self.player:getHandcardNum() > 2 then
    			local dummy_use = self:aiUseCard(c)
				if not dummy_use.to:isEmpty() then
					return "2"
				end
    		end
    		
        local x = nil
        if isCard("ArcheryAttack", c, self.player) then
            x = sgs.Sanguosha:cloneCard("ArcheryAttack")
        elseif isCard("SavageAssault", c, self.player) then
            x = sgs.Sanguosha:cloneCard("SavageAssault")
        else continue end
		if x then
			x:deleteLater()
			local du = self:aiUseCard(x)
			if (du.card) then return "3" end
		end
    end
	return "1"
end

sgs.ai_skill_playerchosen.modao = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard_defense")
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and self:doDisCard(target, "h", true, self.player:getTag("modao"):toInt()) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and self:doDisCard(target, "h", true) then
			return target
		end
	end
	
	return targets[1]
end

sgs.ai_skill_invoke["cuisheng"] = function(self, data)
	local current = self.room:getCurrent()
	return current and self:isFriend(current)
end
sgs.ai_choicemade_filter.skillInvoke.cuisheng = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local current = self.room:getCurrent()
		sgs.updateIntention(player, current, -50)
	end
end


sgs.ai_skill_use["@@huayuan"]=function(self,prompt)
	self:updatePlayers()
	local enemytargets = {}
		for _, enemy in ipairs(self.enemies) do
			if  not enemy:isChained() 
				and not enemy:hasSkill("danlao")
				--不要對董允敵人使用
				and not enemy:hasSkill("sheyan")
				--不要對陸抗敵人使用
				and not enemy:hasSkill("qianjie")
				--不要對司馬徽敵人使用
				and not enemy:hasSkills("chenghao+yinshi")
				
				--add dongmanbao enemy
				and not enemy:hasSkill("Tianhuo") 
				
				--add fate
				and not enemy:hasSkill("fatefapao") 
				
				
				and not (self:objectiveLevel(enemy) <= 3) 
				and not self:needToLoseHp(enemy) and self:isGoodTarget(enemy, self.enemies, nil) 
				and #enemytargets < 2  then
				table.insert(enemytargets, enemy:objectName())
			end
		end
		for _, friend in ipairs(self.friends) do
			if not friend:isChained() 			
				and self:needToLoseHp(friend)
				and #enemytargets < 2  then
				table.insert(enemytargets, friend:objectName())
			end
		end
		if #enemytargets > 0 then
			if #enemytargets > 1 then
				return "#huayuanCard:.:->" .. table.concat(enemytargets, "+")
			end
			return "#huayuanCard:.:->" .. enemytargets[1]
		end
	return "."
end


sgs.ai_card_intention["huayuanCard"]  = sgs.ai_card_intention.IronChain

sgs.ai_skill_playerchosen["jiaosha"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	for _,p in ipairs(targets) do
		if self:isFriend(p) then
			if not self:willSkipPlayPhase(p) then
				if self:needToLoseHp(p) or not self:damageIsEffective(p, sgs.DamageStruct_Normal) then
					return p
				end
			end
		end
	end
	for _,p in ipairs(targets) do
		if self:isEnemy(p) then
			if self:willSkipPlayPhase(p) and self:damageIsEffective(p, sgs.DamageStruct_Normal)
			and not self:needToLoseHp(p) and self:isGoodTarget(p, self.enemies, nil)   then
				return p
			end
		end
	end
	return nil
end

sgs.ai_skill_cardask["@huanglue"] = function(self, data, pattern, target, target2)
	local use = data:toCardUse()
	local handcards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(handcards)
	if use.card:isKindOf("Jink") or use.card:isKindOf("Nullification") then
		if use.from and self:isEnemy(use.from) then
			for _, card in ipairs(handcards) do
				if card:getNumber() > use.card:getNumber() then
					return "$" .. card:getEffectiveId()
				end
			end
		end
	elseif use.card:isKindOf("Peach") then
		if use.from and self:isEnemy(use.from) then
			for _, p in sgs.qlist(use.to) do
				if self:isEnemy(p) then
					for _, card in ipairs(handcards) do
						if card:getNumber() > use.card:getNumber() then
							return "$" .. card:getEffectiveId()
						end
					end
				end
			end
		end
	else
		if not self:isWeak() and use.from and not self:isFriend(use.from) then
			for _, p in sgs.qlist(use.to) do
				if self:isFriend(p) then
					for _, card in ipairs(handcards) do
						if card:getNumber() > use.card:getNumber() then
							return "$" .. card:getEffectiveId()
						end
					end
				end
			end
		end
	end
	return "."
end


sgs.ai_skill_playerchosen.luafenwei = function(self, targets)
	if self:needKongcheng(self.player, true) then
		return nil
	end
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, target in ipairs(targets) do
		if self:isFriend(target) and ( target:getJudgingArea():length() > 0  and not target:containsTrick("YanxiaoCard")) then return target end
	end
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and (( target:getJudgingArea():length() > 0  and  target:containsTrick("YanxiaoCard"))) then return target end
	end
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and not ( target:hasSkills(sgs.lose_equip_skill) or self:doDisCard(target, "ej", true)) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isFriend(target) and ((target:hasSkills(sgs.lose_equip_skill) and target:getEquips():length() > 0) or self:needToThrowArmor(target)) then return target end
	end

	return targets[1]
end

sgs.ai_skill_cardchosen["luafenwei"] = function(self, who, flags)
	self:updatePlayers()
			if flags:match("e") then
				if self:isEnemy(who) then
					if not  who:hasSkills(sgs.lose_equip_skill) then
						for _, e in ipairs(sgs.QList2Table(who:getCards("e"))) do
							local equip_index = e:getRealCard():toEquipCard():location()
							return e:getEffectiveId()
						end
					end
				else
					if  who:hasSkills(sgs.lose_equip_skill) then
						for _, e in ipairs(sgs.QList2Table(who:getCards("e"))) do
							local equip_index = e:getRealCard():toEquipCard():location()
							return e:getEffectiveId()
						end
					end
				end
			end
			if flags:match("j") then
				if self:isEnemy(who) then
					local judges = who:getJudgingArea()
					if who:containsTrick("YanxiaoCard") then
						for _, judge in sgs.qlist(judges) do
							if judge:isKindOf("YanxiaoCard") then
								return judge:getEffectiveId()
							end
						end
					end
				elseif self:isFriend(who) then
					local judges = who:getJudgingArea()
					for _, judge in sgs.qlist(judges) do
						if not judge:isKindOf("YanxiaoCard") then
							return judge:getEffectiveId()
						end
					end
				end
			end
end
sgs.need_kongcheng = sgs.need_kongcheng .. "|luafenwei"




guihao_skill={}
guihao_skill.name="guihao"
table.insert(sgs.ai_skills,guihao_skill)
guihao_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end

	local card

	self:sortByUseValue(cards,true)

	for _,acard in ipairs(cards)  do
		if acard:isBlack() then
			card = acard
			break
		end
	end

	if not card then return nil end
	if  self.player:getMark("guihao") == 0 then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("analeptic:guihao[%s:%s]=%d"):format(suit, number, card_id)
	local analeptic = sgs.Card_Parse(card_str)

	if sgs.Analeptic_IsAvailable(self.player, analeptic) then
		assert(analeptic)
		return analeptic
	end
end

sgs.ai_view_as.guihao = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
		if card:isBlack() and player:getMark("guihao") > 0 then
			return ("analeptic:guihao[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

function sgs.ai_cardneed.guihao(to, card, self)
	return card:isBlack() and (getKnownCard(to, self.player, "club", false) + getKnownCard(to, self.player, "spade", false)) == 0
end



sgs.ai_skill_invoke.guihao = function(self, data)
	if self:isWeak(self.player) and self:getAllPeachNum() == 0 then return false end
	if self:willSkipPlayPhase(self.player) then return false end
	for _,card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Peach") or card:isKindOf("Analeptic") or card:isKindOf("Slash") then
			return true
		end
	end
	if math.random()<0.6 then return true end
	return false
end

sgs.ai_skill_use["@@caiduan"] = function(self,prompt)
	local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
		if h and not h:targetFixed() then
			local dummy_use = self:aiUseCard(h)
			if dummy_use.card and dummy_use.to	then
				local tos = {}
				for _,p in sgs.list(dummy_use.to)do
					table.insert(tos,p:objectName())
				end
				return h:toString().."->"..table.concat(tos,"+")
			end
		end
	end
end

sgs.ai_skill_invoke["caiduan"] = function(self, data)
	local current = self.room:getCurrent()
	return current and self:isEnemy(current) and not self:isWeak()
end
sgs.ai_choicemade_filter.skillInvoke.caiduan = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local current = self.room:getCurrent()
		sgs.updateIntention(player, current, 50)
	end
end

sgs.ai_skill_invoke["shenni"] = function(self, data)
	local move = data:toMoveOneTime()
	for _,card_id in sgs.qlist(move.card_ids) do
		if sgs.Sanguosha:getCard(card_id):isKindOf("Peach") then
			return true
		end
	end
	return not self:isWeak()
end


sgs.ai_skill_playerchosen.yui_changxin = function(self, targets)
	return self:findPlayerToDiscard("he", true, true, targets, false)[1]
end