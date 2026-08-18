ai_skill_use["@@lianying"] = function(self)
    local upperlimit = self.player:getMark("lianying")
    if self.player:getPhase() > sgs.Player_Play or upperlimit ~= 1 then
        return nil
    end

    return {
        kind = "use_card",
        card = "@LianyingCard=.->" .. self.player:objectName()
    }
end
