sgs.ai_skill_invoke["LuaSuiyu"] = true

local LuaFengrao_skill = {}
LuaFengrao_skill.name = "LuaFengrao"
table.insert(sgs.ai_skills, LuaFengrao_skill)

LuaFengrao_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum() < 2 then return end
	local can = false
	for _, p in sgs.qlist(self.player:getAliveSiblings()) do
		if self.player:getHandcardNum() > p:getHandcardNum() then
			can = true
		end
	end
	if not can then return end
	local cards = sgs.QList2Table(self.player:getHandcards())
	local subcards = {}
	self:sortByUseValue(cards, true)
	local reds, blacks = {}, {}
	for _, card in ipairs(cards) do
		if card:isRed() then 
			if not (isCard("Peach", card, self.player) or isCard("ExNihilo", card, self.player)) then table.insert(reds, card) end
		else
			if not (isCard("Peach", card, self.player) or isCard("ExNihilo", card, self.player)) then table.insert(blacks, card) end
		end
	end
	if #reds == 0 or #blacks == 0 then return end
	if self:getKeepValue(reds[1]) + self:getKeepValue(blacks[1]) > 18 then return end
	if self:getUseValue(reds[1]) + self:getUseValue(blacks[1]) > 12 then return end
	if self.player:getHandcardNum() > 3 then 
		sgs.ai_use_priority.AmazingGrace = 1
		sgs.ai_use_value.AmazingGrace = 1
	end
	table.insert(subcards, reds[1]:getId())
	table.insert(subcards, blacks[1]:getId())
	local card_str = "amazing_grace:LuaFengrao[to_be_decided:0]="..table.concat(subcards, "+")
	local AsCard = sgs.Card_Parse(card_str)
	assert(AsCard)
	return AsCard
end
