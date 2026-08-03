-- MeleePeach AI
-- 鏖戰模式：桃當殺/閃

sgs.ai_fill_skill.melee_peach = function(self, player)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    
    for _, card in ipairs(cards) do
        if card:isKindOf("Peach") then
            local suit = card:getSuitString()
            local number = card:getNumberString()
            local card_id = card:getEffectiveId()
            local slash = sgs.Card_Parse(("slash:melee_peach[%s:%s]=%d"):format(suit, number, card_id))
            if slash:isAvailable(self.player) then
                return slash
            end
        end
    end
    return nil
end

sgs.ai_cardsview.melee_peach = function(self, class_name, player)
    if not player:hasSkill("melee_peach") then return end
    local handcards = player:getCards("h")
    for _, c in sgs.list(handcards) do
        if c:isKindOf("Peach") then
            if class_name == "Slash" then
                return ("slash:melee_peach[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(), c:getEffectiveId())
            elseif class_name == "Jink" then
                return ("jink:melee_peach[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(), c:getEffectiveId())
            end
        end
    end
end

sgs.ai_use_value.MeleeSlashJink = sgs.ai_use_value.Slash
sgs.ai_keep_value.MeleeSlashJink = sgs.ai_keep_value.Slash
