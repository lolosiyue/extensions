-- Complete fixed b6025acc animecard policy bodies. Readonly native evaluations
-- supply hypothetical card rules; every eventual action retains native gates.
local function known(value, key)
    if AIUnsupported and AIUnsupported.is(value) then error(value, 0) end
    if value == nil then ai_unsupported("animecard value is unknown", key) end
    return value
end

local function has_skill(self, player, name)
    local value=player:hasSkill(name)
    local view=type(player)=="table" and rawget(player,"_view")
    -- Non-view objects are explicit helper oracles in source differential tests.
    -- Production PlayerViews must distinguish a complete roster from disclosure.
    if value or not view or view.skills_complete==true then return value end
    if player:objectName()==self.player:objectName() then
        ai_unsupported("animecard owner skill roster is incomplete",name)
    end
    -- Authorized role-view policy: an unobserved foreign skill is treated as
    -- absent for these four source predicates, with explicit estimate provenance.
    -- This is never exported as a complete roster or used as native authority.
    return self:useKnowledgeEstimate({status="estimate",value=false,
        player=player:objectName(),skill=name,
        basis="animecard_unobserved_foreign_skill_absent_role_view"}, "animecard skill presence")
end
sgs.weapon_range.GreenRose = 2
sgs.ai_weapon_value.GreenRose = function(self, enemy, player)
    if not enemy then return 5
    elseif not enemy:hasArmorEffect("SilverLion") and enemy:getArmor() then return 6 end
    return 6
end
sgs.ai_slash_weaponfilter.GreenRose = function(self, to)
    return to:getArmor() and not to:hasArmorEffect("SilverLion")
end
sgs.weapon_range.Elucidator = 2
sgs.ai_weapon_value.Elucidator = function(self, enemy, player)
    if not enemy then return 0
    elseif enemy:getHandcardNum() < 3 and player:getHandcardNum() > 2 then return 4
    elseif has_skill(self, player, "se_erdao") or has_skill(self, player, "LuaChanshi") then return 6 end
    return 3
end
sgs.ai_slash_weaponfilter.Elucidator = function(self, to)
    return to:getHandcardNum() < 3
end
sgs.ai_skill_invoke.Se_Elucidator = function(self, data)
    local effect = data:toCardEffect()
    local duel = self:evaluateSkillCard("Se_Elucidator", "duel", {})
    local use = {isDummy=true, extra_target=0, current_targets=self.room:getOtherPlayers(effect.to), to=AIList.new({})}
    local planned = self:evaluateCard(duel, use)
    if planned.card and planned and planned.to and planned.to:contains(effect.to) then return true end
    return false
end
function SmartAIView:useCardreijyuu(card, use)
    local enemies, friends = known(self.enemies,"enemies"), known(self.friends_noself,"friends_noself")
    if #enemies == 0 and #friends == 0 then return false end
    local weak
    for _, player in ipairs(enemies) do if self:isWeak(player) then weak=player end end
    if weak then
        for _, player in ipairs(enemies) do
            if player:objectName() ~= weak:objectName() then
                use.card=card
                if use.to and not self.player:isProhibited(player, card) then use.to:append(player) end
                return
            end
        end
    else
        for _, player in ipairs(enemies) do
            use.card=card
            if use.to and not self.player:isProhibited(player, card) then use.to:append(player) end
            return
        end
    end
end
ai_card_use.reijyuu=function(self,card,use)return self:useCardreijyuu(card,use)end
sgs.ai_use_priority.reijyuu=4.55
sgs.ai_use_value.reijyuu=9
sgs.ai_keep_value.reijyuu=1.0
sgs.ai_card_intention.reijyuu=40
sgs.ai_nullification.reijyuu=function(self,card,from,to,positive)
    if positive then
        if self:isFriend(to) and self:isEnemy(from) then return true end
    else
        if self:isEnemy(to) and self:isFriend(from) then return true end
    end
end
sgs.ai_skill_playerchosen.reijyuu=function(self,targets)
    for _, player in ipairs(targets) do
        if self:isEnemy(player) and self:isWeak(player) then return player end
    end
    return self.player
end
sgs.ai_skill_choice.reijyuu=function(self,choices,data)
    local context=self:getDecisionContext()
    local flagged=known(context.reijyuu_flagged_players,"public reijyuu selected-player flags")
    if not AIValue.isList(flagged) then ai_unsupported("invalid reijyuu public flag list","reijyuu") end
    -- Producer retains the actual alive-roster order. A missing list is not a
    -- claim that all flags are absent and cannot silently choose Move.
    for _, name in ipairs(flagged) do
        local player=known(self.room:findPlayerByObjectName(name),"reijyuu flagged player")
        if self:isFriend(player) then return "reijyuuMove" else return "reijyuuDamage" end
    end
    return "reijyuuMove"
end
function SmartAIView:useCardtacos(card,use)
    for _, player in ipairs(known(self.enemies,"enemies")) do if has_skill(self,player,"eastfast") then return end end
    for _, player in ipairs(known(self.friends,"friends")) do if has_skill(self,player,"SE_Jiawu") then return end end
    use.card=card
end
ai_card_use.tacos=function(self,card,use)return self:useCardtacos(card,use)end
sgs.ai_card_intention.tacos=-40
sgs.ai_keep_value.tacos=2.5
sgs.ai_use_value.tacos=8
sgs.ai_use_priority.tacos=4
sgs.dynamic_value.benefit.tacos=true
