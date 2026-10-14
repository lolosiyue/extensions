-- ===== diyba b03 =====
do
-- diyba b03 AI hooks
sgs.ai_skill_invoke.diyba_mingye_give = true
sgs.ai_skill_cardask["@diyba-mingye-discard"] = function(self, data, pattern)
    if self.player:isWounded() then
        local cards = sgs.QList2Table(self.player:getCards("he"))
        self:sortByKeepValue(cards)
        for _, c in ipairs(cards) do
            if c:getSuit() == sgs.Card_Heart then return c:toString() end
        end
    end
    return "."
end
sgs.ai_skill_playerchosen.diyba_dangshu = function(self, targets)
    for _, p in sgs.qlist(targets) do
        if self:isFriend(p) then return p end
    end
    return nil
end
sgs.ai_skill_playerchosen.diyba_xiaheng = function(self, targets)
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) then return p end
    end
    return targets:first()
end
end

