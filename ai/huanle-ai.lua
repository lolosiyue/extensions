-- GU 欢乐三国杀 (huanle.md) AI; skills live in extensions/offline.lua (package huanle).

-- ==================== c201
do
-- c201 AI: 丁原 .. 关索 (欢乐杀修改 / 欢乐杀界限突破). Conservative and nil-safe.
local function c201_enemy(self, targets)
    local ps = sgs.QList2Table(targets); self:sort(ps, "hp")
    for _, p in ipairs(ps) do if self:isEnemy(p) then return p end end
end
local function c201_friend(self, targets)
    local ps = sgs.QList2Table(targets); self:sort(ps, "hp")
    for _, p in ipairs(ps) do if self:isFriend(p) then return p end end
end
local function c201_low(self, flags)
    local cards = sgs.QList2Table(self.player:getCards(flags or "he"))
    if #cards == 0 then return nil end
    self:sortByKeepValue(cards)
    return cards[1]
end
local function c201_low_ids(self, n, flags)
    local cards = sgs.QList2Table(self.player:getCards(flags or "he"))
    self:sortByKeepValue(cards)
    local ids = {}
    for i = 1, math.min(n, #cards) do table.insert(ids, cards[i]:getEffectiveId()) end
    return ids
end

-- 丁原
sgs.ai_skill_playerchosen.hlxg_cixiao = function(self, targets) return c201_friend(self, targets) end
sgs.ai_skill_playerchosen.hlxg_cixiao_slash = function(self, targets) return c201_enemy(self, targets) or targets:first() end
sgs.ai_skill_discard.hlxg_cixiao = function(self, discard_num, min_num, optional)
    if #self.enemies == 0 then return {} end
    return c201_low_ids(self, 1, "h")
end
sgs.ai_skill_playerchosen.hlxg_panshi = function(self, targets) return c201_friend(self, targets) or targets:first() end

-- 丁奉
local function c201_fenxun_fill(name)
    sgs.ai_fill_skill[name] = function(self)
        if self:getCardsNum("Slash") == 0 and not self.player:hasSkill("hljx_fenxun") then return end
        return sgs.Card_Parse("#" .. name .. "Card:.:")
    end
    sgs.ai_skill_use_func["#" .. name .. "Card"] = function(card, use, self)
        self:sort(self.enemies, "hp")
        for _, p in ipairs(self.enemies) do
            if self.player:distanceTo(p) > 1 then use.card = card; use.to:append(p); return end
        end
    end
    sgs.ai_use_priority[name .. "Card"] = 8
end
c201_fenxun_fill("hlxg_fenxun")
c201_fenxun_fill("hljx_fenxun")

-- 严夫人
sgs.ai_fill_skill.hlxg_channi = function(self)
    if #self.friends_noself == 0 or self.player:getHandcardNum() <= self.player:getHp() then return end
    local c = c201_low(self, "h")
    if c then return sgs.Card_Parse("#hlxg_channiCard:" .. c:getEffectiveId() .. ":") end
end
sgs.ai_skill_use_func["#hlxg_channiCard"] = function(card, use, self)
    self:sort(self.friends_noself, "handcard")
    for _, p in ipairs(self.friends_noself) do
        if not p:hasSkill("manjuan") then use.card = card; use.to:append(p); return end
    end
end
sgs.ai_use_priority.hlxg_channiCard = 1
sgs.ai_skill_discard.hlxg_channi = function(self, discard_num, min_num, optional)
    if #self.enemies == 0 then return {} end
    return c201_low_ids(self, 1, "h")
end
sgs.ai_skill_playerchosen.hlxg_channi_duel = function(self, targets) return c201_enemy(self, targets) end
sgs.ai_skill_invoke.hlxg_channi_prevent = function(self, data)
    local to = data:toPlayer()
    return to and self:isFriend(to) and self.player:getHandcardNum() <= 2
end

-- 严畯
sgs.ai_skill_choice.hlxg_guanchao = function(self, choices)
    if self:getCardsNum("Slash") >= 2 and choices:find("up") then return "up" end
    if choices:find("down") then return "down" end
    return "cancel"
end
sgs.ai_skill_playerchosen.hlxg_xunxian = function(self, targets)
    local friends = {}
    for _, p in sgs.qlist(targets) do if self:isFriend(p) and not p:hasSkill("manjuan") then table.insert(friends, p) end end
    if #friends == 0 then return nil end
    self:sort(friends, "handcard")
    return friends[1]
end

-- 严颜
sgs.ai_skill_invoke.hlxg_juzhan_draw = true
sgs.ai_skill_invoke.hlxg_juzhan_get = function(self, data)
    local to = data:toPlayer()
    return to and self:isEnemy(to)
end

-- 乐进
sgs.ai_skill_discard.hlxg_xiaoguo = function(self, discard_num, min_num, optional)
    local cur = self.room:getCurrent()
    if not cur or not self:isEnemy(cur) then return {} end
    local c = c201_low(self)
    if not c or self:getKeepValue(c) > 5 then return {} end
    return {c:getEffectiveId()}
end
sgs.ai_skill_choice.hlxg_xiaoguo = function(self, choices)
    if choices:find("equip") and (self.player:getHp() <= 2 or self.player:getEquips():length() > 1) then return "equip" end
    return "damage"
end

-- 于禁
sgs.ai_skill_playerchosen.hlxg_zhenjun = function(self, targets)
    local best, n = nil, 0
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) and p:getCardCount(true) > n then best, n = p, p:getCardCount(true) end
    end
    return best
end
sgs.ai_skill_choice.hlxg_zhenjun = function(self, choices, data)
    local to = data:toPlayer()
    if to and self:isFriend(to) and choices:find("draw") then return "draw" end
    if choices:find("discard") and self.player:getCardCount(true) > 2 then return "discard" end
    if choices:find("draw") and to and not self:isEnemy(to) then return "draw" end
    return choices:find("discard") and "discard" or "draw"
end
sgs.ai_skill_discard.hlxg_xiayuan = function(self, discard_num, min_num, optional)
    local dying = self.room:getCurrentDyingPlayer()
    if not dying or not self:isFriend(dying) then return {} end
    return c201_low_ids(self, math.min(2, 1 - dying:getHp()))
end
sgs.ai_skill_playerchosen.hlxg_jieyue = function(self, targets) return c201_enemy(self, targets) end

-- 伏完
sgs.ai_skill_choice.hlxg_moukui = function(self, choices, data)
    local t = data:toPlayer()
    if t and self:isEnemy(t) and choices:find("discard") then
        return self.player:getCardCount(true) > 2 and choices:find("both") and "both" or "discard"
    end
    return "draw"
end

-- 伏皇后
sgs.ai_skill_invoke.hlxg_zhuikong = function(self, data)
    local t = data:toPlayer()
    if not t or not self:isEnemy(t) then return false end
    for _, c in sgs.qlist(self.player:getHandcards()) do
        if c:getNumber() >= 11 then return true end
    end
    return false
end
sgs.ai_skill_playerschosen.hlxg_qiuyuan = function(self, targets)
    local chosen = {}
    for _, p in sgs.qlist(targets) do
        if #chosen < 3 and (self:isEnemy(p) or self:isFriend(p) and p:getHandcardNum() > 2) then table.insert(chosen, p) end
    end
    return chosen
end
sgs.ai_skill_cardask["@hlxg_qiuyuan-give"] = function(self, data, pattern, target)
    local fhh
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasSkill("hlxg_qiuyuan") then fhh = p end
    end
    if fhh and self:isFriend(fhh) then
        for _, c in sgs.qlist(self.player:getHandcards()) do
            if c:isKindOf("Jink") then return "$" .. c:getEffectiveId() end
        end
    end
    return "."
end

-- 何太后
sgs.ai_skill_invoke.hlxg_qiluan = true
sgs.ai_skill_discard.hlxg_zhendu = function(self, discard_num, min_num, optional)
    local cur = self.room:getCurrent()
    if not cur or cur:objectName() == self.player:objectName() or not self:isEnemy(cur) or cur:getHp() <= 1 then return {} end
    local c = c201_low(self)
    if not c or self:getKeepValue(c) > 5 then return {} end
    return {c:getEffectiveId()}
end

-- 全琮
sgs.ai_skill_choice.hlxg_yaoming = function(self, choices)
    if choices:find("opt2") then return "opt2" end
    if choices:find("opt1") and #self.enemies > 0 then return "opt1" end
    return "cancel"
end
sgs.ai_skill_playerchosen.hlxg_yaoming_1 = function(self, targets) return c201_enemy(self, targets) end
sgs.ai_skill_playerchosen.hlxg_yaoming_2 = function(self, targets)
    for _, p in sgs.qlist(targets) do if p:objectName() == self.player:objectName() then return p end end
    return c201_friend(self, targets)
end
sgs.ai_skill_playerchosen.hlxg_yaoming_3 = function(self, targets) return c201_friend(self, targets) end

-- 公孙渊
local function c201_minor_color(self)
    local red, black = 0, 0
    for _, c in sgs.qlist(self.player:getHandcards()) do
        if c:isRed() then red = red + 1 elseif c:isBlack() then black = black + 1 end
    end
    return red, black
end
sgs.ai_fill_skill.hlxg_huaiyi = function(self)
    local red, black = c201_minor_color(self)
    if red == 0 or black == 0 or math.min(red, black) > 2 or #self.enemies == 0 then return end
    return sgs.Card_Parse("#hlxg_huaiyiCard:.:")
end
sgs.ai_skill_use_func["#hlxg_huaiyiCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hlxg_huaiyiCard = 1.5
sgs.ai_skill_choice.hlxg_huaiyi = function(self, choices)
    local red, black = c201_minor_color(self)
    return red <= black and "red" or "black"
end
sgs.ai_fill_skill.hljx_huaiyi = function(self)
    if self.player:isKongcheng() or #self.enemies == 0 then return end
    return sgs.Card_Parse("#hljx_huaiyiCard:.:")
end
sgs.ai_skill_use_func["#hljx_huaiyiCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hljx_huaiyiCard = 1.5
local c201_hj_color = "red"
sgs.ai_skill_choice.hljx_huaiyi = function(self, choices)
    local red, black = c201_minor_color(self)
    if not choices:find("red") then c201_hj_color = "black"
    elseif not choices:find("black") then c201_hj_color = "red"
    else c201_hj_color = red <= black and "red" or "black" end
    return c201_hj_color
end
sgs.ai_skill_discard.hljx_huaiyi = function(self, discard_num, min_num, optional)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    local ids = {}
    for _, c in ipairs(cards) do
        local match = (c201_hj_color == "red" and c:isRed()) or (c201_hj_color == "black" and c:isBlack())
        if match and #ids < math.min(discard_num, #self.enemies) and not c:isKindOf("Peach") then
            table.insert(ids, c:getEffectiveId())
        end
    end
    return ids
end
local function c201_huaiyi_targets(self, targets)
    local chosen = {}
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) then table.insert(chosen, p) end
    end
    return chosen
end
sgs.ai_skill_playerschosen.hlxg_huaiyi = c201_huaiyi_targets

-- 公孙瓒
sgs.ai_skill_invoke.hljx_qiaomeng = function(self, data)
    local d = data:toDamage()
    return d.to and not self:isFriend(d.to)
end

-- 关兴张苞
sgs.ai_fill_skill.hlxg_fuhun = function(self) return turnUse_spear and turnUse_spear(self, "hlxg_fuhun") end
sgs.ai_cardsview.hlxg_fuhun = function(self, class_name, player)
    if class_name == "Slash" and cardsView_spear then return cardsView_spear(self, player, "hlxg_fuhun") end
end

-- 关平
sgs.ai_skill_invoke.hlxg_jiezhong = function(self)
    return self.player:getMaxHp() - self.player:getHandcardNum() >= 2
end
sgs.ai_skill_cardask["@hlxg_longyin"] = function(self, data)
    local use = data:toCardUse()
    if not use.from or not self:isFriend(use.from) or not use.card then return "." end
    if not use.card:isRed() and use.from:getHandcardNum() < 2 then return "." end
    local c = c201_low(self)
    if not c or c:isKindOf("Peach") then return "." end
    return "$" .. c:getEffectiveId()
end

-- 关索
sgs.ai_skill_invoke.hlxg_zhengnan = true
sgs.ai_skill_choice.hlxg_zhengnan = function(self, choices)
    for _, s in ipairs({"hlxg_wusheng_guansuo", "hlxg_dangxian_guansuo", "olzhiman"}) do
        if choices:find(s) then return s end
    end
end
end

-- ==================== c204
do
-- c204 AI: 吕蒙 .. 夏侯渊 (huanle.md L789-957). Conservative, nil-safe.
local function c204_enemy(self, targets)
    local list = sgs.QList2Table(targets)
    self:sort(list, "hp")
    for _, p in ipairs(list) do if self:isEnemy(p) then return p end end
    return nil
end
local function c204_friend(self, targets, noself)
    local list = sgs.QList2Table(targets)
    self:sort(list, "hp")
    for _, p in ipairs(list) do
        if self:isFriend(p) and not (noself and p:objectName() == self.player:objectName()) then return p end
    end
    return nil
end
local function c204_named(self, data)
    local name = data and data:toString() or ""
    if name == "" then return nil end
    return self.room:findPlayerByObjectName(name)
end

-- 克己 (all three) / 博图 / 设变: always worth it.
sgs.ai_skill_invoke.hlxg_keji_lvmeng = true
sgs.ai_skill_invoke.hljx_keji = true
sgs.ai_skill_invoke.hlxg_keji_lvmeng3 = true
sgs.ai_skill_invoke.hljx_botu = true
sgs.ai_skill_invoke.hljx_shebian = true

-- 攻心
local function c204_gongxin_invoke(name)
    return function(self, data)
        local to = self.room:findPlayerByObjectName(self.player:getTag(name .. "_target"):toString())
        return to ~= nil and not self:isFriend(to) and not to:isKongcheng()
    end
end
sgs.ai_skill_invoke.hljx_gongxin = c204_gongxin_invoke("hljx_gongxin")
sgs.ai_skill_invoke.hlxg_gongxin_lvmeng2 = c204_gongxin_invoke("hlxg_gongxin_lvmeng2")
sgs.ai_skill_choice.hljx_gongxin = function() return "obtain" end
sgs.ai_skill_choice.hlxg_gongxin_lvmeng2 = function() return "obtain" end

-- 夺荆 (谋弈)
sgs.ai_fill_skill.hlxg_duojing = function(self)
    if #self.enemies > 0 then return sgs.Card_Parse("#hlxg_duojingCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_duojingCard"] = function(card, use, self)
    self:sort(self.enemies, "hp")
    for _, p in ipairs(self.enemies) do
        if not p:isNude() or self.player:canSlash(p, nil, false) then use.card = card; use.to:append(p); return end
    end
end
sgs.ai_use_priority.hlxg_duojingCard = 4
sgs.ai_skill_choice.hlxg_duojing = function(self, choices)
    if choices:find("xiuyang2") then
        return math.random(1, 2) == 1 and "xiuyang2" or "baiyi2"
    end
    if self.player:isWounded() and math.random(1, 2) == 1 then return "xiuyang" end
    return "baiyi"
end
sgs.ai_skill_invoke.hlxg_duojing_draw = true

-- 挫锐
sgs.ai_skill_playerchosen.hlxg_cuorui = function(self, targets)
    for _, p in sgs.qlist(targets) do
        if self:isFriend(p) and not p:getJudgingArea():isEmpty() then return p end
    end
    return c204_enemy(self, targets)
end
sgs.ai_skill_choice.hlxg_cuorui = function(self, choices)
    if choices:find("hand") then return "hand" end
    return choices:split("+")[1]
end
sgs.ai_skill_playerchosen.hlxg_cuorui_equip = function(self, targets) return c204_enemy(self, targets) or targets:first() end
sgs.ai_skill_playerchosen.hlxg_cuorui_hand = function(self, targets) return c204_enemy(self, targets) or targets:first() end

-- 甘露: keep to the simple draw options.
sgs.ai_skill_choice.hlxg_ganlu = function() return "draw" end
sgs.ai_skill_choice.hljx_ganlu = function() return "draw" end
sgs.ai_skill_choice.hljx_ganlu_more = function() return "cancel" end

-- 补益
sgs.ai_skill_invoke.hlxg_buyi = function(self, data)
    local p = c204_named(self, data); return p ~= nil and self:isFriend(p)
end
sgs.ai_skill_invoke.hljx_buyi = sgs.ai_skill_invoke.hlxg_buyi

-- 怠宴 / 福绵
sgs.ai_skill_playerchosen.hlxg_daiyan = function(self, targets) return c204_friend(self, targets, true) end
sgs.ai_skill_choice.hlxg_fumian = function(self, choices)
    if self.player:getTag("hlxg_fumian_last"):toString() == "draw" then return "target" end
    return "draw"
end
sgs.ai_skill_playerschosen.hlxg_fumian = function(self, targets) return {} end

-- 忠勇
sgs.ai_skill_playerchosen.hlxg_zhongyong = function(self, targets) return c204_friend(self, targets, true) end

-- 良姻
sgs.ai_skill_playerchosen.hlxg_liangyin_draw = function(self, targets) return c204_friend(self, targets) end
sgs.ai_skill_playerchosen.hlxg_liangyin_discard = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) and not p:isNude() then return p end end
    return nil
end

-- 贤淑
sgs.ai_fill_skill.hlxg_xianshu = function(self)
    for _, c in sgs.qlist(self.player:getHandcards()) do
        if c:hasTip("hlxg_konghou") and not c:isKindOf("Peach") then
            return sgs.Card_Parse("#hlxg_xianshuCard:" .. c:getEffectiveId() .. ":")
        end
    end
end
sgs.ai_skill_use_func["#hlxg_xianshuCard"] = function(card, use, self)
    local c = sgs.Sanguosha:getCard(card:getSubcards():first())
    local hp = self.player:getHp()
    if c:isRed() then
        for _, p in ipairs(self.friends_noself) do
            if p:getHp() <= hp and p:isWounded() then use.card = card; use.to:append(p); return end
        end
    else
        for _, p in ipairs(self.enemies) do
            if p:getHp() >= hp then use.card = card; use.to:append(p); return end
        end
    end
end
sgs.ai_use_priority.hlxg_xianshuCard = 3

-- 奋激
local function c204_fenji_invoke(self, data)
    local p = c204_named(self, data)
    return p ~= nil and self:isFriend(p) and self.player:getHp() > 2
end
sgs.ai_skill_invoke.hlxg_fenji = c204_fenji_invoke
sgs.ai_skill_invoke.hljx_fenji = c204_fenji_invoke

-- 清创: only spend 【酒】 when the 创 are nearly used up.
sgs.ai_fill_skill.hljx_qingchuang = function(self)
    if self.player:getMark("@hljx_buqu") < 3 then return end
    for _, c in sgs.qlist(self.player:getHandcards()) do
        if c:isKindOf("Analeptic") then return sgs.Card_Parse("#hljx_qingchuangCard:" .. c:getEffectiveId() .. ":") end
    end
end
sgs.ai_skill_use_func["#hljx_qingchuangCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hljx_qingchuangCard = 1

-- 反间 / 业炎
sgs.ai_skill_playerchosen.hlxg_fanjian = function(self, targets) return c204_enemy(self, targets) end
sgs.ai_skill_playerchosen.hlxg_yeyan_zhouyu2 = function(self, targets) return c204_enemy(self, targets) end
sgs.ai_fill_skill.hljx_fanjian = function(self)
    if #self.enemies > 0 and not self.player:isKongcheng() then return sgs.Card_Parse("#hljx_fanjianCard:.:") end
end
sgs.ai_skill_use_func["#hljx_fanjianCard"] = function(card, use, self)
    self:sort(self.enemies, "hp")
    for _, p in ipairs(self.enemies) do
        if self:damageIsEffective(p) then use.card = card; use.to:append(p); return end
    end
end
sgs.ai_use_priority.hljx_fanjianCard = 6
sgs.ai_skill_choice.hljx_fanjian = function(self, choices)
    local list = choices:split("+"); return list[math.random(1, #list)]
end

-- 琴音
sgs.ai_skill_choice.hlxg_qinyin = function(self, choices)
    local fw, ew = 0, 0
    for _, p in ipairs(self.friends) do if p:isWounded() then fw = fw + 1 end end
    for _, p in ipairs(self.enemies) do if p:isWounded() then ew = ew + 1 end end
    if fw > ew then return "recover" end
    return "draw"
end

-- 诱敌
sgs.ai_skill_playerchosen.hlxg_youdi = function(self, targets)
    local slashes = 0
    for _, c in sgs.qlist(self.player:getHandcards()) do if c:isKindOf("Slash") then slashes = slashes + 1 end end
    if slashes * 2 > self.player:getHandcardNum() then return nil end
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) and not p:isNude() then return p end end
    return nil
end

-- 抗歌 / 节烈
sgs.ai_skill_playerchosen.hlxg_kangge = function(self, targets) return c204_friend(self, targets, true) or targets:first() end
sgs.ai_skill_invoke.hlxg_kangge = function(self, data)
    local p = c204_named(self, data); return p ~= nil and self:isFriend(p)
end
sgs.ai_skill_invoke.hlxg_jielie = function(self, data)
    local d = data:toDamage()
    return d.damage > 1 and self.player:getHp() > 1
end

-- 清俭: give one low card to a friend.
sgs.ai_skill_discard.hljx_qingjian = function(self, discard_num, min_num, optional)
    if #self.friends_noself == 0 then return {} end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    return cards[1] and {cards[1]:getEffectiveId()} or {}
end
sgs.ai_skill_playerchosen.hljx_qingjian = function(self, targets) return c204_friend(self, targets, true) or targets:first() end

-- 樵拾 / 燕语 (夏侯氏 1)
sgs.ai_skill_invoke.hlxg_qiaoshi_xiahoushi = function(self, data)
    local p = c204_named(self, data); return p ~= nil and not self:isEnemy(p)
end
sgs.ai_fill_skill.hlxg_yanyu_xiahoushi = function(self)
    if self:getCardsNum("Slash") < 2 and self.player:getMark("hlxg_yanyu_xiahoushi-Clear") > 0 then return end
    for _, c in sgs.qlist(self.player:getHandcards()) do
        if c:isKindOf("Slash") then return sgs.Card_Parse("#hlxg_yanyu_xiahoushiCard:" .. c:getEffectiveId() .. ":") end
    end
end
sgs.ai_skill_use_func["#hlxg_yanyu_xiahoushiCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hlxg_yanyu_xiahoushiCard = 0.5
sgs.ai_skill_choice.hlxg_yanyu_xiahoushi = function(self, choices)
    if choices:find("give") and #self.friends_noself > 0 then return "give" end
    return "draw"
end
sgs.ai_skill_playerchosen.hlxg_yanyu_xiahoushi = function(self, targets) return c204_friend(self, targets, true) or targets:first() end

-- 樵拾 / 燕语 (夏侯氏 2)
sgs.ai_skill_invoke.hlxg_qiaoshi_xiahoushi2 = function(self, data)
    local d = data:toDamage()
    return d.to ~= nil and self:isFriend(d.to)
end
sgs.ai_skill_discard.hlxg_yanyu_xiahoushi2 = function(self, discard_num, min_num, optional)
    if self.player:getHandcardNum() <= self.player:getHp() + 1 then return {} end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    return {cards[1]:getEffectiveId()}
end
sgs.ai_skill_playerchosen.hlxg_yanyu_xiahoushi2 = function(self, targets) return c204_friend(self, targets) end

-- 神速: option 1 / 2 only with a weak enemy in sight; option 3 whenever it turns the general face up.
local function c204_shensu(opt)
    return function(self, targets)
        local to = c204_enemy(self, targets)
        if not to then return nil end
        if opt == 3 then return (not self.player:faceUp() or to:getHp() <= 1) and to or nil end
        if opt == 2 then return (self.player:getHandcardNum() <= 2 or to:getHp() <= 1) and to or nil end
        return (to:getHp() <= 1 or self.player:getHandcardNum() >= 4) and to or nil
    end
end
for _, base in ipairs({"hlxg_shensu", "hljx_shensu"}) do
    for opt = 1, 3 do sgs.ai_skill_playerchosen[base .. opt] = c204_shensu(opt) end
end
end

-- ==================== c202_01
do
sgs.ai_skill_invoke.hlxg_wusheng_guanyu = true
sgs.ai_skill_playerchosen.hlxg_wuhun = function(self, targets)
    local players = sgs.QList2Table(targets)
    self:sort(players, "hp")
    for _, p in ipairs(players) do if self:isEnemy(p) then return p end end
    return players[1]
end
local function c202_ai_slash(skill, predicate, red)
    sgs.ai_view_as[skill] = function(card, player, place)
        if predicate(card, player, place) then
            local suit = card:getSuitString()
            if red and not card:isRed() then suit = "heart" end
            return ("slash:%s[%s:%s]=%s"):format(skill, suit, card:getNumberString(), card:getEffectiveId())
        end
    end
end
c202_ai_slash("hlxg_wusheng_guanyu", function(c, p, place)
    return p:getMark("hlxg_wusheng_guanyu_id-Clear") == c:getEffectiveId() + 1
        and (place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip)
end, true)
c202_ai_slash("hljx_wusheng", function(c, p, place)
    return c:isRed() and (place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip)
end, false)
c202_ai_slash("hlxg_wushen", function(c, p, place)
    return c:getSuit() == sgs.Card_Heart and place == sgs.Player_PlaceHand
end, false)
end

-- ==================== c202_02
do
sgs.ai_view_as.hlxg_wusheng_guanyu3 = function(card, player, place, class_name)
    if class_name == "Slash" and card:isRed() and not card:hasFlag("using")
        and (place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip) then
        return ("slash:hlxg_wusheng_guanyu3[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId())
    end
end
sgs.ai_fill_skill.hlxg_wusheng_guanyu3 = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByUseValue(cards, true)
    for _, c in ipairs(cards) do
        if c:isRed() and not c:isKindOf("Peach") and not c:isKindOf("Slash") and not c:hasFlag("using")
            and self:getUseValue(c) < (sgs.ai_use_value.Slash or 4.5) then
            return sgs.Card_Parse(("slash:hlxg_wusheng_guanyu3[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(), c:getEffectiveId()))
        end
    end
end
sgs.ai_fill_skill.hlxg_xuehen = function(self)
    if self.player:hasUsed("#hlxg_xuehenCard") or #self.enemies == 0 then return end
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isRed() and not c:isKindOf("Peach") and not self.player:isJilei(c) and self:getKeepValue(c) < 6 then
            return sgs.Card_Parse("#hlxg_xuehenCard:" .. c:getEffectiveId() .. ":")
        end
    end
end
sgs.ai_skill_use_func["#hlxg_xuehenCard"] = function(card, use, self)
    self:sort(self.enemies, "hp")
    for _, p in ipairs(self.enemies) do
        if p:isAlive() and self:damageIsEffective(p, sgs.DamageStruct_Fire, self.player)
            and (not p:isChained() or self:isGoodChainTarget(p, self.player, sgs.DamageStruct_Fire, 1)) then
            use.card = card; if use.to then use.to:append(p) end; return
        end
    end
end
sgs.ai_skill_playerchosen.hlxg_xuehen = function(self, targets)
    local list = sgs.QList2Table(targets); self:sort(list, "hp")
    for _, p in ipairs(list) do if self:isEnemy(p) then return p end end
    return list[1]
end
sgs.ai_use_priority.hlxg_xuehenCard = 3
end

-- ==================== c202_03
do
-- Conservative active use and optional damage costs; locked skills need no AI.
local function hl_c202_damage_cost(self, data, kind)
    local d = data and data:toDamage()
    if not d or not d.to or not self:isEnemy(d.to)
        or not self:damageIsEffective(d.to, d.nature, d.from) then return "." end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isKindOf(kind) and not self.player:isJilei(c) then return "$" .. c:getEffectiveId() end
    end
    return "."
end
sgs.ai_skill_cardask["@hlxg_qiangxi-weapon"] = function(self, data)
    return hl_c202_damage_cost(self, data, "Weapon")
end
sgs.ai_skill_cardask["@hljx_qiangxi-equip"] = function(self, data)
    return hl_c202_damage_cost(self, data, "EquipCard")
end
sgs.ai_fill_skill.hljx_qiangxi = function(self)
    if self.player:getHp() > 1 then return sgs.Card_Parse("#hljx_qiangxiCard:.:") end
end
sgs.ai_skill_use_func["#hljx_qiangxiCard"] = function(card, use, self)
    self:sort(self.enemies, "hp")
    for _, p in ipairs(self.enemies) do
        if p:isAlive() and self.player:inMyAttackRange(p)
            and self.player:getMark("hljx_qiangxi_" .. p:objectName() .. "-PlayClear") == 0
            and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then
            use.card = card
            if use.to then use.to:append(p) end
            return
        end
    end
end
sgs.ai_use_priority.hljx_qiangxiCard = 2.5
sgs.ai_fill_skill.hljx_xuehen = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isRed() and not c:isKindOf("Peach") and not self.player:isJilei(c) then
            return sgs.Card_Parse("#hljx_xuehenCard:" .. c:getEffectiveId() .. ":")
        end
    end
end
sgs.ai_skill_use_func["#hljx_xuehenCard"] = function(card, use, self)
    self:sort(self.enemies, "hp")
    for _, p in ipairs(self.enemies) do
        if p:isAlive() and self:damageIsEffective(p, sgs.DamageStruct_Fire, self.player)
            and self:isGoodChainTarget(p, sgs.DamageStruct_Fire, self.player, 1) then
            use.card = card
            if use.to then use.to:append(p) end
            return
        end
    end
end
sgs.ai_skill_playerchosen.hljx_xuehen = function(self, targets)
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) and self:damageIsEffective(p, sgs.DamageStruct_Fire, self.player) then return p end
    end
    return targets:first()
end
sgs.ai_use_priority.hljx_xuehenCard = 3
end

-- ==================== c202_04
do
sgs.ai_skill_invoke.hlxg_tianming = true
sgs.ai_skill_playerchosen.hlxg_tianming = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
end
sgs.ai_skill_playerchosen.hlxg_mizhao = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return targets:first()
end
sgs.ai_skill_invoke.hljx_rende_red = function(self, data)
    local p = data:toPlayer(); return p and self:isEnemy(p)
end
sgs.ai_skill_invoke.hljx_jijiang_liubei_bonus = function(self, data)
    local p = data:toPlayer(); return p and self:isFriend(p)
end
for _, name in ipairs({"hlxg_rende_liubei", "hljx_rende"}) do
    local skill = name
    sgs.ai_fill_skill[skill] = function(self)
        if self.player:isKongcheng() then return end
        local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
        return sgs.Card_Parse("#" .. skill .. "Card:" .. cards[1]:getEffectiveId() .. ":")
    end
    sgs.ai_skill_use_func["#" .. skill .. "Card"] = function(card, use, self)
        for _, p in ipairs(self.friends_noself) do
            if p:getMark(skill .. "_" .. self.player:objectName() .. "-PlayClear") == 0 then
                use.card = card; use.to:append(p); return
            end
        end
    end
    sgs.ai_use_priority[skill .. "Card"] = 4
    sgs.ai_skill_choice[skill] = function(self, choices)
        local options = choices:split("+")
        if self.player:isWounded() and table.contains(options, "peach") then return "peach" end
        if table.contains(options, "ex_nihilo") then return "ex_nihilo" end
        for _, name in ipairs(options) do
            if name ~= "cancel" then
                local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0); c:setSkillName(skill)
                local use = {isDummy = true, to = sgs.SPlayerList()}; self:useCardByClassName(c, use); c:deleteLater()
                if use.card then return name end
            end
        end
        return "cancel"
    end
    sgs.ai_skill_use["@@" .. skill] = function(self)
        local cn = self.player:getTag(skill .. "_card"):toString()
        if cn == "" then return "." end
        local c = sgs.Sanguosha:cloneCard(cn, sgs.Card_NoSuit, 0); c:setSkillName(skill)
        local use = {isDummy = true, to = sgs.SPlayerList()}; self:useCardByClassName(c, use)
        if not use.card then c:deleteLater(); return "." end
        local targets = {}; for _, p in sgs.qlist(use.to) do table.insert(targets, p:objectName()) end
        local result = c:toString(); c:deleteLater()
        return result .. (#targets > 0 and "->" .. table.concat(targets, "+") or "")
    end
end
sgs.ai_fill_skill.hlxg_mizhao = function(self)
    if self.player:hasUsed("#hlxg_mizhaoCard") or self.player:isKongcheng() then return end
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    return sgs.Card_Parse("#hlxg_mizhaoCard:" .. cards[1]:getEffectiveId() .. ":")
end
sgs.ai_skill_use_func["#hlxg_mizhaoCard"] = function(card, use, self)
    for _, p in ipairs(self.friends_noself) do
        for _, enemy in ipairs(self.enemies) do
            if not enemy:isKongcheng() and p:canSlash(enemy, nil, false) then use.card = card; use.to:append(p); return end
        end
    end
end
sgs.ai_use_priority.hlxg_mizhaoCard = 2
for _, name in ipairs({"hlxg_jijiang_liubei", "hljx_jijiang_liubei"}) do
    local skill = name
    sgs.ai_skill_invoke[skill] = true
    sgs.ai_fill_skill[skill] = function(self)
        if not self.player:hasLordSkill(skill) or not sgs.Slash_IsAvailable(self.player) then return end
        for _, p in ipairs(self.friends_noself) do
            if p:getKingdom() == "shu" and not p:isKongcheng() then return sgs.Card_Parse("#" .. skill .. "Card:.:") end
        end
    end
    sgs.ai_skill_use_func["#" .. skill .. "Card"] = function(card, use, self)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        local dummy = {isDummy = true, to = sgs.SPlayerList()}; self:useCardSlash(slash, dummy); slash:deleteLater()
        if dummy.card and not dummy.to:isEmpty() then
            use.card = card; for _, p in sgs.qlist(dummy.to) do use.to:append(p) end
        end
    end
    sgs.ai_use_priority[skill .. "Card"] = 2.6
    sgs.ai_skill_cardask["@" .. skill] = function(self, data)
        local lord = data:toPlayer()
        if lord and self:isFriend(lord) then return self:getCardId("Slash") or "." end
        return "."
    end
    sgs.ai_cardsview_valuable[skill] = function(self, class_name, player)
        if class_name ~= "Slash" or not player:hasLordSkill(skill) then return end
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if p:getKingdom() == "shu" and self:isFriend(p) and not p:isKongcheng() then return "#" .. skill .. "Card:.:" end
        end
    end
end
sgs.ai_skill_discard.hlxg_tianming = function(self, discard_num, min_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getCards(include_equip and "he" or "h"))
    self:sortByKeepValue(cards)
    local ids = {}
    for _, c in ipairs(cards) do
        if not self.player:isJilei(c) and #ids < discard_num then table.insert(ids, c:getEffectiveId()) end
    end
    return ids
end
end

-- ==================== c202_05
do
sgs.ai_skill_invoke.hlxg_jieying_liubei2 = true
sgs.ai_skill_playerchosen.hlxg_jieying_liubei2 = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) and not p:isChained() then return p end end
    return nil
end
sgs.ai_skill_choice.hlxg_longnu = function(self)
    if self.player:getHp() > 2 then return "fire" end
    return self.player:getMaxHp() > 2 and "thunder" or "fire"
end
sgs.ai_skill_invoke.hlxg_jijiang_liubei3 = function(self) return #self.enemies > 0 end
sgs.ai_skill_playerchosen.hlxg_jijiang_liubei3 = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
    return targets:first()
end
sgs.ai_skill_choice.hlxg_jijiang_liubei3 = function(self, choices, data)
    local to = data and data:toPlayer()
    if to and self:isFriend(to) and to:getHp() <= 1 then return "skip" end
    return "slash"
end
sgs.ai_fill_skill.hlxg_rende_liubei3 = function(self)
    if self.player:getMark("hlxg_rende_disabled-Clear") > 0 then return end
    for _, p in ipairs(self.friends_noself) do
        if p:getMark("hlxg_rende_given_" .. self.player:objectName() .. "-PlayClear") == 0 and not self.player:isNude() then
            return sgs.Card_Parse("#hlxg_rende_liubei3Card:.:")
        end
    end
end
sgs.ai_skill_use_func["#hlxg_rende_liubei3Card"] = function(card, use, self)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    if #cards == 0 then return end
    for _, p in ipairs(self.friends_noself) do
        if p:getMark("hlxg_rende_given_" .. self.player:objectName() .. "-PlayClear") == 0 then
            use.card = sgs.Card_Parse("#hlxg_rende_liubei3Card:" .. cards[1]:getEffectiveId() .. ":")
            if use.to then use.to:append(p) end
            return
        end
    end
end
sgs.ai_use_priority.hlxg_rende_liubei3Card = 2
sgs.ai_cardsview_valuable.hlxg_rende_liubei3 = function(self, class_name, p)
    if p:getMark("hlxg_rende_disabled-Clear") > 0 or p:getMark("hlxg_rende_used-Clear") > 0 then return end
    local names = {Slash = "slash", Jink = "jink", Peach = "peach", Analeptic = "analeptic", Nullification = "nullification"}
    local name = names[class_name]
    if not name or p:getMark("&hlxg_ren") < (class_name == "Nullification" and 3 or 2) then return end
    if class_name == "Peach" and p:getMark("Global_PreventPeach") > 0 then return end
    return "#hlxg_rende_liubei3Card:.:" .. name
end
sgs.ai_skill_choice.hlxg_rende_liubei3 = function(self, choices)
    if self.player:isWounded() and choices:split("+") and string.find("+" .. choices .. "+", "+peach+", 1, true) then return "peach" end
    if string.find("+" .. choices .. "+", "+cancel+", 1, true) then return "cancel" end
    return choices:split("+")[1]
end
sgs.ai_skill_use["@@hlxg_rende_liubei3_imitate"] = function(self)
    local name = self.player:getTag("hlxg_rende_declare"):toString()
    local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
    if not c then return "." end
    c:setSkillName("hlxg_rende_liubei3"); c:deleteLater()
    local use = {isDummy = true, to = sgs.SPlayerList()}
    self:useCardByClassName(c, use)
    if not use.card then return "." end
    local names = {}; for _, p in sgs.qlist(use.to) do table.insert(names, p:objectName()) end
    return c:toString() .. (#names > 0 and "->" .. table.concat(names, "+") or "")
end
sgs.ai_fill_skill.hlxg_zhangwu = function(self)
    if self.player:getMark("@hlxg_zhangwu") > 0 and self.player:getLostHp() >= 2 then return sgs.Card_Parse("#hlxg_zhangwuCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_zhangwuCard"] = function(card, use, self) use.card = card end
sgs.ai_use_priority.hlxg_zhangwuCard = 6
sgs.ai_skill_discard.hlxg_zhangwu = function(self, discard_num, min_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    local ids = {}; for i = 1, math.min(discard_num, #cards) do table.insert(ids, cards[i]:getEffectiveId()) end
    return ids
end
sgs.ai_skill_use["@@hlxg_xiansi"] = function(self)
    self:sort(self.enemies, "defense")
    local targets = {}
    for _, p in ipairs(self.enemies) do
        if self.player:canDiscard(p, "hej") then
            table.insert(targets, p:objectName()); if #targets == 2 then break end
        end
    end
    return #targets > 0 and "#hlxg_xiansiCard:.:->" .. table.concat(targets, "+") or "."
end
sgs.ai_skill_cardchosen.hlxg_xiansi = function(self, who, flags)
    if self:isEnemy(who) then
        for _, c in sgs.qlist(who:getCards("h")) do if self.player:canDiscard(who, c:getEffectiveId()) then return c:getEffectiveId() end end
        for _, c in sgs.qlist(who:getCards("e")) do if self.player:canDiscard(who, c:getEffectiveId()) then return c:getEffectiveId() end end
    end
    return -1
end
end

-- ==================== c202_06
do
-- Conservative decisions; locked skills need no AI hooks.
sgs.ai_fill_skill.hlxg_zhuning = function(self)
    local quota = self.player:getMark("hlxg_zhuning_extra-PlayClear") > 0 and 2 or 1
    if self.player:getMark("hlxg_zhuning_used-PlayClear") >= quota or #self.friends_noself == 0 then return end
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if not c:isKindOf("Peach") and not c:isKindOf("ExNihilo") and self:getKeepValue(c) < 5 then
            return sgs.Card_Parse("#hlxg_zhuningCard:" .. c:getEffectiveId() .. ":")
        end
    end
end
sgs.ai_skill_use_func["#hlxg_zhuningCard"] = function(card, use, self)
    self:sort(self.friends_noself, "handcard")
    for _, p in ipairs(self.friends_noself) do
        if self:canDraw(p) and not self.player:isProhibited(p, card) then use.card = card; use.to:append(p); return end
    end
end
sgs.ai_use_priority.hlxg_zhuningCard = 4
local function c206_damage_use(self, id)
    local original = sgs.Sanguosha:getEngineCard(id)
    if not original then return end
    local c = sgs.Sanguosha:cloneCard(original:objectName(), sgs.Card_NoSuit, 0)
    if not c then return end
    c:setSkillName("hlxg_zhuning"); c:deleteLater()
    return c, self:aiUseCard(c)
end
sgs.ai_skill_askforag.hlxg_zhuning = function(self, ids)
    for _, id in ipairs(ids) do
        local c, use = c206_damage_use(self, id)
        if c and use and use.card then return id end
    end
    return -1
end
sgs.ai_skill_use["@@hlxg_zhuning"] = function(self)
    local id = self.player:getMark("hlxg_zhuning_card") - 1
    if id < 0 then return "." end
    local c, use = c206_damage_use(self, id)
    if not c or not use or not use.card then return "." end
    local targets = {}
    if use.to then for _, p in sgs.qlist(use.to) do table.insert(targets, p:objectName()) end end
    return c:toString() .. (#targets > 0 and "->" .. table.concat(targets, "+") or "")
end
sgs.ai_skill_invoke.hlxg_yinlang = function(self)
    -- Keep the set of legal recipients broad and make enemy targeting restrictive.
    return #self.enemies > 0
end
sgs.ai_skill_choice.hlxg_yinlang = function(self, choices)
    local best, score = nil, -math.huge
    for _, kingdom in ipairs(choices:split("+")) do
        local value = 0
        for _, p in sgs.qlist(self.room:getAlivePlayers()) do
            if p ~= self.player then
                if self:isFriend(p) and p:getKingdom() == kingdom then value = value + 2 end
                if self:isEnemy(p) and p:getKingdom() == kingdom then value = value - 1 end
            end
        end
        if value > score then best, score = kingdom, value end
    end
    return best or choices:split("+")[1]
end
sgs.ai_skill_invoke.hlxg_fangquan = function(self)
    if #self.friends_noself == 0 then return false end
    if sgs.ai_skill_invoke.fangquan then return sgs.ai_skill_invoke.fangquan(self, sgs.QVariant()) end
    return self.player:getHandcardNum() <= 2
end
sgs.ai_skill_playerchosen.hlxg_fangquan = function(self, targets)
    local friends = {}
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then table.insert(friends, p) end end
    self:sort(friends, "handcard", true)
    return friends[1]
end
sgs.ai_skill_cardask["@hlxg_xiangle-discard"] = function(self, data)
    local use = data:toCardUse()
    if not use or not use.card then return "." end
    local worthwhile = false
    for _, p in sgs.qlist(use.to) do
        if p:hasSkill("hlxg_xiangle") and self:isEnemy(p) and self:slashIsEffective(use.card, p) then worthwhile = true end
    end
    if not worthwhile then return "." end
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isKindOf("BasicCard") and not c:isKindOf("Peach") and not self.player:isJilei(c) then return "$" .. c:getEffectiveId() end
    end
    return "."
end
sgs.ai_skill_invoke.hlxg_jijiang_liuchan = function(self)
    for _, p in ipairs(self.friends_noself) do if p:getKingdom() == "shu" then return true end end
    return false
end
sgs.ai_skill_cardask["@hlxg_jijiang_liuchan-slash"] = function(self, data)
    local source = data:toPlayer()
    if not source or not self:isFriend(source) then return "." end
    return self:getCardId("Slash") or "."
end
sgs.ai_fill_skill.hlxg_jijiang_liuchan = function(self)
    if not self.player:hasLordSkill("hlxg_jijiang_liuchan") or not sgs.Slash_IsAvailable(self.player) then return end
    if sgs.ai_skill_invoke.hlxg_jijiang_liuchan(self) then return sgs.Card_Parse("#hlxg_jijiang_liuchanCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_jijiang_liuchanCard"] = function(card, use, self)
    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0); slash:deleteLater()
    local dummy = self:aiUseCard(slash)
    if dummy and dummy.card and dummy.to and not dummy.to:isEmpty() then
        use.card = card
        for _, p in sgs.qlist(dummy.to) do use.to:append(p) end
    end
end
sgs.ai_use_priority.hlxg_jijiang_liuchanCard = sgs.ai_use_priority.Slash or 2.6
sgs.ai_cardsview_valuable.hlxg_jijiang_liuchan = function(self, class_name, player)
    if class_name ~= "Slash" or not player:hasLordSkill("hlxg_jijiang_liuchan") then return end
    for _, p in sgs.qlist(player:getAliveSiblings()) do
        if p:getKingdom() == "shu" and self:isFriend(p, player) then return "#hlxg_jijiang_liuchanCard:.:" end
    end
end
end

-- ==================== c202_07
do
sgs.ai_skill_invoke.hlxg_zishou = function(self)
    return self:getCardsNum("Slash") == 0 or self:isWeak()
end
sgs.ai_skill_invoke.hljx_zishou = sgs.ai_skill_invoke.hlxg_zishou
sgs.ai_skill_invoke.hljx_xiangle = function(self) return not self.player:faceUp() end
sgs.ai_skill_invoke.hljx_fangquan = function(self)
    return #self.friends_noself > 0 and (self:isWeak() or self:getCardsNum("Slash") == 0)
end
sgs.ai_skill_invoke.hljx_jijiang_liuchan = function(self, data)
    local name = data:toString()
    for _, friend in ipairs(self.friends) do if friend:objectName() == name then return true end end
    return false
end
sgs.ai_skill_playerchosen.hljx_fangquan = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) and p:faceUp() then return p end end
    return nil
end
sgs.ai_skill_playerchosen.hljx_sishu = function(self, targets)
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) and p:getMark("&hljx_sishu") == 0 then return p end
    end
    return nil
end
sgs.ai_skill_discard.hljx_xiangle = function(self, discard_num)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    local ids = {}
    for _, card in ipairs(cards) do
        if not self.player:isJilei(card) then table.insert(ids, card:getEffectiveId()) end
        if #ids == discard_num then break end
    end
    return ids
end
sgs.ai_skill_discard.hljx_fangquan = function() return {} end
sgs.ai_skill_cardask["@hljx_xiangle-basic"] = function(self, data)
    local use = data:toCardUse()
    if not use.from or use.to:isEmpty() or not self:isEnemy(use.to:first()) then return "." end
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isKindOf("BasicCard") and not c:isKindOf("Peach") and not self.player:isJilei(c) then return "$" .. c:getEffectiveId() end
    end
    return "."
end
sgs.ai_skill_cardask["@hljx_jijiang_liuchan-slash"] = function(self, data, pattern, target)
    local name = data:toString()
    for _, friend in ipairs(self.friends) do
        if friend:objectName() == name then return self:getCardId("Slash") or "." end
    end
    return "."
end
sgs.ai_fill_skill.hljx_jijiang_liuchan = function(self)
    if not self.player:hasLordSkill("hljx_jijiang_liuchan") or not sgs.Slash_IsAvailable(self.player) then return end
    for _, p in ipairs(self.friends_noself) do
        if p:getKingdom() == "shu" and p:getHandcardNum() > 0 then return sgs.Card_Parse("#hljx_jijiang_liuchanCard:.:") end
    end
end
sgs.ai_skill_use_func["#hljx_jijiang_liuchanCard"] = function(card, use, self)
    local slash = sgs.Sanguosha:cloneCard("slash"); slash:deleteLater()
    local dummy = {isDummy = true, to = sgs.SPlayerList()}
    self:useCardSlash(slash, dummy)
    if dummy.card and not dummy.to:isEmpty() then
        use.card = card
        if use.to then for _, p in sgs.qlist(dummy.to) do use.to:append(p) end end
    end
end
sgs.ai_use_priority.hljx_jijiang_liuchanCard = sgs.ai_use_priority.Slash or 2.6
sgs.ai_cardsview_valuable.hljx_jijiang_liuchan = function(self, class_name, player)
    if class_name ~= "Slash" or not player:hasLordSkill("hljx_jijiang_liuchan") then return end
    for _, p in ipairs(self.friends_noself) do
        if p:getKingdom() == "shu" and p:getHandcardNum() > 0 then return "#hljx_jijiang_liuchanCard:.:" end
    end
end
end

-- ==================== c203_01
do
sgs.ai_fill_skill.hlxg_qinwang = function(self)
    if self.player:hasLordSkill("hlxg_qinwang") then return sgs.Card_Parse("#hlxg_qinwangCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_qinwangCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hlxg_qinwangCard = 6
sgs.ai_skill_invoke.hlxg_qinwang = function(self, data)
    local p = data:toPlayer(); return p and self:isFriend(p)
end
sgs.ai_skill_cardask["@hlxg_qinwang-give"] = function(self, data)
    local p = data:toPlayer()
    if not p or not self:isFriend(p) then return "." end
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isKindOf("BasicCard") and not c:isKindOf("Peach") and self:getKeepValue(c) < 5 then return "$" .. c:getEffectiveId() end
    end
    return "."
end
sgs.ai_fill_skill.hlxg_zhanjue = function(self)
    if self.player:getMark("hlxg_zhanjue_draw-PlayClear") >= 3 then return nil end
    local ids = {}
    for _, c in sgs.qlist(self.player:getHandcards()) do
        if self.player:getMark("hlxg_qinwang_" .. c:getEffectiveId() .. "-Clear") == 0 then
            if c:isKindOf("Peach") or self:getKeepValue(c) > 6 then return nil end
            table.insert(ids, c:getEffectiveId())
        end
    end
    if #ids > 0 and #ids <= 2 then return sgs.Card_Parse("duel:hlxg_zhanjue[to_be_decided:0]=" .. table.concat(ids, "+")) end
end
sgs.ai_skill_invoke.hlxg_zhanjue = function(self, data)
    local d = data:toDamage()
    return d and d.from and self:isEnemy(d.from)
end
sgs.ai_skill_invoke.hlxg_shiyuan = true
sgs.ai_skill_playerchosen.hlxg_dushi = function(self, targets)
    local list = sgs.QList2Table(targets); self:sort(list, "hp")
    for _, p in ipairs(list) do if self:isEnemy(p) and not p:hasSkill("hlxg_dushi") then return p end end
    return list[1]
end
-- Reused jijiu uses the engine's existing AI.
sgs.ai_fill_skill.hlxg_qingnang = function(self)
    for _, p in ipairs(self.friends or {}) do if p:isWounded() then return sgs.Card_Parse("#hlxg_qingnangCard:.:") end end
end
sgs.ai_skill_use_func["#hlxg_qingnangCard"] = function(card, use, self)
    local friends = {}
    for _, p in ipairs(self.friends or {}) do if p:isWounded() then table.insert(friends, p) end end
    self:sort(friends, "hp")
    if friends[1] then use.card = card; if use.to then use.to:append(friends[1]) end end
end
sgs.ai_use_priority.hlxg_qingnangCard = 5
end

-- ==================== c203_02
do
sgs.ai_skill_playerchosen.hljx_jijiu = function(self, targets)
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) then return p end
    end
    return nil
end
sgs.ai_view_as.hljx_jijiu = function(card, player, card_place, class_name)
    if class_name == "Peach" and player:getPhase() == sgs.Player_NotActive
        and player:getMark("Global_PreventPeach") == 0 and card:isRed()
        and card_place ~= sgs.Player_PlaceSpecial then
        return ("peach:hljx_jijiu[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId())
    end
end
sgs.ai_fill_skill.hljx_qingnang = function(self)
    if self.player:hasUsed("#hljx_qingnangCard") then return nil end
    return sgs.Card_Parse("#hljx_qingnangCard:.:")
end
sgs.ai_skill_use_func["#hljx_qingnangCard"] = function(card, use, self)
    local target = self.player
    for _, p in ipairs(self.friends or {}) do
        if p:isAlive() and p:isWounded() then target = p; break end
    end
    use.card = card
    if use.to then use.to:append(target) end
end
sgs.ai_use_priority.hljx_qingnangCard = 4.2
-- 扬威 has no optional decision; both 耀武 variants are compulsory.
end

-- ==================== c203_03
do
sgs.ai_skill_choice.hlxg_bojue = function(self, choices) return "draw" end
sgs.ai_skill_discard.hlxg_bojue = function(self, discard_num, min_num, optional, include_equip)
    return self:askForDiscard("dummy", discard_num, min_num, optional, include_equip)
end
sgs.ai_fill_skill.hlxg_bojue = function(self)
    return sgs.Card_Parse("#hlxg_bojueCard:.:")
end
sgs.ai_skill_use_func["#hlxg_bojueCard"] = function(card, use, self)
    self:sort(self.enemies, "defense")
    for _, p in ipairs(self.enemies) do
        if self.player:canSlash(p, nil, false) and self:slashIsEffective(sgs.Sanguosha:cloneCard("slash"), p) then
            use.card = card; if use.to then use.to:append(p) end; return
        end
    end
end
sgs.ai_use_priority.hlxg_bojueCard = 4
sgs.ai_skill_playerchosen.hlxg_zonggui = function(self, targets)
    local list = sgs.QList2Table(targets); self:sort(list, "defense")
    for _, p in ipairs(list) do if self:isEnemy(p) then return p end end
    return list[1]
end
sgs.ai_skill_invoke.hlxg_canshi_beimihu = function(self, data)
    local use = data:toCardUse()
    return use.from and self:isEnemy(use.from) and use.card and not use.card:isKindOf("Peach") and not use.card:isKindOf("ExNihilo")
end
sgs.ai_skill_playerschosen.hlxg_canshi_beimihu = function(self, targets)
    local result = {}; local use = self.player:getTag("hlxg_canshi_beimihu_use"):toCardUse()
    if not use.card then return result end
    for _, p in sgs.qlist(targets) do
        if use.card:isDamageCard() and self:isEnemy(p) or (use.card:isKindOf("Peach") or use.card:isKindOf("ExNihilo")) and self:isFriend(p) then table.insert(result, p) end
    end
    return result
end
sgs.ai_skill_exchange.hlxg_mingren = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    if cards[1] then return {cards[1]:getEffectiveId()} end
    return {}
end
sgs.ai_fill_skill.hlxg_zhenliang = function(self)
    local pile = self.player:getPile("hlxg_mingren_ren")
    if pile:isEmpty() or self.player:getMark("&hlxg_zhenliang_yin") > 0 then return end
    local color = sgs.Sanguosha:getCard(pile:first()):getColor()
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:getColor() == color and not self.player:isJilei(c) then return sgs.Card_Parse("#hlxg_zhenliangCard:" .. c:getEffectiveId() .. ":") end
    end
end
sgs.ai_skill_use_func["#hlxg_zhenliangCard"] = function(card, use, self)
    self:sort(self.enemies, "hp")
    for _, p in ipairs(self.enemies) do
        if self.player:inMyAttackRange(p) and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then
            use.card = card; if use.to then use.to:append(p) end; return
        end
    end
end
sgs.ai_use_priority.hlxg_zhenliangCard = 5
sgs.ai_skill_playerchosen.hlxg_zhenliang = function(self, targets)
    local list = sgs.QList2Table(targets); self:sort(list, "handcard")
    for _, p in ipairs(list) do if self:isFriend(p) then return p end end
end
end
