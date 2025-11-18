--激唱
sgs.ai_skill_invoke.berserk_jichang = function(self, data)
    local dying = data:toDying()
	local peaches = 1 - dying.who:getHp()
	return self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < peaches and dying.who:getMark("@guiming") <= 0
end

sgs.ai_canNiepan_skill.berserk_jichang = function(player)
	return player:getMark("@jichang") > 0
end

sgs.ai_skill_cardask["@jichang"] = function(self, data, pattern, target)
    local miku = self.room:findPlayerBySkillName("berserk_jichang")
	if self:isFriend(miku) then return "." end
end


--心弦
sgs.ai_skill_invoke.berserk_xinxian = function(self, data)
    local damage = data:toDamage()
	if not self:isFriend(damage.from) then
	    return true
	end
	return false
end


--梦幻
sgs.ai_skill_playerchosen["@menghuan-target2"] = function(self, targets)
    if #self.enemies == 0 then return self.player end
	self:sort(self.enemies, "defense") 
	for _,enemy in ipairs(self.enemies) do
		if enemy then
			return enemy
		end
	end
	return self.enemies[1]
end

