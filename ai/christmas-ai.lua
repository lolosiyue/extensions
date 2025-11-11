sgs.ai_skill_invoke["RLiwa"] = function(self, data)
	return not (self.player:isKongcheng() and self:needKongcheng(self.player))
end

RLiwa_skill = {}
RLiwa_skill.name = "RLiwa"
table.insert(sgs.ai_skills, RLiwa_skill)

RLiwa_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#RLiwaCard") then return end
	local CardParse = sgs.Card_Parse("#RLiwaCard:"..self:getLijianCard()..":&RLiwa")
	assert(CardParse)
	return CardParse
end

sgs.ai_skill_use_func["#RLiwaCard"] = function(card, use, self)
	if #self.friends_noself == 0 then return false end
	self:sort(self.friends_noself, "threat")
	local target = self.friends_noself[1]
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasSkill(sgs.cardneed_skill) then target = friend end
	end
	if target then use.card = card end
	if use.to and target then
		use.to:append(target)
	end
end

sgs.ai_use_value["RLiwaCard"] = 2.0
sgs.ai_use_priority["RLiwaCard"] = 5.9