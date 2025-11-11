sgs.ai_skill_invoke.Rcekuiwei = function(self, data)
    local current = self.room:getCurrent()
    if current:getNextAlive():objectName() == self.player:objectName() and self.player:faceUp() then
        return false
    end
    return true
end

sgs.ai_view_as.Rceyanzheng = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place==sgs.Player_PlaceHand then
		if player:getHandcardNum()>player:getHp() then
			return ("nullification:Rceyanzheng[%s:%s]=%d"):format(suit,number,card_id)
		end
	end
end