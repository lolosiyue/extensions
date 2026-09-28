-- Assassins value-only decisions. Native policy/state dependencies remain explicit
-- unsupported branches; this file does not claim full legacy strategy coverage.
local function known(value, key)
    if value == nil then ai_unsupported("required visible value is unknown", key) end
    return value
end
local function relation(self, player, key)
    local value = self:relationTo(player)
    if value ~= "friend" and value ~= "enemy" and value ~= "neutral" then
        ai_unsupported("player relation is unknown", key)
    end
    return value
end
local function pass() return {kind = "pass"} end
local function choice(options, wanted, key)
    for _, value in ipairs(options and options.choices or {}) do
        if value == wanted then return value end
    end
    ai_unsupported("legacy choice was not offered", key)
end
local function selected(options, id, key)
    if not options or options.candidates_complete ~= true then
        ai_unsupported("card candidates are incomplete", key)
    end
    for _, value in ipairs(options.card_ids or {}) do if value == id then return id end end
    ai_unsupported("legacy selected card was not offered", key)
end
local function active_action(self, key)
    local action = self:getSkillAction()
    if action then
        if action:getActivationSkillName() ~= key then ai_unsupported("different activation skill", key) end
    else
        for _, candidate in ipairs(known(self:getSkillActions(), key)) do
            if candidate:getActivationSkillName() == key then
                if action then ai_unsupported("activation instance is ambiguous", key) end
                action = candidate
            end
        end
    end
    if not action or not action:isValid() then ai_unsupported("activation ticket is missing", key) end
    return action
end

ai_skill_invoke.moukui = function(self)
    local target = known(self:getDecisionContext().player, "moukui")
    -- The original choice consumes the target saved by the preceding invoke.
    known(self:rememberAt("assassins.moukui.target", target:objectName()), "moukui")
    if relation(self, target, "moukui") == "friend" then
        ai_unsupported("needToThrowArmor policy is not covered", "moukui")
    end
    return true
end
ai_skill_choice.moukui = function(self, options)
    local name, revision = self:recallAt("assassins.moukui.target")
    self:remember("assassins.moukui.target", nil)
    local context = self:getDecisionContext().player
    if context then
        if context:objectName() ~= name then ai_unsupported("moukui target changed", "moukui") end
    elseif revision == nil or revision ~= self.request.state_revision then
        ai_unsupported("moukui saved target is stale", "moukui")
    end
    local target = known(self.room:findPlayerByObjectName(known(name, "moukui")), "moukui")
    return choice(options, known(self:doDisCard(target), "moukui") and "discard" or "draw", "moukui")
end

ai_skill_invoke.tianming = function(self)
    -- hasManjuanEffect precedes even the nude-player shortcut in the source.
    ai_unsupported("tianming needs hasManjuanEffect/canHit and the exact discard policy", "tianming")
end
ai_skill_discard.tianming = function(self)
    ai_unsupported("tianming invoke discard plan and legacy fallback are not covered", "tianming")
end
ai_skill_activate.mizhao = function(self)
    if known(self.player:getHandcardNum(), "mizhao") == 0 then return nil end
    ai_unsupported("mizhao needs needBear, Tuntian and the original gift policy", "mizhao")
end
sgs.ai_use_priority.MizhaoCard = 1.5
sgs.ai_card_intention.MizhaoCard = 0
sgs.ai_playerchosen_intention.mizhao = 10
ai_skill_playerchosen.mizhao = function(self, options)
    if not options or options.candidates_complete ~= true then ai_unsupported("incomplete candidates", "mizhao") end
    for _, player in ipairs(known(self.room:getOtherPlayers(self.player), "mizhao")) do
        if known(player:hasFlag("AI_MizhaoTarget"), "mizhao") then
            ai_unsupported("mizhao source Slash/Leiji policy and flag consumption are not covered", "mizhao")
        end
    end
    local allowed = {}
    for _, name in ipairs(options.players or {}) do allowed[name] = true end
    local enemies = known(self.enemies, "mizhao")
    for _, enemy in ipairs(known(self:sort(enemies, "defense"), "mizhao")) do
        if allowed[enemy:objectName()] then return enemy:objectName() end
    end
    return nil
end
-- Keep the original positional Pindian ABI; the common adapter supplies values.
sgs.ai_skill_pindian.mizhao = function(minusecard, self, requestor, maxcard)
    local req = requestor
    if not req then ai_unsupported("pindian requestor is missing", "mizhao") end
    if self.player:objectName() == req:objectName() then
        req = nil
        for _, player in ipairs(known(self.room:getOtherPlayers(self.player), "mizhao")) do
            if known(player:hasFlag("MizhaoPindianTarget"), "mizhao") then req = player; break end
        end
    end
    req = known(req, "mizhao")
    local cards = known(self.player:getHandcards(), "mizhao")
    if #cards == 0 then ai_unsupported("pindian hand is empty", "mizhao") end
    cards = known(self:sortByKeepValue(cards), "mizhao")
    local maximum = known(self:getKeepValue(cards[#cards]), "mizhao")
    local ascending = relation(self, req, "mizhao") == "friend"
        and known(self.player:getHp(), "mizhao") > known(req:getHp(), "mizhao")
    for _, card in ipairs(cards) do known(card:getNumber(), "mizhao") end
    table.sort(cards, function(a, b)
        if ascending then return a:getNumber() < b:getNumber() end
        return a:getNumber() > b:getNumber()
    end)
    for _, card in ipairs(cards) do
        if maximum > 7 or known(self:getKeepValue(card), "mizhao") < 7 or card:isKindOf("EquipCard") then return card end
    end
    return cards[1]
end

local function jieyuan_cards(self)
    local unrestricted = known(self.player:getMark("jieyuan_renegade-Keep"), "jieyuan") > 0
    local cards = known(self.player:getCards(unrestricted and "he" or "h"), "jieyuan")
    return known(self:sortByKeepValue(cards), "jieyuan"), unrestricted
end
local function jieyuan_pick(cards, unrestricted, color)
    for _, card in ipairs(cards) do
        if unrestricted or (color == "black" and card:isBlack()) or (color == "red" and card:isRed()) then
            return card:getEffectiveId()
        end
    end
end
ai_skill_cardask["@jieyuan-increase"] = function(self, options)
    local damage = known(self:getDecisionContext().damage, "jieyuan")
    local target = known(damage.to, "jieyuan")
    if relation(self, target, "jieyuan") ~= "enemy" then return pass() end
    if known(target:hasArmorEffect("SilverLion"), "jieyuan") then return pass() end
    local cards, unrestricted = jieyuan_cards(self)
    local id = jieyuan_pick(cards, unrestricted, "black")
    return id and selected(options, id, "jieyuan") or pass()
end
ai_skill_cardask["@jieyuan-decrease"] = function(self, options)
    local damage = known(self:getDecisionContext().damage, "jieyuan")
    local cards, unrestricted = jieyuan_cards(self)
    if damage.card and damage.card:isKindOf("Slash") then
        if known(self:ajustDamage(damage.from, self.player, 1, damage.card), "jieyuan") > 1 then
            local id = jieyuan_pick(cards, unrestricted, "red")
            if id then return selected(options, id, "jieyuan") end
        end
    end
    if known(self:needToLoseHp(self.player, damage.from, damage.card), "jieyuan")
        and known(damage.damage, "jieyuan") <= 1 then return pass() end
    local id = jieyuan_pick(cards, unrestricted, "red")
    return id and selected(options, id, "jieyuan") or pass()
end
sgs.ai_cardneed.jieyuan = function(to, card)
    local mark = known(to:getMark("jieyuan_renegade-Keep"), "jieyuan")
    if mark > 0 then
        return known(to:getHandcardNum(), "jieyuan") < 4 and known(to:getHp(), "jieyuan") >= 3
    end
    return known(to:getHandcardNum(), "jieyuan") < 4
        and (known(to:getHp(), "jieyuan") >= 3 or card:isRed())
end
ai_skill_invoke.fenxin = function(self)
    ai_unsupported("fenxin needs role prediction and gameProcess, not an enemy shortcut", "fenxin")
end
ai_skill_activate.mixin = function(self)
    if known(self.player:getHandcardNum(), "mixin") == 0 then return nil end
    ai_unsupported("mixin needs needBear, Tuntian and view-as Slash counting", "mixin")
end
ai_skill_playerchosen.mixin = function(self)
    ai_unsupported("zero_card_as_slash target policy is not covered", "mixin")
end
ai_skill_cardask["#mixin"] = function(self)
    ai_unsupported("mixin needs full Slash enumeration and needLeiji policy", "mixin")
end
sgs.ai_use_priority.MixinCard = 0
sgs.ai_card_intention.MixinCard = -20

ai_skill_invoke.cangni = function(self)
    local target = known(self.room:getCurrent(), "cangni")
    if known(self.player:hasFlag("cangnilose"), "cangni") then return relation(self, target, "cangni") == "enemy" end
    if known(self.player:hasFlag("cangniget"), "cangni") then return relation(self, target, "cangni") == "friend" end
    return known(self.player:getHandcardNum(), "cangni") + 2 <= known(self.player:getHp(), "cangni")
        or known(self.player:getHp(), "cangni") < known(self.player:getMaxHp(), "cangni")
end
ai_skill_choice.cangni = function(self, options)
    local draw = known(self.player:getHandcardNum(), "cangni") + 2 <= known(self.player:getHp(), "cangni")
    return choice(options, draw and "draw" or "recover", "cangni")
end
ai_skill_activate.duyi = function(self)
    return {kind = "use_card", skill_action = active_action(self, "duyi"):toAnswer()}
end
ai_skill_playerchosen.duyi = function(self)
    ai_unsupported("duyi needs ai_duyi card/target state and needBear before draw selection", "duyi")
end
sgs.ai_playerchosen_intention.duyi = function(self, from, to)
    ai_unsupported("duyi intention needs the revealed ai_duyi card state", "duyi")
end
ai_skill_invoke.duanzhi = function(self)
    local use = known(self:getDecisionContext().use, "duanzhi")
    if not use.from then return false end
    if relation(self, use.from, "duanzhi") ~= "enemy" then return false end
    local card = known(use.card, "duanzhi")
    local hp = known(self.player:getHp(), "duanzhi")
    if type(card.getSubtype) ~= "function" then ai_unsupported("card subtype is not projected", "duanzhi") end
    if known(card:getSubtype(), "duanzhi") == "attack_card" and hp == 1 then
        ai_unsupported("duanzhi death branch needs rescue enumeration and AI_doNotSave state", "duanzhi")
    end
    return known(self:doDisCard(use.from, "he", nil, 2), "duanzhi") and hp > 2
end
ai_skill_choice.duanzhi = function(self, options) return choice(options, "discard", "duanzhi") end
ai_skill_use["@@fengyin"] = function(self)
    ai_unsupported("fengyin needs needBear, skip-phase policy and a conversion ticket", "fengyin")
end
ai_skill_invoke.cv_caocao = function(self) return math.random(0, 6) == 0 end
ai_skill_invoke.cv_lingju = function(self) return math.random(0, 2) == 0 end
