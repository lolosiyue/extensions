
LuaYanjiu_skill={}
LuaYanjiu_skill.name="LuaYanjiu"
table.insert(sgs.ai_skills,LuaYanjiu_skill)
LuaYanjiu_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end

	local card

	self:sortByUseValue(cards,true)
	local big_suit = self.player:property("LuaYanjiu"):toString():split("+")
	for _,acard in ipairs(cards)  do
		if table.contains(big_suit,acard:getSuitString()) then
			card = acard
			break
		end
	end

	if not card then return nil end
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("analeptic:LuaYanjiu[%s:%s]=%d"):format(card:getSuitString(),number, card_id)
	local analeptic = sgs.Card_Parse(card_str)

	if sgs.Analeptic_IsAvailable(self.player, analeptic) then
		assert(analeptic)
		return analeptic
	end
end

sgs.ai_view_as.LuaYanjiu = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
		local big_suit = player:property("LuaYanjiu"):toString():split("+")
		if table.contains(big_suit,card:getSuitString()) then
			return ("analeptic:LuaYanjiu[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end


sgs.ai_skill_playerchosen.LuaJiangfu = function(self, targets)
	local minHp = 100
	local target
	for _,friend in ipairs(self.friends) do
		local hp = friend:getHp()
		if self:hasSkills(sgs.masochism_skill, friend) then
			hp = hp - 1
		end
		if friend:isLord() then
			hp = hp - 1
		end
		if hp < minHp then
			minHp = hp
			target = friend
		end
	end
	if target then return target end
	return self.player
end

sgs.ai_playerchosen_intention.LuaJiangfu = -80




