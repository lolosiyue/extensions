-- Fixed b6025acc jiange-defense effective source, pure values only.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported("jiange fact unknown",k)end;return v end

local function dummy(is_dummy,extra,current)local u=AIUsePlan.new();u.isDummy=is_dummy~=false;u.extra_target=extra or 0;u.current_targets=current or{};return u end
--[[********************************************************************
	Copyright (c) 2013-2014-QSanguosha-Rara

  This file is part of QSanguosha-Hegemony.

  This game is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 3.0
  of the License,or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  General Public License for more details.

  See the LICENSE file for more details.

  QSanguosha-Rara
*********************************************************************]]

sgs.ai_skill_invoke.jglingfeng = true

sgs.ai_skill_playerchosen.jglingfeng = function(self,targets)
	self.enemies = self:sort(self.enemies,"hp")
	for _,enemy in ipairs(self.enemies)do
		return enemy
	end
end

sgs.ai_playerchosen_intention.jglingfeng = 80

sgs.ai_skill_invoke.jgbiantian = true

sgs.ai_slash_prohibit.jgbiantian = function(self,from,enemy,card)
        if enemy:getStrategyMark("&dawu")>0 and not card:isKindOf("ThunderSlash") then return false end
	return true
end

sgs.ai_skill_choice.jggongshen = function(self,choice)
	self.friends_noself = self:sort(self.friends_noself)
	local target = nil
	for _,enemy in ipairs(self.enemies)do
		if string.find(enemy:getKnownGeneralName(),"machine") then
                        if enemy:hasArmorEffect("Vine") or enemy:getStrategyMark("&kuangfeng")>0 or enemy:getHp()==1 then
				return "damage"
			end
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if string.find(friend:getKnownGeneralName(),"machine") and friend:getLostHp()>0 then
			if self:isWeak(friend) then
				return "recover"
			end
		end
	end
	return "damage"
end

sgs.ai_skill_invoke.jgzhinang = true

sgs.ai_skill_playerchosen.jgzhinang = function(self,targets)
	for _,friend in ipairs(self.friends_noself)do
		if friend:faceUp() and not self:isWeak(friend) then
			if not friend:getWeapon() or friend:hasSkills("rende|jizhi") then
				return friend
			end
		end
	end
	return self.player
end

sgs.ai_playerchosen_intention.jgzhinang = function(self,from,to)
	if not self:needKongcheng(to,true)  then self:updateIntention(from,to,-50) end
end

sgs.ai_skill_invoke.jgjingmiao = true

sgs.ai_skill_invoke.jgqiwu = true

sgs.ai_skill_playerchosen.jgqiwu = function(self,targets)
	local target
	self.friends = self:sort(self.friends,"hp")
	for _,friend in ipairs(self.friends)do
		if  friend:getLostHp()>0 then
			target = friend
		end
	end
	return target
end

sgs.ai_skill_playerchosen.jgtianyun = function(self,targets)
	local target = nil
	local chained = 0
	self.enemies = self:sort(self.enemies,"hp")
	for _,enemy in ipairs(self.enemies)do
        if enemy:getCards("e"):length()>=2 or enemy:getHp()<=1
		or self:ajustDamage(self.player,enemy,1,nil,"F")>1
		then target = enemy break end
	end
	if not target then
		for _,enemy in ipairs(self.enemies)do
			if self:isGoodChainTarget(enemy,"F")
			then target = enemy break end
		end
	end
	if not target then
		for _,enemy in ipairs(self.enemies)do
			if self:damageIsEffective(enemy,sgs.DamageStruct_Fire,self.player)
			then target = enemy break end
		end
	end
	return target
end

sgs.ai_playerchosen_intention.jgtianyun = 80

function sgs.ai_skill_invoke.jglingyu(self,data)
	local weak = 0
	for _,friend in ipairs(self.friends)do
		if friend:getLostHp()>0 then
			weak = weak+1
			if self:isWeak(friend) then
				weak = weak+1
			end
		end
	end
	if not self.player:faceUp() then return true end
	for _,friend in ipairs(self.friends)do
		if friend:hasSkills("fangzhu") then return true end
	end
	return weak>=2
end

sgs.ai_skill_playerchosen.jgleili = function(self,targets)
	self.enemies = self:sort(self.enemies,"hp")
	local target
	for _,enemy in ipairs(self.enemies)do
		if self:isGoodChainTarget(enemy,"T")
		then
			target = enemy
			break
		end
	end
	if not target then
		for _,enemy in ipairs(self.enemies)do
			if self:damageIsEffective(enemy,sgs.DamageStruct_Thunder,self.player)
			then
				target = enemy
				break
			end
		end
	end
	if not target then
		for _,enemy in ipairs(self.enemies)do
			target = enemy
			break
		end
	end
	return target
end

sgs.ai_playerchosen_intention.jgleili = 80

sgs.ai_skill_playerchosen.jgchuanyun = function(self,targets)
	local target
	self.enemies = self:sort(self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if  enemy:getHp()>self.player:getHp() then
			target = enemy
			break
		end
	end
	return target
end

sgs.ai_playerchosen_intention.jgchuanyun = 80

-- jgfengxing alias is absent in the fixed effective census; do not revive it.

sgs.ai_playerchosen_intention.jgfengxing = 80

sgs.ai_skill_playerchosen.jghuodi = function(self,targets)
	local target
	self.enemies = self:sort(self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if enemy:hasSkills("jgtianyu|jgtianyun") and not enemy:faceUp() then
			target = enemy
			break
		end
	end
	if not target then
		self.enemies = self:sort(self.enemies)
		for _,enemy in ipairs(self.enemies)do
			if self:toTurnOver(enemy) and enemy:hasSkills(sgs.priority_skill)
                        and not (enemy:getStrategyMark("&dawu")>0 and enemy:hasSkill("jgbiantian")) then
				target = enemy
				break
			end
		end
		if not target then
			for _,enemy in ipairs(self.enemies)do
				if self:toTurnOver(enemy)
                                and not (enemy:getStrategyMark("&dawu")>0 and enemy:hasSkill("jgbiantian")) then
					target = enemy
					break
				end
			end
		end
	end
	return target
end

sgs.ai_playerchosen_intention.jghuodi = 80

sgs.ai_skill_invoke.jgjueji = true

sgs.ai_skill_playerchosen.jgdidong = function(self,targets)
	local target
	self.enemies = self:sort(self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if enemy:hasSkills("jgtianyu|jgtianyun") and not self:isWeak(enemy) and not enemy:faceUp() then
			target = enemy
			break
		end
	end
	if not target then
		self.enemies = self:sort(self.enemies)
		for _,enemy in ipairs(self.enemies)do
                        if self:toTurnOver(enemy) and enemy:hasSkills(sgs.priority_skill) and not (enemy:getStrategyMark("&dawu")>0 and enemy:hasSkill("jgbiantian")) then
				target = enemy
				break
			end
		end
		if not target then
			for _,enemy in ipairs(self.enemies)do
                                if self:toTurnOver(enemy) and not (enemy:getStrategyMark("&dawu")>0 and enemy:hasSkill("jgbiantian")) then
					target = enemy
					break
				end
			end
		end
	end
	return target
end

sgs.ai_playerchosen_intention.jgdidong = 80

sgs.ai_skill_invoke.jglianyu = true

function sgs.ai_skill_invoke.jgdixian(self,data)
	local throw = 0
	for _,enemy in ipairs(self.enemies)do
		throw = throw+enemy:getCards("e"):length()
	end
	if not self.player:faceUp() then return true end
	for _,friend in ipairs(self.friends)do
		if friend:hasSkills("fangzhu") then return true end
	end
	return throw>=3
end

sgs.ai_skill_invoke.jgkonghun = true


sgs.ai_fill_skill.jgjiaoxie = function(self,inclusive,request)
    return self:legacySkillSeed("jgjiaoxie","JGJiaoxieCard",request)
end

sgs.ai_skill_use_func["JGJiaoxieCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"handcard")
	for _,p in sgs.list(self.enemies)do
		if use.to:length()<2 and p:getKnownGeneralName():contains("jg_machine_") and p:getCardCount()>0 then
			use.card = card
			use.to:append(p)
		end
	end
if use.card==card then use.card=self:bindSkillCard("jgjiaoxie",{},nil,nil,"JGJiaoxieCard")end
end

sgs.ai_use_value.JGJiaoxieCard = 3.4
sgs.ai_use_priority.JGJiaoxieCard = 9.2

sgs.ai_skill_invoke.jgbashi = function(self,data)
	local use = data:toCardUse()
	if use.card:isKindOf("Slash") then
		return self:getCardsNum("Jink")<1 and self:isWeak()
	end
	if use.card:isDamageCard() then
		local tcn = sgs.aiResponse[use.card:getClassName()] or "Nullification"
		return self:getCardsNum(tcn)<1 and self:isWeak()
	end
end

sgs.ai_skill_invoke.jgdanjing = function(self,data)
	return self:getAllPeachNum()<1
end

sgs.ai_fill_skill.jgyingji = function(self,inclusive,request)
    return self:legacySkillSeed("jgyingji","JGYingjiCard",request)
end

sgs.ai_skill_use_func["JGYingjiCard"] = function(card,use,self)
	local dc = known(self:getEvaluationCard("slash"),"Slash")
	local d = self:aiUseCard(dc)
	if d.card then
		use.card = self:bindSkillCard("jgyingji",{},nil,nil,"JGYingjiCard")
		use.to = d.to
	end
end

sgs.ai_use_value.JGYingjiCard = 3.4
sgs.ai_use_priority.JGYingjiCard = 3.7

sgs.ai_skill_cardask.jgweizhu = function(self,data,pattern,prompt)
    local damage = data:toDamage()
    if self:isFriend(damage.to) and self:isWeak(damage.to)
	then return true end
	return "."
end

sgs.ai_fill_skill.jghanjun = function(self,inclusive,request)
    return self:legacySkillSeed("jghanjun","JGHanjunCard",request)
end

sgs.ai_skill_use_func["JGHanjunCard"] = function(card,use,self)
	local n = 0
	for _,p in sgs.list(self.enemies)do
		if p:getCardCount()>0 then
			n = n+1
		end
	end
	if n>=#self.enemies/2 then
		use.card = self:bindSkillCard("jghanjun",{},nil,nil,"JGHanjunCard")
	end
end

sgs.ai_use_value.JGHanjunCard = 3.4
sgs.ai_use_priority.JGHanjunCard = 9.2

sgs.ai_skill_use["@@jgkeding"] = function(self,prompt)
	local row=known(nil,"jgkedingUser") -- The Keding source parse is not projected.
    local user=known(row.parts,"jgkeding exact split")
    local face=known(row.card,"jgkeding source parse")
    local dc=face~=false and CardView.new(face)or nil
    if dc then dc._evaluation_candidate=known(row.candidate,"jgkeding candidate")end
	local valid,ids = {},{}
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- ���б�ת��Ϊ��
    cards = self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if self:getKeepValue(h)<7 then table.insert(ids,h:getEffectiveId()) end
	end
	local d = self:aiUseCard(dc,dummy(nil,99,{user[2]}))
    for _,p in sgs.list(d.to)do
    	if #ids>#valid then
			table.insert(valid,p:objectName())
		end
	end
	while #ids>#valid do
		table.removeOne(ids,ids[#ids])
	end
	if #valid<1 then return end
	local paid=self:bindSkillCard("jgkeding",ids,nil,nil,"JGKedingCard")
    return {kind="use_card",card_spec=paid:toCardSpec(),targets=valid}
end

sgs.ai_skill_invoke.jglongwei = function(self,data)
	return self:getAllPeachNum()<1
end




