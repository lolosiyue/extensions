extension = sgs.Package("Dan", sgs.Package_GeneralPack)
local tr = sgs.LoadTranslationTable
local isHegemony = sgs.Sanguosha:getVersionName() == "Heg"
if isHegemony then
    local kingdomtab = table.Shuffle{"wei","shu","wu","qun"}
    dan_gen = sgs.General(extension,"dan_amira",kingdomtab[math.random(1,4)],2)
else
    dan_gen = sgs.General(extension,"dan_amira","god",2, false)
end

tr{
    ["Dan"] = "年",

    ["dan_amira"] = "新年娘",
    ["#dan_amira"] = "新年快乐",

    ["designer:dan_amira"] = "Amira",
	["illustrator:dan_amira"] = "",
}
if isHegemony then
    LuaJiangfu = sgs.CreateTriggerSkill{
        name = "LuaJiangfu",
        events = {sgs.Damaged},
        can_preshow = true,
        can_trigger = function(self, event, room, player, data)
            if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
            if player:getPhase() ~= sgs.Player_NotActive then return "" end
            local num_tab = {}
            local invoke = false
            local draw_pile = room:getDrawPile()
            for _,id in sgs.qlist(draw_pile)do
                local c = sgs.Sanguosha:getCard(id);
                if table.contains(num_tab,c:getNumber()) then
                    invoke = true
                    break
                else
                    table.insert(num_tab,c:getNumber())
                end
            end
            if invoke then
                return self:objectName()
            end
            return ""
        end,
        on_cost = function(self,event,room,player,data)
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getAlivePlayers())do
                if p:getLostHp() > 0 then
                    targets:append(p)
                end
            end
            local pl= room:askForPlayerChosen(player, targets, self:objectName(),self:objectName() .. "_Invoke", true, true)
            if pl then
                local _data = sgs.QVariant()
                _data:setValue(pl)
                player:setTag(self:objectName(),_data)
                return true
            end
            return false
        end,
        on_effect = function(self,event,room,player,data)
            local p = player:getTag(self:objectName()):toPlayer()
            if p then
                local re = sgs.RecoverStruct()
                re.who = player
                re.recover = 1
                room:recover(p,re)
            end
            return false
        end,
    }
else
    LuaJiangfu = sgs.CreateTriggerSkill{
	name = "LuaJiangfu",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_NotActive then
			local num_tab = {}
			for _,id in sgs.qlist(room:getDrawPile())do
				local c = sgs.Sanguosha:getCard(id)
				if table.contains(num_tab,c:getNumber()) then
					local targets = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getAlivePlayers())do
						if p:getLostHp() > 0 then
							targets:append(p)
						end
					end
					local p = room:askForPlayerChosen(player, targets, self:objectName(),"LuaJiangfu_Invoke", true, true)
					if p then
						room:recover(p, sgs.RecoverStruct(player))
					end
					break
				else
					table.insert(num_tab,c:getNumber())
				end
			end
        end
        return false
	end
}
end

dan_gen:addSkill(LuaJiangfu)

tr{
    ["LuaJiangfu"] = "降福",
    [":LuaJiangfu"] = "每当你于回合外受到伤害后，若牌堆里还有点数相同的牌，你可令一名角色回复一点体力",
    ["LuaJiangfu_Invoke"] = "请选择一名受伤的角色来发动技能 降福 ~",
}

if isHegemony then
    LuaYanjiuVS = sgs.CreateOneCardViewAsSkill{   
        name = "LuaYanjiu",
        view_filter = function(self, to_select)
            local suits = sgs.Self:property(self:objectName()):toString():split("+")
            return table.contains(suits,to_select:getSuitString())
        end,
        response_or_use = true,
        view_as = function(self,card)
            local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
            analeptic:setSkillName(self:objectName())
            analeptic:setShowSkill(self:objectName())
            analeptic:addSubcard(card)
            return analeptic
        end,

        enabled_at_play = function(self, player)
            return sgs.Analeptic_IsAvailable(player)
        end,

        enabled_at_response = function(self, player, pattern)
            return string.find(pattern, "analeptic")
        end
    }

    LuaYanjiu = sgs.CreateTriggerSkill{
        name = "LuaYanjiu",
        events = {sgs.CardsMoveOneTime},
        view_as_skill = LuaYanjiuVS,
        
        on_record = function(self, event, room, player, data)
            if player and player:isAlive() and player:hasSkill(self:objectName()) then
                local move = data:toMoveOneTime()
                if move.from_places:contains(sgs.Player_DrawPile) or move.to_place == sgs.Player_DrawPile then
                    local hash = {}
                    for _,id in sgs.qlist(room:getDrawPile())do
                        local c = sgs.Sanguosha:getCard(id)
                        if hash[c:getSuitString()] then
                            hash[c:getSuitString()] = hash[c:getSuitString()] + 1
                        else
                            hash[c:getSuitString()] = 1
                        end
                    end
                    local max = 0
                    for _,v in pairs(hash)do
                        if v > max then max = v end
                    end
                    local big_suit = {}
                    for s,v in pairs(hash)do
                        if v == max then table.insert(big_suit,s) end
                    end
                    room:setPlayerProperty(player,self:objectName(),sgs.QVariant(table.concat(big_suit,"+")))
                end
            end
        end,
        can_trigger = function()
            return ""
        end
    }
else
    LuaYanjiuVS = sgs.CreateOneCardViewAsSkill{   
        name = "LuaYanjiu",
        view_filter = function(self, to_select)
            local suits = sgs.Self:property(self:objectName()):toString():split("+")
            return table.contains(suits,to_select:getSuitString())
        end,
        response_or_use = true,
        view_as = function(self,card)
            local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
            analeptic:setSkillName(self:objectName())
            analeptic:addSubcard(card)
            return analeptic
        end,

        enabled_at_play = function(self, player)
            return sgs.Analeptic_IsAvailable(player)
        end,

        enabled_at_response = function(self, player, pattern)
            return string.find(pattern, "analeptic")
        end
    }

    LuaYanjiu = sgs.CreateTriggerSkill{
        name = "LuaYanjiu",
        events = {sgs.CardsMoveOneTime},
        view_as_skill = LuaYanjiuVS,
        on_trigger = function(self, event, player, data, room)
            local move = data:toMoveOneTime()
            if move.from_places:contains(sgs.Player_DrawPile) or move.to_place == sgs.Player_DrawPile then
                local hash = {}
                for _,id in sgs.qlist(room:getDrawPile())do
                    local c = sgs.Sanguosha:getCard(id)
                    if hash[c:getSuitString()] then
                        hash[c:getSuitString()] = hash[c:getSuitString()] + 1
                    else
                        hash[c:getSuitString()] = 1
                    end
                end
                local max = 0
                for _,v in pairs(hash)do
                    if v > max then max = v end
                end
                local big_suit = {}
                for s,v in pairs(hash)do
                    if v == max then table.insert(big_suit,s) end
                end
                room:setPlayerProperty(player,self:objectName(),sgs.QVariant(table.concat(big_suit,"+")))
            end
        end
    }
end

dan_gen:addSkill(LuaYanjiu)

tr{
    ["LuaYanjiu"] = "言酒",
    [":LuaYanjiu"] = "你可将一张花色为O的牌当【酒】使用或打出（O为牌堆剩余最多的花色数之一）",
}

return extension