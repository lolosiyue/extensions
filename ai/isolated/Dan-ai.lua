-- Effective Dan callbacks at b6025acc. Read the skill's disclosed owner property;
-- never recompute its aggregate from the hidden draw pile.
local function call(object, method, ...)
    if not object or type(object[method]) ~= "function" then ai_unsupported("Dan policy helper is unavailable", method) end
    local value=object[method](object,...)
    if AIUnsupported.is(value) then error(value,0) end
    if value==nil then ai_unsupported("Dan policy fact is unknown",method) end
    return value
end
local function allowedSuits(player)
    local ai=player and player._room and player._room._ai
    local facts=ai and ai.world and ai.world.strategy_facts
    local properties=type(facts)=="table" and facts.owner_skill_properties
    local value=type(properties)=="table" and properties.LuaYanjiu
    if not ai or player~=ai.player or type(value)~="string" then
        ai_unsupported("owner LuaYanjiu property is not projected", "LuaYanjiu.property")
    end
    local suits={}
    for suit in value:gmatch("[^+]+") do suits[suit]=true end
    return suits
end
local function proposal(card)
    -- Card::Parse's zero stored number inherits its single material, including
    -- the JOKER strings whose numeric parsing gives zero.
    local suit=call(card,"getSuitString")
    local number=call(card,"getNumberString")
    local id=call(card,"getEffectiveId")
    local numeric=({A=1,J=11,Q=12,K=13})[number] or tonumber(number) or 0
    if numeric<=0 then numeric=call(card,"getNumber") end
    return {name="analeptic",skill="LuaYanjiu",suit=call(card,"getSuit"),number=numeric,subcards={id}}
end
sgs.ai_fill_skill.LuaYanjiu=function(self,inclusive,request)
    local cards=sgs.QList2Table(call(self.player,"getCards","h"))
    if #call(self.player,"getPile","wooden_ox")>0 then
        for _,id in ipairs(call(self.player,"getPile","wooden_ox")) do table.insert(cards,call(self,"getKnownCardById",id)) end
    end
    cards=call(self,"sortByUseValue",cards,true)
    local suits=allowedSuits(self.player)
    local selected
    for _,card in ipairs(cards) do if suits[call(card,"getSuitString")] then selected=card break end end
    if not selected then return nil end
    local analeptic=call(self,"evaluateTurnConversion","LuaYanjiu","Analeptic",proposal(selected),request)
    -- The donor asks Analeptic::IsAvailable on the hypothetical clone, before
    -- native payment selection. Even an illegal first cost remains the policy choice.
    if call(self,"readonlyTurnAvailability",analeptic) then return analeptic end
end
sgs.ai_view_as.LuaYanjiu=function(card,player,card_place)
    local suit=call(card,"getSuitString")
    local number=call(card,"getNumberString")
    local id=call(card,"getEffectiveId")
    if card_place==sgs.Player_PlaceHand or call(player,"getPile","wooden_ox"):contains(id) then
        local suits=allowedSuits(player)
        if suits[call(card,"getSuitString")] then
            -- Preserve the native single-material parsed identity.
            local numeric=({A=1,J=11,Q=12,K=13})[number] or tonumber(number) or 0
            if numeric<=0 then numeric=call(card,"getNumber") end
            return {name="analeptic",skill="LuaYanjiu",suit=call(card,"getSuit"),number=numeric,subcards={id}}
        end
    end
end
sgs.ai_skill_playerchosen.LuaJiangfu=function(self)
    local minimum,target=100,nil
    if not AIValue.isList(self.friends) then ai_unsupported("Dan friends are unknown","LuaJiangfu") end
    for _,friend in ipairs(self.friends) do
        local hp=call(friend,"getHp")
        if call(self,"hasSkills",sgs.masochism_skill,friend) then hp=hp-1 end
        if call(friend,"isLord") then hp=hp-1 end
        if hp<minimum then minimum,target=hp,friend end
    end
    return target or self.player
end
sgs.ai_playerchosen_intention.LuaJiangfu=-80
