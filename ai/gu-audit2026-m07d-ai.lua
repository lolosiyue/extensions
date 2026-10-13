-- GU-audit2026 2026-07d smart-ai (loaded from mobile-ai.lua).
-- 界马超（台服重置） gu_twjiemachao：马术 + 铁骑 gu_twtieji.

sgs.ai_skill_invoke.gu_twtieji = function(self, data)
	local target = data:toPlayer()
	return target and not self:isFriend(target)
end

-- Target side: hand over a card of the judge suit, otherwise no response and +1 damage.
-- An unanswerable, boosted 【杀】 costs more than one card, so give the cheapest match.
sgs.ai_skill_cardask["@gu_twtieji-give"] = function(self, data, pattern, target)
	local use = data:toCardUse()
	local suit = pattern:split("|")[2]
	local from = use and use.from or target
	if use and use.card and from and not self:slashIsEffective(use.card, self.player, from) then return "." end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _, c in ipairs(cards) do
		if c:getSuitString() == suit then return "$" .. c:getEffectiveId() end
	end
	return "."
end
