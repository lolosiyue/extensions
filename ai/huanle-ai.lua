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

-- ==================== c1a_01
do
-- c1a_01: no AI definitions because all assigned variants are skipped.
end

-- ==================== c1a_02
do
-- c1a_02: all variants are skipped; no AI hooks are registered.
end

-- ==================== c1a_03
do
sgs.ai_fill_skill.hl_qiangxi = function(self)
    if self.player:getHp() > 2 then return sgs.Card_Parse("#hl_qiangxiCard:.:") end
end
sgs.ai_skill_use_func["#hl_qiangxiCard"] = function(card, use, self)
    self:sort(self.enemies, "hp")
    for _, p in ipairs(self.enemies) do
        if p:getMark("hl_qiangxi_" .. self.player:objectName() .. "-PlayClear") == 0
            and self.player:inMyAttackRange(p) and self:damageIsEffective(p) then
            use.card = card; if use.to then use.to:append(p) end; return
        end
    end
end
sgs.ai_use_priority.hl_qiangxiCard = 2.5
sgs.ai_skill_cardask["@hl_qiangxi-equip"] = function(self, data)
    local d = data:toDamage()
    if not d.to or not self:isEnemy(d.to) or not self:damageIsEffective(d.to, d.nature, d.from) then return "." end
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isKindOf("EquipCard") and not self.player:isJilei(c) and self:getKeepValue(c) < 5 then return "$" .. c:getEffectiveId() end
    end
    return "."
end
sgs.ai_skill_invoke.hl_chuanglie = function(self, data)
    local use = data:toCardUse()
    return use.to and not use.to:isEmpty() and self:isFriend(use.to:first())
        and self.player:getHp() > 2 and self:getCardsNum("Jink") > 0
end
sgs.ai_skill_playerchosen.hl_chuanglie = function(self, targets)
    if self.player:getHp() <= 2 then return nil end
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) and self:damageIsEffective(p) then return p end end
end
sgs.ai_skill_discard.hl_kuangji = function(self, maximum, minimum)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    if #cards < 2 then return {} end
    return {cards[1]:getEffectiveId(), cards[2]:getEffectiveId()}
end
sgs.ai_fill_skill.hl_kuangji = function(self)
    if self.player:getMark("hl_kuangji-Clear") > 0 then return end
    for _, c in sgs.qlist(self.player:getCards("he")) do
        if c:isKindOf("Weapon") then
            local slash = sgs.Sanguosha:cloneCard("slash", c:getSuit(), c:getNumber())
            slash:addSubcard(c); slash:setSkillName("hl_kuangji"); return slash
        end
    end
end
sgs.ai_view_as.hl_kuangji = function(card, player, place, class_name)
    if class_name == "Jink" and card:isKindOf("Weapon") and player:getMark("hl_kuangji-Clear") == 0
        and (place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip) then
        return "jink:hl_kuangji[" .. card:getSuitString() .. ":" .. card:getNumberString() .. "]=" .. card:getEffectiveId()
    end
end
sgs.ai_skill_discard.hl_pozhen = function(self, maximum, minimum)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    local ids = {}
    for _, c in ipairs(cards) do
        if #ids >= maximum then break end
        if self:getKeepValue(c) < 4 then table.insert(ids, c:getEffectiveId()) end
    end
    return ids
end
sgs.ai_skill_invoke.hl_tuxi = function(self)
    for _, p in ipairs(self.enemies) do if not p:isKongcheng() then return true end end
    return false
end
sgs.ai_skill_playerchosen.hl_tuxi = function(self, targets)
    local list = sgs.QList2Table(targets); self:sort(list, "handcard")
    for _, p in ipairs(list) do if self:isEnemy(p) then return p end end
end
sgs.ai_skill_playerchosen.hl_biaoxi = function(self, targets)
    local list = sgs.QList2Table(targets); self:sort(list, "handcard")
    for _, p in ipairs(list) do if self:isFriend(p) then return p end end
end
sgs.ai_skill_discard.hl_shijie = function(self, maximum, minimum)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    if #cards > 2 and self.player:getHp() > 2 then return {cards[1]:getEffectiveId()} end
    return {}
end
sgs.ai_skill_invoke.hl_xurui = true
sgs.ai_skill_choice.hl_xurui = function(self, choices, data)
    local use = data:toCardUse()
    if use.card and use.to and not use.to:isEmpty() and self:isEnemy(use.to:first()) and use.card:isDamageCard() then return "damage" end
    return "adjacent"
end
sgs.ai_skill_playerchosen.hl_xurui = function(self, targets)
    local list = sgs.QList2Table(targets)
    if self.hl_xurui_giving then
        self.hl_xurui_giving = nil
        for _, p in ipairs(list) do if self:isFriend(p) then return p end end
    else
        for _, p in ipairs(list) do if self:isEnemy(p) and self:damageIsEffective(p, sgs.DamageStruct_Fire) then return p end end
    end
    return list[1]
end
sgs.ai_skill_discard.hl_xurui = function(self, maximum, minimum)
    for _, p in ipairs(self.friends_noself) do
        if p:isAlive() then
            local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
            if cards[1] then self.hl_xurui_giving = true; return {cards[1]:getEffectiveId()} end
        end
    end
    return {}
end
end

-- ==================== c1a_04
do
sgs.ai_skill_invoke.hl_tieqi = function(self, data)
    local to = data:toPlayer(); return to and self:isEnemy(to)
end
sgs.ai_skill_invoke.hl_dingjun = function(self, data)
    local from = data:toPlayer(); return from and self:isFriend(from)
end
sgs.ai_skill_invoke.hl_lizhan = function(self)
    for _, p in ipairs(self.enemies or {}) do if p:isAlive() and self:damageIsEffective(p) then return true end end
    return false
end
sgs.ai_skill_playerchosen.hl_lizhan = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) and self:damageIsEffective(p) then return p end end
    return targets:first()
end
sgs.ai_skill_choice.hl_lizhan = function(self, choices)
    local list = choices:split("+")
    for _, name in ipairs({"duel", "slash", "fire_attack"}) do for _, choice in ipairs(list) do if choice == name then return choice end end end
    return list[1]
end
sgs.ai_fill_skill.hl_lizhan = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    local ids = {}
    for _, c in ipairs(cards) do
        if c:isKindOf("Slash") and not self.player:isCardLimited(c, sgs.Card_MethodUse) then table.insert(ids, c:getEffectiveId()); if #ids == 2 then break end end
    end
    if #ids == 2 then return sgs.Card_Parse("slash:hl_lizhan[no_suit:0]=" .. table.concat(ids, "+")) end
end
sgs.ai_skill_playerchosen.hl_tiaoxin = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) and not p:isKongcheng() then return p end end
    return nil
end
sgs.ai_skill_cardchosen.hl_tiaoxin = function(self, who, flags)
    if not who or not self:isEnemy(who) then return -1 end
    local cards = sgs.QList2Table(who:getHandcards()); if #cards > 0 then return cards[1]:getEffectiveId() end
    return -1
end
sgs.ai_skill_discard.hl_tiaoxin = function(self, discard_num, min_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getCards(include_equip and "he" or "h")); self:sortByKeepValue(cards)
    local ids = {}; for _, c in ipairs(cards) do if not self.player:isJilei(c) and #ids < min_num then table.insert(ids, c:getEffectiveId()) end end
    return ids
end
sgs.ai_fill_skill.hl_yilve = function(self)
    if self.player:getMark("hl_yilve_used-PlayClear") < 1 + self.player:getMark("hl_yilve_extra-PlayClear") then return sgs.Card_Parse("#hl_yilveCard:.:") end
end
sgs.ai_skill_use_func["#hl_yilveCard"] = function(card, use, self)
    use.card = card
    if not use.to then return end
    use.to:append(self.player)
    local n = 1
    for _, p in ipairs(self.friends_noself or {}) do if n < 5 and p:isAlive() then use.to:append(p); n = n + 1 end end
end
sgs.ai_skill_choice.hl_yilve = function() return "reveal" end
sgs.ai_skill_askforag.hl_yilve = function(self, ids)
    local cards = {}; for _, id in ipairs(ids) do table.insert(cards, sgs.Sanguosha:getCard(id)) end
    self:sortByUseValue(cards); return cards[1] and cards[1]:getEffectiveId() or -1
end
sgs.ai_skill_cardask["@hl_qiezhi-discard"] = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do if not self.player:isJilei(c) and self:getKeepValue(c) < 4 then return "$" .. c:getEffectiveId() end end
    return "."
end
sgs.ai_use_priority.hl_yilveCard = 5
end

-- ==================== c1a_05
do
sgs.ai_skill_invoke.hl_mingtan = true
sgs.ai_skill_playerchosen.hl_mingtan = function(self, targets)
    local list = sgs.QList2Table(targets)
    self:sort(list, "defense")
    for _, p in ipairs(list) do if self:isEnemy(p) then return p end end
    return list[1]
end
sgs.ai_skill_choice.hl_mingtan = function(self, choices, data)
    if choices:find("hl_mingtan_use", 1, true) then
        local p = data:toPlayer()
        return p and self:isEnemy(p) and "hl_mingtan_use" or "hl_mingtan_stop"
    end
    local p = data:toPlayer()
    if choices:find("hl_mingtan_slash", 1, true) and p and self:isEnemy(p) and self:getCardsNum("Slash") > 0 then return "hl_mingtan_slash" end
    return "hl_mingtan_lose"
end
sgs.ai_skill_invoke.hl_andu = function(self, data)
    local p = data:toPlayer()
    return p and self:isEnemy(p)
end
local function hl_c1a05_helpful(card)
    return card and (card:isKindOf("GodSalvation") or card:isKindOf("AmazingGrace") or card:isKindOf("ExNihilo"))
end
local function hl_c1a05_hedou_target(self, targets, use)
    if not use or not use.card then return nil end
    local helpful = hl_c1a05_helpful(use.card)
    for _, p in sgs.qlist(targets) do
        local good = helpful and self:isFriend(p) or (not helpful and self:isEnemy(p))
        local bad = helpful and self:isEnemy(p) or (not helpful and self:isFriend(p))
        if (good and self.player:getMark("hl_hedou_double-Clear") == 0)
            or (bad and self.player:getMark("hl_hedou_gain-Clear") == 0) then return p end
    end
end
sgs.ai_skill_invoke.hl_hedou = function(self, data)
    local use = data:toCardUse()
    return use and use.to and hl_c1a05_hedou_target(self, use.to, use) ~= nil
end
sgs.ai_skill_playerchosen.hl_hedou = function(self, targets)
    local use = self.player:getTag("hl_hedou_use"):toCardUse()
    return hl_c1a05_hedou_target(self, targets, use) or sgs.QList2Table(targets)[1]
end
sgs.ai_skill_choice.hl_hedou = function(self, choices, data)
    local use = data:toCardUse()
    local target = self.player:getTag("hl_hedou_target"):toPlayer()
    local helpful = hl_c1a05_helpful(use.card)
    if choices:find("hl_hedou_double", 1, true) and target
        and ((helpful and self:isFriend(target)) or (not helpful and self:isEnemy(target))) then return "hl_hedou_double" end
    if choices:find("hl_hedou_gain", 1, true) then return "hl_hedou_gain" end
    return "hl_hedou_double"
end
sgs.ai_skill_choice.hl_pozhan = function(self, choices)
    if choices:find("2", 1, true) then return "2" end
    return choices:split("+")[1]
end
sgs.ai_skill_invoke.hl_pozhan = true
sgs.ai_skill_discard.hl_pozhan = function(self, discard_num, min_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    local ids = {}
    for i = 1, math.min(discard_num, #cards) do table.insert(ids, cards[i]:getEffectiveId()) end
    return ids
end
end

-- ==================== c1b_01
do
sgs.ai_skill_choice.hl_qingchan = function(self, choices)
    return "lvbu"
end

sgs.ai_skill_choice.hl_qingzhan = function(self, choices, data)
    local target = data and data:toPlayer()
    if target and self:isEnemy(target) and self:getCardsNum("Slash") > 0 then return "slash" end
    return "losehp"
end

sgs.ai_skill_playerchosen.hl_qingyuan = function(self, targets)
    -- Keep the locked benefit unless an allied damage dealer can use it better.
    local best
    for _, p in sgs.qlist(targets) do
        if self:isFriend(p) and not p:hasSkill("manjuan")
            and p:getHandcardNum() > self.player:getHandcardNum() + 2 then
            if not best or p:getHandcardNum() > best:getHandcardNum() then best = p end
        end
    end
    return best
end

sgs.ai_fill_skill.hl_qingzhan = function(self)
    if self.player:getHp() <= 2 or self:getCardsNum("Slash") == 0 then return end
    if self.player:hasUsed("#hl_qingzhanCard") then return end
    return sgs.Card_Parse("#hl_qingzhanCard:.:")
end

sgs.ai_skill_use_func["#hl_qingzhanCard"] = function(card, use, self)
    self:sort(self.enemies, "hp")
    for _, p in ipairs(self.enemies) do
        -- A rival duel must continue until dying; avoid starting a long exchange.
        local rival = p:getGender() == self.player:getGender()
        if (not rival or p:getHp() <= 1) and self:damageIsEffective(p)
            and p:getHp() < self.player:getHp() then
            use.card = card
            if use.to then use.to:append(p) end
            return
        end
    end
end
sgs.ai_use_priority.hl_qingzhanCard = 2.5
end

-- ==================== c1b_02
do
sgs.ai_skill_invoke.hl_langgu = true
sgs.ai_skill_invoke.hl_langgu_reveal = true
sgs.ai_skill_choice.hl_langgu_count = function(self) return "5" end
sgs.ai_skill_askforag.hl_langgu = function(self, ids)
    if not ids or #ids == 0 then return -1 end
    local current = self.room:getCurrent()
    if not current or not self:isFriend(current) then return -1 end
    local cards = {}
    for _, id in ipairs(ids) do table.insert(cards, sgs.Sanguosha:getCard(id)) end
    self:sortByUseValue(cards, true)
    return cards[#cards]:getEffectiveId()
end
sgs.ai_skill_invoke.hl_jibian = function(self)
    if self.player:getMark("hl_langgu-Clear") > 0 then return true end
    local current = self.room:getCurrent()
    return current and (self:isEnemy(current) or self:needToLoseHp(self.player))
end
sgs.ai_skill_playerchosen.hl_jibian = function(self, targets)
    for _, target in sgs.qlist(targets) do if self:isEnemy(target) then return target end end
    return self.player
end
sgs.ai_skill_playerschosen.hl_quanxue = function(self, targets)
    local chosen = {}
    for _, target in sgs.qlist(targets) do
        if self:isEnemy(target) and #chosen < 2 then table.insert(chosen, target) end
    end
    return chosen
end
sgs.ai_skill_choice.hl_quanxue = function(self)
    if self.player:getHp() <= 2 or self.player:isKongcheng() then return "hl_quanxue_restrict" end
    return "hl_quanxue_losehp"
end
sgs.ai_skill_invoke.hl_dingli = function(self, data)
    local target = data and data:toPlayer()
    return target and (target:getHp() < self.player:getHp() or self.player:isWounded())
end
end

-- ==================== c1b_03
do
-- Conservative decisions for c1b_03.
sgs.ai_view_as.hl_taoxian = function(card, player, place)
    if card:getSuit() == sgs.Card_Heart and not card:isKindOf("Peach") then
        return ("peach:hl_taoxian[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId())
    end
end
sgs.ai_view_as.hl_luoshen = function(card, player, place)
    if card:isBlack() and not card:isKindOf("Jink") then
        return ("jink:hl_luoshen[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId())
    end
end
sgs.ai_skill_invoke.hl_jishi = function(self, data)
    local p = data:toDying().who
    return p and self:isFriend(p)
end
sgs.ai_skill_invoke.hl_luoshen = true
sgs.ai_skill_invoke.hl_shenzhen = function(self)
    for _, p in ipairs(self.friends or {}) do if p:isWounded() then return self.player:getMark("&hl_jishi") > 0 end end
    for _, p in ipairs(self.enemies or {}) do if p:getHp() == 1 then return self.player:getMark("&hl_jishi") > 0 end end
    return false
end
sgs.ai_skill_choice.hl_shenzhen = function(self, choices)
    if choices:find("recover", 1, true) then
        for _, p in ipairs(self.friends or {}) do if p:isWounded() then return "recover" end end
        return "losehp"
    end
    local n = 0
    for _, p in ipairs(self.friends or {}) do if p:isWounded() then n = n + 1 end end
    if n == 0 then n = #(self.enemies or {}) end
    n = math.min(n, self.player:getMark("&hl_jishi"))
    for i = n, 0, -1 do
        for _, choice in ipairs(choices:split("+")) do if choice == tostring(i) then return choice end end
    end
    return "0"
end
sgs.ai_skill_playerschosen.hl_shenzhen = function(self, targets, max_num, min_num)
    local list = sgs.QList2Table(targets); local selected = {}; local heal = false
    for _, p in ipairs(self.friends or {}) do if p:isWounded() then heal = true end end
    table.sort(list, function(a, b)
        local function score(p)
            if heal then return (self:isFriend(p) and p:isWounded()) and 10 + p:getLostHp() or 0 end
            return self:isEnemy(p) and 10 - p:getHp() or 0
        end
        return score(a) > score(b)
    end)
    for _, p in ipairs(list) do if #selected < (max_num or 1) then table.insert(selected, p) end end
    return selected
end
sgs.ai_skill_playerchosen.hl_huimou = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) and not p:faceUp() then return p end end
end
sgs.ai_skill_use["@@hl_tianxiang"] = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    local cost
    for _, card in ipairs(cards) do
        if card:getSuit() == sgs.Card_Heart and not self.player:isJilei(card) and not card:isKindOf("Peach") then cost = card; break end
    end
    if not cost then return "." end
    local enemies = self.enemies or {}; self:sort(enemies, "hp")
    for _, enemy in ipairs(enemies) do
        if enemy:isAlive() then return "#hl_tianxiangCard:" .. cost:getEffectiveId() .. ":->" .. enemy:objectName() end
    end
    return "."
end
sgs.ai_skill_choice.hl_tianxiang = function(self, choices, data)
    local p = data:toPlayer()
    if not p then return "one" end
    local n = math.min(5, p:getLostHp())
    if self:isFriend(p) then return n > 1 and "losthp" or "one" end
    return n < 1 and "losthp" or "one"
end
sgs.ai_fill_skill.hl_xingwu = function(self)
    if self.player:faceUp() and self.player:getHp() > 1 then return end
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if not self.player:isJilei(card) and not card:isKindOf("Peach") then
            return sgs.Card_Parse("#hl_xingwuCard:" .. card:getEffectiveId() .. ":")
        end
    end
end
sgs.ai_skill_use_func["#hl_xingwuCard"] = function(card, use, self)
    for _, p in ipairs(self.enemies or {}) do
        if self.player:canDiscard(p, "e") and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then
            use.card = card; if use.to then use.to:append(p) end; return
        end
    end
end
sgs.ai_skill_cardchosen.hl_xingwu = function(self, who, flags)
    if not who then return -1 end
    local cards = sgs.QList2Table(who:getEquips()); self:sortByKeepValue(cards, true)
    for _, card in ipairs(cards) do if self.player:canDiscard(who, card:getEffectiveId()) then return card:getEffectiveId() end end
    return -1
end
sgs.ai_use_priority.hl_xingwuCard = 3
sgs.ai_skill_playerschosen.hl_jinghong = function(self, targets, max_num)
    local chosen = {}
    for _, p in sgs.qlist(targets) do
        if #chosen < (max_num or 4) and self:isEnemy(p) and not p:isKongcheng() then table.insert(chosen, p) end
    end
    return chosen
end
end

-- ==================== c1b_04
do
sgs.ai_skill_invoke.hl_lunce = function(self, data)
    local target = data and data:toPlayer()
    return not target or self:isFriend(target)
end
sgs.ai_skill_playerchosen.hl_lunce = function(self, targets)
    local friends = {}
    for _, p in sgs.qlist(targets) do
        if self:isFriend(p) then table.insert(friends, p) end
    end
    self:sort(friends, "hp")
    return friends[1] or (not targets:isEmpty() and targets:first() or nil)
end
sgs.ai_skill_choice.hl_lunce = function(self, choices)
    if string.find(choices, "lower", 1, true) then return "lower" end
    return choices:split("+")[1]
end
sgs.ai_skill_discard.hl_lunce = function(self, discard_num, min_num, optional, include_equip)
    return {} -- Zero cards is expressly permitted; keep equipment and valuable cards.
end
end

-- ==================== c1c_01
do
sgs.ai_skill_invoke.hl_moyu = function(self)
    return self.player:isWounded() and self.player:getHandcardNum() <= 2
end
sgs.ai_fill_skill.hl_sanlian = function(self)
    if self.player:getHp() <= 1 or #self.enemies <= #self.friends_noself then return end
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    local groups = {}
    for _, c in ipairs(cards) do
        if not self.player:isJilei(c) and not c:isKindOf("Peach") then
            local t = c:getTypeId(); groups[t] = groups[t] or {}; table.insert(groups[t], c:getEffectiveId())
            if #groups[t] == 3 then return sgs.Card_Parse("#hl_sanlianCard:" .. table.concat(groups[t], "+") .. ":") end
        end
    end
end
sgs.ai_skill_use_func["#hl_sanlianCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hl_sanlianCard = 2
sgs.ai_skill_invoke.hl_zuzhou = function(self, data)
    local p = data:toPlayer(); return p and self:isEnemy(p) and self.player:getHp() > 2 and p:getHandcardNum() > 0
end
sgs.ai_skill_choice.hl_zuzhou = function() return "slash_to_jink" end
sgs.ai_fill_skill.hl_tuantu = function(self)
    local names = {}
    for _, c in sgs.qlist(self.player:getHandcards()) do names[c:objectName()] = true end
    for _, id in sgs.qlist(self.room:getDiscardPile()) do
        if names[sgs.Sanguosha:getCard(id):objectName()] then return sgs.Card_Parse("#hl_tuantuCard:.:") end
    end
end
sgs.ai_skill_use_func["#hl_tuantuCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hl_tuantuCard = 5
sgs.ai_fill_skill.hl_daoyao = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if not self.player:isJilei(c) and not c:isKindOf("Peach") then
            return sgs.Card_Parse("#hl_daoyaoCard:" .. c:getEffectiveId() .. ":")
        end
    end
end
sgs.ai_skill_use_func["#hl_daoyaoCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hl_daoyaoCard = 6
sgs.ai_skill_choice.hl_guanghan = function(self, choices, data)
    if choices:find("discard") then return "discard" end
    return "losehp"
end
sgs.ai_skill_discard.hl_guanghan = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do if not self.player:isJilei(c) then return {c:getEffectiveId()} end end
    return {}
end
end

-- ==================== c1c_02
do
sgs.ai_skill_invoke.hl_shixian = true
sgs.ai_skill_invoke.hl_jingyesi = true
sgs.ai_skill_invoke.hl_xiakexing = function(self, data)
    local d = data:toDamage()
    local c = self:getMaxCard()
    return d.to and self:isEnemy(d.to) and c and c:getNumber() >= 10
end
sgs.ai_skill_cardask["@hl_qiangjinjiu"] = function(self, data)
    local p = self.room:getCurrent()
    if not p or not self:isEnemy(p) or p:isAllNude() then return "." end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if not c:isKindOf("Peach") and not self.player:isJilei(c) and self:getKeepValue(c) < 5 then return "$" .. c:getEffectiveId() end
    end
    return "."
end
sgs.ai_skill_choice.hl_qiangjinjiu = function(self)
    local p = self.room:getCurrent()
    return p and p:getEquips():length() >= 2 and "equipment" or "wine"
end
sgs.ai_skill_cardask["@hl_shanshan"] = function(self)
    return self:getCardId("Jink") or "."
end
sgs.ai_view_as.hl_shanshan = function(card, player, place, class_name)
    if class_name == "Jink" and card:isKindOf("EquipCard") and (place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip) then
        return ("jink:hl_shanshan[%s:%s]=%s"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId())
    end
end
sgs.ai_skill_use["@@hl_jingyesi"] = function(self)
    local id = self.player:getTag("hl_jingyesi_id"):toInt() - 1
    if id < 0 then return "." end
    local c = sgs.Sanguosha:getCard(id)
    if not c or not c:isAvailable(self.player) then return "." end
    local use = {isDummy = true, to = sgs.SPlayerList()}
    self:useCardByClassName(c, use)
    if not use.card then return "." end
    local targets = {}
    for _, p in sgs.qlist(use.to) do table.insert(targets, p:objectName()) end
    return c:toString() .. (#targets > 0 and "->" .. table.concat(targets, "+") or "")
end
end

-- ==================== c1c_03
do
-- c1c_03: no AI registrations because the only assigned variant is skipped.
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

-- ==================== c203_04
do
-- Conservative AI; no hook is needed for locked Yinshi.
sgs.ai_skill_invoke.hlxg_luanfeng = function(self, data)
    local dying = data:toDying()
    return dying.who and self:isFriend(dying.who)
end
sgs.ai_skill_invoke.hlxg_chenghao = true
sgs.ai_skill_invoke.hlxg_huoji_simahui = true
sgs.ai_skill_askforag.hlxg_huoji_simahui = function(self, ids)
    for _, id in ipairs(ids) do if sgs.Sanguosha:getCard(id):getSuit() == self.player:getTag("hlxg_huoji_suit"):toInt() then return id end end
    return -1
end
sgs.ai_skill_askforag.hlxg_chenghao = function(self, ids)
    local cards = {}; for _, id in ipairs(ids) do table.insert(cards, sgs.Sanguosha:getCard(id)) end
    self:sortByUseValue(cards, true)
    return cards[1] and cards[1]:getEffectiveId() or -1
end
sgs.ai_skill_playerchosen.hlxg_chenghao = function(self, targets)
    local friends = {}; for _, p in sgs.qlist(targets) do if self:isFriend(p) then table.insert(friends, p) end end
    self:sort(friends, "handcard")
    return friends[1] or self.player
end
sgs.ai_skill_playerchosen.hlxg_jianjie = function(self, targets)
    local friends = {}; for _, p in sgs.qlist(targets) do if self:isFriend(p) then table.insert(friends, p) end end
    self:sort(friends, "handcard", true)
    return friends[1] or targets:first()
end
sgs.ai_skill_choice.hlxg_jianjie = function(self, choices) return choices:split("+")[1] end
sgs.ai_fill_skill.hlxg_jianjie = function(self)
    if self.player:getMark("hlxg_jianjie_turns") <= 1 or self.player:hasUsed("hlxg_jianjieCard") then return end
    return sgs.Card_Parse("#hlxg_jianjieCard:.:")
end
sgs.ai_skill_use_func["#hlxg_jianjieCard"] = function(card, use, self)
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if self:isEnemy(p) and (p:getMark("&hlxg_jianjie_dragon") > 0 or p:getMark("&hlxg_jianjie_phoenix") > 0) then
            use.card = card; use.to:append(p); use.to:append(self.player); return
        end
    end
end
sgs.ai_use_priority.hlxg_jianjieCard = 8
sgs.ai_fill_skill.hlxg_fuhai = function(self)
    if not self.player:hasUsed("hlxg_fuhaiCard") then return sgs.Card_Parse("#hlxg_fuhaiCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_fuhaiCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hlxg_fuhaiCard = 8
sgs.ai_skill_exchange.hlxg_fuhai = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    return cards[1] and {cards[1]:getEffectiveId()} or {}
end
sgs.ai_skill_choice.hlxg_fuhai = function(self) return "clockwise" end
sgs.ai_skill_choice.hlxg_youlong = function(self, choices)
    local list = choices:split("+")
    for _, name in ipairs(list) do
        if name == "ex_nihilo" or name == "peach" and self.player:isWounded() then return name end
    end
    for _, name in ipairs(list) do if name ~= "cancel" then return name end end
    return list[1]
end
sgs.ai_fill_skill.hlxg_youlong = function(self)
    if self.player:getChangeSkillState("hlxg_youlong") == 2 and self.player:isWounded()
        and self.player:getMark("hlxg_youlong_name_peach") == 0
        and (self.player:getMark("hlxg_youlong_unlimited") > 0 or self.player:getMark("hlxg_youlong_yin-Clear") == 0) then
        for _, c in sgs.qlist(self.player:getCards("he")) do
            if not c:isKindOf("BasicCard") and self.player:canDiscard(self.player, c:getEffectiveId()) then return sgs.Card_Parse("#hlxg_youlongCard:.:") end
        end
    end
    if self.player:getChangeSkillState("hlxg_youlong") <= 1 and self.player:hasEquipArea()
        and self.player:getMark("hlxg_youlong_name_ex_nihilo") == 0
        and (self.player:getMark("hlxg_youlong_unlimited") > 0 or self.player:getMark("hlxg_youlong_yang-Clear") == 0) then
        return sgs.Card_Parse("#hlxg_youlongCard:.:")
    end
end
sgs.ai_skill_use_func["#hlxg_youlongCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hlxg_youlongCard = 7
sgs.ai_skill_use["@@hlxg_youlong_imitate"] = function(self)
    local name = self.player:getTag("hlxg_youlong_declare"):toString()
    local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
    if not card then return "." end
    card:setSkillName("hlxg_youlong"); card:deleteLater()
    local use = self:aiUseCard(card)
    if not use or not use.card then return "." end
    local targets = {}; if use.to then for _, p in sgs.qlist(use.to) do table.insert(targets, p:objectName()) end end
    local ids = "."
    if self.player:getChangeSkillState("hlxg_youlong") == 2 then
        local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
        for _, c in ipairs(cards) do
            if not c:isKindOf("BasicCard") and self.player:canDiscard(self.player, c:getEffectiveId()) then ids = tostring(c:getEffectiveId()); break end
        end
        if ids == "." then return "." end
    end
    return "#hlxg_youlongCard:" .. ids .. ":" .. name .. (#targets > 0 and "->" .. table.concat(targets, "+") or "")
end
for _, pair in ipairs({{"hlxg_huoji_simahui", "fire_attack"}, {"hlxg_lianhuan_simahui", "iron_chain"}}) do
    local skill, target = pair[1], pair[2]
    sgs.ai_fill_skill[skill] = function(self)
        if self.player:getMark(skill .. "-Clear") >= 3 then return end
        local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
        for _, c in ipairs(cards) do
            if (target == "fire_attack" and c:isRed() or target == "iron_chain" and c:getSuit() == sgs.Card_Club)
                and not c:isKindOf("Peach") and self:getKeepValue(c) < 5 then
                return sgs.Card_Parse(target .. ":" .. skill .. "[" .. c:getSuitString() .. ":" .. c:getNumberString() .. "]=" .. c:getEffectiveId())
            end
        end
    end
end
sgs.ai_fill_skill.hlxg_yeyan_simahui = function(self)
    if self.player:getMark("hlxg_yeyan_simahui_used") == 0 and #self.enemies > 0 then return sgs.Card_Parse("#hlxg_yeyan_simahuiCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_yeyan_simahuiCard"] = function(card, use, self)
    self:sort(self.enemies, "hp")
    for _, p in ipairs(self.enemies) do
        if use.to:length() < 3 and self:damageIsEffective(p, sgs.DamageStruct_Fire, self.player) then use.card = card; use.to:append(p) end
    end
end
sgs.ai_skill_choice.hlxg_yeyan_simahui = function() return "three" end
sgs.ai_skill_playerchosen.hlxg_yeyan_simahui = function(self, targets)
    local enemies = {}; for _, p in sgs.qlist(targets) do if self:isEnemy(p) then table.insert(enemies, p) end end
    self:sort(enemies, "hp"); return enemies[1] or targets:first()
end
sgs.ai_use_priority.hlxg_yeyan_simahuiCard = 3
end

-- ==================== c203_05
do
sgs.ai_skill_invoke.hljx_fankui = true
sgs.ai_skill_playerchosen.hljx_fankui = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return targets:first()
end
sgs.ai_skill_cardask["@hljx_guicai"] = function(self, data)
    local judge = data:toJudge()
    if not judge or not self:needRetrial(judge) then return "." end
    local id = self:getRetrialCardId(sgs.QList2Table(self.player:getCards("he")), judge)
    return id and id >= 0 and "$" .. id or "."
end
sgs.ai_skill_cardask["@hlxg_guicai"] = function(self, data)
    local judge = data:toJudge()
    if not judge or not self:needRetrial(judge) then return "." end
    local id = self:getRetrialCardId(sgs.QList2Table(self.player:getHandcards()), judge)
    return id and id >= 0 and "$" .. id or "."
end
sgs.ai_skill_playerchosen.hlxg_fangzhu_simayi = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) and not p:faceUp() then return p end end
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) and p:faceUp() then return p end end
    return nil
end
sgs.ai_skill_invoke.hlxg_jizhi_simayi = true
sgs.ai_skill_invoke.hlxg_lianpo = true
sgs.ai_skill_invoke.hlxg_jilve = function(self) return self.player:getMark("hlxg_jilve-Clear") == 0 end
sgs.ai_skill_invoke.hlxg_jilve_draw = true
sgs.ai_skill_invoke.hlxg_junbing = function(self, data)
    local owner = data:toPlayer()
    return owner and self:isFriend(owner) or false
end
sgs.ai_skill_discard.hlxg_junbing = function(self, n, min, optional, equip)
    if optional then return {} end
    local cards = sgs.QList2Table(self.player:getCards(equip and "he" or "h"))
    self:sortByKeepValue(cards)
    local ids = {}; for i = 1, math.min(n, #cards) do ids[i] = cards[i]:getEffectiveId() end
    return ids
end
sgs.ai_fill_skill.hlxg_jilve = function(self)
    if self.player:getMark("@hlxg_renjie") > 0 and self.player:getMark("hlxg_jilve-Clear") == 0 then
        return sgs.Card_Parse("#hlxg_jilveCard:.:hlxg_wansha_simayi")
    end
end
sgs.ai_skill_use_func["#hlxg_jilveCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hlxg_jilveCard = 5
sgs.ai_fill_skill.hlxg_quji = function(self)
    if self.player:hasUsed("#hlxg_qujiCard") then return end
    local n = self.player:getLostHp() + 1
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    if #cards < n then return end
    local ids = {}; for i = 1, n do ids[i] = cards[i]:getEffectiveId() end
    return sgs.Card_Parse("#hlxg_qujiCard:" .. table.concat(ids, "+") .. ":")
end
sgs.ai_skill_use_func["#hlxg_qujiCard"] = function(card, use, self)
    use.card = card
    if not use.to then return end
    local n = card:subcardsLength()
    for _, p in ipairs(self.friends or {}) do
        if n == 0 then break end
        if p:isWounded() then use.to:append(p); n = n - 1 end
    end
end
sgs.ai_use_priority.hlxg_qujiCard = 4
end

-- ==================== c203_06
do
sgs.ai_fill_skill.hlxg_kanji = function(self)
    local seen = {}
    for _, c in sgs.qlist(self.player:getHandcards()) do
        if seen[c:getSuit()] then return nil end
        seen[c:getSuit()] = true
    end
    return sgs.Card_Parse("#hlxg_kanjiCard:.:")
end
sgs.ai_skill_use_func["#hlxg_kanjiCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hlxg_kanjiCard = 6
sgs.ai_skill_exchange.hlxg_qianzheng = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    if #cards >= 2 and self:getKeepValue(cards[2]) < 5 then return {cards[1]:getEffectiveId(), cards[2]:getEffectiveId()} end
    return {}
end
sgs.ai_skill_invoke.hlxg_qianzheng_obtain = true
sgs.ai_fill_skill.hlxg_tunan = function(self) return sgs.Card_Parse("#hlxg_tunanCard:.:") end
sgs.ai_skill_use_func["#hlxg_tunanCard"] = function(card, use, self)
    local friends = self.friends or {}
    if #friends == 0 then return end
    use.card = card
    if use.to then
        for i = 1, math.min(2, #friends) do use.to:append(friends[i]) end
    end
end
sgs.ai_use_priority.hlxg_tunanCard = 4
local function hl06_ai_card(self, slash)
    local id = self.player:getMark("hlxg_tunan_id") - 1
    if id < 0 then return nil end
    local material = sgs.Sanguosha:getCard(id)
    if not material then return nil end
    local c = sgs.Sanguosha:cloneCard(slash and "slash" or material:objectName(), material:getSuit(), material:getNumber())
    c:addSubcard(id); c:setSkillName("hlxg_tunan")
    if not slash then c:setFlags("hlxg_tunan_distance") end
    return c
end
sgs.ai_skill_choice.hlxg_tunan = function(self, choices)
    if choices:find("use", 1, true) then
        local c = hl06_ai_card(self, false)
        if c then
            local use = self:aiUseCard(c); c:deleteLater()
            if use and use.card then return "use" end
        end
    end
    return choices:find("slash", 1, true) and "slash" or "use"
end
local function hl06_ai_use(self, c)
    if not c then return "." end
    local use = self:aiUseCard(c)
    local result = "."
    if use and use.card then
        local names = {}
        if use.to then for _, p in sgs.qlist(use.to) do names[#names + 1] = p:objectName() end end
        result = c:toString() .. (#names > 0 and "->" .. table.concat(names, "+") or "")
    end
    c:deleteLater(); return result
end
sgs.ai_skill_use["@@#hlxg_tunan_use"] = function(self)
    return hl06_ai_use(self, hl06_ai_card(self, self.player:getMark("hlxg_tunan_slash") > 0))
end
sgs.ai_skill_askforag.hlxg_tunan = function(self, ids) return ids[1] or -1 end
sgs.ai_skill_exchange.hlxg_bijing = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    local ids = {}
    for i = 1, math.min(2, #cards) do ids[#ids + 1] = cards[i]:getEffectiveId() end
    return ids
end
sgs.ai_skill_discard.hlxg_bijing = function(self, max_num, min_num)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    local ids = {}
    for _, c in ipairs(cards) do
        if not self.player:isJilei(c) then ids[#ids + 1] = c:getEffectiveId() end
        if #ids >= min_num then break end
    end
    return ids
end
sgs.ai_skill_use["@@#hlxg_qinguo_use"] = function(self)
    local c = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0); c:setSkillName("hlxg_qinguo")
    return hl06_ai_use(self, c)
end
end

-- ==================== c203_07
do
sgs.ai_skill_invoke.hljx_wuchang = function(self, data)
    local damage = data:toDamage()
    return damage.to and self:isEnemy(damage.to)
end
sgs.ai_skill_choice.hljx_wuchang = function(self, choices)
    local options = choices:split("+")
    for _, friend in ipairs(self.friends or {}) do
        for _, kingdom in ipairs(options) do if kingdom == friend:getKingdom() then return kingdom end end
    end
    return options[1]
end
sgs.ai_fill_skill.hljx_wuchang = function(self)
    return sgs.Card_Parse("#hljx_wuchangCard:.:")
end
sgs.ai_skill_use_func["#hljx_wuchangCard"] = function(card, use, self)
    self:sort(self.friends_noself, "handcard")
    local target = self.friends_noself[1]
    if target then use.card = card; if use.to then use.to:append(target) end end
end
sgs.ai_use_priority.hljx_wuchangCard = 5
sgs.ai_fill_skill.hlxg_shenfen = function(self)
    if self.player:getHp() > 3 and self.player:getMark("@hlxg_shenfen") > 0 then return sgs.Card_Parse("#hlxg_shenfenCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_shenfenCard"] = function(card, use, self)
    if self.player:getHp() <= 3 then return end
    local value = 0
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        local impact = 1 + math.min(4, p:getHandcardNum()) * 0.3 + p:getEquips():length() * 0.5
        if p:getHp() == 1 then impact = impact + 2 end
        if self:isEnemy(p) then value = value + impact elseif self:isFriend(p) then value = value - impact end
    end
    if value > 4 and (self.player:getHp() > 4 or self:getCardsNum("Peach") > 0) then use.card = card end
end
sgs.ai_use_priority.hlxg_shenfenCard = 2
end

-- ==================== c205_01
do
local function low_discard(self, hand)
    local cards = sgs.QList2Table(self.player:getCards(hand and "h" or "he"))
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if not self.player:isJilei(c) and not c:isKindOf("Peach") then return "$" .. c:getEffectiveId() end
    end
    return "."
end
for _, name in ipairs({"hlxg_liuli", "hljx_liuli"}) do
    sgs.ai_skill_playerchosen[name] = function(self, targets)
        for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
        return nil
    end
    sgs.ai_skill_cardask["@" .. name .. "-discard"] = function(self) return low_discard(self, false) end
end
sgs.ai_skill_invoke.hlxg_anxian = function(self, data)
    local p = data:toPlayer(); return p and self:isEnemy(p)
end
sgs.ai_skill_cardask["@hlxg_anxian-discard"] = function(self, data)
    local use = data:toCardUse()
    if use.from and self:isFriend(use.from) and self.player:getHp() > 2 then return "." end
    return low_discard(self, true)
end
sgs.ai_skill_choice.hljx_wanrong = function(self, choices)
    if choices:find("remove") then return "remove" end
    return "use"
end
for _, name in ipairs({"hljx_wanrong", "hlxg_yanxiao"}) do
    sgs.ai_fill_skill[name] = function(self)
        if name == "hljx_wanrong" and self.player:hasUsed("hljx_wanrongCard") then return end
        local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
        for _, c in ipairs(cards) do
            if c:getSuit() == sgs.Card_Diamond and not self.player:isJilei(c) and not c:isKindOf("Peach") then
                return sgs.Card_Parse("#" .. name .. "Card:" .. c:getEffectiveId() .. ":")
            end
        end
    end
end
sgs.ai_skill_use_func["#hljx_wanrongCard"] = function(card, use, self)
    for _, p in ipairs(self.friends) do
        if p:containsTrick("indulgence") then use.card = card; if use.to then use.to:append(p) end; return end
    end
    for _, p in ipairs(self.enemies) do
        if p ~= self.player and not p:containsTrick("indulgence") then
            local trick = sgs.Sanguosha:cloneCard("indulgence")
            local legal = not self.player:isProhibited(p, trick); trick:deleteLater()
            if legal then use.card = card; if use.to then use.to:append(p) end; return end
        end
    end
end
sgs.ai_skill_use_func["#hlxg_yanxiaoCard"] = function(card, use, self)
    for _, p in ipairs(self.friends) do
        if not p:getJudgingArea():isEmpty() then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_use_priority.hljx_wanrongCard = 5
sgs.ai_use_priority.hlxg_yanxiaoCard = 4
end

-- ==================== c205_02
do
sgs.ai_skill_invoke.hlxg_tianyi_taishici = true
sgs.ai_skill_choice.hlxg_tianyi_taishici = function(self, choices)
    if self.player:isWounded() and self:getCardsNum("Slash") > 0 then return "assault" end
    if self:getCardsNum("Slash") > 1 then return "assault" end
    return "reach"
end
sgs.ai_skill_invoke.hljx_tianyi = function(self, data)
    local to = data and data:toPlayer()
    if not to then return true end
    local max = self:getMaxCard()
    return self:isEnemy(to) and max and max:getNumber() >= 10
end
sgs.ai_skill_choice.hljx_tianyi = function(self, choices)
    local available = choices:split("+")
    local preferred = {"draw", "reach", "residue", "recover"}
    if self.player:isWounded() and self:getCardsNum("Slash") > 0 then preferred = {"recover", "draw", "reach", "residue"}
    elseif self:getCardsNum("Slash") > 1 then preferred = {"residue", "reach", "draw", "recover"} end
    for _, choice in ipairs(preferred) do if table.contains(available, choice) then return choice end end
    return available[1]
end
sgs.ai_skill_playerchosen.hljx_tianyi = function(self, targets)
    local enemies = {}
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then table.insert(enemies, p) end end
    self:sort(enemies, "defenseSlash")
    return enemies[1]
end
sgs.ai_skill_invoke.hljx_hanzhan = function(self, data)
    local other = data and data:toPlayer()
    return not other or self:isEnemy(other)
end
sgs.ai_skill_pindian.hljx_tianyi = function(minusecard, self, requestor, maxcard)
    return maxcard or self:getMaxCard()
end
sgs.ai_fill_skill.hlxg_jixu = function(self)
    return sgs.Card_Parse("#hlxg_jixuCard:.:")
end
sgs.ai_skill_use_func["#hlxg_jixuCard"] = function(card, use, self)
    local enemies = {}; for _, p in ipairs(self.enemies or {}) do table.insert(enemies, p) end
    self:sort(enemies, "defenseSlash")
    if #enemies == 0 then return end
    use.card = card
    if use.to then for i = 1, math.min(4, #enemies) do use.to:append(enemies[i]) end end
end
sgs.ai_use_priority.hlxg_jixuCard = 6
sgs.ai_skill_choice.hlxg_jixu = function(self, choices, data)
    local source = data and data:toPlayer()
    if source and self:getKnownCard(source, self.player, "Slash", true) > 0 then return "has" end
    return source and source:getHandcardNum() >= 3 and "has" or "absent"
end
end

-- ==================== c205_03
do
sgs.ai_skill_choice.hlxg_shenzhu = function(self)
    if self:getCardsNum("Slash") > 0 and #self.enemies > 0 then return "extra" end
    return "stop"
end
sgs.ai_skill_choice.hlxg_chongwei = function(self, choices, data)
    local target = data:toPlayer()
    if not target or not self:isEnemy(target) then return "cancel" end
    if choices:find("obtain", 1, true) then return "obtain" end
    if choices:find("damage", 1, true) and self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player) then return "damage" end
    return "cancel"
end
sgs.ai_skill_choice.hlxg_zhiji = function(self)
    return self.player:isWounded() and self.player:getHp() <= 2 and "recover" or "draw"
end
sgs.ai_skill_invoke.hlxg_guanxing_jiangwei = true
local function hl20503_target(self, targets)
    local enemies = {}
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then table.insert(enemies, p) end end
    self:sort(enemies, "handcard")
    return enemies[#enemies]
end
sgs.ai_skill_playerchosen.hlxg_tiaoxin_jiangwei = hl20503_target
sgs.ai_skill_playerchosen.hlxg_tiaoxin_jiangwei2 = hl20503_target
sgs.ai_skill_invoke.hlxg_kunfen_jiangwei2 = function(self)
    return self.player:getHp() > 2 or (self.player:getMark("hlxg_fengliang") == 0 and self.player:getMaxHp() > 1)
end
sgs.ai_skill_use["@@hlxg_kunfen_jiangwei2"] = function(self)
    local card = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_NoSuit, 0)
    card:setSkillName("hlxg_kunfen_jiangwei2")
    local use = {isDummy = true, to = sgs.SPlayerList()}
    self:useTrickCard(card, use)
    local result = "."
    if use.card and use.to and not use.to:isEmpty() then
        local names = {}; for _, p in sgs.qlist(use.to) do table.insert(names, p:objectName()) end
        result = card:toString() .. "->" .. table.concat(names, "+")
    end
    card:deleteLater()
    return result
end
end

-- ==================== c205_04
do
sgs.ai_skill_invoke.hlxg_kunfen_jiangwei3 = function(self) return self.player:getHp() > 2 end
sgs.ai_skill_invoke.hlxg_ranji = function(self) return self.player:getHp() <= 2 and self.player:getHandcardNum() < self.player:getMaxHp() end
sgs.ai_skill_choice.hlxg_ranji = function(self, choices)
    if choices:find("both", 1, true) then return "both" end
    if choices:find("zhaxiang", 1, true) then return "zhaxiang" end
    return "kunfen"
end
sgs.ai_skill_choice.hlxg_zhuri = function(self) return self.player:getHp() > 2 and "losehp" or "lose_skill" end
local function c205_04_pindian_target(self, targets)
    local maximum = self:getMaxCard()
    if not maximum or maximum:getNumber() < 10 then return nil end
    local enemies = {}
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then table.insert(enemies, p) end end
    self:sort(enemies, "handcard")
    return enemies[1]
end
sgs.ai_skill_playerchosen.hlxg_zhuri = c205_04_pindian_target
sgs.ai_skill_playerchosen.hljx_shuomeng = c205_04_pindian_target
sgs.ai_skill_pindian.hlxg_zhuri = function(minusecard, self) return self:getMaxCard() or minusecard end
sgs.ai_skill_pindian.hljx_shuomeng = function(minusecard, self) return self:getMaxCard() or minusecard end
sgs.ai_skill_askforag.hlxg_zhuri = function(self, ids)
    local best, value = -1, -1
    for _, id in ipairs(ids) do
        local c = sgs.Sanguosha:getCard(id)
        local dummy = {isDummy = true, to = sgs.SPlayerList()}
        self:useCardByClassName(c, dummy)
        if dummy.card and self:getUseValue(c) > value then best, value = id, self:getUseValue(c) end
    end
    return best
end
sgs.ai_skill_use["@@#hlxg_zhuri_use"] = function(self)
    local id = self.player:getMark("hlxg_zhuri_card") - 1
    if id < 0 then return "." end
    local original = sgs.Sanguosha:getCard(id)
    local c = sgs.Sanguosha:cloneCard(original:objectName(), original:getSuit(), original:getNumber())
    c:addSubcard(id); c:setSkillName("hlxg_zhuri")
    local dummy = {isDummy = true, to = sgs.SPlayerList()}
    self:useCardByClassName(c, dummy)
    local names = {}
    if dummy.card then for _, p in sgs.qlist(dummy.to) do table.insert(names, p:objectName()) end end
    local answer = dummy.card and c:toString() .. "->" .. table.concat(names, "+") or "."
    c:deleteLater(); return answer
end
sgs.ai_skill_invoke.hlxg_zhengyi = function(self, data)
    local d = data:toDamage()
    return d.to and self:isFriend(d.to) and d.to:objectName() ~= self.player:objectName()
        and self.player:getHp() > d.damage + 1
end
sgs.ai_skill_playerchosen.hlxg_lirang = function(self, targets)
    local friends = {}
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then table.insert(friends, p) end end
    self:sort(friends, "handcard"); return friends[1]
end
sgs.ai_skill_invoke.hlxg_lirang = true
sgs.ai_skill_invoke.hljx_qianya = true
sgs.ai_skill_playerchosen.hljx_qianya = function(self, targets)
    local friends = {}
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then table.insert(friends, p) end end
    self:sort(friends, "handcard"); return friends[1] or targets:first()
end
sgs.ai_skill_discard.hljx_qianya = function(self, discard_num, min_num)
    return {} -- Zero is legal; keep valuable cards while taking the non-equipment card.
end
sgs.ai_skill_discard.hlxg_ranji = function(self, discard_num, min_num)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    local ids = {}
    for i = 1, math.min(discard_num, #cards) do table.insert(ids, cards[i]:getEffectiveId()) end
    return ids
end
end

-- ==================== c205_05
do
sgs.ai_skill_invoke.hlxg_kuizhu = true
sgs.ai_skill_choice.hlxg_kuizhu = "draw"
sgs.ai_skill_use["@@hlxg_kuizhu"] = function(self)
    local names = {}
    local n = self.player:getMark("hlxg_kuizhu_count")
    for _, p in ipairs(self.friends or {}) do
        if #names < n and p:isAlive() then table.insert(names, p:objectName()) end
    end
    if #names == 0 then return "." end
    return "#hlxg_kuizhuCard:.:->" .. table.concat(names, "+")
end
sgs.ai_skill_invoke.hlxg_lijun = function(self, data)
    local p = data:toPlayer(); return p and self:isFriend(p)
end
sgs.ai_skill_playerschosen.hlxg_xingxue = function(self, targets)
    local chosen = {}
    for _, p in sgs.qlist(targets) do
        if #chosen < self.player:getMaxHp() and self:isFriend(p) then table.insert(chosen, p) end
    end
    return chosen
end
sgs.ai_skill_choice.hlxg_xingxue = "top"
sgs.ai_skill_playerchosen.hlxg_xingxue = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
    return targets:first()
end
sgs.ai_skill_discard.hlxg_xingxue = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    return cards[1] and {cards[1]:getEffectiveId()} or {}
end
sgs.ai_fill_skill.hlxg_yanzhu = function(self) return sgs.Card_Parse("#hlxg_yanzhuCard:.:") end
sgs.ai_skill_use_func["#hlxg_yanzhuCard"] = function(card, use, self)
    for _, p in ipairs(self.enemies or {}) do
        if p:isAlive() then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_skill_choice.hlxg_yanzhu = function(self, choices, data)
    local to = data:toPlayer()
    return choices:find("equip", 1, true) and to and to:hasEquip() and "equip" or "discard"
end
sgs.ai_skill_discard.hlxg_yanzhu = function(self, discard_num, min_num)
    return self:askForDiscard("dummy", discard_num, min_num, false, true)
end
sgs.ai_use_priority.hlxg_yanzhuCard = 5
sgs.ai_fill_skill.hlxg_zhaofu = function(self)
    if self.player:hasLordSkill("hlxg_zhaofu") then return sgs.Card_Parse("#hlxg_zhaofuCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_zhaofuCard"] = function(card, use, self)
    local n = 0
    for _, p in ipairs(self.enemies or {}) do
        if p:isAlive() and n < 2 then use.card = card; if use.to then use.to:append(p) end; n = n + 1 end
    end
end
sgs.ai_use_priority.hlxg_zhaofuCard = 6
sgs.ai_skill_playerchosen.hlxg_yinghun_sunjian = function(self, targets)
    local x = self.player:getLostHp()
    for _, p in sgs.qlist(targets) do
        if x <= 1 and self:isFriend(p) or x > 1 and self:isEnemy(p) then return p end
    end
    return nil
end
sgs.ai_skill_discard.hlxg_yinghun_sunjian = function(self, discard_num, min_num)
    return self:askForDiscard("dummy", discard_num, min_num, false, true)
end
end

-- ==================== c205_06
do
sgs.ai_skill_invoke.hljx_wulie = function(self) return self.player:getHp() > 2 end
sgs.ai_skill_choice.hljx_wulie = function(self, choices, data) return data:toInt() == 0 and "more" or "done" end
sgs.ai_skill_playerschosen.hljx_wulie = function(self, targets, max_num, min_num)
    local chosen = {}
    for _, p in sgs.qlist(targets) do
        if self:isFriend(p) and #chosen < max_num then table.insert(chosen, p) end
    end
    return chosen
end
sgs.ai_skill_invoke.hljx_wulie_prevent = true
sgs.ai_skill_playerchosen.hljx_yinghun_sunjian = function(self, targets)
    local x = self.player:getLostHp()
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
    if x > 1 then
        for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    end
end
sgs.ai_skill_choice.hljx_yinghun_sunjian = function(self, choices, data)
    local p = data:toPlayer()
    return p and self:isEnemy(p) and "discard" or "draw"
end
sgs.ai_skill_playerchosen.hlxg_huiling = function(self, targets)
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) and not p:isNude() then return p end
    end
    for _, p in sgs.qlist(targets) do
        if self:isFriend(p) and not p:getJudgingArea():isEmpty() then return p end
    end
end
sgs.ai_skill_invoke.hlxg_taji = true
sgs.ai_skill_playerchosen.hlxg_taji = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return targets:first()
end
sgs.ai_skill_invoke.hlxg_qinghuang = function(self)
    return self.player:getMaxHp() > 3 and self.player:getHandcardNum() > 2
end
sgs.ai_fill_skill.hlxg_chongxu = function(self)
    if self.player:getMark("@hlxg_chongxu") > 0 and self.player:getMark("&hlxg_huiling_ling") >= 4 then
        return sgs.Card_Parse("#hlxg_chongxuCard:.:")
    end
end
sgs.ai_skill_use_func["#hlxg_chongxuCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hlxg_chongxuCard = 8
end

-- ==================== c206_01
do
sgs.ai_skill_invoke.hlxg_xiaoji_sunshangxiang = true
sgs.ai_skill_invoke.hljx_xiaoji = true
sgs.ai_skill_invoke.hlxg_xiaoji_sunshangxiang2 = true
sgs.ai_skill_invoke.hljx_jieyi = function(self, data)
    local p = data:toPlayer(); return p and self:isFriend(p)
end
local function c206_gift_ai(name, male, extra)
    sgs.ai_fill_skill[name] = function(self)
        if self.player:hasUsed("#" .. name .. "Card") or (not extra and not self.player:isWounded()) then return end
        local friend = false
        for _, p in ipairs(self.friends_noself) do
            if (not male or p:isMale()) then friend = true; break end
        end
        if not friend then return end
        local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
        for _, c in ipairs(cards) do
            if not c:isKindOf("Peach") and self:getKeepValue(c) < 6 then
                return sgs.Card_Parse("#" .. name .. "Card:" .. c:getEffectiveId() .. ":")
            end
        end
    end
    sgs.ai_skill_use_func["#" .. name .. "Card"] = function(card, use, self)
        self:sort(self.friends_noself, "handcard")
        for _, p in ipairs(self.friends_noself) do
            if not male or p:isMale() then use.card = card; if use.to then use.to:append(p) end; return end
        end
    end
    sgs.ai_skill_choice[name] = function() return "give" end
    sgs.ai_use_priority[name .. "Card"] = 5
end
c206_gift_ai("hlxg_jieyin_sunshangxiang", true, false)
c206_gift_ai("hljx_jieyi", false, true)
sgs.ai_skill_invoke.hlxg_liangzhu = true
sgs.ai_skill_choice.hlxg_liangzhu = function(self, choices, data)
    local p = data:toPlayer()
    if p and self:isFriend(p) and not p:hasSkill("manjuan") then return "targetdraw" end
    if p and self:isEnemy(p) and choices:find("weapon", 1, true) then return "weapon" end
    return "selfdraw"
end
sgs.ai_fill_skill.hlxg_wujian_sunshangxiang2 = function(self)
    local cards = sgs.QList2Table(self.player:getEquips()); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if self.player:getMark("hlxg_wujian_sunshangxiang2_" .. c:toEquipCard():location() .. "-PlayClear") == 0
            and not self.player:isJilei(c) then
            local slash = sgs.Card_Parse("slash:hlxg_wujian_sunshangxiang2[" .. c:getSuitString() .. ":" .. c:getNumberString() .. "]=" .. c:getEffectiveId())
            if slash and self:aiUseCard(slash).card then return slash end
        end
    end
end
end

-- ==================== c206_02
do
local function hl02_friend(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
end
sgs.ai_skill_playerchosen.hlxg_jieyin_sunshangxiang3 = hl02_friend
sgs.ai_skill_playerchosen.hlxg_xiaoji_sunshangxiang3 = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) and not p:getCards("ej"):isEmpty() then return p end end
end
sgs.ai_skill_choice.hlxg_jieyin_sunshangxiang3 = function(self, choices, data)
    local p = data:toPlayer(); return p and self:isFriend(p) and "equip" or "give"
end
sgs.ai_fill_skill.hlxg_jieyin_sunshangxiang3 = function(self)
    if self.player:hasUsed("#hlxg_jieyin_sunshangxiang3Card") then return end
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    if cards[1] then return sgs.Card_Parse("#hlxg_jieyin_sunshangxiang3Card:" .. cards[1]:getEffectiveId() .. ":") end
end
sgs.ai_skill_use_func["#hlxg_jieyin_sunshangxiang3Card"] = function(card, use, self)
    for _, p in ipairs(self.friends_noself) do
        if p:getMark("&hlxg_jieyin_sunshangxiang3") > 0 then use.card = card; use.to:append(p); return end
    end
end
sgs.ai_fill_skill.hlxg_fanxiang_sunshangxiang3 = function(self)
    if self.player:getMark("@hlxg_fanxiang_sunshangxiang3") > 0 then
        for _, p in ipairs(self.enemies) do
            if p:getMark("&hlxg_jieyin_sunshangxiang3") > 0 and not p:getEquips():isEmpty() then return sgs.Card_Parse("#hlxg_fanxiang_sunshangxiang3Card:.:") end
        end
    end
end
sgs.ai_skill_use_func["#hlxg_fanxiang_sunshangxiang3Card"] = function(card, use, self)
    for _, p in ipairs(self.enemies) do if p:getMark("&hlxg_jieyin_sunshangxiang3") > 0 and not p:getEquips():isEmpty() then use.card = card; use.to:append(p); return end end
end
sgs.ai_fill_skill.hlxg_wujian_sunshangxiang3 = function(self)
    for _, c in sgs.qlist(self.player:getEquips()) do
        local slot = c:getRealCard():toEquipCard():location()
        if self.player:getMark("hlxg_wujian_sunshangxiang3_" .. slot .. "-PlayClear") == 0 and (self:isWeak() or self:getKeepValue(c) < 4) then
            return sgs.Card_Parse("slash:hlxg_wujian_sunshangxiang3[to_be_decided:0]=" .. c:getEffectiveId())
        end
    end
end
for _, name in ipairs({"hlxg_zhiheng", "hljx_zhiheng"}) do
    sgs.ai_fill_skill[name] = function(self)
        if self.player:getMark(name .. "_used-PlayClear") >= 1 + self.player:getMark(name .. "_extra-PlayClear") then return end
        local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
        local ids = {}
        for _, c in ipairs(cards) do if not self.player:isJilei(c) and self:getKeepValue(c) < 4 then table.insert(ids, c:getEffectiveId()) end end
        if #ids > 0 then return sgs.Card_Parse("#" .. name .. "Card:" .. table.concat(ids, "+") .. ":") end
    end
    sgs.ai_skill_use_func["#" .. name .. "Card"] = function(card, use) use.card = card end
    sgs.ai_use_priority[name .. "Card"] = 2.6
end
for _, name in ipairs({"hlxg_jiuyuan", "hljx_jiuyuan"}) do
    sgs.ai_skill_invoke[name] = function(self, data)
        local lord = data:toPlayer(); return lord and self:isFriend(lord) and lord:isWounded() and (not self:isWeak() or lord:getHp() < self.player:getHp())
    end
end
sgs.ai_use_priority.hlxg_jieyin_sunshangxiang3Card = 4
sgs.ai_use_priority.hlxg_fanxiang_sunshangxiang3Card = 5
end

-- ==================== c206_03
do
sgs.ai_skill_invoke.hljx_kuangbi = function(self, data)
    local to = self.room:findPlayerByObjectName(data:toString())
    return to and self:isFriend(to)
end
sgs.ai_fill_skill.hljx_kuangbi = function(self) return sgs.Card_Parse("#hljx_kuangbiCard:.:") end
sgs.ai_skill_use_func["#hljx_kuangbiCard"] = function(card, use, self)
    for _, p in ipairs(self.friends_noself) do
        if not p:isNude() then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_skill_exchange.hljx_kuangbi = function(self, pattern, max_num, min_num, expand_pile)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    local result = {}
    max_num = max_num or 3
    for _, c in ipairs(cards) do
        if #result < max_num and self:getKeepValue(c) < 4 then table.insert(result, c:getEffectiveId()) end
    end
    return result
end
sgs.ai_skill_invoke.hlxg_canshi_sunhao = true
sgs.ai_skill_invoke.hlxg_jiang = true
sgs.ai_skill_playerchosen.hlxg_yinghun_sunce = function(self, targets)
    local list = sgs.QList2Table(targets)
    if self.player:getLostHp() <= 1 then
        for _, p in ipairs(list) do if self:isFriend(p) then return p end end
    else
        self:sort(list, "handcard")
        for _, p in ipairs(list) do if self:isEnemy(p) then return p end end
    end
    return nil
end
sgs.ai_fill_skill["#hlxg_zhiba_give"] = function(self)
    local lord
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if p:hasLordSkill("hlxg_zhiba") and self:isFriend(p) then lord = p; break end
    end
    if not lord then return end
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if (c:isKindOf("Duel") or (c:isKindOf("Slash") and c:isRed())) and self:getKeepValue(c) < 5 then
            return sgs.Card_Parse("#hlxg_zhibaCard:" .. c:getEffectiveId() .. ":")
        end
    end
end
sgs.ai_skill_use_func["#hlxg_zhibaCard"] = function(card, use, self)
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if p:hasLordSkill("hlxg_zhiba") and self:isFriend(p) then
            use.card = card; if use.to then use.to:append(p) end; return
        end
    end
end
sgs.ai_use_priority.hljx_kuangbiCard = 3
sgs.ai_use_priority["hlxg_zhibaCard"] = 2
end

-- ==================== c206_04
do
sgs.ai_skill_invoke.hljx_jiang = true
sgs.ai_skill_invoke.hlxg_youxu = function(self, data)
    local p = data:toPlayer()
    return p and self:isEnemy(p) and #self.friends > 0
end
sgs.ai_skill_playerchosen.hlxg_youxu = function(self, targets)
    local friends = {}
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then table.insert(friends, p) end end
    self:sort(friends, "hp")
    return friends[1] or targets:first()
end
sgs.ai_skill_playerchosen.hljx_yinghun_sunce = function(self, targets)
    local n = self.player:getLostHp()
    for _, p in sgs.qlist(targets) do
        if n <= 1 and self:isFriend(p) then return p end
        if n > 1 and self:isEnemy(p) and not p:isNude() then return p end
    end
    return nil
end
sgs.ai_skill_invoke.hlxg_xiecui = function(self, data)
    local d = data:toDamage()
    return d.from and d.to and self:isFriend(d.from) and self:isEnemy(d.to)
end
sgs.ai_skill_invoke.hlxg_zenhui = function(self, data)
    local use = data:toCardUse()
    return use.to and not use.to:isEmpty() and self:isEnemy(use.to:first())
end
sgs.ai_skill_discard.hlxg_zenhui = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    if cards[1] and (self.player:getHp() <= 2 or self:getKeepValue(cards[1]) < 5) then return {cards[1]:getEffectiveId()} end
    return {}
end
sgs.ai_skill_cardask["@hlxg_jiaojin"] = function(self, data)
    local use = data:toCardUse()
    if not use.from or not self:isEnemy(use.from) then return "." end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if not self.player:isJilei(c) and (self:getKeepValue(c) < 5 or self.player:getHp() <= 1) then return "$" .. c:getEffectiveId() end
    end
    return "."
end
sgs.ai_fill_skill["hljx_zhiba"] = function(self)
    if self.player:getKingdom() ~= "wu" then return end
    local friend = false
    for _, p in sgs.qlist(self.player:getAliveSiblings()) do if p:getMark("hljx_zhiba_recipient") > 0 and p:hasLordSkill("hljx_zhiba") and self:isFriend(p) then friend = true end end
    if not friend then return end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isKindOf("Slash") or c:isKindOf("Duel") then return sgs.Card_Parse("#hljx_zhibaCard:" .. c:getEffectiveId() .. ":") end
    end
end
sgs.ai_skill_use_func["#hljx_zhibaCard"] = function(card, use, self)
    for _, p in sgs.qlist(self.player:getAliveSiblings()) do
        if p:getMark("hljx_zhiba_recipient") > 0 and p:hasLordSkill("hljx_zhiba") and self:isFriend(p) then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_use_priority["hljx_zhibaCard"] = 1
end

-- ==================== c206_05
do
sgs.ai_skill_invoke.hlxg_zaiqi = function(self) return self.player:getLostHp() >= 2 end
sgs.ai_skill_invoke.hljx_zaiqi = function(self)
    return self.player:getPhase() == sgs.Player_Finish or self.player:getLostHp() >= 2
end
sgs.ai_skill_playerchosen.hlxg_mumu = function(self, targets)
    local list = sgs.QList2Table(targets)
    for _, p in ipairs(list) do
        if self:isFriend(p) and self:needToThrowArmor(p) then return p end
    end
    for _, p in ipairs(list) do if self:isEnemy(p) then return p end end
end
sgs.ai_skill_choice.hlxg_mumu = function(self, choices)
    if choices:find("discard") and self:getCardsNum("Slash") > 1 then return "discard" end
    return "obtain"
end
sgs.ai_skill_discard.hlxg_meibu = function(self, discard_num, min_num, optional, include_equip)
    local current = self.room:getCurrent()
    if not current or not self:isEnemy(current) or current:getHandcardNum() < 3 then return {} end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if not c:isKindOf("Peach") and not self.player:isJilei(c) then return {c:getEffectiveId()} end
    end
    return {}
end
end

-- ==================== c206_06
do
sgs.ai_skill_invoke.hlxg_panqin = function(self)
    local card = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
    local good = self:getAoeValue(card) > 0
    card:deleteLater()
    return good
end
sgs.ai_skill_invoke.hlxg_chengshang = true
sgs.ai_skill_invoke.hlxg_qiao = function(self, data)
    local use = data:toCardUse()
    return use.from and self:isEnemy(use.from) and not self.player:isNude()
end
sgs.ai_skill_discard.hlxg_qiao = function(self, discard_num, min_num, optional, include_equip)
    return self:askForDiscard("dummy", discard_num, min_num, optional, include_equip)
end
sgs.ai_skill_cardask["@hlxg_tianxiang"] = function(self, data)
    local damage = data:toDamage()
    if not damage or damage.damage <= 0 then return "." end
    local target
    for _, enemy in ipairs(self.enemies) do
        if self:damageIsEffective(enemy, damage.nature, damage.from) then target = enemy; break end
    end
    if not target then return "." end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if card:getSuit() == sgs.Card_Heart and not self.player:isJilei(card) then return "$" .. card:getEffectiveId() end
    end
    return "."
end
sgs.ai_skill_playerchosen.hlxg_tianxiang = function(self, targets)
    local players = sgs.QList2Table(targets)
    self:sort(players, "hp")
    for _, p in ipairs(players) do if self:isEnemy(p) then return p end end
    return players[1]
end
sgs.ai_fill_skill.hlxg_manwang = function(self)
    if self.player:hasUsed("#hlxg_manwangCard") then return end
    local last = 4 - self.player:getMark("hlxg_manwang_removed")
    if last <= 1 then return end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    local ids = {}
    for _, card in ipairs(cards) do
        if not self.player:isJilei(card) and not self:isCard("Peach", card, self.player)
            and self:getKeepValue(card) < 4 then
            table.insert(ids, card:getEffectiveId())
            if #ids >= math.min(last, self.player:isWounded() and 3 or 2) then break end
        end
    end
    if #ids >= 2 then return sgs.Card_Parse("#hlxg_manwangCard:" .. table.concat(ids, "+") .. ":") end
end
sgs.ai_skill_use_func["#hlxg_manwangCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hlxg_manwangCard = 3
end

-- ==================== c206_07
do
sgs.ai_skill_cardask["@hljx_tianxiang"] = function(self, data)
    local damage = data:toDamage()
    if not damage or damage.damage <= 0 then return "." end
    local target
    for _, enemy in ipairs(self.enemies) do
        if enemy:isAlive() and self:damageIsEffective(enemy, damage.nature, damage.from) then target = enemy; break end
    end
    if not target then return "." end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if card:getSuit() == sgs.Card_Heart and not self.player:isJilei(card) then
            return "$" .. card:getEffectiveId()
        end
    end
    return "."
end
sgs.ai_skill_playerchosen.hljx_tianxiang = function(self, targets)
    local players = sgs.QList2Table(targets)
    self:sort(players, "hp")
    for _, p in ipairs(players) do if self:isEnemy(p) then return p end end
    return players[1]
end
sgs.ai_skill_choice.hljx_tianxiang = function(self, choices, data)
    local target = data:toPlayer()
    if not target then return "one" end
    local n = math.min(5, target:getLostHp())
    if self:isFriend(target) then return n > 1 and "lost" or "one" end
    return n < 1 and "lost" or "one"
end
end

-- ==================== c207_01
do
sgs.ai_skill_invoke.hlxg_yingyu = true
sgs.ai_skill_playerchosen.hlxg_yingyu = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
    return targets:first()
end
sgs.ai_fill_skill.hlxg_yongbi = function(self)
    if self.player:getMark("@hlxg_yongbi") == 0 or #self.friends_noself == 0 then return end
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    local ids, suits = {}, {}
    for _, c in ipairs(cards) do
        if not suits[c:getSuit()] and not c:isKindOf("Peach") then
            suits[c:getSuit()] = true; table.insert(ids, c:getEffectiveId())
        end
    end
    return sgs.Card_Parse("#hlxg_yongbiCard:" .. (#ids > 0 and table.concat(ids, "+") or ".") .. ":")
end
sgs.ai_skill_use_func["#hlxg_yongbiCard"] = function(card, use, self)
    self:sort(self.friends_noself, "handcard")
    for _, p in ipairs(self.friends_noself) do
        if not p:hasSkill("manjuan") then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_use_priority.hlxg_yongbiCard = 3
sgs.ai_skill_invoke.hlxg_xinsheng = true
sgs.ai_skill_askforag.hlxg_xinsheng = function(self, ids)
    local best, value = ids[1], -1000
    for _, id in ipairs(ids) do
        local v = self:getUseValue(sgs.Sanguosha:getCard(id))
        if v > value then best, value = id, v end
    end
    return best
end
sgs.ai_skill_invoke.hlxg_shendao = true
sgs.ai_skill_choice.hlxg_shendao = function(self, choices, data)
    local judge = data:toJudge()
    if judge and judge.card then
        for _, suit in ipairs({sgs.Card_Heart, sgs.Card_Diamond, sgs.Card_Club, sgs.Card_Spade}) do
            local c = sgs.Sanguosha:cloneCard(judge.card:objectName(), suit, judge.card:getNumber())
            local good = judge:isGood(c); local name = c:getSuitString(); c:deleteLater()
            if good then return name end
        end
        return judge.card:getSuitString()
    end
    return "heart"
end
sgs.ai_skill_invoke.hlxg_jianchu = function(self, data)
    local to = data:toPlayer()
    return to and self:isEnemy(to) and to:getCardCount(true) > 0
end
end

-- ==================== c207_02
do
sgs.ai_skill_invoke.hljx_jianchu = function(self, data)
    local p = data:toPlayer()
    return p and self:isEnemy(p)
end
sgs.ai_fill_skill.hlxg_juesi = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isKindOf("Slash") and not self.player:isJilei(c) then
            return sgs.Card_Parse("#hlxg_juesiCard:" .. c:getEffectiveId() .. ":")
        end
    end
end
sgs.ai_skill_use_func["#hlxg_juesiCard"] = function(card, use, self)
    for _, p in ipairs(self.enemies or {}) do
        if not p:isNude() and self.player:inMyAttackRange(p) and self:damageIsEffective(p)
            and self.player:getHandcardNum() > 1 then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_use_priority.hlxg_juesiCard = 3
sgs.ai_skill_discard.hlxg_juesi = function(self, max, min)
    return self:askForDiscard("dummy", max, min, false, true)
end
sgs.ai_fill_skill.hlxg_heqia = function(self)
    if self.player:hasUsed("#hlxg_heqiaCard") then return end
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    if #cards > 2 and #(self.friends_noself or {}) > 0 then
        return sgs.Card_Parse("#hlxg_heqiaCard:" .. cards[1]:getEffectiveId() .. ":")
    end
end
sgs.ai_skill_use_func["#hlxg_heqiaCard"] = function(card, use, self)
    for _, p in ipairs(self.friends_noself or {}) do
        if p:isAlive() then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_use_priority.hlxg_heqiaCard = 2
sgs.ai_skill_discard.hlxg_heqia = function(self, max, min)
    return self:askForDiscard("dummy", min, min, false, false)
end
sgs.ai_skill_choice.hlxg_heqia = function(self, choices)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    self.c207_heqia_plan = nil
    for _, name in ipairs(choices:split("+")) do
        if name ~= "cancel" and cards[1] then
            local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
            if c then
                c:addSubcard(cards[1]); c:setSkillName("hlxg_heqia")
                local use = {isDummy = true, to = sgs.SPlayerList()}
                self:useCardByClassName(c, use)
                if use.card and use.to:length() <= self.player:getMark("hlxg_heqia_count") then
                    local names = {}; for _, p in sgs.qlist(use.to) do table.insert(names, p:objectName()) end
                    self.c207_heqia_plan = "#hlxg_heqia_useCard:" .. cards[1]:getEffectiveId() .. ":" .. name
                        .. (#names > 0 and "->" .. table.concat(names, "+") or "")
                    c:deleteLater(); return name
                end
                c:deleteLater()
            end
        end
    end
    return "cancel"
end
sgs.ai_skill_use["@@hlxg_heqia_use"] = function(self)
    return self.c207_heqia_plan or "."
end
end

-- ==================== c207_03
do
sgs.ai_skill_invoke.hlxg_niepan = true
sgs.ai_skill_invoke.hljx_niepan = true
sgs.ai_skill_invoke.hlxg_songsang = true
sgs.ai_skill_choice.hljx_niepan = function(self, choices)
    return "hljx_bazhen"
end
sgs.ai_skill_playerschosen.hlxg_lianhuan_pangtong = function(self, targets)
    local result = {}
    for _, p in sgs.qlist(targets) do
        if self:isFriend(p) and p:isChained() then table.insert(result, p)
        elseif self:isEnemy(p) and not p:isChained() then table.insert(result, p) end
        if #result == 2 then break end
    end
    return result
end
sgs.ai_skill_use["@@hljx_lianhuan"] = function(self)
    local card = sgs.Sanguosha:cloneCard("iron_chain")
    card:setSkillName("hljx_lianhuan")
    local use = {isDummy = true, to = sgs.SPlayerList()}
    self:useTrickCard(card, use)
    local result = "."
    if use.card and not use.to:isEmpty() then
        local targets = {}
        for _, p in sgs.qlist(use.to) do table.insert(targets, p:objectName()) end
        result = card:toString() .. "->" .. table.concat(targets, "+")
    end
    card:deleteLater()
    return result
end
sgs.ai_fill_skill.hljx_huoji = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByUseValue(cards, true)
    for _, c in ipairs(cards) do
        if c:isRed() and not c:isKindOf("Peach") and self:getUseValue(c) < sgs.ai_use_value.FireAttack then
            return sgs.Card_Parse(("fire_attack:hljx_huoji[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(), c:getEffectiveId()))
        end
    end
end
sgs.ai_skill_invoke.hljx_huoji = true
sgs.ai_skill_askforag.hljx_huoji = function(self, ids)
    local suit = self.player:getTag("hljx_huoji_suit"):toInt()
    for _, id in ipairs(ids) do if sgs.Sanguosha:getCard(id):getSuit() == suit then return id end end
    return -1
end
sgs.ai_view_as.hljx_kanpo = function(card, player, place)
    if card and place == sgs.Player_PlaceHand and card:isBlack() then
        return ("nullification:hljx_kanpo[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId())
    end
end
sgs.ai_fill_skill.hlxg_guolun = function(self)
    if not self.player:hasUsed("#hlxg_guolunCard") then return sgs.Card_Parse("#hlxg_guolunCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_guolunCard"] = function(card, use, self)
    local targets = {}
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do if not p:isKongcheng() then table.insert(targets, p) end end
    self:sort(targets, "handcard")
    if targets[1] then use.card = card; if use.to then use.to:append(targets[1]) end end
end
sgs.ai_skill_cardask["@hlxg_guolun"] = function(self, data)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    if cards[1] then return "$" .. cards[1]:getEffectiveId() end
    return "."
end
sgs.ai_skill_cardask["@hljx_huoji-discard"] = sgs.ai_skill_cardask["@fire-attack"]
sgs.ai_use_priority.hlxg_guolunCard = 3
end

-- ==================== c207_04
do
sgs.ai_skill_invoke.hljx_fuli = true
sgs.ai_skill_invoke.hlxg_shezang = true
sgs.ai_skill_invoke.hlxg_tongli = function(self, data)
    local use = data:toCardUse()
    if not use.card then return false end
    if use.card:isKindOf("Peach") or use.card:isKindOf("ExNihilo") then return true end
    if use.card:isKindOf("Slash") or use.card:isKindOf("Duel") or use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement") then
        if use.to:isEmpty() then return false end
        for _, p in sgs.qlist(use.to) do if not self:isEnemy(p) then return false end end
        return true
    end
    return false
end
local function c207_04_ag(self, ids)
    local cards = {}
    for _, id in ipairs(ids) do cards[#cards + 1] = sgs.Sanguosha:getCard(id) end
    if #cards == 0 then return -1 end
    cards = self:sortByUseValue(cards)
    return cards[1]:getEffectiveId()
end
sgs.ai_skill_askforag.hlxg_dangxian_liaohua = c207_04_ag
sgs.ai_skill_askforag.hljx_dangxian = c207_04_ag
sgs.ai_skill_askforag.hlxg_shezang = c207_04_ag
end

-- ==================== c207_05
do
sgs.ai_fill_skill.hlxg_difa = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isRed() and self:getKeepValue(c) < 5 then
            return sgs.Card_Parse("#hlxg_difaCard:" .. c:getEffectiveId() .. ":")
        end
    end
end
sgs.ai_skill_use_func["#hlxg_difaCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hlxg_difaCard = 3
sgs.ai_skill_choice.hlxg_difa = function(self, choices)
    for _, name in ipairs({"ex_nihilo", "god_salvation", "amazing_grace"}) do
        if table.contains(choices:split("+"), name) then return name end
    end
    return choices:split("+")[1]
end
sgs.ai_skill_use["@@hlxg_difa_use!"] = function(self)
    local c = sgs.Sanguosha:cloneCard(self.player:getTag("hlxg_difa_trick"):toString())
    if not c then return "." end
    c:setSkillName("hlxg_difa")
    local use = {isDummy = true, to = sgs.SPlayerList()}
    self:useTrickCard(c, use)
    if use.card then
        local names = {}; for _, p in sgs.qlist(use.to) do table.insert(names, p:objectName()) end
        return c:toString() .. (#names > 0 and "->" .. table.concat(names, "+") or "")
    end
    return "."
end
sgs.ai_skill_cardask["@hlxg_tianze"] = function(self, data)
    local target = data:toCardUse().from
    if not target or not self:isEnemy(target) or not self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player) then return "." end
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isBlack() and not self.player:isJilei(c) then return "$" .. c:getEffectiveId() end
    end
    return "."
end
sgs.ai_fill_skill.hlxg_zhoufu = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    for _, enemy in ipairs(self.enemies) do
        if not enemy:getPile("hlxg_zhoufu"):isEmpty() then return sgs.Card_Parse("#hlxg_zhoufuCard:.:") end
    end
    if cards[1] then return sgs.Card_Parse("#hlxg_zhoufuCard:" .. cards[1]:getEffectiveId() .. ":") end
end
sgs.ai_skill_use_func["#hlxg_zhoufuCard"] = function(card, use, self)
    for _, enemy in ipairs(self.enemies) do
        if (card:subcardsLength() == 0) == (not enemy:getPile("hlxg_zhoufu"):isEmpty()) then
            use.card = card; if use.to then use.to:append(enemy) end; return
        end
    end
end
sgs.ai_use_priority.hlxg_zhoufuCard = 2
sgs.ai_fill_skill.hlxg_wurong = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isKindOf("Slash") then return sgs.Card_Parse("#hlxg_wurongCard:" .. c:getEffectiveId() .. ":") end
    end
end
sgs.ai_skill_use_func["#hlxg_wurongCard"] = function(card, use, self)
    for _, enemy in ipairs(self.enemies) do
        if not enemy:isKongcheng() and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
            use.card = card; if use.to then use.to:append(enemy) end; return
        end
    end
end
sgs.ai_skill_discard.hlxg_wurong = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do if c:isKindOf("Jink") then return {c:getEffectiveId()} end end
    return cards[1] and {cards[1]:getEffectiveId()} or {}
end
sgs.ai_use_priority.hlxg_wurongCard = 4
end

-- ==================== c207_06
do
sgs.ai_skill_invoke.hlxg_zhenxing = true
sgs.ai_skill_invoke.hlxg_shengshen = true
sgs.ai_skill_invoke.hlxg_shenxian = true
sgs.ai_skill_choice.hlxg_zhenxing = function() return "1" end
sgs.ai_skill_choice.hlxg_qianxin = function(self, choices, data)
    local source = data:toPlayer()
    return source and self:isFriend(source) and "draw" or "maxcards"
end
local function c207_06_ag(self, ids)
    local best, value = ids[1], -10000
    for _, id in ipairs(ids) do
        local v = self:getUseValue(sgs.Sanguosha:getCard(id))
        if v > value then best, value = id, v end
    end
    return best or -1
end
sgs.ai_skill_askforag.hlxg_zhenxing = c207_06_ag
sgs.ai_skill_askforag.hlxg_yanjiao = c207_06_ag
sgs.ai_fill_skill.hlxg_qianxin = function(self)
    if self.player:isKongcheng() then return end
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    if cards[1] then return sgs.Card_Parse("#hlxg_qianxinCard:" .. cards[1]:getEffectiveId() .. ":") end
end
sgs.ai_skill_use_func["#hlxg_qianxinCard"] = function(card, use, self)
    use.card = card
    if use.to then use.to:append(self.player) end
end
sgs.ai_use_priority.hlxg_qianxinCard = 2
sgs.ai_fill_skill.hlxg_yanjiao = function(self) return sgs.Card_Parse("#hlxg_yanjiaoCard:.:") end
sgs.ai_skill_use_func["#hlxg_yanjiaoCard"] = function(card, use, self)
    self:sort(self.friends_noself, "handcard")
    for _, p in ipairs(self.friends_noself) do
        if not p:hasSkill("manjuan") then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_use_priority.hlxg_yanjiaoCard = 6
sgs.ai_fill_skill.hlxg_qiangwu = function(self) return sgs.Card_Parse("#hlxg_qiangwuCard:.:") end
sgs.ai_skill_use_func["#hlxg_qiangwuCard"] = function(card, use, self) use.card = card end
sgs.ai_use_priority.hlxg_qiangwuCard = 8
end

-- ==================== c207_07
do
sgs.ai_skill_invoke.hljx_jueqing = function(self, data)
    local damage = data:toDamage()
    return damage.to and self:isEnemy(damage.to)
end
sgs.ai_skill_choice.hljx_jueqing = function(self) return "losehp" end
sgs.ai_skill_discard.hljx_shangshi = function(self) return {} end
sgs.ai_skill_invoke.hlxg_guzheng = function(self, data)
    local target = data:toPlayer()
    return target and self:isFriend(target)
end
sgs.ai_skill_choice.hlxg_guzheng = function(self) return "obtain" end
sgs.ai_skill_askforag.hlxg_guzheng = function(self, ids) return ids[1] or -1 end
sgs.ai_fill_skill.hlxg_zhijian = function(self)
    for _, card in sgs.qlist(self.player:getHandcards()) do
        if card:isKindOf("EquipCard") then
            local equip = card:getRealCard():toEquipCard()
            for _, friend in ipairs(self.friends_noself or {}) do
                if friend:hasEquipArea(equip:location()) and not friend:getEquip(equip:location()) then
                    return sgs.Card_Parse("#hlxg_zhijianCard:" .. card:getEffectiveId() .. ":")
                end
            end
        end
    end
end
sgs.ai_skill_use_func["#hlxg_zhijianCard"] = function(card, use, self)
    local material = sgs.Sanguosha:getCard(card:getSubcards():first())
    local equip = material:getRealCard():toEquipCard()
    for _, friend in ipairs(self.friends_noself or {}) do
        if friend:hasEquipArea(equip:location()) and not friend:getEquip(equip:location()) then
            use.card = card
            if use.to then use.to:append(friend) end
            return
        end
    end
end
sgs.ai_use_priority.hlxg_zhijianCard = 4
end

-- ==================== c207_08
do
sgs.ai_skill_invoke.hlxg_fangtong = true
sgs.ai_skill_askforag.hlxg_fangtong = function(self, ids)
    local n = self.player:getPile("hlxg_fang"):length() - #ids
    local desired = self.player:isWounded() and 2 or 1
    if #self.enemies > 0 and self.player:getPile("hlxg_fang"):length() >= 3 then desired = 3 end
    if n >= desired then return -1 end
    return ids[1] or -1
end
sgs.ai_skill_playerchosen.hlxg_fangtong = function(self, targets)
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) and self:damageIsEffective(p, sgs.DamageStruct_Thunder, self.player) then return p end
    end
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return targets:first()
end
sgs.ai_skill_invoke.hlxg_guangshi = function(self)
    return self.player:getHp() > 1 or self:getCardsNum("Peach") > 0
end
sgs.ai_skill_invoke.hlxg_rihui = function(self, data)
    local use = data:toCardUse()
    if not use.card or use.to:isEmpty() then return false end
    local target = use.to:first()
    if target:getMark("&hlxg_xinzhong") > 0 then
        return self:isEnemy(target) and not target:getCards("hej"):isEmpty()
            or self:isFriend(target) and not target:getJudgingArea():isEmpty()
    end
    if use.card:isDamageCard() then return self:isEnemy(target) end
    if use.card:isKindOf("Peach") then return self:isFriend(target) and target:isWounded() end
    if use.card:isKindOf("ExNihilo") then return self:isFriend(target) end
    return false
end
sgs.ai_skill_choice.hlxg_jizhong = function(self, choices, data)
    local owner = data:toPlayer()
    if owner and self:isFriend(owner) and self.player:getCards("hej"):length() < 3 then return "hlxg_give" end
    return "hlxg_follower"
end
sgs.ai_fill_skill.hlxg_jizhong = function(self)
    if self.player:hasUsed("#hlxg_jizhongCard") then return end
    return sgs.Card_Parse("#hlxg_jizhongCard:.:")
end
sgs.ai_skill_use_func["#hlxg_jizhongCard"] = function(card, use, self)
    self:sort(self.enemies, "handcard")
    for _, p in ipairs(self.enemies) do
        if p:getMark("&hlxg_xinzhong") > 0 then use.card = card; use.to:append(p); return end
    end
    self:sort(self.friends_noself, "handcard")
    for _, p in ipairs(self.friends_noself) do
        if p:getMark("&hlxg_xinzhong") == 0 and not p:hasSkill("manjuan") then use.card = card; use.to:append(p); return end
    end
end
sgs.ai_use_priority.hlxg_jizhongCard = 4
end

-- ==================== c208_01
do
sgs.ai_skill_invoke.hlxg_sibian = true
sgs.ai_skill_invoke.hlxg_songshu = function(self, data)
    local target = data:toPlayer()
    return target and self:isFriend(target)
end
sgs.ai_skill_choice.hlxg_lveming = function(self, choices)
    local options = choices:split("+")
    return options[math.random(#options)]
end
sgs.ai_skill_playerchosen.hlxg_sibian = function(self, targets)
    local friends = {}
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then friends[#friends + 1] = p end end
    self:sort(friends, "handcard")
    return friends[1]
end
sgs.ai_skill_playerchosen.hlxg_leiji = function(self, targets)
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) and self:damageIsEffective(p, sgs.DamageStruct_Thunder, self.player) then return p end
    end
end
sgs.ai_fill_skill.hlxg_lveming = function(self) return sgs.Card_Parse("#hlxg_lvemingCard:.:") end
sgs.ai_skill_use_func["#hlxg_lvemingCard"] = function(card, use, self)
    self:sort(self.enemies, "hp")
    for _, p in ipairs(self.enemies) do
        if p:getEquips():length() <= self.player:getEquips():length() then
            use.card = card; if use.to then use.to:append(p) end; return
        end
    end
end
sgs.ai_fill_skill.hlxg_tunjun = function(self)
    if self.player:getMark("@hlxg_tunjun") > 0 and self.player:getMark("hlxg_lveming_count") >= 2 then return sgs.Card_Parse("#hlxg_tunjunCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_tunjunCard"] = function(card, use, self)
    local friends = {}
    for _, p in ipairs(self.friends) do friends[#friends + 1] = p end
    table.sort(friends, function(a, b) return a:getEquips():length() < b:getEquips():length() end)
    if friends[1] then use.card = card; if use.to then use.to:append(friends[1]) end end
end
sgs.ai_fill_skill.hlxg_songshu = function(self)
    if self.player:getMark("hlxg_songshu-PlayClear") == 0 and self.player:canPindian() then return sgs.Card_Parse("#hlxg_songshuCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_songshuCard"] = function(card, use, self)
    local highest = self:getMaxCard()
    if not highest or highest:getNumber() < 10 then return end
    for _, p in ipairs(self.enemies) do
        if self.player:canPindian(p) then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_skill_pindian.hlxg_songshu = function(minusecard, self, requestor, maxcard) return maxcard or minusecard end
sgs.ai_fill_skill.hlxg_huangtian_give = function(self)
    if self.player:getKingdom() ~= "qun" then return end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isKindOf("Lightning") or (c:isKindOf("Jink") and self:getCardsNum("Jink") > 1) then
            return sgs.Card_Parse("#hlxg_huangtian_giveCard:" .. c:getEffectiveId() .. ":")
        end
    end
end
sgs.ai_skill_use_func["#hlxg_huangtian_giveCard"] = function(card, use, self)
    for _, p in ipairs(self.friends_noself) do
        if p:hasLordSkill("hlxg_huangtian") then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_use_priority.hlxg_lvemingCard = 5
sgs.ai_use_priority.hlxg_tunjunCard = 4
sgs.ai_use_priority.hlxg_songshuCard = 3
sgs.ai_use_priority.hlxg_huangtian_giveCard = 2
end

-- ==================== c208_02
do
sgs.ai_skill_playerchosen.hljx_leiji = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
end
sgs.ai_skill_cardask["@hljx_guidao"] = function(self, data)
    local judge = data:toJudge()
    if not judge or not self:needRetrial(judge) then return "." end
    local cards = {}
    for _, c in sgs.qlist(self.player:getCards("he")) do if c:isBlack() then table.insert(cards, c) end end
    local id = self:getRetrialCardId(cards, judge)
    return id and id >= 0 and ("$" .. id) or "."
end
sgs.ai_skill_playerchosen.hlxg_duorui = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) and not p:isKongcheng() then return p end end
end
sgs.ai_fill_skill.hljx_huangtian_give = function(self)
    if self.player:getKingdom() ~= "qun" then return end
    local friend
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if p:hasLordSkill("hljx_huangtian") and self:isFriend(p) then friend = p; break end
    end
    if not friend then return end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isKindOf("Lightning") or c:getSuit() == sgs.Card_Spade and self:getKeepValue(c) < 4 or c:isKindOf("Jink") and self:getCardsNum("Jink") > 1 then
            return sgs.Card_Parse("#hljx_huangtian_giveCard:" .. c:getEffectiveId() .. ":")
        end
    end
end
sgs.ai_skill_use_func["#hljx_huangtian_giveCard"] = function(card, use, self)
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if p:hasLordSkill("hljx_huangtian") and self:isFriend(p) then
            use.card = card; if use.to then use.to:append(p) end; return
        end
    end
end
sgs.ai_use_priority.hljx_huangtian_giveCard = 2
end

-- ==================== c208_03
do
sgs.ai_fill_skill.hlxg_mubing = function(self)
    if not self.player:hasUsed("#hlxg_mubingCard") then return sgs.Card_Parse("#hlxg_mubingCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_mubingCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hlxg_mubingCard = 4
sgs.ai_skill_discard.hlxg_mubing = function(self, maximum, minimum)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    local ids = {}
    for _, card in ipairs(cards) do
        if #ids < maximum and not self.player:isJilei(card) and self:getKeepValue(card) < 4 then ids[#ids + 1] = card:getEffectiveId() end
    end
    return ids
end
sgs.ai_skill_askforag.hlxg_mubing = function(self, ids)
    local best, value = -1, -100
    for _, id in ipairs(ids) do
        local v = self:getUseValue(sgs.Sanguosha:getCard(id))
        if sgs.Sanguosha:getCard(id):getNumber() <= self.player:getTag("hlxg_mubing_budget"):toInt() and v > value then best, value = id, v end
    end
    return best
end
sgs.ai_fill_skill.hlxg_diaoling = function(self)
    local tag = self.player:getTag("hlxg_mubing_ids"):toString()
    local ids = {}
    for _, card in sgs.qlist(self.player:getHandcards()) do
        for id in string.gmatch(tag, "[^+]+") do
            if tonumber(id) == card:getEffectiveId() then ids[#ids + 1] = id; break end
        end
    end
    if #ids > 0 and #self.friends_noself > 0 then return sgs.Card_Parse("#hlxg_diaolingCard:" .. table.concat(ids, "+") .. ":") end
end
sgs.ai_skill_use_func["#hlxg_diaolingCard"] = function(card, use, self)
    self:sort(self.friends_noself, "handcard")
    for _, friend in ipairs(self.friends_noself) do
        if not self:needKongcheng(friend, true) then use.card = card; use.to:append(friend); return end
    end
end
sgs.ai_use_priority.hlxg_diaolingCard = 1
local function hl208_enemy_hand(self, targets)
    local players = sgs.QList2Table(targets)
    self:sort(players, "handcard")
    for _, p in ipairs(players) do if self:isEnemy(p) and not p:isKongcheng() then return p end end
end
sgs.ai_skill_playerchosen.hlxg_diaoling = hl208_enemy_hand
sgs.ai_skill_playerchosen.hlxg_qiaobian = hl208_enemy_hand
sgs.ai_skill_invoke.hlxg_ziqu = function(self, data)
    local damage = data:toDamage()
    if not damage.to then return false end
    if self:isFriend(damage.to) then return true end
    return self:isEnemy(damage.to) and damage.to:getHp() > 2 and damage.to:getHandcardNum() > 0 and damage.damage == 1
end
sgs.ai_skill_askforag.hlxg_ziqu = function(self, ids)
    local best, value = -1, 100
    for _, id in ipairs(ids) do
        local v = self:getKeepValue(sgs.Sanguosha:getCard(id))
        if v < value then best, value = id, v end
    end
    return best
end
sgs.ai_skill_discard.hlxg_qiaobian = function(self, maximum, minimum)
    local phase = self.player:getTag("hlxg_qiaobian_phase"):toInt()
    local want = phase == sgs.Player_Judge and not self.player:getJudgingArea():isEmpty()
        or phase == sgs.Player_Draw and #self.enemies > 1
        or phase == sgs.Player_Discard and self:getOverflow() > 1
        or phase == sgs.Player_Play and self.player:isKongcheng()
    if not want then return {} end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do if not self.player:isJilei(card) then return {card:getEffectiveId()} end end
    return {}
end
sgs.ai_skill_invoke.hlxg_zhouxuan = true
sgs.ai_skill_discard.hlxg_zhouxuan = function(self, maximum, minimum)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    local ids = {}
    for _, card in ipairs(cards) do if #ids < maximum then ids[#ids + 1] = card:getEffectiveId() end end
    return ids
end
sgs.ai_skill_askforag.hlxg_zhouxuan = sgs.ai_skill_askforag.hlxg_ziqu
end

-- ==================== c208_04
do
sgs.ai_skill_invoke.hlxg_yishe = true
sgs.ai_skill_discard.hlxg_yishe = function(self, discard_num, min_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    local ids = {}
    for i = 1, math.min(2, #cards) do table.insert(ids, cards[i]:getEffectiveId()) end
    return ids
end
sgs.ai_skill_invoke.hlxg_bushi = function(self, data)
    local target = data:toPlayer()
    return target and self:isFriend(target)
end
sgs.ai_skill_askforag.hlxg_bushi = function(self, card_ids)
    return card_ids[1] or -1
end
sgs.ai_skill_invoke.hlxg_midao = function(self, data)
    local judge = data:toJudge()
    if not judge or not judge.who then return false end
    for _, id in sgs.qlist(self.player:getPile("hlxg_yishe_rice")) do
        if judge:isGood(sgs.Sanguosha:getCard(id)) == self:isFriend(judge.who) then return true end
    end
    return false
end
sgs.ai_skill_askforag.hlxg_midao = function(self, card_ids)
    local judge = self.player:getTag("hlxg_midao_judge"):toJudge()
    if not judge or not judge.who then return -1 end
    for _, id in ipairs(card_ids) do
        if judge:isGood(sgs.Sanguosha:getCard(id)) == self:isFriend(judge.who) then return id end
    end
    return -1
end
end

-- ==================== c208_05
do
sgs.ai_skill_cardask["@hlxg_jujian-discard"] = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if not card:isKindOf("BasicCard") and not self.player:isJilei(card)
            and self:getKeepValue(card) < 5 then return "$" .. card:getEffectiveId() end
    end
    return "."
end
sgs.ai_skill_playerchosen.hlxg_jujian = function(self, targets)
    local friends = {}
    for _, player in sgs.qlist(targets) do
        if self:isFriend(player) then
            if not player:faceUp() then return player end
            table.insert(friends, player)
        end
    end
    self:sort(friends, "hp")
    return friends[1] or self.player
end
sgs.ai_skill_choice.hlxg_jujian = function(self)
    if not self.player:faceUp() then return "reset" end
    if self.player:isWounded() and self:isWeak() then return "recover" end
    if self.player:isChained() and not self:isGoodChainPartner(self.player) then return "reset" end
    return "draw"
end
sgs.ai_view_as.hlxg_duanliang_xuhuang = function(card, player, card_place, class_name)
    if class_name == "SupplyShortage" and card:isBlack() and not card:isKindOf("TrickCard")
        and (card_place == sgs.Player_PlaceHand or card_place == sgs.Player_PlaceEquip) then
        return ("supply_shortage:hlxg_duanliang_xuhuang[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId())
    end
end
sgs.ai_fill_skill.hlxg_duanliang_xuhuang = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByUseValue(cards, true)
    for _, card in ipairs(cards) do
        if card:isBlack() and not card:isKindOf("TrickCard") and self:getUseValue(card) < 5 then
            return sgs.Card_Parse(("supply_shortage:hlxg_duanliang_xuhuang[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId()))
        end
    end
end
end

-- ==================== c208_06
do
local function hl_pojun_invoke(self, data)
    local target = data:toPlayer()
    return target and self:isEnemy(target)
end
sgs.ai_skill_invoke.hlxg_pojun = hl_pojun_invoke
sgs.ai_skill_invoke.hljx_pojun = hl_pojun_invoke
sgs.ai_skill_invoke.hlxg_jiedao = function(self, data)
    local d = data:toDamage()
    return d.to and self:isEnemy(d.to)
end
sgs.ai_skill_choice.hlxg_jiedao = function(self, choices, data)
    local d = data:toDamage()
    local best = 0
    local budget = self.player:getCards("he"):length()
    for choice in choices:gmatch("[^+]+") do
        local n = tonumber(choice) or 0
        if d.to and self:isEnemy(d.to) and (n <= budget or d.damage + n >= d.to:getHp()) then
            best = math.max(best, n)
        end
    end
    return tostring(best)
end
sgs.ai_skill_discard.hlxg_jiedao = function(self, discard_num, min_num, optional, include_equip)
    return self:askForDiscard("dummy", discard_num, min_num, optional, include_equip)
end
end

-- ==================== c208_07
do
-- Matching engine 天妒/颂威 reuse their existing AI.
sgs.ai_skill_playerchosen.hlxg_xianfu = function(self, targets)
    local friends = {}
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then table.insert(friends, p) end end
    self:sort(friends, "hp", true)
    return friends[1] or targets:first()
end
sgs.ai_skill_invoke.hlxg_chouce = true
sgs.ai_skill_playerchosen.hlxg_chouce_black = function(self, targets)
    for _, p in sgs.qlist(targets) do
        if self:isFriend(p) and not p:getJudgingArea():isEmpty() then return p end
    end
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return targets:first()
end
sgs.ai_skill_cardchosen.hlxg_chouce = function(self, who, flags)
    if self:isFriend(who) and not who:getJudgingArea():isEmpty() then return who:getJudgingArea():first():getEffectiveId() end
    return -1
end
sgs.ai_skill_playerchosen.hlxg_chouce_red = function(self, targets)
    local linked = self.player:getTag("hlxg_xianfu_target"):toString()
    for _, p in sgs.qlist(targets) do if self:isFriend(p) and p:objectName() == linked then return p end end
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
    return targets:first()
end
sgs.ai_fill_skill.hlxg_xieju = function(self)
    if self.player:getMark("hlxg_xieju-PlayClear") == 0 then return sgs.Card_Parse("#hlxg_xiejuCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_xiejuCard"] = function(card, use, self)
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if self:isFriend(p) and p:getMark("hlxg_huiqi_target") > 0 then
            for _, enemy in ipairs(self.enemies) do
                if p:canSlash(enemy) then
                    use.card = card
                    if use.to then use.to:append(p) end
                    break
                end
            end
        end
    end
end
sgs.ai_use_priority.hlxg_xiejuCard = 3
sgs.ai_skill_use["@@hlxg_xieju"] = function(self)
    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
    slash:setSkillName("_hlxg_xieju")
    local use = self:aiUseCard(slash)
    local result = "."
    if use.card and use.to and not use.to:isEmpty() then
        local names = {}
        for _, p in sgs.qlist(use.to) do table.insert(names, p:objectName()) end
        result = slash:toString() .. "->" .. table.concat(names, "+")
    end
    slash:deleteLater()
    return result
end
sgs.ai_skill_invoke.hlxg_guangao = function(self, data)
    local p = data:toPlayer()
    return p and self:isEnemy(p) or false
end
sgs.ai_skill_playerschosen.hlxg_guangao_nullify = function(self, targets)
    local chosen = {}
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then table.insert(chosen, p) end end
    return chosen
end
sgs.ai_skill_playerchosen.hlxg_fangzhu_caopi = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) and not p:faceUp() then return p end end
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) and p:faceUp() then return p end end
end
sgs.ai_skill_invoke.hlxg_xingshang_caopi = true
end

-- ==================== c208_08
do
local function c208_08_jushou_invoke(self)
    return not self.player:faceUp() or self.player:getHandcardNum() < 3 or self.player:getHp() <= 2
end
sgs.ai_skill_invoke.hlxg_jushou = c208_08_jushou_invoke
sgs.ai_skill_invoke.hljx_jushou = c208_08_jushou_invoke
sgs.ai_view_as.hljx_jiewei = function(card, player, card_place)
    if card_place == sgs.Player_PlaceEquip then
        return "nullification:hljx_jiewei[" .. card:getSuitString() .. ":" .. card:getNumberString() .. "]=" .. card:getEffectiveId()
    end
end
sgs.ai_skill_discard.hljx_jiewei = function(self, discard_num, min_num, optional, include_equip)
    if self.player:getCardCount(true) <= 2 then return {} end
    local movable = false
    for _, friend in ipairs(self.friends) do
        if not friend:getJudgingArea():isEmpty() then movable = true; break end
    end
    if not movable then
        for _, enemy in ipairs(self.enemies) do
            if not enemy:getEquips():isEmpty() then movable = true; break end
        end
    end
    if not movable then return {} end
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if self.player:canDiscard(self.player, card:getEffectiveId()) and not card:isKindOf("Peach") then
            return {card:getEffectiveId()}
        end
    end
    return {}
end
sgs.ai_fill_skill.hlxg_weikui = function(self)
    if self.player:getHp() > 2 and not self.player:hasUsed("#hlxg_weikuiCard") then
        return sgs.Card_Parse("#hlxg_weikuiCard:.:")
    end
end
sgs.ai_skill_use_func["#hlxg_weikuiCard"] = function(card, use, self)
    self:sort(self.enemies, "handcard")
    for _, enemy in ipairs(self.enemies) do
        if not enemy:isKongcheng() then use.card = card; use.to:append(enemy); return end
    end
end
sgs.ai_use_priority.hlxg_weikuiCard = 3
sgs.ai_skill_playerschosen.hlxg_lizhan = function(self, targets)
    local chosen = {}
    for _, target in sgs.qlist(targets) do
        if self:isFriend(target) then table.insert(chosen, target) end
    end
    return chosen
end
end

-- ==================== c208_09
do
sgs.ai_skill_invoke.hlxg_qingxi = function(self, data)
    local target = data:toPlayer()
    return target and self:isEnemy(target)
end
sgs.ai_skill_choice.hlxg_qingxi = function(self, choices, data)
    if not string.find(choices, "discard", 1, true) then return "damage" end
    local n = self.player:getTag("hlxg_qingxi_count"):toInt()
    if n <= 2 or self:isWeak() then return "discard" end
    return "damage"
end
sgs.ai_skill_discard.hlxg_qingxi = function(self, discard_num, min_num)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    local ids = {}
    for _, card in ipairs(cards) do
        if not self.player:isJilei(card) then
            table.insert(ids, card:getEffectiveId())
            if #ids == discard_num then break end
        end
    end
    return ids
end
end

-- ==================== c209_01
do
sgs.ai_skill_cardask["@hlxg_renxin"] = function(self, data)
    local to = data:toDamage().to
    if not to or not self:isFriend(to) then return "." end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isKindOf("EquipCard") and self.player:canDiscard(self.player, c:getEffectiveId()) then return "$" .. c:getEffectiveId() end
    end
    return "."
end
sgs.ai_skill_askforag.hlxg_chengxiang = function(self, ids)
    local best, value = -1, -1000
    for _, id in ipairs(ids) do
        local v = self:getUseValue(sgs.Sanguosha:getCard(id))
        if v > value then best, value = id, v end
    end
    return best
end
sgs.ai_skill_invoke.hlxg_xingshuai = true
sgs.ai_skill_choice.hlxg_xingshuai = function(self, choices, data)
    local to = data:toPlayer()
    return to and self:isFriend(to) and "yes" or "no"
end
sgs.ai_skill_playerchosen.hlxg_huituo = function(self, targets)
    local friends = {}
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then table.insert(friends, p) end end
    self:sort(friends, "hp")
    return friends[1]
end
sgs.ai_fill_skill.hlxg_mingjian = function(self)
    if #self.friends_noself == 0 then return end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    local id = cards[1] and tostring(cards[1]:getEffectiveId()) or ""
    return sgs.Card_Parse("#hlxg_mingjianCard:" .. id .. ":")
end
sgs.ai_skill_use_func["#hlxg_mingjianCard"] = function(card, use, self)
    local friends = self.friends_noself
    if #friends == 0 then return end
    self:sort(friends, "handcard")
    use.card = card
    if use.to then use.to:append(friends[1]) end
end
sgs.ai_use_priority.hlxg_mingjianCard = 2
sgs.ai_skill_playerchosen.hlxg_fujian = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return targets:first()
end
sgs.ai_skill_playerchosen.hlxg_lingren = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
end
sgs.ai_skill_choice.hlxg_lingren = function(self, choices, data)
    local to = data:toPlayer()
    if not to or to:isKongcheng() then return choices:match("([^+]+_no)") end
    if choices:find("basic_yes", 1, true) then return "basic_yes" end
    if choices:find("trick_yes", 1, true) then return to:getHandcardNum() >= 3 and "trick_yes" or "trick_no" end
    return "equip_no"
end
sgs.ai_skill_invoke.hlxg_jianxiong_caoying = true
sgs.ai_skill_invoke.hlxg_xingshang_caoying = true
end

-- ==================== c209_02
do
sgs.ai_skill_choice.hlxg_xianwei = function(self, choices)
    local list = choices:split("+")
    for _, choice in ipairs(list) do
        if not self.player:getEquip(tonumber(choice)) then return choice end
    end
    return list[1]
end
sgs.ai_skill_playerchosen.hlxg_xianwei = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
    return targets:first()
end
sgs.ai_skill_invoke.hlxg_jiangchi = true
sgs.ai_skill_choice.hlxg_jiangchi = function(self)
    if self:getCardsNum("Slash") >= 2 and #self.enemies > 0 then return "attack" end
    if self:getCardsNum("Slash") == 0 then return "draw" end
    return "guard"
end
sgs.ai_fill_skill.hlxg_liushi = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:getSuit() == sgs.Card_Heart and not c:isKindOf("Peach") then
            return sgs.Card_Parse("#hlxg_liushiCard:" .. c:getEffectiveId() .. ":")
        end
    end
end
sgs.ai_skill_use_func["#hlxg_liushiCard"] = function(card, use, self)
    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
    slash:setSkillName("_hlxg_liushi")
    self:sort(self.enemies, "defense")
    for _, p in ipairs(self.enemies) do
        if not self.player:isLocked(slash) and self.player:canSlash(p, slash, false)
            and self:slashIsEffective(slash, p) and self:damageIsEffective(p) then
            use.card = card
            if use.to then use.to:append(p) end
            break
        end
    end
    slash:deleteLater()
end
sgs.ai_use_priority.hlxg_liushiCard = 2.6
end

-- ==================== c209_03
do
sgs.ai_skill_invoke.hlxg_guixin = true
sgs.ai_skill_invoke.hlxg_jianxiong_caocao2 = true
local function hl03_ai_marks(self, choices)
    if choices:find("zero", 1, true) then return "zero" end
    if choices:find("decrease", 1, true) then return "decrease" end
    return "cancel"
end
sgs.ai_skill_choice.hlxg_jianxiong_caocao2 = hl03_ai_marks
sgs.ai_skill_playerchosen.hlxg_hujia = function(self, targets)
    local enemies = {}
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then table.insert(enemies, p) end end
    self:sort(enemies, "hp")
    if #enemies > 0 then return enemies[1] end
    if self:isWeak() then
        for _, p in sgs.qlist(targets) do
            if self:isFriend(p) and p:getHp() > self.player:getHp() + 1 then return p end
        end
    end
end
sgs.ai_fill_skill.hlxg_qingzheng = function(self)
    local groups = {}
    for _, c in sgs.qlist(self.player:getHandcards()) do
        local suit = c:getSuit()
        groups[suit] = groups[suit] or {id = c:getEffectiveId(), value = 0, valid = true}
        local g = groups[suit]
        g.value = g.value + self:getKeepValue(c)
        if not self.player:canDiscard(self.player, c:getEffectiveId()) then g.valid = false end
    end
    local options = {}
    for _, g in pairs(groups) do if g.valid then table.insert(options, g) end end
    table.sort(options, function(a, b) return a.value < b.value end)
    local n, ids, cost = 3 - self.player:getMark("&hlxg_zhishi"), {}, 0
    if #options < n then return end
    for i = 1, n do ids[i] = options[i].id; cost = cost + options[i].value end
    if cost > 12 then return end
    for _, p in ipairs(self.enemies) do
        if not p:isKongcheng() then return sgs.Card_Parse("#hlxg_qingzhengCard:" .. table.concat(ids, "+") .. ":") end
    end
end
sgs.ai_skill_use_func["#hlxg_qingzhengCard"] = function(card, use, self)
    self:sort(self.enemies, "handcard")
    for _, p in ipairs(self.enemies) do
        if not p:isKongcheng() then use.card = card; use.to:append(p); return end
    end
end
sgs.ai_use_priority.hlxg_qingzhengCard = 3
sgs.ai_skill_choice.hlxg_qingzheng = function(self, choices, data)
    if choices:find("cancel", 1, true) then return hl03_ai_marks(self, choices) end
    local p = data and data:toPlayer()
    local available = choices:split("+")
    if not p then return available[1] end
    local values = {}
    for _, c in sgs.qlist(p:getHandcards()) do
        local suit = c:getSuitString()
        values[suit] = (values[suit] or 0) + self:getKeepValue(c)
    end
    local best = available[1]
    for _, suit in ipairs(available) do
        if (values[suit] or 0) > (values[best] or 0) then best = suit end
    end
    return best
end
end

-- ==================== c209_04
do
sgs.ai_skill_invoke.hlxg_luoying = true
sgs.ai_skill_invoke.hlxg_jiushi = true
sgs.ai_skill_cardask["@hlxg_kangkai-give"] = function(self, data)
    local target = data:toCardUse().to
    local friend
    for _, p in sgs.qlist(target) do if self:isFriend(p) and self.player:distanceTo(p) <= 1 then friend = p; break end end
    if not friend then return "." end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do if not c:isKindOf("Peach") then return "$" .. c:getEffectiveId() end end
    return "."
end
sgs.ai_skill_discard.hlxg_luoying = function(self, discard_num, min_num, optional, include_equip)
    local ids = {}
    for _, c in sgs.qlist(self.player:getHandcards()) do if c:getSuit() == sgs.Card_Club then table.insert(ids, c:getEffectiveId()) end end
    return ids
end
sgs.ai_cardsview_valuable.hlxg_jiushi = function(self, class_name, player)
    if class_name == "Analeptic" and player:faceUp() then return "analeptic:hlxg_jiushi[no_suit:0]=." end
end
sgs.ai_fill_skill.hlxg_jiushi = function(self)
    if self.player:faceUp() and self.player:getHp() <= 1 then return sgs.Card_Parse("analeptic:hlxg_jiushi[no_suit:0]=.") end
end
sgs.ai_fill_skill.hlxg_juezhu = function(self)
    if self.player:getMark("@hlxg_juezhu") > 0 and (self.player:hasEquipArea(2) or self.player:hasEquipArea(3)) then return sgs.Card_Parse("#hlxg_juezhuCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_juezhuCard"] = function(card, use, self)
    for _, p in ipairs(self.friends_noself or {}) do
        if not p:hasSkill("hlxg_feiying_caohong") then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_skill_choice.hlxg_juezhu = function(self, choices)
    local opts = choices:split("+")
    if self.player:getOffensiveHorse() == nil then for _, s in ipairs(opts) do if s == "3" then return s end end end
    return opts[1]
end
sgs.ai_fill_skill.hlxg_yuanhu = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do if c:isKindOf("EquipCard") then return sgs.Card_Parse("#hlxg_yuanhuCard:" .. c:getEffectiveId() .. ":") end end
end
sgs.ai_skill_use_func["#hlxg_yuanhuCard"] = function(card, use, self)
    local c = sgs.Sanguosha:getCard(card:getSubcards():first())
    if not c then return end
    local slot = c:getRealCard():toEquipCard():location()
    for _, p in ipairs(self.friends or {}) do
        if p:hasEquipArea(slot) and not p:getEquip(slot) then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_skill_playerchosen.hlxg_yuanhu = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return targets:first()
end
sgs.ai_use_priority.hlxg_yuanhuCard = 5
sgs.ai_use_priority.hlxg_juezhuCard = 4
end

-- ==================== c209_05
do
sgs.ai_skill_invoke.hlxg_shouxi = true
sgs.ai_skill_choice.hlxg_shouxi = function(self, choices)
    local options = choices:split("+")
    for _, name in ipairs(options) do if name == "peach" then return name end end
    return options[1]
end
sgs.ai_skill_cardask["@hlxg_shouxi-discard"] = function() return "." end
sgs.ai_skill_invoke.hlxg_huimin = true
sgs.ai_skill_playerchosen.hlxg_huimin = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
    return targets:first()
end
sgs.ai_skill_askforag.hlxg_huimin = function(self, ids)
    local best, value = ids[1], -1000
    for _, id in ipairs(ids) do
        local c = sgs.Sanguosha:getCard(id)
        local v = self:getUseValue(c)
        if v > value then best, value = id, v end
    end
    return best
end
sgs.ai_skill_invoke.hlxg_gongjian = function(self, data)
    local use = data:toCardUse()
    if not use.card then return false end
    for _, p in sgs.qlist(use.to) do if self:isEnemy(p) and not p:isNude() then return true end end
    return false
end
-- Optional selections use the engine's conservative default; never force a discard.
sgs.ai_skill_discard.hlxg_jujiang = function() return {} end
end

-- ==================== c209_06
do
sgs.ai_fill_skill.hlxg_anguo = function(self)
    if not self.player:hasUsed("#hlxg_anguoCard") then return sgs.Card_Parse("#hlxg_anguoCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_anguoCard"] = function(card, use, self)
    local best, best_score = nil, 0
    local players = sgs.QList2Table(self.room:getAlivePlayers())
    local function score(p)
        local hand, hp, equip = true, true, true
        for _, q in ipairs(players) do
            if q:getHandcardNum() < p:getHandcardNum() then hand = false end
            if q:getHp() < p:getHp() then hp = false end
            if q:getEquips():length() < p:getEquips():length() then equip = false end
        end
        return (hand and 1 or 0) + (hp and p:isWounded() and 2 or 0) + (equip and 1 or 0)
    end
    for _, p in ipairs(self.friends) do
        local value = score(p)
        if value > best_score then best, best_score = p, value end
    end
    if best then use.card = card; if use.to then use.to:append(best) end end
end
sgs.ai_use_priority.hlxg_anguoCard = 5

sgs.ai_fill_skill.hlxg_duliang = function(self)
    if not self.player:hasUsed("#hlxg_duliangCard") then return sgs.Card_Parse("#hlxg_duliangCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_duliangCard"] = function(card, use, self)
    self:sort(self.enemies, "handcard")
    for _, p in ipairs(self.enemies) do
        if not p:isKongcheng() then use.card = card; if use.to then use.to:append(p) end; return end
    end
    self:sort(self.friends_noself, "handcard")
    for _, p in ipairs(self.friends_noself) do
        if p:getHandcardNum() > 1 then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_use_priority.hlxg_duliangCard = 4
sgs.ai_skill_choice.hlxg_duliang = function(self, choices, data)
    local target = data and data:toPlayer()
    return target and self:isFriend(target) and "watch" or "draw"
end
sgs.ai_skill_discard.hlxg_duliang = function(self, max_num, min_num, optional, include_equip, pattern)
    local ids = {}
    for _, c in sgs.qlist(self.player:getHandcards()) do
        -- The exchange prompt sets the exact eligible drawn-card pattern.
        if sgs.Sanguosha:matchExpPattern(pattern or ".", self.player, c) then
            table.insert(ids, c)
        end
    end
    self:sortByKeepValue(ids)
    return #ids > 0 and {ids[1]:getEffectiveId()} or {}
end
end

-- ==================== c209_07
do
for _, name in ipairs({"hlxg_mieji", "hljx_mieji"}) do
    local skill = name
    sgs.ai_fill_skill[skill] = function(self)
        if self.player:hasUsed("#" .. skill .. "Card") then return end
        local cards = sgs.QList2Table(self.player:getCards("he"))
        self:sortByKeepValue(cards)
        for _, c in ipairs(cards) do
            if (skill == "hljx_mieji" or c:isBlack()) and not c:hasFlag("using") and self:getKeepValue(c) < 5 then
                return sgs.Card_Parse("#" .. skill .. "Card:" .. c:getEffectiveId() .. ":")
            end
        end
    end
    sgs.ai_skill_use_func["#" .. skill .. "Card"] = function(card, use, self)
        for _, p in ipairs(self.enemies) do
            if not p:isKongcheng() then use.card = card; if use.to then use.to:append(p) end; return end
        end
    end
    sgs.ai_skill_choice[skill] = function(self)
        for _, c in sgs.qlist(self.player:getCards("he")) do
            if c:isKindOf("TrickCard") and not self.player:isJilei(c) and self:getKeepValue(c) < 5 then return "trick" end
        end
        return "discard"
    end
    sgs.ai_use_priority[skill .. "Card"] = 3
end
for _, name in ipairs({"hlxg_fencheng", "hljx_fencheng"}) do
    local skill = name
    sgs.ai_fill_skill[skill] = function(self)
        if self.player:getMark("@" .. skill) > 0 and #self.enemies > #self.friends then
            return sgs.Card_Parse("#" .. skill .. "Card:.:")
        end
    end
    sgs.ai_skill_use_func["#" .. skill .. "Card"] = function(card, use, self)
        if skill == "hlxg_fencheng" then use.card = card
        elseif self.enemies[1] then use.card = card; if use.to then use.to:append(self.enemies[1]) end end
    end
    sgs.ai_skill_discard[skill] = function(self, discard_num, min_num)
        if self.player:getHp() > 2 and min_num > 2 then return {} end
        return self:askForDiscard("dummy", min_num, min_num, false, true)
    end
    sgs.ai_use_priority[skill .. "Card"] = 1
end
for _, name in ipairs({"hlxg_juece", "hljx_juece", "hlxg_xianzhu_target"}) do
    sgs.ai_skill_playerchosen[name] = function(self, targets)
        for _, p in sgs.qlist(targets) do
            if self:isEnemy(p) and self:damageIsEffective(p) then return p end
        end
        return nil
    end
end
sgs.ai_skill_playerchosen.hlxg_xianzhu = function(self, targets)
    for _, p in sgs.qlist(targets) do if p == self.player then return p end end
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
    return targets:first()
end
-- 巧言 is compulsory; its mandatory single-card exchange uses the normal exchange AI.
end

-- ==================== c209_08
do
sgs.ai_fill_skill.hlxg_yijiao = function(self)
    return sgs.Card_Parse("#hlxg_yijiaoCard:.:")
end
sgs.ai_skill_use_func["#hlxg_yijiaoCard"] = function(card, use, self)
    self:sort(self.enemies, "handcard")
    for _, p in ipairs(self.enemies) do
        if p:isAlive() then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_skill_choice.hlxg_yijiao = "4"
sgs.ai_use_priority.hlxg_yijiaoCard = 3
sgs.ai_skill_invoke.hlxg_qibie = true
sgs.ai_skill_discard.hlxg_qibie = function(self, discard_num, min_num)
    local ids = {}
    for _, c in sgs.qlist(self.player:getHandcards()) do
        if not self.player:isJilei(c) and self:getKeepValue(c) < 4 then table.insert(ids, c:getEffectiveId()) end
    end
    return ids
end
sgs.ai_skill_choice.hlxg_yise = function(self, choices, data)
    local p = data:toPlayer()
    if p and self:isFriend(p) and p:isWounded() and self:isWeak(p) then return "recover" end
    return "draw"
end
sgs.ai_skill_invoke.hlxg_yise = function(self, data)
    local p = data:toPlayer()
    return p and self:isEnemy(p) or false
end
sgs.ai_skill_invoke.hlxg_shunshi = function(self)
    return #self.friends_noself > 0
end
sgs.ai_skill_exchange.hlxg_shunshi = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    return cards[1] and {cards[1]:getEffectiveId()} or {}
end
sgs.ai_skill_playerchosen.hlxg_shunshi = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
    return targets:first()
end
sgs.ai_skill_choice.hlxg_shawu = function(self, choices, data)
    local p = data:toPlayer()
    if not p or not self:isEnemy(p) or not self:damageIsEffective(p) then return "cancel" end
    if string.find(choices, "sand", 1, true) then return "sand" end
    if string.find(choices, "discard", 1, true) and self.player:getHandcardNum() > 3 then return "discard" end
    return "cancel"
end
sgs.ai_skill_discard.hlxg_shawu = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    local ids = {}
    for _, c in ipairs(cards) do
        if not self.player:isJilei(c) and #ids < 2 then table.insert(ids, c:getEffectiveId()) end
    end
    return ids
end
sgs.ai_skill_invoke.hlxg_huaping = function(self, data)
    local p = data:toPlayer()
    return p and not p:getVisibleSkillList():isEmpty() or false
end
sgs.ai_skill_playerchosen.hlxg_huaping = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
    return nil
end
sgs.ai_fill_skill.hlxg_xiaowu = function(self)
    return sgs.Card_Parse("#hlxg_xiaowuCard:.:")
end
sgs.ai_skill_use_func["#hlxg_xiaowuCard"] = function(card, use) use.card = card end
sgs.ai_skill_choice.hlxg_xiaowu = function(self, choices, data)
    if string.find(choices, "next", 1, true) then return "next" end
    local p = data:toPlayer()
    if p and self:isFriend(p) and choices ~= "selfdraw" then return "draw" end
    return "selfdraw"
end
sgs.ai_skill_playerchosen.hlxg_xiaowu = function(self, targets)
    -- A single adjacent participant guarantees a simple, predictable vote.
    return targets:first()
end
sgs.ai_use_priority.hlxg_xiaowuCard = 4
end

-- ==================== c210_01
do
sgs.ai_skill_invoke.hlxg_youyan = true
sgs.ai_fill_skill.hlxg_youyan = function(self)
    if self.player:getMark("hlxg_youyan_active-PlayClear") > 0 or self.player:getMark("hlxg_youyan_reveal") > 0 then return end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if self.player:canDiscard(self.player, card:getEffectiveId()) and not card:isKindOf("Peach")
            and self:getKeepValue(card) < 4 then
            return sgs.Card_Parse("#hlxg_youyanCard:" .. card:getEffectiveId() .. ":")
        end
    end
end
sgs.ai_skill_use_func["#hlxg_youyanCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hlxg_youyanCard = 0.5
local function c210_01_ai_ag(self, ids)
    local best, value = nil, -math.huge
    for _, id in ipairs(ids) do
        local card = sgs.Sanguosha:getCard(id)
        if card then
            local v = self:getUseValue(card)
            if v > value then best, value = id, v end
        end
    end
    return best or ids[1] or -1
end
sgs.ai_skill_askforag.hlxg_youyan = c210_01_ai_ag
sgs.ai_skill_askforag.hlxg_xingluan = c210_01_ai_ag
sgs.ai_skill_playerchosen.hlxg_zhuihuan = function(self, targets)
    local friends = {}
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then table.insert(friends, p) end end
    self:sort(friends, "hp")
    return friends[1]
end
sgs.ai_skill_playerchosen.hlxg_lulve = function(self, targets)
    local enemies = {}
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then table.insert(enemies, p) end end
    self:sort(enemies, "handcard")
    if not self.player:faceUp() then return enemies[#enemies] end
    return enemies[1]
end
sgs.ai_skill_choice.hlxg_lulve = function(self, choices, data)
    local owner = data:toPlayer()
    if not owner then return "turnover" end
    if self:isFriend(owner) and not owner:faceUp() then return "give" end
    if not self.player:faceUp() then return "turnover" end
    if self.player:getHandcardNum() <= 1 and self:isEnemy(owner) and owner:faceUp() then return "give" end
    return "turnover"
end
end

-- ==================== c210_02
do
sgs.ai_skill_playerchosen.hlxg_anxu = function(self, targets)
    local players = sgs.QList2Table(targets)
    self:sort(players, "handcard")
    for _, p in ipairs(players) do if self:isEnemy(p) then return p end end
    return nil
end
local function hlxg_c210_02_friend(self, targets)
    local players = sgs.QList2Table(targets)
    self:sort(players, "hp")
    for _, p in ipairs(players) do if self:isFriend(p) then return p end end
    return nil
end
sgs.ai_skill_playerchosen.hlxg_zhuiyi = hlxg_c210_02_friend
sgs.ai_skill_playerchosen.hlxg_hongde = hlxg_c210_02_friend
sgs.ai_skill_invoke.hlxg_hongde = true
sgs.ai_skill_invoke.hlxg_zhengrong = function(self, data)
    local target = data:toDamage().to
    return target and self:isEnemy(target)
end
sgs.ai_fill_skill.hlxg_dingpan = function(self)
    local seen, count = {}, 0
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if not seen[p:getKingdom()] then seen[p:getKingdom()] = true; count = count + 1 end
    end
    if self.player:getMark("hlxg_dingpan-PlayClear") < count then return sgs.Card_Parse("#hlxg_dingpanCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_dingpanCard"] = function(card, use, self)
    for _, p in ipairs(self.enemies) do
        if not p:getEquips():isEmpty() then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_use_priority.hlxg_dingpanCard = 4
sgs.ai_skill_choice.hlxg_dingpan = function(self, choices, data)
    if self.player:getHp() > 2 and self.player:getEquips():length() >= 2 then return "obtain" end
    return "discard"
end
sgs.ai_fill_skill.hlxg_qingce = function(self)
    if not self.player:getPile("hlxg_zhengrong_rong"):isEmpty() then return sgs.Card_Parse("#hlxg_qingceCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_qingceCard"] = function(card, use, self)
    for _, p in ipairs(self.friends) do
        if not p:getJudgingArea():isEmpty() and self.player:canDiscard(p, "j") then
            use.card = card; if use.to then use.to:append(p) end; return
        end
    end
    for _, p in ipairs(self.enemies) do
        if self.player:canDiscard(p, "e") then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_use_priority.hlxg_qingceCard = 5
sgs.ai_skill_askforag.hlxg_qingce = function(self, ids)
    local cards = {}; for _, id in ipairs(ids) do cards[#cards + 1] = sgs.Sanguosha:getCard(id) end
    self:sortByKeepValue(cards)
    return cards[1] and cards[1]:getEffectiveId() or -1
end
sgs.ai_skill_discard.hlxg_hongju = function(self, discard_num, min_num)
    -- Zero is legal; conservatively retain the current hand and pile.
    return {}
end
sgs.ai_skill_askforag.hlxg_hongju = function(self, ids)
    local cards = {}; for _, id in ipairs(ids) do cards[#cards + 1] = sgs.Sanguosha:getCard(id) end
    self:sortByKeepValue(cards, true)
    return cards[1] and cards[1]:getEffectiveId() or -1
end
end

-- ==================== c210_03
do
sgs.ai_skill_invoke.hlxg_jili_shamoke = true
sgs.ai_skill_discard.hlxg_jili_shamoke = function(self, discard_num, min_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getCards(include_equip and "he" or "h"))
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if not self.player:isJilei(card) and not card:isKindOf("Peach") and self:getKeepValue(card) < 5 then
            return {card:getEffectiveId()}
        end
    end
    return {}
end
sgs.ai_skill_invoke.hlxg_jianying = true
sgs.ai_skill_invoke.hlxg_enyuan = function(self, data)
    local move = data:toMoveOneTime()
    return move.from and self:isFriend(move.from)
end
-- The same playerchosen hook handles the required victim selection. Distinguish
-- it by the candidate list: it contains self only for the victim prompt.
sgs.ai_skill_playerchosen.hlxg_xuanhuo = function(self, targets)
    local candidates = sgs.QList2Table(targets)
    self:sort(candidates, "defense")
    if targets:contains(self.player) then
        for _, p in ipairs(candidates) do if self:isEnemy(p) then return p end end
        for _, p in ipairs(candidates) do if p ~= self.player then return p end end
        return targets:first()
    end
    for _, p in ipairs(candidates) do if self:isEnemy(p) and not p:isNude() then return p end end
    return nil
end
-- askForUseSlashTo uses the standard Slash response AI.
end

-- ==================== c210_04
do
sgs.ai_skill_invoke.hljx_enyuan = function(self, data)
    local p = data:toPlayer()
    if p then return self:isFriend(p) end
    local d = data:toDamage()
    return d and d.from and self:isEnemy(d.from)
end
sgs.ai_skill_cardask["@hljx_enyuan-give"] = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do if c:isRed() and not c:isKindOf("Peach") then return "$" .. c:getEffectiveId() end end
    return "."
end
sgs.ai_skill_invoke.hljx_xuanhuo = function(self) return #self.enemies > 0 end
sgs.ai_skill_playerchosen.hljx_xuanhuo = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return targets:first()
end
sgs.ai_skill_exchange.hljx_xuanhuo = function() return {} end
sgs.ai_skill_choice.hljx_xuanhuo = function(self, choices)
    return "take"
end
sgs.ai_skill_askforag.hljx_xuanhuo = function(self, ids) return ids[1] or -1 end
sgs.ai_fill_skill.hlxg_kuangfu = function(self)
    if self.player:hasUsed("#hlxg_kuangfuCard") then return end
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if self.player:canDiscard(p, "e") then return sgs.Card_Parse("#hlxg_kuangfuCard:.:") end
    end
end
sgs.ai_skill_use_func["#hlxg_kuangfuCard"] = function(card, use, self)
    local holder
    for _, p in ipairs(self.enemies) do if self.player:canDiscard(p, "e") then holder = p; break end end
    if not holder then return end
    local slash = sgs.Sanguosha:cloneCard("slash"); slash:setSkillName("hlxg_kuangfu")
    for _, p in ipairs(self.enemies) do
        if not self.player:isProhibited(p, slash) and self:slashIsEffective(slash, p) then
            use.card = card; use.to:append(p); break
        end
    end
    slash:deleteLater()
end
sgs.ai_use_priority.hlxg_kuangfuCard = 4
sgs.ai_skill_cardask["@hlxg_guanwei"] = function(self, data)
    local p = data:toPlayer()
    if not p or not self:isFriend(p) then return "." end
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do if not self.player:isJilei(c) and not c:isKindOf("Peach") then return "$" .. c:getEffectiveId() end end
    return "."
end

sgs.ai_skill_playerchosen.hlxg_kuangfu = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return targets:first()
end
end

-- ==================== c210_05
do
sgs.ai_skill_playerchosen.hljx_qizhi = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return nil
end
sgs.ai_skill_invoke.hljx_jinqu = function(self)
    return self.player:getHandcardNum() <= self.player:getMark("hljx_qizhi-Clear") + 1
end
sgs.ai_skill_playerchosen.hlxg_lianji = function(self, targets)
    local giving = self.player:hasFlag("hlxg_lianji_giving")
    for _, p in sgs.qlist(targets) do
        if giving and self:isFriend(p) then return p end
        if not giving and self:isEnemy(p) then return p end
    end
    return targets:first()
end
sgs.ai_fill_skill.hlxg_lianji = function(self)
    if self.player:hasUsed("#hlxg_lianjiCard") then return end
    return sgs.Card_Parse("#hlxg_lianjiCard:.:")
end
sgs.ai_skill_use_func["#hlxg_lianjiCard"] = function(card, use, self)
    for _, p in ipairs(self.friends_noself or {}) do
        if p:isAlive() then
            use.card = card
            if use.to then use.to:append(p) end
            return
        end
    end
end
sgs.ai_use_priority.hlxg_lianjiCard = 4
-- Declare a useful trick with the cheapest equipment/Slash, using the standard card AI.
sgs.ai_fill_skill.hlxg_jingong = function(self)
    if self.player:usedTimes("hlxg_jingong") > 0 then return end
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isKindOf("EquipCard") or c:isKindOf("Slash") then
            for _, name in ipairs({"ex_nihilo", "dismantlement", "snatch", "duel"}) do
                local trick = sgs.Sanguosha:cloneCard(name, c:getSuit(), c:getNumber())
                if trick then
                    trick:addSubcard(c); trick:setSkillName("hlxg_jingong")
                    local dummy = {isDummy = true, to = sgs.SPlayerList()}
                    if trick:isAvailable(self.player) then self:useTrickCard(trick, dummy) end
                    if dummy.card then return trick end
                    trick:deleteLater()
                end
            end
            return
        end
    end
end
end

-- ==================== c210_06
do
-- Conservative decisions for c210_06.
sgs.ai_fill_skill.hlxg_feijun = function(self)
    if self.player:hasUsed("#hlxg_feijunCard") then return end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if not self.player:isJilei(c) and not c:isKindOf("Peach") then
            return sgs.Card_Parse("#hlxg_feijunCard:" .. c:getEffectiveId() .. ":")
        end
    end
end
sgs.ai_skill_use_func["#hlxg_feijunCard"] = function(card, use, self)
    self:sort(self.enemies, "handcard")
    for _, p in ipairs(self.enemies) do
        if not p:isNude() then use.card = card; use.to:append(p); return end
    end
    if self.player:hasSkill("hlxg_binglve") then
        for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
            if p:isNude() then use.card = card; use.to:append(p); return end
        end
    end
end
sgs.ai_use_priority.hlxg_feijunCard = 5
sgs.ai_skill_choice.hlxg_feijun = function(self, choices, data)
    local p = data:toPlayer()
    if p and self:isEnemy(p) and p:getHandcardNum() > 0 and p:getEquips():length() > 0 then return "equip" end
    return "give"
end
sgs.ai_skill_discard.hlxg_feijun = function(self, max, min, optional, equip)
    local cards = sgs.QList2Table(self.player:getCards(equip and "e" or "h"))
    self:sortByKeepValue(cards)
    local ids = {}
    for _, c in ipairs(cards) do
        if not self.player:isJilei(c) and #ids < min then table.insert(ids, c:getEffectiveId()) end
    end
    return ids
end
sgs.ai_skill_exchange.hlxg_feijun = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    return cards[1] and {cards[1]:getEffectiveId()} or {}
end
sgs.ai_skill_invoke.hljx_miji = true
sgs.ai_skill_askforyiji.hljx_miji = function(self, ids, tos)
    if not ids or #ids == 0 then return end
    for _, p in sgs.qlist(tos or self.room:getOtherPlayers(self.player)) do
        if self:isFriend(p) and p ~= self.player and not p:hasSkill("manjuan") then return p, ids[1] end
    end
end
sgs.ai_skill_invoke.hljx_zhenlie = function(self, data)
    local use = data:toCardUse()
    if not use.card or not use.from or self.player:getHp() <= 1 or not self:isEnemy(use.from) then return false end
    if use.card:isKindOf("Slash") then return not self:getCardId("Jink") end
    return use.card:isDamageCard() or use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement")
end
sgs.ai_skill_choice.hljx_zhenlie = function(self, choices)
    if choices:find("miji") and self.player:getLostHp() >= 2 then return "miji" end
    return "obtain"
end
sgs.ai_skill_invoke.hlxg_huguan = function(self, data)
    local p = data:toPlayer()
    return p and self:isFriend(p)
end
sgs.ai_skill_choice.hlxg_huguan = function(self, choices, data)
    if choices:find("show") then return "show" end
    local p = data:toPlayer()
    local counts = {spade = 0, club = 0, heart = 0, diamond = 0}
    if p == self.player then
        for _, c in sgs.qlist(p:getHandcards()) do
            local suit = c:getSuitString()
            if counts[suit] then counts[suit] = counts[suit] + 1 end
        end
    end
    local best = "heart"
    for _, suit in ipairs({"spade", "club", "heart", "diamond"}) do
        if counts[suit] > counts[best] then best = suit end
    end
    return best
end
sgs.ai_skill_exchange.hlxg_huguan = function(self, pattern)
    local ids = {}
    for _, c in sgs.qlist(self.player:getHandcards()) do
        if sgs.Sanguosha:matchExpPattern(pattern or ".", self.player, c) then table.insert(ids, c:getEffectiveId()) end
    end
    return ids
end
sgs.ai_skill_invoke.hlxg_mingluan = function(self, data)
    local p = data:toPlayer()
    return p and p:getHandcardNum() > 0
end
sgs.ai_skill_discard.hlxg_mingluan = function(self, max, min)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    local ids = {}
    for _, c in ipairs(cards) do
        if not self.player:isJilei(c) and #ids < min then table.insert(ids, c:getEffectiveId()) end
    end
    return ids
end
end

-- ==================== c210_07
do
sgs.ai_skill_invoke.hlxg_qiai = true
sgs.ai_skill_invoke.hlxg_sanwen = true
sgs.ai_skill_invoke.hlxg_denglou = true
sgs.ai_skill_invoke.hlxg_luoshen_zhenji = true
sgs.ai_skill_invoke.hlxg_jijing = function(self) return self.player:isWounded() end
sgs.ai_skill_playerchosen.hlxg_zhuide = function(self, targets)
    local friends = {}
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then table.insert(friends, p) end end
    self:sort(friends, "handcard")
    return friends[1]
end
sgs.ai_skill_playerchosen.hlxg_denglou = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return targets:first()
end
sgs.ai_skill_use["@@hlxg_jijing"] = function(self)
    if not self.player:isWounded() then return "." end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    local ids, sum = {}, 0
    for _, c in ipairs(cards) do
        if not self.player:isJilei(c) and self.player:canDiscard(self.player, c:getEffectiveId()) then
            table.insert(ids, c:getEffectiveId()); sum = sum + c:getNumber()
            if sum >= self.player:getMark("hlxg_jijing_number") then return "#hlxg_jijingCard:" .. table.concat(ids, "+") .. ":" end
        end
    end
    return "."
end
sgs.ai_skill_use["@@hlxg_denglou"] = function(self)
    for _, id in sgs.qlist(self.player:getTag("hlxg_denglou_ids"):toIntList()) do
        local card = sgs.Sanguosha:getCard(id)
        local use = {isDummy = true, to = sgs.SPlayerList()}
        self:useBasicCard(card, use)
        if use.card then
            local names = {}
            for _, p in sgs.qlist(use.to) do table.insert(names, p:objectName()) end
            return card:toString() .. (#names > 0 and "->" .. table.concat(names, "+") or "")
        end
    end
    return "."
end
sgs.ai_fill_skill.hlxg_minsi = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    local sums = {[0] = {}}
    for _, c in ipairs(cards) do
        if not self.player:isJilei(c) and self.player:canDiscard(self.player, c:getEffectiveId()) and c:getNumber() > 0 then
            for sum = 13 - c:getNumber(), 0, -1 do
                if sums[sum] and not sums[sum + c:getNumber()] then
                    local ids = {}
                    for _, id in ipairs(sums[sum]) do table.insert(ids, id) end
                    table.insert(ids, c:getEffectiveId()); sums[sum + c:getNumber()] = ids
                end
            end
        end
    end
    if sums[13] then return sgs.Card_Parse("#hlxg_minsiCard:" .. table.concat(sums[13], "+") .. ":") end
end
sgs.ai_skill_use_func["#hlxg_minsiCard"] = function(card, use, self) use.card = card end
sgs.ai_use_priority.hlxg_minsiCard = 4
sgs.ai_view_as.hlxg_qingguo_zhenji = function(card, player, place, class_name)
    if class_name == "Jink" and place == sgs.Player_PlaceHand and card:isBlack() then
        return ("jink:hlxg_qingguo_zhenji[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId())
    end
end
sgs.ai_skill_exchange.hlxg_qiai = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    return cards[1] and {cards[1]:getEffectiveId()} or {}
end
end

-- ==================== c210_08
do
sgs.ai_skill_invoke.hljx_luoshen = true
sgs.ai_skill_invoke.hlxg_luoshen_zhenji3 = true
for _, name in ipairs({"hljx_qingguo", "hlxg_feifu"}) do
    sgs.ai_view_as[name] = function(card, player, place)
        if card:isBlack() and (place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip) then
            return ("jink:%s[%s:%s]=%d"):format(name, card:getSuitString(), card:getNumberString(), card:getEffectiveId())
        end
    end
end
sgs.ai_skill_cardask["@hlxg_qixian-store"] = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    if cards[1] then return "$" .. cards[1]:getEffectiveId() end
    return "."
end
sgs.ai_skill_playerchosen.hlxg_shenfu = function(self, targets)
    local odd = self.player:getHandcardNum() % 2 == 1
    for _, q in sgs.qlist(targets) do
        if odd and self:isEnemy(q) and self:damageIsEffective(q, sgs.DamageStruct_Thunder, self.player) then return q end
        if not odd and self:isFriend(q) then return q end
    end
    if not odd then for _, q in sgs.qlist(targets) do if self:isEnemy(q) and self.player:canDiscard(q, "he") then return q end end end
end
sgs.ai_skill_choice.hlxg_shenfu = function(self, choices, data)
    local q = self.room:findPlayerByObjectName(data:toString())
    if q and self:isEnemy(q) and choices:find("discard") then return "discard" end
    return "draw"
end
sgs.ai_skill_discard.hlxg_qingguo_zhenji3 = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do if c:isBlack() then return {c:getEffectiveId()} end end
    return {}
end
sgs.ai_skill_cardask["@hlxg_qingguo_zhenji3-defend"] = function(self, data)
    local use = data:toCardUse()
    if not use.card or not use.card:isDamageCard() then return "." end
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do if c:isBlack() and not self.player:isJilei(c) then return "$" .. c:getEffectiveId() end end
    return "."
end
sgs.ai_fill_skill.hlxg_qingguo_zhenji3 = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do if c:isRed() then return sgs.Card_Parse("#hlxg_qingguo_zhenji3Card:" .. c:getEffectiveId() .. ":") end end
end
sgs.ai_skill_use_func["#hlxg_qingguo_zhenji3Card"] = function(card, use, self)
    for _, q in ipairs(self.friends_noself) do
        if not q:isNude() then use.card = card; use.to:append(q); return end
    end
end
sgs.ai_use_priority.hlxg_qingguo_zhenji3Card = 3
sgs.ai_skill_use["@@#hlxg_luoshen_zhenji3_use"] = function(self)
    local id = self.player:getMark("hlxg_luoshen_zhenji3_card") - 1
    if id < 0 then return "." end
    local original = sgs.Sanguosha:getCard(id)
    local c = sgs.Sanguosha:cloneCard(original:objectName(), original:getSuit(), original:getNumber())
    c:addSubcard(id); c:setSkillName("hlxg_luoshen_zhenji3")
    local dummy = {isDummy = true, to = sgs.SPlayerList()}; self:useCardByClassName(c, dummy)
    local names = {}
    if dummy.card then for _, q in sgs.qlist(dummy.to) do table.insert(names, q:objectName()) end end
    local answer = dummy.card and c:toString() .. "->" .. table.concat(names, "+") or "."
    c:deleteLater(); return answer
end
end

-- ==================== c211_01
do
sgs.ai_skill_invoke.hlxg_shushen = function(self, data)
    if not data then return false end
    local damage = data:toDamage()
    if not damage or not damage.to or not self:isFriend(damage.to) then return false end
    if self.player:getHp() <= 1 then return false end
    return damage.to:objectName() ~= self.player:objectName() or damage.damage > 1
end
sgs.ai_skill_playerchosen.hlxg_shushen = function(self, targets)
    local list = sgs.QList2Table(targets)
    self:sort(list, "handcard")
    for _, player in ipairs(list) do
        if self:isFriend(player) and not self:needKongcheng(player, true) then return player end
    end
    return nil
end
sgs.ai_skill_invoke.hlxg_huangsi = true
sgs.ai_skill_playerchosen.hlxg_huangsi = function(self, targets)
    local list = sgs.QList2Table(targets)
    self:sort(list, "handcard")
    for _, player in ipairs(list) do
        if self:isFriend(player) and not self:needKongcheng(player, true) then return player end
    end
    return self.player
end
local function hl_qixi_target(self, targets)
    local list = sgs.QList2Table(targets)
    self:sort(list, "defense")
    for _, player in ipairs(list) do
        if self:isEnemy(player) then return player end
    end
    for _, player in ipairs(list) do
        if self:isFriend(player) and (player:containsTrick("indulgence") or player:containsTrick("supply_shortage")) then
            return player
        end
    end
    return nil
end
sgs.ai_skill_playerchosen.hlxg_qixi_ganning = hl_qixi_target
sgs.ai_skill_playerchosen.hljx_qixi = hl_qixi_target
sgs.ai_skill_cardchosen.hlxg_qixi_ganning = function(self, who, flags)
    if self:isFriend(who) then
        for _, card in sgs.qlist(who:getJudgingArea()) do
            if card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage") then return card:getEffectiveId() end
        end
    end
    return nil -- Use the engine AI's normal discard selection.
end
sgs.ai_skill_cardchosen.hljx_qixi = sgs.ai_skill_cardchosen.hlxg_qixi_ganning
sgs.ai_fill_skill.hljx_qixi = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByUseValue(cards, true)
    for _, card in ipairs(cards) do
        if card:isBlack() and not card:isKindOf("Peach")
            and (not card:isEquipped() or (card:isKindOf("Armor") and self:needToThrowArmor()))
            and self:getUseValue(card) < sgs.ai_use_value.Dismantlement then
            return sgs.Card_Parse(("dismantlement:hljx_qixi[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId()))
        end
    end
end
local function hl_fenwei_help(self, card, target)
    if not card or not target then return false end
    if card:isKindOf("AOE") or card:isKindOf("Duel") or card:isKindOf("Dismantlement")
        or card:isKindOf("Snatch") or card:isKindOf("DelayedTrick") or card:isKindOf("FireAttack") then
        return self:isFriend(target)
    end
    if card:isKindOf("GodSalvation") then return self:isEnemy(target) and target:isWounded() end
    if card:isKindOf("ExNihilo") then return self:isEnemy(target) end
    return false
end
sgs.ai_skill_invoke.hljx_fenwei = function(self, data)
    if not data then return false end
    local use = data:toCardUse()
    if not use or not use.card then return false end
    for _, target in sgs.qlist(use.to) do
        if hl_fenwei_help(self, use.card, target) then return true end
    end
    return false
end
sgs.ai_skill_playerschosen.hljx_fenwei = function(self, targets, max, min)
    local selected = {}
    local use = self.player:getTag("hljx_fenwei_use"):toCardUse()
    for _, target in sgs.qlist(targets) do
        if #selected < (max or 999) and hl_fenwei_help(self, use and use.card, target) then table.insert(selected, target) end
    end
    return selected
end
end

-- ==================== c211_02
do
sgs.ai_skill_playerchosen.hlxg_jieying_ganning2 = function(self, targets)
    local enemies = {}
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then table.insert(enemies, p) end end
    self:sort(enemies, "handcard")
    return enemies[#enemies]
end
sgs.ai_fill_skill.hlxg_poxi = function(self) return sgs.Card_Parse("#hlxg_poxiCard:.:") end
sgs.ai_skill_use_func["#hlxg_poxiCard"] = function(card, use, self)
    self:sort(self.enemies, "handcard")
    for i = #self.enemies, 1, -1 do
        if not self.enemies[i]:isKongcheng() then use.card = card; use.to:append(self.enemies[i]); return end
    end
end
sgs.ai_skill_askforag.hlxg_poxi = function(self, ids)
    local cards = {}
    for _, id in ipairs(ids) do table.insert(cards, sgs.Sanguosha:getCard(id)) end
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        local owner = self.room:getCardOwner(c:getEffectiveId())
        if owner and self:isEnemy(owner) then return c:getEffectiveId() end
    end
    return cards[1] and cards[1]:getEffectiveId() or -1
end
sgs.ai_use_priority.hlxg_poxiCard = 4
end

-- ==================== c211_03
do
sgs.ai_skill_choice.hlxg_juedi = function(self, choices)
    if choices:find("give") then
        for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
            if self:isFriend(p) and p:getHp() <= self.player:getHp() and p:isWounded() then return "give" end
        end
    end
    return "remove"
end
sgs.ai_skill_playerchosen.hlxg_juedi = function(self, targets)
    local players = sgs.QList2Table(targets)
    self:sort(players, "hp")
    for _, p in ipairs(players) do if self:isFriend(p) then return p end end
    return players[1]
end
sgs.ai_skill_exchange.hlxg_yinbing = function(self, pattern, max_num, min_num, expand_pile)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    local ids = {}
    for _, card in ipairs(cards) do
        if not card:isKindOf("BasicCard") and self:getKeepValue(card) < 4 then ids[#ids + 1] = card:getEffectiveId() end
    end
    return ids
end
sgs.ai_skill_invoke.hljx_lieren = function(self, data)
    local p = data:toPlayer()
    return p and self:isEnemy(p) and not self.player:isKongcheng()
end
sgs.ai_skill_pindian.hljx_lieren = function(minusecard, self, requestor)
    return self:getMaxCard() or minusecard
end
sgs.ai_fill_skill.hljx_zhangbiao = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if not c:isKindOf("Peach") and not c:isKindOf("Jink") and self:getKeepValue(c) < 5 then
            return sgs.Card_Parse("slash:hljx_zhangbiao[no_suit:0]=" .. c:getEffectiveId())
        end
    end
end
end

-- ==================== c211_04
do
sgs.ai_skill_invoke.hlxg_tianbian = function(self)
    local card = self:getMaxCard()
    return not card or card:getNumber() < 10
end
sgs.ai_skill_invoke.hlxg_zhuandui = function(self, data)
    local target = data:toPlayer()
    local card = self:getMaxCard()
    return target and self:isEnemy(target) and card and card:getNumber() >= 10
end
sgs.ai_skill_invoke.hlxg_zongshi_jianyong = true
sgs.ai_skill_invoke.hlxg_lihuo = function(self, data)
    local use = data:toCardUse()
    if not use.card then return false end
    for _, p in sgs.qlist(use.to) do
        if self:isEnemy(p) and p:hasArmorEffect("vine") and not self:isWeak() then return true end
    end
    return false
end
sgs.ai_skill_cardask["@hlxg_jianzheng"] = function(self, data)
    local use = data:toCardUse()
    if not use.card then return "." end
    local help = false
    for _, p in sgs.qlist(use.to) do if self:isFriend(p) and self:isWeak(p) then help = true end end
    if not help or (not use.card:isBlack() and self:isWeak()) then return "." end
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    return cards[1] and "$" .. cards[1]:getEffectiveId() or "."
end
sgs.ai_skill_askforag.hlxg_chunlao = function(self, ids)
    local dying = self.room:getCurrentDyingPlayer()
    if not dying or not self:isFriend(dying) then return -1 end
    return ids[1] or -1
end
sgs.ai_skill_exchange.hlxg_chunlao = function(self)
    local ids = {}
    for _, c in sgs.qlist(self.player:getHandcards()) do if c:isKindOf("Slash") then table.insert(ids, c:getEffectiveId()) end end
    return ids
end
sgs.ai_fill_skill.hlxg_qiaoshuo = function(self)
    if self.player:getMark("hlxg_qiaoshuo_ready-Clear") > 0 then return end
    local c = self:getMaxCard()
    if c and c:getNumber() >= 11 then return sgs.Card_Parse("#hlxg_qiaoshuoCard:.:" ) end
end
sgs.ai_skill_use_func["#hlxg_qiaoshuoCard"] = function(card, use, self)
    for _, p in ipairs(self.enemies) do
        if self.player:canPindian(p) then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_use_priority.hlxg_qiaoshuoCard = 7
sgs.ai_skill_choice.hlxg_qiaoshuo = function() return "cancel" end
sgs.ai_skill_playerchosen.hlxg_qiaoshuo = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return targets:first()
end

sgs.ai_skill_playerchosen.hlxg_lihuo = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return nil
end
end

-- ==================== c211_05
do
sgs.ai_skill_invoke.hlxg_mingjie = true
sgs.ai_skill_invoke.tenyeartuiyan = true
sgs.ai_skill_invoke.hlxg_yongjue = true
sgs.ai_skill_cardask["@hlxg_yongjue-discard"] = function(self, data)
    local damage = data:toDamage()
    if not damage.card then return "." end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if card:isKindOf("Slash") and card:getNumber() >= damage.card:getNumber() and not self.player:isJilei(card) then
            return "$" .. card:getEffectiveId()
        end
    end
    return "."
end
sgs.ai_fill_skill.hlxg_bosuan = function(self)
    if #self.friends_noself > 0 then return sgs.Card_Parse("#hlxg_bosuanCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_bosuanCard"] = function(card, use, self)
    self:sort(self.friends_noself, "handcard")
    for _, friend in ipairs(self.friends_noself) do
        if not friend:hasSkill("manjuan") then use.card = card; use.to:append(friend); return end
    end
end
sgs.ai_skill_choice.hlxg_bosuan = function(self, choices)
    local available = choices:split("+")
    for _, name in ipairs({"ex_nihilo", "peach", "jink", "slash"}) do
        for _, choice in ipairs(available) do if choice == name then return choice end end
    end
    return available[1]
end
sgs.ai_use_priority.hlxg_bosuanCard = 3
sgs.ai_fill_skill.hlxg_cunsi = function(self)
    if self.player:getMark("@hlxg_cunsi") > 0 and self.player:getHp() <= 1 and #self.friends_noself > 0 then
        return sgs.Card_Parse("#hlxg_cunsiCard:.:")
    end
end
sgs.ai_skill_use_func["#hlxg_cunsiCard"] = function(card, use, self)
    self:sort(self.friends_noself, "handcard")
    for _, friend in ipairs(self.friends_noself) do
        if not friend:hasSkill("manjuan") then use.card = card; use.to:append(friend); return end
    end
end
sgs.ai_use_priority.hlxg_cunsiCard = 2
sgs.ai_skill_playerschosen.hlxg_jugu = function(self, targets, max_num, min_num)
    local chosen = {}
    for _, player in sgs.qlist(targets) do
        if #chosen < (max_num or self.player:getMaxHp()) and self:isFriend(player) and not player:hasSkill("manjuan") then
            table.insert(chosen, player)
        end
    end
    return chosen
end
sgs.ai_fill_skill.hlxg_ziyuan = function(self)
    -- Literal “任意张” permits zero cards: a once-per-phase draw is useful.
    return sgs.Card_Parse("#hlxg_ziyuanCard:.:")
end
sgs.ai_skill_use_func["#hlxg_ziyuanCard"] = function(card, use, self)
    local to
    self:sort(self.friends_noself, "hp")
    for _, friend in ipairs(self.friends_noself) do if friend:isWounded() then to = friend; break end end
    if to then
        local cards = sgs.QList2Table(self.player:getHandcards())
        self:sortByKeepValue(cards)
        -- Find an exact 13-point gift; both literal threshold clauses then apply.
        local sums = {[0] = {}}
        for _, c in ipairs(cards) do
            local n = c:getNumber()
            if n > 0 and n <= 13 and not c:isKindOf("Peach") then
                for total = 13 - n, 0, -1 do
                    if sums[total] and not sums[total + n] then
                        local ids = {}
                        for _, id in ipairs(sums[total]) do table.insert(ids, id) end
                        table.insert(ids, c:getEffectiveId()); sums[total + n] = ids
                    end
                end
            end
        end
        if sums[13] then
            use.card = sgs.Card_Parse("#hlxg_ziyuanCard:" .. table.concat(sums[13], "+") .. ":")
            use.to:append(to); return
        end
    end
    local others = self.room:getOtherPlayers(self.player)
    if not others:isEmpty() then use.card = card; use.to:append(others:first()) end
end
sgs.ai_use_priority.hlxg_ziyuanCard = 4
end

-- ==================== c211_06
do
sgs.ai_skill_playerchosen.hlxg_fengshi = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
end
sgs.ai_skill_invoke.hlxg_fengshi = function(self, data)
    local use = data:toCardUse()
    return use.from and self:isEnemy(use.from) and self.player:getHp() > 2 and not use.card:isDamageCard()
end
sgs.ai_skill_playerchosen.hlxg_shuangren = function(self, targets)
    local card = self:getMaxCard()
    if not card or card:getNumber() < 10 then return nil end
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
end
sgs.ai_skill_pindian.hlxg_shuangren = function(minusecard, self, requestor)
    return self:getMaxCard() or minusecard
end
sgs.ai_skill_invoke.hlxg_deshao = true
sgs.ai_skill_invoke.hlxg_deshao_discard = function(self, data)
    local use = data:toCardUse()
    return use.from and self:isEnemy(use.from)
end
sgs.ai_skill_invoke.hlxg_mingfa = function(self, data)
    local use = data:toCardUse()
    return use.card and use.card:isDamageCard() and #self.enemies > 0
end
sgs.ai_skill_playerchosen.hlxg_mingfa = function(self, targets)
    local best
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) and (not best or p:getHandcardNum() > best:getHandcardNum()) then best = p end
    end
    return best or targets:first()
end
end

-- ==================== c211_07
do
sgs.ai_fill_skill.hlxg_wuyuan = function(self)
    if self.player:hasUsed("#hlxg_wuyuanCard") or #self.friends_noself == 0 then return end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isKindOf("Slash") then return sgs.Card_Parse("#hlxg_wuyuanCard:" .. c:getEffectiveId() .. ":") end
    end
end
sgs.ai_skill_use_func["#hlxg_wuyuanCard"] = function(card, use, self)
    local friends = {}; for _, p in ipairs(self.friends_noself) do friends[#friends + 1] = p end
    self:sort(friends, "hp")
    for _, p in ipairs(friends) do
        if p:isAlive() then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_use_priority.hlxg_wuyuanCard = 4.2
sgs.ai_use_value.hlxg_wuyuanCard = 6
sgs.ai_skill_invoke.hlxg_zhanyuan = function(self) return #self.friends_noself > 0 end
sgs.ai_skill_playerchosen.hlxg_zhanyuan = function(self, targets)
    local friends = {}
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then friends[#friends + 1] = p end end
    self:sort(friends, "handcard", true)
    return friends[1] or targets:first()
end
sgs.ai_skill_cardask["@hlxg_xili"] = function(self, data)
    local d = data:toDamage()
    if not d.from or not d.to or not self:isFriend(d.from) or not self:isEnemy(d.to)
        or not self:damageIsEffective(d.to, d.nature, d.from) then return "." end
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if self.player:canDiscard(self.player, c:getEffectiveId()) and not c:isKindOf("Peach") then
            return "$" .. c:getEffectiveId()
        end
    end
    return "."
end
local function c21107_souying_payment(self, data, defensive)
    local use = data:toCardUse()
    if not use.card or not use.from then return "." end
    if defensive and (not self:isEnemy(use.from)
        or not (use.card:isDamageCard() or use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement"))) then return "." end
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if self.player:canDiscard(self.player, c:getEffectiveId()) and not c:isKindOf("Peach")
            and (defensive or self:getKeepValue(c) < self:getUseValue(use.card)) then return "$" .. c:getEffectiveId() end
    end
    return "."
end
sgs.ai_skill_cardask["@hlxg_souying_obtain"] = function(self, data) return c21107_souying_payment(self, data, false) end
sgs.ai_skill_cardask["@hlxg_souying_nullify"] = function(self, data) return c21107_souying_payment(self, data, true) end
sgs.ai_fill_skill.hlxg_mansi = function(self)
    if self.player:isKongcheng() then return end
    local ids = {}
    for _, c in sgs.qlist(self.player:getHandcards()) do
        if self.player:isJilei(c) or c:isKindOf("Peach") then return end
        ids[#ids + 1] = c:getEffectiveId()
    end
    local card = sgs.Card_Parse("savage_assault:hlxg_mansi[no_suit:0]=" .. table.concat(ids, "+"))
    if card and card:isAvailable(self.player) and self:getAoeValue(card) > 0 then return card end
end
end

-- ==================== c212_01
do
local function c212_friend(self, targets, cap, draw)
    local best, score
    for _, p in sgs.qlist(targets) do
        if self:isFriend(p) then
            local n = math.min(cap, p:getMaxHp()) - p:getHandcardNum()
            if draw then n = math.min(cap, p:getMaxHp()) - math.max(0, p:getHandcardNum() - math.min(cap, p:getMaxHp())) end
            if not score or n > score then best = p; score = n end
        end
    end
    if score and score > 0 then return best end
end
sgs.ai_skill_playerchosen.hlxg_jieming = function(self, targets) return c212_friend(self, targets, 4, false) end
sgs.ai_skill_playerchosen.hljx_jieming = function(self, targets) return c212_friend(self, targets, 5, true) end
sgs.ai_fill_skill.hlxg_quhu = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    local ids = {}
    for _, card in ipairs(cards) do
        if not self.player:isJilei(card) and not card:isKindOf("Peach") and not card:isKindOf("Analeptic") then
            table.insert(ids, card:getEffectiveId()); if #ids == 2 then break end
        end
    end
    if #ids == 2 and #self.enemies > 0 then return sgs.Card_Parse("#hlxg_quhuCard:" .. table.concat(ids, "+") .. ":") end
    if self.player:getHp() > 2 and #self.friends > 1 then return sgs.Card_Parse("#hlxg_quhuCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_quhuCard"] = function(card, use, self)
    if card:getSubcards():isEmpty() then use.card = card; return end
    self:sort(self.enemies, "hp")
    for _, enemy in ipairs(self.enemies) do
        if self:damageIsEffective(enemy) then use.card = card; use.to:append(enemy); return end
    end
end
sgs.ai_use_priority.hlxg_quhuCard = 2.5
sgs.ai_fill_skill.hljx_quhu = function(self)
    if self.player:canPindian() then return sgs.Card_Parse("#hljx_quhuCard:.:") end
end
sgs.ai_skill_use_func["#hljx_quhuCard"] = function(card, use, self)
    local maximum = self:getMaxCard(); if not maximum then return end
    for _, enemy in ipairs(self.enemies) do
        if self.player:canPindian(enemy) and maximum:getNumber() >= 10 then use.card = card; use.to:append(enemy); return end
    end
end
sgs.ai_skill_playerchosen.hljx_quhu = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) and self:damageIsEffective(p) then return p end end
    return targets:first()
end
sgs.ai_skill_pindian.hljx_quhu = function(minusecard, self, requestor, maxcard) return maxcard or minusecard end
sgs.ai_use_priority.hljx_quhuCard = 3
sgs.ai_fill_skill.hlxg_kuangzuo = function(self)
    if self.player:getMark("@hlxg_kuangzuo") > 0 then return sgs.Card_Parse("#hlxg_kuangzuoCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_kuangzuoCard"] = function(card, use, self)
    local receiver = self.player
    for _, p in ipairs(self.friends) do if p:isLord() then receiver = p; break end end
    local donor
    for _, p in ipairs(self.enemies) do if p ~= receiver and not p:isNude() then donor = p; break end end
    if donor then use.card = card; use.to:append(receiver); use.to:append(donor) end
end
sgs.ai_use_priority.hlxg_kuangzuoCard = 5
sgs.ai_skill_askforag.hlxg_kuangzuo = function(self, ids)
    local best, value = ids[1], 1000
    for _, id in ipairs(ids) do local v = self:getKeepValue(sgs.Sanguosha:getCard(id)); if v < value then best = id; value = v end end
    return best
end
sgs.ai_skill_invoke.hlxg_anshu = function(self, data)
    local to = data and data:toPlayer()
    return not to or self:isFriend(to) and to:getHandcardNum() < math.min(5, to:getMaxHp())
end
sgs.ai_skill_playerchosen.hlxg_anshu = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
    return targets:first()
end
sgs.ai_skill_askforag.hlxg_anshu = function(self, ids)
    local best, value = ids[1], -1000
    for _, id in ipairs(ids) do local c = sgs.Sanguosha:getCard(id); local v = self:getUseValue(c); if v > value then best = id; value = v end end
    return best
end
sgs.ai_skill_invoke.hlxg_chengfeng = true
sgs.ai_view_as.hlxg_chengfeng = function(card, player, place, class_name)
    if player:getMark("hlxg_chengfeng-Clear") > 0 or player:getMark("hlxg_chengfeng_resolving") == 0 or not player:getPile("hlxg_kuangzuo"):contains(card:getEffectiveId()) then return end
    if class_name == "Jink" and card:isRed() then return ("jink:hlxg_chengfeng[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId()) end
    if class_name == "Nullification" and card:isBlack() then return ("nullification:hlxg_chengfeng[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId()) end
end
sgs.ai_skill_invoke.hlxg_tongyin = true

sgs.ai_cardsview_valuable.hlxg_chengfeng = function(self, class_name, player)
    if not player or player:getMark("hlxg_chengfeng-Clear") > 0 or player:getMark("hlxg_chengfeng_resolving") == 0 then return end
    for _, id in sgs.qlist(player:getPile("hlxg_kuangzuo")) do
        local card = sgs.Sanguosha:getCard(id)
        if class_name == "Jink" and card:isRed() then return ("jink:hlxg_chengfeng[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), id) end
        if class_name == "Nullification" and card:isBlack() then return ("nullification:hlxg_chengfeng[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), id) end
    end
end
end

-- ==================== c212_02
do
sgs.ai_skill_invoke.hlxg_gongxin_gexuan = true
sgs.ai_skill_askforag.hlxg_gongxin_gexuan = function(self, ids)
    local best, value = -1, -100
    for _, id in ipairs(ids) do local c = sgs.Sanguosha:getCard(id); local v = self:getUseValue(c); if v > value then best, value = id, v end end
    return best
end
sgs.ai_skill_choice.hlxg_gongxin_gexuan = function() return "obtain" end
sgs.ai_skill_invoke.hlxg_guanxing_gexuan = true
sgs.ai_skill_playerchosen.hlxg_zhiyan_gexuan = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
end
sgs.ai_fill_skill.hlxg_zhafu = function(self)
    if self.player:getMark("@hlxg_zhafu") > 0 then return sgs.Card_Parse("#hlxg_zhafuCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_zhafuCard"] = function(card, use, self)
    local best
    for _, p in ipairs(self.enemies) do if not best or p:getHandcardNum() > best:getHandcardNum() then best = p end end
    if best and best:getHandcardNum() > 2 then use.card = card; use.to:append(best) end
end
sgs.ai_use_priority.hlxg_zhafuCard = 3
sgs.ai_skill_exchange.hlxg_zhafu = function(self, pattern, max_num, min_num, expand_pile)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards, true)
    if cards[1] then return {cards[1]:getEffectiveId()} end
    return {}
end
sgs.ai_skill_use["@@hlxg_lianhua"] = function(self)
    local name = self.player:getTag("hlxg_lianhua_card"):toString()
    if name == "" then return "." end
    local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0); card:setSkillName("hlxg_lianhua")
    local use = {isDummy = true, to = sgs.SPlayerList()}
    self:useCardByClassName(card, use)
    if not use.card then card:deleteLater(); return "." end
    local names = {}; for _, p in sgs.qlist(use.to) do table.insert(names, p:objectName()) end
    local result = card:toString() .. (#names > 0 and "->" .. table.concat(names, "+") or "")
    card:deleteLater(); return result
end
sgs.ai_skill_playerchosen.hlxg_bingzheng = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) and p:getHandcardNum() + 1 == p:getHp() then return p end end
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) and p:getHandcardNum() > 0 then return p end end
    return self.player
end
sgs.ai_skill_choice.hlxg_bingzheng = function(self, choices, data)
    local p = data:toPlayer()
    if p and self:isEnemy(p) and choices:find("discard") then return "discard" end
    return "draw"
end
sgs.ai_skill_exchange.hlxg_bingzheng = function() return {} end
sgs.ai_skill_choice.hlxg_sheyan = function(self, choices, data)
    local use = data:toCardUse()
    if not use.card then return "cancel" end
    local helpful = use.card:isKindOf("ExNihilo") or use.card:isKindOf("GodSalvation") or use.card:isKindOf("AmazingGrace")
    if choices:find("remove") then
        for _, p in sgs.qlist(use.to) do if (helpful and self:isEnemy(p)) or (not helpful and self:isFriend(p)) then self.hlxg_sheyan_target = p; return "remove" end end
    end
    self.hlxg_sheyan_target = nil
    return "cancel"
end
sgs.ai_skill_playerchosen.hlxg_sheyan = function(self, targets)
    if self.hlxg_sheyan_target and targets:contains(self.hlxg_sheyan_target) then return self.hlxg_sheyan_target end
    return targets:first()
end
sgs.ai_skill_choice.hlxg_benghuai_dongzhuo = function(self)
    return self.player:getHp() > 3 and "hp" or "maxhp"
end
sgs.ai_skill_invoke.hlxg_baonve = function(self, data) local p = data:toPlayer(); return p and self:isFriend(p) and p:isWounded() end
sgs.ai_view_as.hlxg_jiuchi = function(card, player, place)
    if place == sgs.Player_PlaceHand and card:isBlack() then return "analeptic:hlxg_jiuchi[" .. card:getSuitString() .. ":" .. card:getNumberString() .. "]=" .. card:getEffectiveId() end
end
sgs.ai_fill_skill.hlxg_jiuchi = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByUseValue(cards, true)
    for _, c in ipairs(cards) do if c:isBlack() and self:getUseValue(c) < 5 then return sgs.Card_Parse(sgs.ai_view_as.hlxg_jiuchi(c, self.player, sgs.Player_PlaceHand)) end end
end
end

-- ==================== c212_03
do
-- c212_03: conservative decisions, no AI for passive locked effects.
sgs.ai_skill_choice.hljx_benghuai = function(self)
    if self.player:getHp() > 2 or self.player:getMaxHp() <= 2 then return "hp" end
    return "maxhp"
end
sgs.ai_skill_invoke.hljx_baonve = true
sgs.ai_skill_invoke.hljx_jiuchi = true
sgs.ai_skill_invoke.hlxg_weicheng = true
local function c21203_lowcard(self, zone)
    local cards = sgs.QList2Table(self.player:getCards(zone)); self:sortByKeepValue(cards)
    return cards[1]
end
sgs.ai_fill_skill.hljx_jiuchi = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByUseValue(cards, true)
    for _, c in ipairs(cards) do
        if c:getSuit() == sgs.Card_Spade and self:getUseValue(c) < 6 then
            return sgs.Card_Parse("analeptic:hljx_jiuchi[" .. c:getSuitString() .. ":" .. c:getNumberString() .. "]=" .. c:getEffectiveId())
        end
    end
end
sgs.ai_view_as.hljx_jiuchi = function(card, player, card_place, class_name)
    if class_name == "Analeptic" and card:getSuit() == sgs.Card_Spade
        and (card_place == sgs.Player_PlaceHand or card_place == sgs.Player_PlaceEquip) then
        return "analeptic:hljx_jiuchi[" .. card:getSuitString() .. ":" .. card:getNumberString() .. "]=" .. card:getEffectiveId()
    end
end
sgs.ai_fill_skill.hlxg_humei = function(self)
    local p = self.player
    if p:getMark("hlxg_humei_used-PlayClear") < p:getMark("hlxg_humei_damage-PlayClear")
        and (p:getMark("hlxg_humei_draw-Clear") == 0 or p:getMark("hlxg_humei_give-Clear") == 0 or p:getMark("hlxg_humei_recover-Clear") == 0) then
        return sgs.Card_Parse("#hlxg_humeiCard:.:")
    end
end
sgs.ai_skill_use_func["#hlxg_humeiCard"] = function(card, use, self)
    self.c21203_humei = nil
    if self.player:getMark("hlxg_humei_recover-Clear") == 0 then
        self:sort(self.friends, "hp")
        for _, p in ipairs(self.friends) do
            if p:isWounded() then self.c21203_humei = "recover"; use.card = card; use.to:append(p); return end
        end
    end
    if self.player:getMark("hlxg_humei_draw-Clear") == 0 then
        self.c21203_humei = "draw"; use.card = card; use.to:append(self.player); return
    end
    if self.player:getMark("hlxg_humei_give-Clear") == 0 then
        self:sort(self.enemies, "card")
        for _, p in ipairs(self.enemies) do
            if not p:isNude() then self.c21203_humei = "give"; use.card = card; use.to:append(p); return end
        end
    end
end
sgs.ai_skill_choice.hlxg_humei = function(self, choices)
    if self.c21203_humei and choices:find(self.c21203_humei, 1, true) then return self.c21203_humei end
    return choices:split("+")[1]
end
sgs.ai_skill_discard.hlxg_humei = function(self)
    local c = c21203_lowcard(self, "he"); return c and {c:getEffectiveId()} or {}
end
sgs.ai_use_priority.hlxg_humeiCard = 6
sgs.ai_fill_skill.hlxg_jiaoxia = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByUseValue(cards, true)
    for _, c in ipairs(cards) do
        if not c:isKindOf("Peach") and not c:isKindOf("Slash") and self:getUseValue(c) < 6 then
            return sgs.Card_Parse("slash:hlxg_jiaoxia[" .. c:getSuitString() .. ":" .. c:getNumberString() .. "]=" .. c:getEffectiveId())
        end
    end
end
sgs.ai_skill_use["@@hlxg_jiaoxia"] = function(self)
    local id = self.player:getMark("hlxg_jiaoxia_original") - 1
    if id < 0 then return "." end
    local card = sgs.Sanguosha:getCard(id)
    if not card then return "." end
    local use = {isDummy = true, to = sgs.SPlayerList()}
    self:useCardByClassName(card, use)
    if not use.card then return "." end
    local targets = {}
    for _, p in sgs.qlist(use.to) do table.insert(targets, p:objectName()) end
    if #targets == 0 then return card:toString() end
    return card:toString() .. "->" .. table.concat(targets, "+")
end
sgs.ai_fill_skill.hlxg_daoshu = function(self)
    if self.player:getMark("hlxg_daoshu_used-PlayClear") == 0 then return sgs.Card_Parse("#hlxg_daoshuCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_daoshuCard"] = function(card, use, self)
    self:sort(self.enemies, "hp")
    for _, p in ipairs(self.enemies) do
        if not p:isKongcheng() and self:damageIsEffective(p) then use.card = card; use.to:append(p); return end
    end
end
sgs.ai_skill_choice.hlxg_daoshu = function(self, choices)
    return choices:find("spade", 1, true) and "spade" or choices:split("+")[1]
end
sgs.ai_skill_playerchosen.hlxg_daoshu = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
    return targets:first()
end
sgs.ai_skill_discard.hlxg_daoshu = function(self)
    local c = c21203_lowcard(self, "h"); return c and {c:getEffectiveId()} or {}
end
sgs.ai_use_priority.hlxg_daoshuCard = 3
end

-- ==================== c212_04
do
sgs.ai_skill_invoke.hlxg_shoucheng = function(self, data)
    local p = data:toPlayer()
    return p and self:isFriend(p)
end
sgs.ai_skill_invoke.hlxg_shengxi = true
sgs.ai_skill_askforag.hlxg_jianyi = function(self, ids)
    local best, value = ids[1], -1000
    for _, id in ipairs(ids) do
        local c = sgs.Sanguosha:getCard(id)
        if c and self:getUseValue(c) > value then best = id; value = self:getUseValue(c) end
    end
    return best
end
sgs.ai_fill_skill.hlxg_shangyi = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if not self.player:isJilei(c) then return sgs.Card_Parse("#hlxg_shangyiCard:" .. c:getEffectiveId() .. ":") end
    end
end
sgs.ai_skill_use_func["#hlxg_shangyiCard"] = function(card, use, self)
    self:sort(self.enemies, "handcard")
    for _, p in ipairs(self.enemies) do
        if not p:isKongcheng() then use.card = card; use.to:append(p); return end
    end
end
sgs.ai_skill_choice.hlxg_shangyi = function(self, choices) return "obtain" end
sgs.ai_skill_cardchosen.hlxg_shangyi = function(self, who)
    local best, value
    for _, c in sgs.qlist(who:getHandcards()) do
        local v = self:getUseValue(c) + (c:isBlack() and 3 or 0)
        if not value or v > value then best = c:getEffectiveId(); value = v end
    end
    return best or -1
end
sgs.ai_skill_exchange.hlxg_shangyi = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    return cards[1] and {cards[1]:getEffectiveId()} or {}
end
sgs.ai_use_priority.hlxg_shangyiCard = 4
sgs.ai_fill_skill.hlxg_shenshi = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    if cards[1] then return sgs.Card_Parse("#hlxg_shenshiCard:" .. cards[1]:getEffectiveId() .. ":") end
end
sgs.ai_skill_use_func["#hlxg_shenshiCard"] = function(card, use, self)
    self:sort(self.enemies, "hp")
    for _, p in ipairs(self.enemies) do
        if self:damageIsEffective(p) and not self:needToLoseHp(p, self.player) then
            use.card = card; use.to:append(p); return
        end
    end
end
sgs.ai_skill_invoke.hlxg_shenshi = function(self, data)
    local p = data:toDamage().from
    return p and (self:isFriend(p) or self.player:getHandcardNum() < 4)
end
sgs.ai_skill_exchange.hlxg_shenshi = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    return cards[1] and {cards[1]:getEffectiveId()} or {}
end
sgs.ai_skill_playerchosen.hlxg_shenshi = function(self, targets)
    local best
    for _, p in sgs.qlist(targets) do
        if self:isFriend(p) and p:getHandcardNum() < 4 and (not best or p:getHandcardNum() < best:getHandcardNum()) then best = p end
    end
    return best
end
sgs.ai_skill_playerchosen.hlxg_jianjiang = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
end
sgs.ai_use_priority.hlxg_shenshiCard = 3
end

-- ==================== c212_05
do
for _, name in ipairs({"hlxg_xianzhou", "hljx_xianzhou"}) do
    sgs.ai_fill_skill[name] = function(self)
        if self.player:getMark("@" .. name) == 0 or #self.friends_noself == 0 then return end
        local cards = sgs.QList2Table(self.player:getHandcards())
        if #cards == 0 then return end
        self:sortByKeepValue(cards)
        local ids = {}
        if name == "hljx_xianzhou" then
            for _, c in ipairs(cards) do
                if #ids < math.max(1, self.player:getLostHp()) and not c:isKindOf("Peach") then table.insert(ids, c:getEffectiveId()) end
            end
            if #ids == 0 then return end
        end
        return sgs.Card_Parse("#" .. name .. "Card:" .. (#ids > 0 and table.concat(ids, "+") or ".") .. ":")
    end
    sgs.ai_skill_use_func["#" .. name .. "Card"] = function(card, use, self)
        for _, friend in ipairs(self.friends_noself) do
            for _, enemy in ipairs(self.enemies) do
                if friend:inMyAttackRange(enemy) and self:damageIsEffective(enemy) then use.card = card; use.to:append(friend); return end
            end
        end
    end
    sgs.ai_use_priority[name .. "Card"] = 2
    sgs.ai_skill_playerschosen[name] = function(self, targets, max_num)
        local chosen = {}
        for _, p in sgs.qlist(targets) do
            if #chosen < (max_num or targets:length()) and self:isEnemy(p) and self:damageIsEffective(p) then table.insert(chosen, p) end
        end
        return chosen
    end
end
sgs.ai_skill_choice.hljx_qieting = function(self, choices, data)
    local p = data:toPlayer()
    if p and self:isEnemy(p) and choices:find("hand") then return "hand" end
    return "draw"
end
sgs.ai_skill_askforag.hljx_qieting = function(self, ids)
    local best, value = ids[1], -100
    for _, id in ipairs(ids) do
        local v = self:getUseValue(sgs.Sanguosha:getCard(id))
        if v > value then best, value = id, v end
    end
    return best
end
sgs.ai_skill_cardask["@hljx_beige"] = function(self, data)
    local d = data:toDamage()
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if not self.player:isJilei(c) and ((c:isRed() and d.to and self:isFriend(d.to))
            or (d.from and self:isEnemy(d.from) and (c:getSuit() == sgs.Card_Club or c:getSuit() == sgs.Card_Spade and d.from:faceUp()))) then
            return "$" .. c:getEffectiveId()
        end
    end
    return "."
end
end

-- ==================== c212_06
do
local function hlc212_friend(self, targets)
    local list = sgs.QList2Table(targets); self:sort(list, "handcard")
    for _, p in ipairs(list) do if self:isFriend(p) then return p end end
end
sgs.ai_skill_playerchosen.hlxg_chenqing = function(self, targets)
    local dying = self.room:getCurrentDyingPlayer()
    if dying and self:isFriend(dying) then return hlc212_friend(self, targets) end
end
sgs.ai_skill_discard.hlxg_chenqing = function(self, discard_num, min_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getCards(include_equip and "he" or "h"))
    self:sortByKeepValue(cards)
    local suits, result = {}, {}
    for _, c in ipairs(cards) do
        if not self.player:isJilei(c) and c:getSuit() < sgs.Card_NoSuit and not suits[c:getSuit()] then
            suits[c:getSuit()] = true; result[#result + 1] = c:getEffectiveId()
        end
    end
    if #result == 4 then return result end
    return self:askForDiscard("dummy", discard_num, min_num, optional, include_equip)
end
sgs.ai_skill_use["@@hlxg_moshi"] = function(self)
    local name = self.player:property("hlxg_moshi_card"):toString()
    if name == "" then return "." end
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    for _, original in ipairs(cards) do
        local card = sgs.Sanguosha:cloneCard(name, original:getSuit(), original:getNumber())
        if card then
            card:addSubcard(original); card:setSkillName("hlxg_moshi")
            local use = self:aiUseCard(card)
            if use and use.card and use.to then
                local targets = {}; for _, p in sgs.qlist(use.to) do targets[#targets + 1] = p:objectName() end
                local answer = card:toString() .. (#targets > 0 and "->" .. table.concat(targets, "+") or "")
                card:deleteLater(); return answer
            end
            card:deleteLater()
        end
    end
    return "."
end
sgs.ai_skill_invoke.hlxg_pizhuan = true
sgs.ai_skill_invoke.hlxg_tongbo = true
sgs.ai_skill_invoke.hlxg_tongbo_give = function(self) return #self.friends_noself > 0 end
sgs.ai_skill_discard.hlxg_tongbo = function(self)
    -- Conservatively keep the current books; zero cards is a legal exchange.
    return {}
end
sgs.ai_skill_playerchosen.hlxg_tongbo = function(self, targets)
    return hlc212_friend(self, targets) or targets:first()
end
sgs.ai_skill_askforag.hlxg_tongbo = function(self, ids)
    local best, value
    for _, id in ipairs(ids) do
        local v = self:getKeepValue(sgs.Sanguosha:getCard(id))
        if not value or v > value then best, value = id, v end
    end
    return best or -1
end
sgs.ai_skill_playerchosen.hlxg_zhiyan_yufan = function(self, targets)
    local list = sgs.QList2Table(targets); self:sort(list, "hp")
    for _, p in ipairs(list) do if self:isFriend(p) and p:isWounded() then return p end end
    return hlc212_friend(self, targets)
end
sgs.ai_skill_invoke.hlxg_zongxuan = function(self) return #self.friends_noself > 0 end
sgs.ai_skill_playerchosen.hlxg_zongxuan = function(self, targets)
    return hlc212_friend(self, targets) or targets:first()
end
sgs.ai_skill_askforag.hlxg_zongxuan = function(self, ids)
    if self.player:hasFlag("hlxg_zongxuan_top") then return -1 end
    return sgs.ai_skill_askforag.hlxg_tongbo(self, ids)
end
end

-- ==================== c213_01
do
local function c213_give_invoke(self)
    for _, p in ipairs(self.friends_noself or {}) do if p:isAlive() then return true end end
    return false
end
local function c213_give_target(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
    return targets:first()
end
sgs.ai_skill_invoke.hlxg_weidi = c213_give_invoke
sgs.ai_skill_invoke.hljx_weidi = c213_give_invoke
sgs.ai_skill_playerchosen.hlxg_weidi = c213_give_target
sgs.ai_skill_playerchosen.hljx_weidi = c213_give_target
sgs.ai_skill_invoke.hljx_weidi_return = function(self, data)
    local p = data:toPlayer()
    return p and self:isEnemy(p)
end
sgs.ai_skill_askforag.hlxg_weidi = function(self, ids)
    local best, value = ids[1], -10000
    for _, id in ipairs(ids) do
        local c = sgs.Sanguosha:getCard(id)
        if c then local v = self:getUseValue(c); if v > value then best, value = id, v end end
    end
    return best or -1
end
sgs.ai_skill_choice.hljx_weidi = function(self, choices)
    local options = choices:split("+")
    return options[1]
end
sgs.ai_skill_choice.hlxg_canxi = function(self, choices)
    local options = choices:split("+")
    if table.contains(options, "wangsheng") then
        local kingdom = self.player:getTag("hlxg_canxi_active"):toString()
        local score = 0
        for _, p in sgs.qlist(self.room:getAlivePlayers()) do
            if p:getKingdom() == kingdom then score = score + (self:isFriend(p) and 1 or -1) end
        end
        return score >= 0 and "wangsheng" or "xiangsi"
    end
    if table.contains(options, self.player:getKingdom()) then return self.player:getKingdom() end
    return options[1]
end
end

-- ==================== c213_02
do
local function c213_ai_archery(self, name, mode)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    local ids = {}
    for _, c in ipairs(cards) do
        local key = mode == 2 and (c:isRed() and "red" or (c:isBlack() and "black" or "none")) or c:getSuitString()
        if not c:isKindOf("Peach") and not self.player:isJilei(c)
            and (mode == 0 or self.player:getMark(name .. "_" .. key .. "-Clear") == 0) then
            table.insert(ids, c:getEffectiveId())
            if #ids == 2 then break end
        end
    end
    if #ids ~= 2 then return nil end
    local c = sgs.Card_Parse("archery_attack:" .. name .. "[no_suit:0]=" .. table.concat(ids, "+"))
    if not c or not c:isAvailable(self.player) then return nil end
    if self:getAoeValue(c) <= 0 then return nil end
    return c
end
sgs.ai_skill_use["@@hlxg_luanji_yuanshao"] = function(self)
    local c = c213_ai_archery(self, "hlxg_luanji_yuanshao", 0)
    return c and c:toString() or "."
end
sgs.ai_fill_skill.hljx_luanji = function(self) return c213_ai_archery(self, "hljx_luanji", 1) end
sgs.ai_fill_skill.hlxg_luanji_yuanshao2 = function(self) return c213_ai_archery(self, "hlxg_luanji_yuanshao2", 2) end
sgs.ai_skill_invoke.hlxg_luanji_yuanshao2 = function(self, data)
    local to = data:toPlayer()
    return to and self:isEnemy(to)
end
for _, name in ipairs({"hlxg_xueyi_yuanshao", "hljx_xueyi"}) do
    sgs.ai_skill_invoke[name] = true
    sgs.ai_fill_skill[name] = function(self)
        if self.player:hasLordSkill(name) and self.player:isWounded() and self.player:getMark("&" .. name) > 0 then
            return sgs.Card_Parse("#" .. name .. "Card:.:")
        end
    end
    sgs.ai_skill_use_func["#" .. name .. "Card"] = function(card, use) use.card = card end
    sgs.ai_use_priority[name .. "Card"] = 6
end
end

-- ==================== c213_03
do
-- Reused cunmu / yinshicai retain their existing engine AI.
sgs.ai_fill_skill.hlxg_chenglve = function(self)
    return sgs.Card_Parse("#hlxg_chenglveCard:.:")
end
sgs.ai_skill_use_func["#hlxg_chenglveCard"] = function(card, use, self) use.card = card end
sgs.ai_use_priority.hlxg_chenglveCard = 7
sgs.ai_skill_discard.hlxg_chenglve = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if not self.player:isJilei(card) then return {card:getEffectiveId()} end
    end
    return {}
end
sgs.ai_fill_skill.hljx_huchi = function(self)
    if self.player:getMark("&hljx_huchi") > 0 then return sgs.Card_Parse("#hljx_huchiCard:.:") end
end
sgs.ai_skill_use_func["#hljx_huchiCard"] = function(card, use, self) use.card = card end
sgs.ai_use_priority.hljx_huchiCard = 8
sgs.ai_skill_invoke.hljx_luoyi = function(self)
    return self:getCardsNum("Slash") + self:getCardsNum("Duel") > 0 and #(self.enemies or {}) > 0
end
sgs.ai_skill_invoke.hlxg_jiaowang = function(self)
    if self.player:getHp() <= 2 then return false end
    local value = 0
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if self:isEnemy(p) then value = value + 1 elseif self:isFriend(p) then value = value - 1 end
    end
    return value > 0
end
sgs.ai_skill_choice.hlxg_xiaoyan = function(self, choices, data)
    local owner = self.room:findPlayerByObjectName(data:toString())
    if choices:find("give") and self.player:isWounded() and owner and self:isFriend(owner) then return "give" end
    return "draw"
end
sgs.ai_skill_discard.hlxg_xiaoyan = function(self, max_num, min_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getCards(include_equip and "he" or "h"))
    self:sortByKeepValue(cards)
    if cards[1] then return {cards[1]:getEffectiveId()} end
    return {}
end
sgs.ai_fill_skill.hlxg_aoshi = function(self)
    if self.player:getKingdom() ~= "qun" then return end
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    if not cards[1] then return end
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if p:hasLordSkill("hlxg_aoshi") and p:getMark("hlxg_aoshi_attached") == 0 and self:isFriend(p) then
            return sgs.Card_Parse("#hlxg_aoshiCard:" .. cards[1]:getEffectiveId() .. ":")
        end
    end
end
sgs.ai_skill_use_func["#hlxg_aoshiCard"] = function(card, use, self)
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if p:hasLordSkill("hlxg_aoshi") and p:getMark("hlxg_aoshi_attached") == 0 and self:isFriend(p) then
            use.card = card; if use.to then use.to:append(p) end; return
        end
    end
end
sgs.ai_use_priority.hlxg_aoshiCard = 4
-- Zero targets is explicitly permitted by 至多X; favor cycling low-value materials.
local function c213_ai_zongshi(self)
    local cards = sgs.QList2Table(self.player:getHandcards())
    local best, count = nil, 0
    for _, shown in ipairs(cards) do
        if shown:isKindOf("BasicCard") or shown:isNDTrick() then
            local n = 0
            for _, c in ipairs(cards) do if c ~= shown and c:getSuit() == shown:getSuit() then n = n + 1 end end
            if n > count and self:getKeepValue(shown) < 5 then best, count = shown, n end
        end
    end
    if best then return sgs.Card_Parse("#hlxg_zongshi_yuanshao3Card:" .. best:getEffectiveId() .. ":") end
end
sgs.ai_fill_skill.hlxg_zongshi_yuanshao3 = function(self)
    if not self.player:hasUsed("hlxg_zongshi_yuanshao3Card") then return c213_ai_zongshi(self) end
end
sgs.ai_skill_use_func["#hlxg_zongshi_yuanshao3Card"] = function(card, use, self) use.card = card end
sgs.ai_skill_use["@@hlxg_zongshi_yuanshao3"] = function(self)
    local card = c213_ai_zongshi(self)
    return card and card:toString() or "."
end
sgs.ai_use_priority.hlxg_zongshi_yuanshao3Card = 6
end

-- ==================== c213_04
do
sgs.ai_skill_playerchosen.hlxg_yechou = function(self, targets)
    local enemies = {}
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then table.insert(enemies, p) end end
    self:sort(enemies, "hp")
    return enemies[1]
end
sgs.ai_skill_invoke.hlxg_biaozhao = true
sgs.ai_skill_playerchosen.hlxg_biaozhao = function(self, targets)
    local list = sgs.QList2Table(targets)
    if #list == self.room:alivePlayerCount() then
        self:sort(list, "handcard", true)
        for _, p in ipairs(list) do if self:isFriend(p) then return p end end
    else
        self:sort(list, "defense")
        for _, p in ipairs(list) do if self:isEnemy(p) then return p end end
    end
    return list[1]
end
sgs.ai_skill_invoke.hlxg_guanxing_zhugeliang = true
sgs.ai_skill_invoke.hljx_guanxing = true
sgs.ai_skill_askforag.hljx_guanxing = function(self, ids)
    local cards = {}
    for _, id in ipairs(ids) do table.insert(cards, sgs.Sanguosha:getCard(id)) end
    self:sortByUseValue(cards, true)
    return cards[1] and cards[1]:getEffectiveId() or -1
end
sgs.ai_fill_skill.hljx_guanxing = function(self)
    if not self.player:getPile("hljx_guanxing_star"):isEmpty() then return sgs.Card_Parse("#hljx_guanxingCard:.:") end
end
sgs.ai_skill_use_func["#hljx_guanxingCard"] = function(card, use, self) use.card = card end
sgs.ai_use_priority.hljx_guanxingCard = 8
end

-- ==================== c213_05
do
sgs.ai_skill_invoke.hlxg_huoji_zhugeliang2 = true
sgs.ai_skill_invoke.hlxg_dawu = true
sgs.ai_skill_askforag.hlxg_huoji_zhugeliang2 = function(self, ids)
    local suit = self.player:getTag("hlxg_huoji_zhugeliang2_suit"):toInt()
    for _, id in ipairs(ids) do if sgs.Sanguosha:getCard(id):getSuit() == suit then return id end end
    return -1
end
sgs.ai_skill_askforag.hlxg_qixing = function(self, ids)
    local best, value = -1, -100
    for _, id in ipairs(ids) do local v = self:getKeepValue(sgs.Sanguosha:getCard(id)); if v > value then best, value = id, v end end
    return best
end
sgs.ai_skill_discard.hlxg_qixing = function() return {} end
sgs.ai_skill_askforag.hlxg_dawu = function(self, ids)
    local best, value = -1, 100
    for _, id in ipairs(ids) do local v = self:getKeepValue(sgs.Sanguosha:getCard(id)); if v < value then best, value = id, v end end
    return best
end
sgs.ai_skill_askforag.hlxg_aocai = function(self, ids)
    if #ids == 0 then return -1 end
    local best, value = ids[1], -100
    for _, id in ipairs(ids) do local v = self:getUseValue(sgs.Sanguosha:getCard(id)); if v > value then best, value = id, v end end
    return best
end
sgs.ai_view_as.hlxg_kanpo = function(card, player, place)
    if place == sgs.Player_PlaceHand and card:isBlack() then
        return ("nullification:hlxg_kanpo[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId())
    end
end
sgs.ai_fill_skill.hlxg_huoji_zhugeliang2 = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isRed() and not c:isKindOf("Peach") and not c:isKindOf("ExNihilo") then
            return sgs.Card_Parse(("fire_attack:hlxg_huoji_zhugeliang2[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(), c:getEffectiveId()))
        end
    end
end
sgs.ai_cardsview_valuable.hlxg_aocai = function(self, class_name, player)
    if player:getPhase() ~= sgs.Player_NotActive then return end
    local names = {Slash = "slash", Jink = "jink", Peach = "peach", Analeptic = "analeptic"}
    if names[class_name] then return names[class_name] .. ":hlxg_aocai[no_suit:0]=." end
end
sgs.ai_skill_use["@@hlxg_kuangfeng"] = function(self)
    local stars = sgs.QList2Table(self.player:getPile("hlxg_qixing_stars"))
    if #stars == 0 then return "." end
    self:sort(self.enemies, "hp")
    local targets, ids = {}, {}
    for _, p in ipairs(self.enemies) do
        if #ids < #stars and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then
            table.insert(targets, p:objectName()); table.insert(ids, stars[#ids + 1])
        end
    end
    if #ids == 0 then return "." end
    return "#hlxg_kuangfengCard:" .. table.concat(ids, "+") .. ":->" .. table.concat(targets, "+")
end
sgs.ai_fill_skill.hlxg_duwu = function(self)
    if self.player:getMark("hlxg_duwu-Clear") > 0 then return end
    return sgs.Card_Parse("#hlxg_duwuCard:.:hlxg_duwu")
end
sgs.ai_skill_use_func["#hlxg_duwuCard"] = function(card, use, self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    self:sort(self.enemies, "hp")
    for _, p in ipairs(self.enemies) do
        local n = math.max(0, p:getHp())
        if self.player:inMyAttackRange(p) and n <= 2 and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then
            local ids = {}
            for _, c in ipairs(cards) do
                if #ids < n and not self.player:isJilei(c) and not c:isKindOf("Peach") and self:getKeepValue(c) < 5 then table.insert(ids, c:getEffectiveId()) end
            end
            if #ids == n then
                use.card = sgs.Card_Parse("#hlxg_duwuCard:" .. (#ids == 0 and "." or table.concat(ids, "+")) .. ":hlxg_duwu")
                if use.to then use.to:append(p) end
                return
            end
        end
    end
end
sgs.ai_use_priority.hlxg_duwuCard = 2.5
end

-- ==================== c213_06
do
sgs.ai_skill_invoke.hlxg_qirang = true
sgs.ai_skill_invoke.hlxg_mingzhe = true
sgs.ai_skill_invoke.hlxg_zuilun = true
sgs.ai_skill_playerschosen.hlxg_hongyuan = function(self, targets)
    local friends = {}
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then table.insert(friends, p) end end
    self:sort(friends, "handcard")
    local result = {}
    for i = 1, math.min(2, #friends) do table.insert(result, friends[i]) end
    return result
end
sgs.ai_skill_discard.hlxg_yuhua = function(self)
    local ids = {}
    for _, card in sgs.qlist(self.player:getHandcards()) do
        if not card:isKindOf("BasicCard") then table.insert(ids, card:getEffectiveId()) end
    end
    return ids
end
sgs.ai_skill_askforag.hlxg_yuhua = function(self, ids)
    local cards = {}
    for _, id in ipairs(ids) do table.insert(cards, sgs.Sanguosha:getCard(id)) end
    self:sortByUseValue(cards, true)
    return cards[1] and cards[1]:getEffectiveId() or ids[1]
end
sgs.ai_skill_choice.hlxg_yuhua = function() return "bottom" end
sgs.ai_skill_invoke.hlxg_huanshi = function(self, data)
    local judge = data:toJudge()
    return judge and judge.who and self:isFriend(judge.who) and self:needRetrial(judge)
end
sgs.ai_skill_askforag.hlxg_huanshi = function(self, ids)
    local judge = self.player:getTag("HuanshiJudge"):toJudge()
    local cards = {}
    for _, id in ipairs(ids) do table.insert(cards, sgs.Sanguosha:getCard(id)) end
    if judge then
        local id = self:getRetrialCardId(cards, judge)
        if id and id >= 0 then return id end
    end
    self:sortByKeepValue(cards)
    return cards[1] and cards[1]:getEffectiveId() or ids[1]
end
sgs.ai_skill_askforag.hlxg_zuilun = function(self, ids)
    local cards = {}
    for _, id in ipairs(ids) do table.insert(cards, sgs.Sanguosha:getCard(id)) end
    self:sortByUseValue(cards)
    return cards[1] and cards[1]:getEffectiveId() or ids[1]
end
sgs.ai_skill_playerchosen.hlxg_zuilun = function(self, targets)
    local list = sgs.QList2Table(targets)
    self:sort(list, "hp")
    for _, p in ipairs(list) do if self:isEnemy(p) then return p end end
    return list[1]
end
end

-- ==================== c213_07
do
sgs.ai_skill_playerchosen.hlxg_nuanhui = function(self, targets)
    local best, score
    for _, p in sgs.qlist(targets) do
        if self:isFriend(p) then
            local value = math.max(1, p:getEquips():length()) + (p:isWounded() and 2 or 0)
            if not score or value > score then best, score = p, value end
        end
    end
    return best
end
sgs.ai_skill_choice.hlxg_nuanhui = function(self, choices)
    for _, name in ipairs(choices:split("+")) do
        if name ~= "cancel" then
            local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
            if c then
                c:setSkillName("hlxg_nuanhui")
                local use = self:aiUseCard(c)
                c:deleteLater()
                if use and use.card then return name end
            end
        end
    end
    return "cancel"
end
sgs.ai_skill_use["@@#hlxg_nuanhui_use"] = function(self)
    local c = sgs.Sanguosha:cloneCard(self.player:property("hlxg_nuanhui_card"):toString(), sgs.Card_NoSuit, 0)
    if not c then return "." end
    c:setSkillName("hlxg_nuanhui")
    local use = self:aiUseCard(c)
    local result = "."
    if use and use.card then
        local targets = {}
        if use.to then for _, p in sgs.qlist(use.to) do table.insert(targets, p:objectName()) end end
        result = c:toString() .. (#targets > 0 and "->" .. table.concat(targets, "+") or "")
    end
    c:deleteLater()
    return result
end
sgs.ai_fill_skill.hlxg_qiongying = function(self)
    local from, card, to = self:moveField()
    if from and card and to then return sgs.Card_Parse("#hlxg_qiongyingCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_qiongyingCard"] = function(card, use, self) use.card = card end
sgs.ai_use_priority.hlxg_qiongyingCard = 4
sgs.ai_skill_playerchosen.hlxg_qiongying_from = function(self, targets)
    local from = self:moveField()
    if from and targets:contains(from) then return from end
    return targets:first()
end
sgs.ai_skill_cardchosen.hlxg_qiongying = function(self, who, flags)
    local from, card = self:moveField()
    if from == who and card then return card:getEffectiveId() end
    local cards = who:getCards(flags)
    if not cards:isEmpty() then return cards:first():getEffectiveId() end
    return -1
end
sgs.ai_skill_playerchosen.hlxg_qiongying_to = function(self, targets)
    local from, card, to = self:moveField()
    if to and targets:contains(to) then return to end
    return targets:first()
end
sgs.ai_skill_invoke.hlxg_juyi = true
sgs.ai_skill_choice.hlxg_benghuai_zhugedan = function(self)
    if self.player:getHp() <= 1 and self.player:getMaxHp() > 1 then return "losemaxhp" end
    if self.player:getMaxHp() > self.player:getHp() then return "losemaxhp" end
    return "losehp"
end
end

-- ==================== c214_01
do
sgs.ai_skill_invoke.hljx_biyue = true
sgs.ai_skill_invoke.hlxg_pianyi = true
sgs.ai_skill_invoke.hlxg_huoxin = true
sgs.ai_skill_invoke.hlxg_meihun = true
local function c214_enemy(self, targets)
    local chosen
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) and (not chosen or p:getHandcardNum() > chosen:getHandcardNum()) then chosen = p end
    end
    return chosen or targets:first()
end
sgs.ai_skill_playerchosen.hlxg_lihun = c214_enemy
sgs.ai_skill_playerchosen.hlxg_meihun = c214_enemy
sgs.ai_skill_playerchosen.hljx_lijian = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
    return targets:first()
end
sgs.ai_skill_choice.hlxg_huoxin = function() return "give" end
sgs.ai_skill_choice.hlxg_huoxin_suit = function(self, choices)
    for _, suit in ipairs({"heart", "spade", "diamond", "club"}) do
        if choices:find(suit, 1, true) then return suit end
    end
    return choices:split("+")[1]
end
sgs.ai_skill_choice.hlxg_meihun_suit = function() return "heart" end
local function c214_cost(self, name)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if not self.player:isJilei(c) and not c:isKindOf("Peach") then
            return sgs.Card_Parse("#" .. name .. "Card:" .. c:getEffectiveId() .. ":")
        end
    end
end
sgs.ai_fill_skill.hljx_lijian = function(self)
    if self.player:usedTimes("#hljx_lijianCard") < 2 then return c214_cost(self, "hljx_lijian") end
end
sgs.ai_skill_use_func["#hljx_lijianCard"] = function(card, use, self)
    local candidates = {}
    for _, p in ipairs(self.enemies) do
        if p:getMark("hljx_lijian_lost-Clear") == 0 then table.insert(candidates, p) end
    end
    if #candidates >= 2 then use.card = card; use.to:append(candidates[1]); use.to:append(candidates[2]) end
end
sgs.ai_use_priority.hljx_lijianCard = 3
sgs.ai_fill_skill.hlxg_lihun = function(self)
    if self.player:hasUsed("#hlxg_lihunCard") then return end
    for _, p in ipairs(self.enemies) do
        if p:getHandcardNum() > math.max(0, p:getHp()) + 1 then return sgs.Card_Parse("#hlxg_lihunCard:.:") end
    end
end
sgs.ai_skill_use_func["#hlxg_lihunCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hlxg_lihunCard = 6
sgs.ai_fill_skill.hlxg_huoxin = function(self)
    if not self.player:hasUsed("#hlxg_huoxinCard") then return c214_cost(self, "hlxg_huoxin") end
end
sgs.ai_skill_use_func["#hlxg_huoxinCard"] = function(card, use, self)
    local candidates = {}
    for _, p in ipairs(self.enemies) do if not p:isKongcheng() then table.insert(candidates, p) end end
    for i = 1, #candidates do
        for j = i + 1, #candidates do
            if candidates[i]:canPindian(candidates[j]) then
                use.card = card; use.to:append(candidates[i]); use.to:append(candidates[j]); return
            end
        end
    end
end
sgs.ai_use_priority.hlxg_huoxinCard = 2
sgs.ai_skill_discard.hlxg_lihun = function(self, discard_num, min_num, optional, include_equip)
    return self:askForDiscard("dummy", discard_num, min_num, optional, include_equip)
end
end

-- ==================== c214_02
do
local function c214_02_enemy(self, targets)
    local list = sgs.QList2Table(targets)
    self:sort(list, "defense")
    for _, p in ipairs(list) do if self:isEnemy(p) then return p end end
    return nil
end
sgs.ai_skill_playerchosen.hlxg_qixi_heqi = c214_02_enemy
sgs.ai_skill_playerchosen.hlxg_xuanfeng = c214_02_enemy
sgs.ai_skill_choice.hlxg_shanxi = function(self, choices, data)
    if choices:find("other", 1, true) then return "other" end
    return "finish"
end
sgs.ai_fill_skill.hlxg_shanxi = function(self)
    if not self.player:hasUsed("#hlxg_shanxiCard") then return sgs.Card_Parse("#hlxg_shanxiCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_shanxiCard"] = function(card, use, self)
    local enemies = self.enemies or {}
    self:sort(enemies, "defense")
    for _, p in ipairs(enemies) do
        if not p:inMyAttackRange(self.player) and not p:isKongcheng() then
            use.card = card; if use.to then use.to:append(p) end; return
        end
    end
end
sgs.ai_use_priority.hlxg_shanxiCard = 4
sgs.ai_fill_skill.hlxg_luanwu = function(self)
    if self.player:getMark("@hlxg_luanwu") > 0 then return sgs.Card_Parse("#hlxg_luanwuCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_luanwuCard"] = function(card, use, self)
    local score = 0
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        local weight = p:getHp() <= 1 and 2 or 1
        if self:isEnemy(p) then score = score + weight elseif self:isFriend(p) then score = score - weight end
    end
    if score > 1 then use.card = card end
end
sgs.ai_use_priority.hlxg_luanwuCard = 2
end

-- ==================== c214_03
do
-- Conservative AI; passive compulsory skills need no decisions.
sgs.ai_fill_skill.hljx_luanwu = function(self)
    if self.player:getMark("@hljx_luanwu") > 0 and #self.enemies > #self.friends_noself then
        return sgs.Card_Parse("#hljx_luanwuCard:.:")
    end
end
sgs.ai_skill_use_func["#hljx_luanwuCard"] = function(card, use, self) use.card = card end
sgs.ai_use_priority.hljx_luanwuCard = 2
sgs.ai_skill_use["@@hljx_luanwu_slash"] = function(self)
    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
    slash:setSkillName("hljx_luanwu"); slash:setFlags("hljx_luanwu_extra")
    local use = {isDummy = true, to = sgs.SPlayerList()}
    self:useBasicCard(slash, use)
    slash:deleteLater()
    if use.card and not use.to:isEmpty() then
        local names = {}; for _, p in sgs.qlist(use.to) do table.insert(names, p:objectName()) end
        return "slash:hljx_luanwu[no_suit:0]=.->" .. table.concat(names, "+")
    end
    return "."
end
sgs.ai_skill_playerchosen.hljx_wansha = function(self, targets)
    local enemies = {}; for _, p in sgs.qlist(targets) do if self:isEnemy(p) then table.insert(enemies, p) end end
    self:sort(enemies, "hp"); return enemies[1]
end
sgs.ai_fill_skill.hlxg_yongdi = function(self)
    if self.player:getMark("@hlxg_yongdi") > 0 then return sgs.Card_Parse("#hlxg_yongdiCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_yongdiCard"] = function(card, use, self)
    local mh, hp, hand = math.huge, math.huge, math.huge
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        mh = math.min(mh, p:getMaxHp()); hp = math.min(hp, p:getHp()); hand = math.min(hand, p:getHandcardNum())
    end
    local best, score
    for _, p in ipairs(self.friends) do
        local s = (p:getMaxHp() == mh and 2 or 0) + (p:getHp() == hp and p:isWounded() and 2 or 0)
            + (p:getHandcardNum() == hand and math.min(p:getMaxHp(), 5) or 0)
        if s > (score or 0) then best, score = p, s end
    end
    if best then use.card = card; use.to:append(best) end
end
sgs.ai_use_priority.hlxg_yongdiCard = 5
sgs.ai_fill_skill.hlxg_jianshu = function(self)
    if self.player:getMark("hlxg_jianshu-PlayClear") > 0 or self.player:isKongcheng() then return end
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if self:getKeepValue(c) < 5 then return sgs.Card_Parse("#hlxg_jianshuCard:" .. c:getEffectiveId() .. ":") end
    end
end
sgs.ai_skill_use_func["#hlxg_jianshuCard"] = function(card, use, self)
    self:sort(self.enemies, "hp")
    for _, first in ipairs(self.enemies) do
        for _, second in ipairs(self.enemies) do
            if first ~= second and not second:isKongcheng() then
                use.card = card; use.to:append(first); use.to:append(second); return
            end
        end
    end
end
sgs.ai_use_priority.hlxg_jianshuCard = 3
sgs.ai_view_as.hlxg_longdan_zhaoyun = function(card, player, place)
    if place ~= sgs.Player_PlaceHand then return end
    local name = card:isKindOf("Jink") and "slash" or (card:isKindOf("Slash") and "jink" or nil)
    if name then return name .. ":hlxg_longdan_zhaoyun[" .. card:getSuitString() .. ":" .. card:getNumberString() .. "]=" .. card:getEffectiveId() end
end
sgs.ai_fill_skill.hlxg_longdan_zhaoyun = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByUseValue(cards, true)
    for _, c in ipairs(cards) do
        if c:isKindOf("Jink") then return sgs.Card_Parse(sgs.ai_view_as.hlxg_longdan_zhaoyun(c, self.player, sgs.Player_PlaceHand)) end
    end
end
end

-- ==================== c214_04
do
sgs.ai_skill_invoke.hljx_yajiao = true
sgs.ai_skill_playerchosen.hljx_yajiao = function(self, targets)
    local friends = {}
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then table.insert(friends, p) end end
    self:sort(friends, "handcard")
    return friends[1] or targets:first()
end
local function c214_ai_name(c, soul)
    if soul then
        return ({[sgs.Card_Heart] = "peach", [sgs.Card_Diamond] = "fire_slash",
            [sgs.Card_Club] = "jink", [sgs.Card_Spade] = "nullification"})[c:getSuit()]
    end
    if c:isKindOf("Slash") then return "jink" end
    if c:isKindOf("Jink") then return "slash" end
    if c:isKindOf("Peach") then return "analeptic" end
    if c:isKindOf("Analeptic") then return "peach" end
end
local function c214_ai_card(c, skill, soul)
    local name = c214_ai_name(c, soul)
    if name then return ("%s:%s[%s:%s]=%d"):format(name, skill, c:getSuitString(), c:getNumberString(), c:getEffectiveId()) end
end
for _, spec in ipairs({{"hljx_longdan", false}, {"hlxg_longhun", true}}) do
    local name, soul = spec[1], spec[2]
    sgs.ai_view_as[name] = function(card, player, place)
        if place ~= sgs.Player_PlaceHand and place ~= sgs.Player_PlaceEquip then return end
        return c214_ai_card(card, name, soul)
    end
    sgs.ai_fill_skill[name] = function(self)
        local cards = sgs.QList2Table(self.player:getCards("he"))
        self:sortByKeepValue(cards)
        for _, c in ipairs(cards) do
            local output = c214_ai_name(c, soul)
            if output == "slash" or output == "fire_slash" or output == "peach" and self.player:isWounded() then
                local converted = sgs.Card_Parse(c214_ai_card(c, name, soul))
                if converted and converted:isAvailable(self.player) then return converted end
            end
        end
    end
end
end

-- ==================== c214_05
do
sgs.ai_skill_invoke.hlxg_sushou = function(self)
    return self.player:getHp() > 1 or self:getCardsNum("Peach") > 0
end
sgs.ai_skill_invoke.hlxg_zhongjie = function(self, data)
    local who = data:toPlayer()
    return who and self:isFriend(who)
end
sgs.ai_skill_discard.hlxg_sushou = function(self, discard_num, min_num)
    -- Exchange is optional; keep our hand unless a safe comparison is available.
    return {}
end
sgs.ai_skill_askforag.hlxg_sushou = function(self, ids)
    local cards = {}
    for _, id in ipairs(ids) do table.insert(cards, sgs.Sanguosha:getCard(id)) end
    self:sortByKeepValue(cards, true)
    return cards[1] and cards[1]:getEffectiveId() or -1
end
local function c214_05_extra(self, targets)
    local name = self.player:hasSkill("hljx_luanzhan") and "hljx_luanzhan" or "hlxg_luanzhan"
    local card = self.player:getTag(name .. "_card"):toCard()
    if not card then return nil end
    if card:isKindOf("ExNihilo") then
        for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
    end
    return nil
end
sgs.ai_skill_playerchosen.hlxg_luanzhan = c214_05_extra
sgs.ai_skill_playerchosen.hljx_luanzhan = c214_05_extra
end

-- ==================== c214_06
do
sgs.ai_skill_invoke.hlxg_tuntian = true
sgs.ai_skill_invoke.hlxg_chijie_obtain = true
sgs.ai_skill_invoke.hlxg_chijie = function(self, data)
    local e = data:toCardEffect()
    return e.from and self:isEnemy(e.from)
end
sgs.ai_skill_invoke.hlxg_koujing_exchange = function(self, data)
    local d = data:toDamage()
    return d.from and self:isEnemy(d.from) and self.player:getHandcardNum() <= 2
end
sgs.ai_skill_exchange.hlxg_koujing = function(self, pattern, max_num, min_num)
    local ids = {}
    for _, c in sgs.qlist(self.player:getHandcards()) do
        if not c:isKindOf("Peach") and not c:isKindOf("Jink") and self:getKeepValue(c) < 5 then table.insert(ids, c:getEffectiveId()) end
    end
    return ids
end
sgs.ai_skill_discard.hlxg_tuntian = function(self, discard_num, min_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    if cards[1] and not cards[1]:isKindOf("Peach") then return {cards[1]:getEffectiveId()} end
    return {}
end
sgs.ai_fill_skill.hlxg_pingduan = function(self) return sgs.Card_Parse("#hlxg_pingduanCard:.:") end
sgs.ai_skill_use_func["#hlxg_pingduanCard"] = function(card, use, self)
    for _, p in ipairs(self.friends or {}) do
        if p:isAlive() and not p:isKongcheng() then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_use_priority.hlxg_pingduanCard = 4
sgs.ai_skill_cardask["@hlxg_pingduan_recast"] = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do if c:isKindOf("TrickCard") and self:getKeepValue(c) < 5 then return "$" .. c:getEffectiveId() end end
    return "."
end
sgs.ai_fill_skill.hlxg_yinju = function(self)
    if self.player:getMark("@hlxg_yinju") > 0 then return sgs.Card_Parse("#hlxg_yinjuCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_yinjuCard"] = function(card, use, self)
    for _, p in ipairs(self.friends_noself or {}) do
        if p:isWounded() and self.player:canSlash(p, nil, false) then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_use_priority.hlxg_yinjuCard = 7
sgs.ai_fill_skill.hlxg_jixi = function(self)
    for _, id in sgs.qlist(self.player:getPile("hlxg_field")) do
        return sgs.Card_Parse("snatch:hlxg_jixi[no_suit:0]=" .. id)
    end
end
sgs.ai_skill_exchange.hlxg_pingduan = function(self)
    local cards = sgs.QList2Table(self.player:getEquips())
    self:sortByKeepValue(cards)
    if cards[1] then return {cards[1]:getEffectiveId()} end
    return {}
end
end

-- ==================== c214_07
do
sgs.ai_skill_choice.hlxg_xianjin = function(self, choices)
    local list = choices:split("+")
    for _, choice in ipairs({"sdatyfengtian", "sdatyqingqu", "sdatyjunshan"}) do
        if table.contains(list, choice) then return choice end
    end
    return list[1]
end
sgs.ai_skill_playerchosen.hlxg_qijing = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return targets:first()
end
sgs.ai_skill_invoke.hlxg_cuixin = function(self, data)
    local p = self.room:findPlayerByObjectName(data:toString())
    if not p then return false end
    local name = self.player:getTag("hlxg_cuixin_card"):toString()
    local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
    if not card then return false end
    local good = card:isKindOf("Peach") or card:isKindOf("ExNihilo") or card:isKindOf("Analeptic")
    local bad = card:isKindOf("Slash") or card:isKindOf("Duel") or card:isKindOf("Snatch")
        or card:isKindOf("Dismantlement") or card:isKindOf("FireAttack")
    card:deleteLater()
    return good and self:isFriend(p) or bad and self:isEnemy(p)
end
sgs.ai_fill_skill.hlxg_weimeng = function(self)
    if self.player:getHp() > 0 then return sgs.Card_Parse("#hlxg_weimengCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_weimengCard"] = function(card, use, self)
    local enemies = self.enemies or {}
    self:sort(enemies, "handcard")
    for _, p in ipairs(enemies) do
        if not p:isKongcheng() then use.card = card; if use.to then use.to:append(p) end; return end
    end
end
sgs.ai_skill_discard.hlxg_weimeng = function(self, max_num, min_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    local ids = {}
    for i = 1, math.min(max_num, #cards) do table.insert(ids, cards[i]:getEffectiveId()) end
    return ids
end
sgs.ai_use_priority.hlxg_weimengCard = 4
sgs.ai_fill_skill.hlxg_qingcheng = function(self) return sgs.Card_Parse("#hlxg_qingchengCard:.:") end
sgs.ai_skill_use_func["#hlxg_qingchengCard"] = function(card, use, self)
    local own = self.player:getHandcardNum()
    for _, p in ipairs(self.enemies or {}) do
        if p:getHandcardNum() > own and p:getHandcardNum() <= own + self.player:getLostHp() then
            use.card = card; if use.to then use.to:append(p) end; return
        end
    end
end
sgs.ai_use_priority.hlxg_qingchengCard = 3
sgs.ai_fill_skill.hlxg_huoshui = function(self) return sgs.Card_Parse("#hlxg_huoshuiCard:.:") end
sgs.ai_skill_use_func["#hlxg_huoshuiCard"] = function(card, use, self)
    for _, p in ipairs(self.enemies or {}) do
        if p:getMark("hlxg_huoshui_target_" .. self.player:objectName() .. "-Clear") == 0 then
            use.card = card; if use.to then use.to:append(p) end; return
        end
    end
end
sgs.ai_skill_choice.hlxg_huoshui = function(self, choices, data)
    local list, p = choices:split("+"), self.room:findPlayerByObjectName(data:toString())
    if p and not p:isKongcheng() and table.contains(list, "hand") then return "hand" end
    if p and not p:getEquips():isEmpty() and table.contains(list, "equip") then return "equip" end
    if table.contains(list, "invalidate") then return "invalidate" end
    return list[1]
end
sgs.ai_use_priority.hlxg_huoshuiCard = 6
end

-- ==================== c215_01
do
-- c215_01: conservative decisions; locked effects need no AI.
sgs.ai_skill_invoke.hlxg_pitian = true
sgs.ai_skill_invoke.hljx_tiandu = true
sgs.ai_skill_invoke.hljx_yiji = true
local function c215_ai_discardable(self, target)
    local n = 0
    for _, c in sgs.qlist(target:getCards("he")) do
        if self.player:canDiscard(target, c:getEffectiveId()) then n = n + 1 end
    end
    return n
end
sgs.ai_fill_skill.hlxg_qiangzhi = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if self.player:canDiscard(self.player, c:getEffectiveId()) and self:getKeepValue(c) < 4 then
            for _, enemy in ipairs(self.enemies or {}) do
                if c215_ai_discardable(self, enemy) >= 2 then
                    return sgs.Card_Parse("#hlxg_qiangzhiCard:" .. c:getEffectiveId() .. ":")
                end
            end
        end
    end
    if self.player:getHp() > 2 then
        for _, enemy in ipairs(self.enemies or {}) do
            if c215_ai_discardable(self, enemy) >= 3 then return sgs.Card_Parse("#hlxg_qiangzhiCard:.:") end
        end
    end
end
sgs.ai_skill_use_func["#hlxg_qiangzhiCard"] = function(card, use, self)
    local needed = 3 - card:subcardsLength()
    self:sort(self.enemies, "handcard")
    for _, enemy in ipairs(self.enemies or {}) do
        if c215_ai_discardable(self, enemy) >= needed then
            use.card = card
            if use.to then use.to:append(enemy) end
            return
        end
    end
end
sgs.ai_use_priority.hlxg_qiangzhiCard = 3
sgs.ai_skill_yiji.hljx_yiji = function(self, ids)
    local friends = {}
    for _, p in ipairs(self.friends_noself or {}) do
        if p:isAlive() then table.insert(friends, p) end
    end
    self:sort(friends, "handcard")
    local to = friends[1]
    if not to then return nil, -1 end
    local cards = {}
    for _, id in ipairs(ids or {}) do
        local c = sgs.Sanguosha:getCard(id)
        if c then table.insert(cards, c) end
    end
    self:sortByKeepValue(cards)
    if cards[1] then return to, cards[1]:getEffectiveId() end
    return nil, -1
end
sgs.ai_fill_skill.hljx_shenglun = function(self) return sgs.Card_Parse("#hljx_shenglunCard:.:") end
sgs.ai_skill_use_func["#hljx_shenglunCard"] = function(card, use, self)
    use.card = card
    if not use.to then return end
    local others = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    self:sort(others, "handcard")
    for i = 1, math.min(2, #others) do use.to:append(others[i]) end
end
sgs.ai_skill_choice.hljx_shenglun = function(self, choices)
    if choices:find("win", 1, true) then return "win" end
    if choices:find("lose", 1, true) then
        for _, p in ipairs(self.enemies or {}) do
            if self:damageIsEffective(p) then return "lose" end
        end
        if self.player:getHp() > 2 then return "lose" end
    end
    return "cancel"
end
sgs.ai_skill_playerchosen.hljx_shenglun = function(self, targets)
    local list = sgs.QList2Table(targets)
    self:sort(list, "hp")
    for _, p in ipairs(list) do
        if self:isEnemy(p) and self:damageIsEffective(p) then return p end
    end
    for _, p in ipairs(list) do if p == self.player then return p end end
    return list[1]
end
sgs.ai_use_priority.hljx_shenglunCard = 5

sgs.ai_skill_invoke.hlxg_zuoxing = function(self)
    local giver = self.player:getTag("hlxg_zuoxing_grantor"):toPlayer()
    return giver and giver:isAlive() and giver:getMaxHp() > 2
end
sgs.ai_fill_skill.hlxg_zuoxing = function(self)
    if self.player:getMark("hlxg_zuoxing_enabled-PlayClear") == 0 then return end
    -- Return the declared ordinary trick directly; V2 supplies its activation provenance.
    for _, name in ipairs({"ex_nihilo", "dismantlement", "snatch", "duel"}) do
        local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
        if card then
            card:setSkillName("hlxg_zuoxing"); card:setCanRecast(false)
            card:deleteLater()
            if card:isAvailable(self.player) then
                local dummy = self:aiUseCard(card)
                if dummy and dummy.card then return card end
            end
        end
    end
end
sgs.ai_skill_playerchosen.hlxg_tianyi_guojia = function(self, targets)
    local list = sgs.QList2Table(targets)
    self:sort(list, "handcard")
    for _, p in ipairs(list) do if self:isFriend(p) then return p end end
    return list[1]
end
sgs.ai_fill_skill.hlxg_huishi_guojia = function(self)
    if self.player:getMaxHp() < 10 then return sgs.Card_Parse("#hlxg_huishi_guojiaCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_huishi_guojiaCard"] = function(card, use, self) use.card = card end
sgs.ai_skill_invoke.hlxg_huishi_guojia = function(self) return self.player:getMaxHp() < 9 end
sgs.ai_skill_playerchosen.hlxg_huishi_guojia = function(self, targets)
    local list = sgs.QList2Table(targets)
    self:sort(list, "handcard")
    for _, p in ipairs(list) do if self:isFriend(p) then return p end end
    return nil
end
sgs.ai_use_priority.hlxg_huishi_guojiaCard = 7
local function c215_ai_wakes(p)
    local names = {}
    for _, skill in sgs.qlist(p:getVisibleSkillList()) do
        if skill:getFrequency(p) == sgs.Skill_Wake and p:getMark(skill:objectName()) == 0 then
            table.insert(names, skill:objectName())
        end
    end
    return names
end
sgs.ai_fill_skill.hlxg_huishi_guojia2 = function(self)
    if self.player:getMark("@hlxg_huishi_guojia2") > 0 and self.player:getMaxHp() > 2 then
        return sgs.Card_Parse("#hlxg_huishi_guojia2Card:.:")
    end
end
sgs.ai_skill_use_func["#hlxg_huishi_guojia2Card"] = function(card, use, self)
    local friends = {}
    for _, p in ipairs(self.friends or {}) do if p:isAlive() then table.insert(friends, p) end end
    self:sort(friends, "handcard")
    for _, p in ipairs(friends) do
        local wakes = c215_ai_wakes(p)
        if #wakes > 0 and self.player:getMaxHp() >= self.room:alivePlayerCount() then
            use.card = card; if use.to then use.to:append(p) end; return
        end
    end
    if self.player:getMaxHp() <= 3 then return end
    for _, p in ipairs(friends) do
        if #c215_ai_wakes(p) == 0 then
            use.card = card; if use.to then use.to:append(p) end; return
        end
    end
end
sgs.ai_skill_choice.hlxg_huishi_guojia2 = function(self, choices)
    local names = choices:split("+")
    return names[1]
end
sgs.ai_use_priority.hlxg_huishi_guojia2Card = 6
end

-- ==================== c215_02
do
sgs.ai_skill_invoke.hlxg_jigong = function(self) return self.player:isWounded() or self.player:getHandcardNum() < 3 end
sgs.ai_skill_choice.hlxg_jigong = function(self) return self.player:isWounded() and "0" or "3" end
sgs.ai_skill_invoke.hlxg_shifei = true
sgs.ai_skill_invoke.hljx_jingce = true
sgs.ai_skill_playerchosen.hlxg_shifei = function(self, targets)
    local list = sgs.QList2Table(targets)
    for _, p in ipairs(list) do if self:isEnemy(p) then return p end end
    return list[1]
end
sgs.ai_skill_playerchosen.hlxg_cidao = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return nil
end
sgs.ai_fill_skill.hlxg_tanbei = function(self)
    return sgs.Card_Parse("#hlxg_tanbeiCard:.:")
end
sgs.ai_skill_use_func["#hlxg_tanbeiCard"] = function(card, use, self)
    for _, p in ipairs(self.enemies) do
        if p:isAlive() then
            use.card = card
            if use.to then use.to:append(p) end
            return
        end
    end
end
sgs.ai_skill_choice.hlxg_tanbei = function(self, choices)
    if string.find(choices, "get", 1, true) then return "get" end
    return "nolimit"
end
sgs.ai_use_priority.hlxg_tanbeiCard = 7
end

-- ==================== c215_03
do
-- c215_03: conservative AI.
sgs.ai_skill_invoke.hlxg_quanji = true
sgs.ai_fill_skill.hlxg_paiyi = function(self)
    if not self.player:getPile("hlxg_quanji"):isEmpty() then return sgs.Card_Parse("#hlxg_paiyiCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_paiyiCard"] = function(card, use, self)
    for _, p in ipairs(self.friends or {}) do
        if p:getHandcardNum() + 2 <= self.player:getHandcardNum() or p == self.player then
            use.card = card; if use.to then use.to:append(p) end; return
        end
    end
end
sgs.ai_use_priority.hlxg_paiyiCard = 4
sgs.ai_fill_skill["#hlxg_quanji_store"] = function(self)
    local spare = self.player:getHandcardNum() - self.player:getMaxCards()
    if spare <= 0 or self.player:getPile("hlxg_quanji"):length() >= 5 then return end
    local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValue(cards)
    local ids = {}
    for i = 1, math.min(spare, 5 - self.player:getPile("hlxg_quanji"):length()) do
        if cards[i] then table.insert(ids, cards[i]:getEffectiveId()) end
    end
    if #ids > 0 then return sgs.Card_Parse("#hlxg_quanjiCard:" .. table.concat(ids, "+") .. ":") end
end
sgs.ai_skill_use_func["#hlxg_quanjiCard"] = function(card, use) use.card = card end
sgs.ai_use_priorityhlxg_quanjiCard = 0.1
sgs.ai_skill_playerchosen.hlxg_zuoding = function(self, targets)
    local ps = sgs.QList2Table(targets); self:sort(ps, "handcard")
    for _, p in ipairs(ps) do if self:isFriend(p) then return p end end
end
sgs.ai_skill_invoke.hlxg_choutao = function(self, data)
    local u = data:toCardUse()
    if not u.from then return false end
    if u.from ~= self.player then return self:isEnemy(u.from) end
    for _, p in sgs.qlist(u.to) do if self:isEnemy(p) and self:damageIsEffective(p) then return true end end
    return false
end
sgs.ai_skill_playerchosen.hlxg_xiangshu = function(self, targets)
    local ps = sgs.QList2Table(targets); self:sort(ps, "hp")
    for _, p in ipairs(ps) do if self:isFriend(p) then return p end end
end
-- Material-bearing previews enter the native V2 payment/effect path.
sgs.ai_view_as.hlxg_huomo = function(card, player, place, class_name)
    if player:getMark("hlxg_huomo-Clear") >= 2 or not card:isBlack() or card:isKindOf("BasicCard")
        or (place ~= sgs.Player_PlaceHand and place ~= sgs.Player_PlaceEquip)
        or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return end
    local names = {Slash = "slash", Jink = "jink", Peach = "peach", Analeptic = "analeptic"}
    local name = names[class_name]
    if name then return name .. ":hlxg_huomo[no_suit:0]=" .. card:getEffectiveId() end
end
sgs.ai_fill_skill.hlxg_huomo = function(self)
    if self.player:getMark("hlxg_huomo-Clear") >= 2 then return end
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    for _, material in ipairs(cards) do
        if material:isBlack() and not material:isKindOf("BasicCard") and self:getKeepValue(material) < 4 then
            for _, name in ipairs({"peach", "slash", "analeptic"}) do
                local c = sgs.Card_Parse(name .. ":hlxg_huomo[no_suit:0]=" .. material:getEffectiveId())
                if c and c:isAvailable(self.player) then
                    local use = {isDummy = true, to = sgs.SPlayerList()}
                    self:useBasicCard(c, use)
                    if use.card then return c end
                end
            end
        end
    end
end
end

-- ==================== c215_04
do
sgs.ai_skill_playerchosen.hlxg_xiashu = function(self, targets)
    local best
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) and (not best or p:getHandcardNum() > best:getHandcardNum()) then best = p end
    end
    return best
end
sgs.ai_skill_choice.hlxg_xiashu = function() return "hidden" end
sgs.ai_skill_exchange.hlxg_xiashu = function() return {} end
sgs.ai_skill_playerchosen.hlxg_kuanshi = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) and p:isWounded() then return p end end
    return self.player
end
sgs.ai_skill_invoke.hlxg_xingzuo = true
sgs.ai_skill_exchange.hlxg_xingzuo = function() return {} end
sgs.ai_skill_playerchosen.hlxg_xingzuo = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) and p:getHandcardNum() < 3 then return p end end
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) and p:getHandcardNum() > 3 then return p end end
end
sgs.ai_skill_askforag.hlxg_xingzuo = function(self, ids)
    local cards = {}
    for _, id in ipairs(ids) do table.insert(cards, sgs.Sanguosha:getCard(id)) end
    self:sortByUseValue(cards, true)
    return cards[1] and cards[1]:getEffectiveId() or -1
end
sgs.ai_fill_skill.hlxg_jueyan = function(self)
    if self.player:hasEquipArea(1) and not self.player:getArmor() then return sgs.Card_Parse("#hlxg_jueyanCard:.:" ) end
    if self.player:isWounded() and (self.player:hasEquipArea(2) or self.player:hasEquipArea(3)) then return sgs.Card_Parse("#hlxg_jueyanCard:.:" ) end
end
sgs.ai_skill_use_func["#hlxg_jueyanCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hlxg_jueyanCard = 8
sgs.ai_skill_choice.hlxg_jueyan = function(self, choices)
    if self.player:isWounded() and choices:find("horses") then return "horses" end
    if choices:find("armor") then return "armor" end
    return choices:split("+")[1]
end
sgs.ai_skill_invoke.hlxg_jizhi_lukang = true
-- Declaration AI selects only usable, positive-value tricks; normal target AI handles the result.
local function hl_declare(self, skill, equipment)
    local material
    for _, c in sgs.qlist(self.player:getHandcards()) do
        local ok = equipment and c:isKindOf("EquipCard") and not self.player:hasEquipArea(c:getRealCard():toEquipCard():location())
        if not equipment and c:isBlack() then
            local n = 0
            for _, h in sgs.qlist(self.player:getHandcards()) do if h:isBlack() then n = n + 1 end end
            ok = n == 1
        end
        if ok and (not material or self:getKeepValue(c) < self:getKeepValue(material)) then material = c end
    end
    if not material then return end
    for _, name in ipairs({"ex_nihilo", "dismantlement", "snatch"}) do
        if not equipment or self.player:getMark("hlxg_huairou_" .. name .. "-Clear") == 0 then
            local c = sgs.Sanguosha:cloneCard(name)
            c:setSkillName(equipment and "_hlxg_huairou" or skill)
            if not equipment then c:addSubcard(material) end
            c:deleteLater()
            if c:isAvailable(self.player) then
                local use = {isDummy = true, to = sgs.SPlayerList()}
                self:useTrickCard(c, use)
                if use.card then return sgs.Card_Parse(name .. ":" .. skill .. "[to_be_decided:0]=" .. material:getEffectiveId()) end
            end
        end
    end
end
sgs.ai_fill_skill.hlxg_miaoxian = function(self)
    if self.player:getMark("hlxg_miaoxian-Clear") == 0 then return hl_declare(self, "hlxg_miaoxian", false) end
end
sgs.ai_fill_skill.hlxg_huairou = function(self) return hl_declare(self, "hlxg_huairou", true) end
end

-- ==================== c215_05
do
sgs.ai_skill_invoke.hlxg_zhenglun = true
sgs.ai_skill_invoke.hlxg_lianying = true
sgs.ai_skill_invoke.hljx_lianying = true
local function friend_recipient(self, targets)
    local friends = {}
    for _, p in sgs.qlist(targets) do
        if self:isFriend(p) then table.insert(friends, p) end
    end
    self:sort(friends, "handcard")
    return friends[1]
end
sgs.ai_skill_playerchosen.hlxg_qianxun = friend_recipient
sgs.ai_skill_playerchosen.hljx_lianying = friend_recipient
sgs.ai_skill_playerchosen.hlxg_yili = function(self, targets)
    if self.player:getMark("@hlxg_huaiju") == 0 and self.player:getHp() <= 2 then return nil end
    return friend_recipient(self, targets)
end
sgs.ai_skill_choice.hlxg_yili = function(self, choices)
    if string.find(choices, "orange", 1, true) then return "orange" end
    return "losehp"
end
local function give_card(self, max_num, min_num)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    return cards[1] and {cards[1]:getEffectiveId()} or {}
end
sgs.ai_skill_discard.hlxg_qianxun = give_card
sgs.ai_skill_discard.hljx_lianying = give_card
sgs.ai_skill_discard.hljx_qianxun = function(self, max_num, min_num)
    local cards = sgs.QList2Table(self.player:getHandcards())
    if #cards > max_num then return {} end
    local ids = {}
    for _, c in ipairs(cards) do table.insert(ids, c:getEffectiveId()) end
    return ids
end
end

-- ==================== c215_06
do
sgs.ai_skill_invoke.hlxg_cuike = function(self) return #self.enemies > 0 end
sgs.ai_skill_playerchosen.hlxg_cuike = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
end
sgs.ai_skill_playerschosen.hlxg_cuike = function(self, targets)
    local result = {}
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then table.insert(result, p) end end
    return result
end
sgs.ai_skill_playerchosen.hlxg_zhiwei = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
    return targets:first()
end
sgs.ai_skill_invoke.hlxg_zhiwei = function(self, data)
    local p = data:toPlayer()
    return p and self:isFriend(p)
end
sgs.ai_skill_exchange.hlxg_zhiwei = function(self)
    local name = self.player:getTag("hlxg_zhiwei_target"):toString()
    local friend = false
    for _, p in ipairs(self.friends) do if p:objectName() == name then friend = true end end
    if not friend then return {} end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    return cards[1] and {cards[1]:getEffectiveId()} or {}
end
sgs.ai_skill_invoke.hlxg_zhente = function(self, data)
    local use = data:toCardUse()
    return use.from and self:isEnemy(use.from)
end
sgs.ai_skill_choice.hlxg_zhente = function() return "nullify" end
sgs.ai_skill_invoke.hlxg_wanglie = function(self, data)
    local use = data:toCardUse()
    if not use.card or not use.card:isDamageCard() then return false end
    for _, p in sgs.qlist(use.to) do if self:isEnemy(p) then return self.player:getHandcardNum() <= 2 end end
    return false
end
sgs.ai_fill_skill.hlxg_zhanhuo = function(self)
    if self.player:getMark("@hlxg_zhanhuo") > 0 and self.player:getMark("&hlxg_junlve") > 0 then return sgs.Card_Parse("#hlxg_zhanhuoCard:.:" ) end
end
sgs.ai_skill_use_func["#hlxg_zhanhuoCard"] = function(card, use, self)
    local n = 0
    for _, p in ipairs(self.enemies) do
        if p:isChained() and n < self.player:getMark("&hlxg_junlve") then
            use.card = card; if use.to then use.to:append(p) end; n = n + 1
        end
    end
end
sgs.ai_skill_playerchosen.hlxg_zhanhuo = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return targets:first()
end
sgs.ai_use_priority.hlxg_zhanhuoCard = 3
end

-- ==================== c215_07
do
sgs.ai_skill_invoke.hlxg_mingce = true
sgs.ai_skill_invoke.hljx_mingce = true
sgs.ai_skill_choice.hljx_mingce = function(self, choices)
    return choices:find("draw") and "draw" or "slash"
end
local function mingce_choose(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
    return targets:first()
end
local function mingce_target(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return targets:first()
end
sgs.ai_skill_playerchosen.hlxg_mingce = mingce_target
sgs.ai_skill_playerchosen.hljx_mingce = mingce_choose
sgs.ai_skill_invoke.hlxg_fenming = function(self)
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:isChained() and self:isEnemy(p) and self.player:canDiscard(p, "he") then return true end
    end
    return false
end
sgs.ai_fill_skill.hlxg_duanxie = function(self)
    return sgs.Card_Parse("#hlxg_duanxieCard:.:")
end
sgs.ai_skill_use_func["#hlxg_duanxieCard"] = function(card, use, self)
    local limit = 2
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do if p:isChained() then limit = 1; break end end
    for _, p in ipairs(self.enemies) do
        if not p:isChained() then
            use.card = card
            if use.to then use.to:append(p) end
            limit = limit - 1
            if limit == 0 then break end
        end
    end
end
sgs.ai_use_priority.hlxg_duanxieCard = 2
end

-- ==================== c215_08
do
sgs.ai_skill_invoke.hlxg_chenyong = true
sgs.ai_skill_playerchosen.hlxg_jiuxian = function(self, targets)
    local friends = {}
    for _, p in sgs.qlist(targets) do
        if self:isFriend(p) and p:isWounded() then table.insert(friends, p) end
    end
    self:sort(friends, "hp")
    return friends[1]
end
sgs.ai_fill_skill.hlxg_jiuxian = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    local ids = {}
    for _, card in ipairs(cards) do
        if #ids >= math.ceil(self.player:getHandcardNum() / 2) then break end
        if self:getKeepValue(card) < 4 and not self.player:isCardLimited(card, sgs.Card_MethodRecast, true) then
            table.insert(ids, card:getEffectiveId())
        end
    end
    return sgs.Card_Parse("#hlxg_jiuxianCard:" .. (#ids > 0 and table.concat(ids, "+") or ".") .. ":")
end
sgs.ai_skill_use_func["#hlxg_jiuxianCard"] = function(card, use, self)
    local duel = sgs.Sanguosha:cloneCard("duel")
    duel:setSkillName("hlxg_jiuxian")
    local dummy = { isDummy = true, to = sgs.SPlayerList() }
    self:useTrickCard(duel, dummy)
    if dummy.card and dummy.to and not dummy.to:isEmpty() then
        use.card = card
        if use.to then
            for _, p in sgs.qlist(dummy.to) do use.to:append(p) end
        end
    end
    duel:deleteLater()
end
sgs.ai_use_priority.hlxg_jiuxianCard = sgs.ai_use_priority.Duel or 2.9
end

-- ==================== c216_01
do
local function c216_low(self, zone, discard, skill)
    local cards = sgs.QList2Table(self.player:getCards(zone))
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if (not discard or self.player:canDiscard(self.player, c:getEffectiveId()))
            and (skill ~= "hlxg_pindi" or self.player:getMark("hlxg_pindi_type" .. c:getTypeId() .. "-Clear") == 0)
            and not c:isKindOf("Peach") then return c end
    end
end
sgs.ai_skill_playerchosen.hlxg_bifa = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
end
sgs.ai_skill_discard.hlxg_bifa = function(self)
    local c = c216_low(self, "h", false)
    return c and {c:getEffectiveId()} or {}
end
sgs.ai_skill_cardask["@hlxg_bifa-give"] = function(self, data, pattern)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    local kind = pattern:match("^[^|]+")
    for _, c in ipairs(cards) do
        if kind and c:isKindOf(kind) and (not c:isKindOf("Peach") or self.player:getHp() <= 1) then return "$" .. c:getEffectiveId() end
    end
    return "."
end
sgs.ai_fill_skill.hlxg_songci = function(self) return sgs.Card_Parse("#hlxg_songciCard:.:") end
sgs.ai_skill_use_func["#hlxg_songciCard"] = function(card, use, self)
    for _, p in ipairs(self.friends) do
        if p:getMark("hlxg_songci_" .. self.player:objectName()) == 0 and p:getHandcardNum() <= p:getHp() then
            use.card = card; use.to:append(p); return
        end
    end
    for _, p in ipairs(self.enemies) do
        if p:getMark("hlxg_songci_" .. self.player:objectName()) == 0 and p:getHandcardNum() > p:getHp() then
            use.card = card; use.to:append(p); return
        end
    end
end
sgs.ai_use_priority.hlxg_songciCard = 3
sgs.ai_skill_invoke.hlxg_fuyuan = function(self, data)
    local p = data:toPlayer(); return p and self:isFriend(p)
end
sgs.ai_skill_invoke.hlxg_wangzu = true
sgs.ai_skill_cardask["@hlxg_wangzu-discard"] = function(self)
    local c = c216_low(self, "h", true)
    return c and "$" .. c:getEffectiveId() or "."
end
sgs.ai_fill_skill.hlxg_yingshuo = function(self)
    if self.player:getMark("hlxg_yingshuo-PlayClear") > 0 then return end
    local c = c216_low(self, "he", false)
    if c then return sgs.Card_Parse("#hlxg_yingshuoCard:" .. c:getEffectiveId() .. ":") end
end
sgs.ai_skill_use_func["#hlxg_yingshuoCard"] = function(card, use, self)
    for _, p in ipairs(self.enemies) do
        if self.player:inMyAttackRange(p) and p:getMark("hlxg_yingshuo_" .. self.player:objectName() .. "-Clear") == 0
            and self:damageIsEffective(p) then use.card = card; use.to:append(p); return end
    end
end
sgs.ai_skill_choice.hlxg_yingshuo = function(self, choices)
    if choices:find("give") and self.player:getHp() <= 1 then return "give" end
    return "damage"
end
sgs.ai_skill_discard.hlxg_yingshuo = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    local ids = {}
    for _, c in ipairs(cards) do if c:isKindOf("EquipCard") and #ids < 2 then table.insert(ids, c:getEffectiveId()) end end
    return ids
end
sgs.ai_use_priority.hlxg_yingshuoCard = 2
sgs.ai_fill_skill.hlxg_pindi = function(self)
    local c = c216_low(self, "he", true, "hlxg_pindi")
    if c then return sgs.Card_Parse("#hlxg_pindiCard:" .. c:getEffectiveId() .. ":") end
end
sgs.ai_skill_use_func["#hlxg_pindiCard"] = function(card, use, self)
    for _, p in ipairs(self.friends_noself) do
        if p:getMark("hlxg_pindi_" .. self.player:objectName() .. "-Clear") == 0 then use.card = card; use.to:append(p); return end
    end
    for _, p in ipairs(self.enemies) do
        if p:getMark("hlxg_pindi_" .. self.player:objectName() .. "-Clear") == 0 and not p:isNude() then use.card = card; use.to:append(p); return end
    end
end
sgs.ai_skill_choice.hlxg_pindi = function(self, choices, data)
    local p = data:toPlayer(); return p and self:isFriend(p) and "draw" or "discard"
end
sgs.ai_use_priority.hlxg_pindiCard = 2.5
sgs.ai_skill_invoke.hlxg_faen = function(self, data)
    local p = data:toPlayer(); return p and self:isFriend(p)
end
sgs.ai_skill_cardask["@hlxg_faen-prevent"] = function(self, data)
    local d = data:toDamage()
    if not d.to or not self:isFriend(d.to) then return "." end
    local c = c216_low(self, "he", true)
    return c and "$" .. c:getEffectiveId() or "."
end
end

-- ==================== c216_02
do
sgs.ai_skill_playerchosen.hlxg_yirang = function(self, targets)
    local friends = {}
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then table.insert(friends, p) end end
    table.sort(friends, function(a, b) return a:getMaxHp() > b:getMaxHp() end)
    if friends[1] and (friends[1]:getMaxHp() > self.player:getMaxHp() or self.player:getEquips():isEmpty()) then return friends[1] end
end
sgs.ai_fill_skill.hlxg_kuiji = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
        if c:isBlack() and c:isKindOf("BasicCard") then return sgs.Card_Parse("#hlxg_kuijiCard:" .. c:getEffectiveId() .. ":") end
    end
end
sgs.ai_skill_use_func["#hlxg_kuijiCard"] = function(card, use, self) use.card = card end
sgs.ai_use_priority.hlxg_kuijiCard = 5
-- The recovery prompt uses the same playerchosen key as the damage prompt.
sgs.ai_skill_playerchosen.hlxg_kuiji = function(self, targets)
    local candidates = sgs.QList2Table(targets)
    -- Damage candidates exclude self and all have the greatest other HP; the recovery prompt has all living players.
    local recovery = targets:contains(self.player)
    if recovery then
        local friends = {}
        for _, p in ipairs(candidates) do if self:isFriend(p) and p:isWounded() then table.insert(friends, p) end end
        self:sort(friends, "hp")
        return friends[1]
    end
    local enemies = {}
    for _, p in ipairs(candidates) do if self:isEnemy(p) then table.insert(enemies, p) end end
    self:sort(enemies, "hp")
    return enemies[1]
end
sgs.ai_skill_invoke.hlxg_yonglve = function(self)
    local current = self.room:getCurrent()
    if not current then return false end
    return self:isEnemy(current) or (self:isFriend(current) and current:containsTrick("indulgence"))
        or (self:isFriend(current) and current:containsTrick("supply_shortage"))
end
sgs.ai_skill_choice.hlxg_yonglve = function(self, choices, data)
    local to = data:toPlayer()
    if string.find(choices, "judge", 1, true) and (not to or self:isFriend(to) or not string.find(choices, "self", 1, true)) then return "judge" end
    return "self"
end
sgs.ai_skill_discard.hlxg_yonglve = function(self, discard_num, min_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getCards(include_equip and "he" or "h"))
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do if self.player:canDiscard(self.player, c:getEffectiveId()) then return {c:getEffectiveId()} end end
    return {}
end
sgs.ai_skill_use["@@hlxg_shenduan"] = function(self)
    for _, id in sgs.qlist(self.player:getPile("#hlxg_shenduan")) do
        local original = sgs.Sanguosha:getCard(id)
        local card = sgs.Sanguosha:cloneCard("supply_shortage", original:getSuit(), original:getNumber())
        card:addSubcard(id); card:setSkillName("hlxg_shenduan")
        local use = {isDummy = true, to = sgs.SPlayerList()}
        self:useCardSupplyShortage(card, use)
        local result
        if use.card and not use.to:isEmpty() then result = card:toString() .. "->" .. use.to:first():objectName() end
        card:deleteLater()
        if result then return result end
    end
    return "."
end
end

-- ==================== c216_03
do
local function c216_ai_conversion(self, skill, name, predicate, hand)
    local cards = sgs.QList2Table(self.player:getCards(hand and "h" or "he"))
    self:sortByUseValue(cards, true)
    for _, c in ipairs(cards) do
        if predicate(c) and not c:isKindOf("Peach") then
            return sgs.Card_Parse(name .. ":" .. skill .. "[" .. c:getSuitString() .. ":" .. c:getNumberString() .. "]=" .. c:getEffectiveId())
        end
    end
end
sgs.ai_fill_skill.hlxg_weiwu = function(self)
    if self.player:getMark("hlxg_weiwu-PlayClear") > 0 then return end
    return c216_ai_conversion(self, "hlxg_weiwu", "snatch", function(c) return c:isRed() end)
end
sgs.ai_fill_skill.hlxg_niluan = function(self)
    if not sgs.Slash_IsAvailable(self.player) then return end
    return c216_ai_conversion(self, "hlxg_niluan", "slash", function(c) return c:isBlack() and not c:isKindOf("Slash") end)
end
sgs.ai_view_as.hlxg_niluan = function(card, player, card_place)
    if card:isBlack() and (card_place == sgs.Player_PlaceHand or card_place == sgs.Player_PlaceEquip) then
        return "slash:hlxg_niluan[" .. card:getSuitString() .. ":" .. card:getNumberString() .. "]=" .. card:getEffectiveId()
    end
end
sgs.ai_fill_skill.hlxg_shenxing = function(self)
    local x = math.min(2, self.player:getMark("hlxg_shenxing-PlayClear"))
    if x == 0 or (x == 1 and self:getOverflow() > 0) then return sgs.Card_Parse("#hlxg_shenxingCard:.:") end
end
sgs.ai_skill_use_func["#hlxg_shenxingCard"] = function(card, use, self) use.card = card end
sgs.ai_use_priority.hlxg_shenxingCard = 2
sgs.ai_skill_discard.hlxg_shenxing = function(self, discard_num, min_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getCards(include_equip and "he" or "h"))
    self:sortByKeepValue(cards)
    local ids = {}
    for _, c in ipairs(cards) do
        if #ids < discard_num and not self.player:isJilei(c) then table.insert(ids, c:getEffectiveId()) end
    end
    return ids
end
sgs.ai_skill_invoke.hlxg_bingyi = true
sgs.ai_skill_playerschosen.hlxg_bingyi = function(self, targets)
    local chosen = {}
    for _, p in sgs.qlist(targets) do
        if #chosen < self.player:getHandcardNum() and self:isFriend(p) then table.insert(chosen, p) end
    end
    return chosen
end
sgs.ai_skill_invoke.hljx_shuangxiong = function(self, data)
    if self.player:getPhase() ~= sgs.Player_Draw then return true end
    return self.player:getHandcardNum() >= 2
end
sgs.ai_skill_choice.hljx_shuangxiong = function(self, choices)
    local red, black = 0, 0
    for _, c in sgs.qlist(self.player:getHandcards()) do
        if c:isRed() then red = red + 1 elseif c:isBlack() then black = black + 1 end
    end
    return red > black and "black" or "red"
end
sgs.ai_fill_skill.hljx_shuangxiong = function(self)
    local color = self.player:getMark("hljx_shuangxiong_color-Clear")
    if color == 0 or self.player:getMark("hljx_shuangxiong_used-Clear") >= 3 then return end
    return c216_ai_conversion(self, "hljx_shuangxiong", "duel", function(c)
        return (color == 1 and c:isBlack()) or (color == 2 and c:isRed())
    end, true)
end
end

-- ==================== c216_04
do
sgs.ai_skill_invoke.hlxg_fengpo = true
sgs.ai_skill_choice.hlxg_fengpo = function(self, choices, data)
    local use = data:toCardUse()
    local to = use.to and not use.to:isEmpty() and use.to:first()
    if to and self:isEnemy(to) and to:getHp() <= 2 and to:getHandcardNum() >= 2 then return "damage" end
    return "draw"
end
sgs.ai_skill_invoke.hlxg_qianxi = true
sgs.ai_skill_askforag.hlxg_qianxi = function(self, ids)
    local cards = {}
    for _, id in ipairs(ids) do table.insert(cards, sgs.Sanguosha:getCard(id)) end
    self:sortByKeepValue(cards)
    return cards[1] and cards[1]:getEffectiveId() or -1
end
sgs.ai_skill_playerchosen.hlxg_qianxi = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
    return targets:first()
end
sgs.ai_skill_askforag.hlxg_fuman = function(self, ids)
    local best, value = -1, -100
    for _, id in ipairs(ids) do
        local c = sgs.Sanguosha:getCard(id)
        local v = self:getUseValue(c)
        if v > value then best = id; value = v end
    end
    return best
end
sgs.ai_fill_skill.hlxg_fuman = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    local slash = false
    for _, id in sgs.qlist(self.room:getDiscardPile()) do if sgs.Sanguosha:getCard(id):isKindOf("Slash") then slash = true; break end end
    for _, c in ipairs(cards) do
        if not self.player:isJilei(c) and (slash or c:isKindOf("Slash")) and self:getKeepValue(c) < 5 then
            return sgs.Card_Parse("#hlxg_fumanCard:" .. c:getEffectiveId() .. ":")
        end
    end
end
sgs.ai_skill_use_func["#hlxg_fumanCard"] = function(card, use, self)
    for _, p in ipairs(self.friends_noself or {}) do
        if p:isAlive() and self.player:getMark("hlxg_fuman_" .. p:objectName() .. "-PlayClear") == 0 then
            use.card = card; use.to:append(p); return
        end
    end
end
sgs.ai_use_priority.hlxg_fumanCard = 3
sgs.ai_skill_use["@@#hlxg_fuman_use"] = function(self)
    local id = self.player:getMark("hlxg_fuman_id") - 1
    if id < 0 then return "." end
    local c = sgs.Sanguosha:getCard(id)
    local use = {isDummy = true, to = sgs.SPlayerList()}
    self:useCardSlash(c, use)
    if not use.card or use.to:isEmpty() then return "." end
    local names = {}
    for _, p in sgs.qlist(use.to) do table.insert(names, p:objectName()) end
    return c:toString() .. "->" .. table.concat(names, "+")
end
end

-- ==================== c216_05
do
local function c216_05_zhiman_ai(self, data)
    local damage = data:toDamage()
    if not damage.to then return false end
    if self:isFriend(damage.to) then return true end
    local flags = self.player:hasSkill("hljx_zhiman") and "hej" or "ej"
    return self:isEnemy(damage.to) and not damage.to:getCards(flags):isEmpty()
        and damage.to:getHp() > damage.damage
end
sgs.ai_skill_invoke.hlxg_zhiman_masu = c216_05_zhiman_ai
sgs.ai_skill_invoke.hljx_zhiman = c216_05_zhiman_ai
sgs.ai_skill_invoke.hlxg_tieqi_machao = true
sgs.ai_fill_skill.hljx_sanyao = function(self)
    if self.player:hasUsed("#hljx_sanyaoCard") then return end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if self.player:canDiscard(self.player, card:getEffectiveId()) and not card:isKindOf("Peach")
            and self:getKeepValue(card) < 5 then
            return sgs.Card_Parse("#hljx_sanyaoCard:" .. card:getEffectiveId() .. ":")
        end
    end
end
sgs.ai_skill_use_func["#hljx_sanyaoCard"] = function(card, use, self)
    self:sort(self.enemies, "hp")
    for _, enemy in ipairs(self.enemies) do
        if enemy:isAlive() and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
            use.card = card
            if use.to then use.to:append(enemy) end
            return
        end
    end
end
sgs.ai_use_priority.hljx_sanyaoCard = 3
end

-- ==================== c216_06
do
sgs.ai_skill_invoke.hljx_tieqi = function(self, data)
    local target = data:toPlayer()
    return target and self:isEnemy(target)
end
-- Shichou's effects and both locked skills require no optional AI decisions.
end

-- ==================== c216_07
do
sgs.ai_skill_invoke.hlxg_xizhen = true
sgs.ai_skill_choice.hlxg_xizhen = function(self, choices)
    if string.find(choices, "slash", 1, true) then return "slash" end
    return "duel"
end
sgs.ai_skill_playerchosen.hlxg_xizhen = function(self, targets)
    local list = sgs.QList2Table(targets); self:sort(list, "defense")
    for _, p in ipairs(list) do if self:isEnemy(p) then return p end end
    return list[1]
end
sgs.ai_fill_skill.hljx_xianzhen = function(self)
    local c = self:getMaxCard()
    if c and c:getNumber() >= 10 and self.player:getMark("hljx_xianzhen_used-Clear") == 0 then
        return sgs.Card_Parse("#hljx_xianzhenCard:.:")
    end
end
sgs.ai_skill_use_func["#hljx_xianzhenCard"] = function(card, use, self)
    local enemies = {}; for _, p in ipairs(self.enemies) do if self.player:canPindian(p) then table.insert(enemies, p) end end
    self:sort(enemies, "handcard")
    if enemies[1] then use.card = card; if use.to then use.to:append(enemies[1]) end end
end
sgs.ai_use_priority.hljx_xianzhenCard = 7
sgs.ai_skill_pindian.hljx_xianzhen = function(minusecard, self, requestor, maxcard) return maxcard or minusecard end
sgs.ai_skill_use["@@hljx_xianzhen_use"] = function(self)
    local id = self.player:getMark("hljx_xianzhen_card") - 1
    if id < 0 then return "." end
    local c = sgs.Sanguosha:getCard(id)
    if not c then return "." end
    local use = {isDummy = true, to = sgs.SPlayerList()}; self:useCardByClassName(c, use)
    if not use.card then return "." end
    local targets = {}; for _, p in sgs.qlist(use.to) do table.insert(targets, p:objectName()) end
    return c:toString() .. (#targets > 0 and "->" .. table.concat(targets, "+") or "")
end
end

-- ==================== c216_08
do
for _, name in ipairs({"hlxg_kuanggu", "hljx_kuanggu"}) do
    sgs.ai_skill_invoke[name] = true
    sgs.ai_skill_choice[name] = function(self) return self.player:isWounded() and "recover" or "draw" end
end
sgs.ai_fill_skill.hljx_qimou = function(self)
    if self.player:getMark("@hljx_qimou") > 0 and self.player:getHp() > 2 and self:getCardsNum("Slash") > 1 then
        return sgs.Card_Parse("#hljx_qimouCard:.:")
    end
end
sgs.ai_skill_use_func["#hljx_qimouCard"] = function(card, use) use.card = card end
sgs.ai_use_priority.hljx_qimouCard = 7
sgs.ai_skill_choice.hljx_qimou = function(self)
    return self.player:getTag("hljx_qimou_amount"):toInt() < 1 and "increase" or "confirm"
end
sgs.ai_skill_invoke.hlxg_haoshi = function(self)
    if self.player:getHandcardNum() + 2 <= 5 then return true end
    local minimum = nil
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if not minimum or p:getHandcardNum() < minimum then minimum = p:getHandcardNum() end
    end
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if p:getHandcardNum() == minimum and self:isFriend(p) then return true end
    end
    return false
end
sgs.ai_skill_choice.hlxg_haoshi = function(self)
    local minimum = nil
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if not minimum or p:getHandcardNum() < minimum then minimum = p:getHandcardNum() end
    end
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if p:getHandcardNum() == minimum and self:isFriend(p) then return "give" end
    end
    return "discard"
end
sgs.ai_skill_playerchosen.hlxg_haoshi = function(self, targets)
    for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
    return targets:first()
end
sgs.ai_skill_discard.hlxg_haoshi = function(self, discard_num)
    local cards = sgs.QList2Table(self.player:getCards("h")); self:sortByKeepValue(cards)
    local ids = {}
    for _, c in ipairs(cards) do
        if #ids < discard_num and not self.player:isJilei(c) then table.insert(ids, c:getEffectiveId()) end
    end
    return ids
end
sgs.ai_fill_skill.hlxg_dimeng = function(self)
    return sgs.Card_Parse("#hlxg_dimengCard:.:")
end
sgs.ai_skill_use_func["#hlxg_dimengCard"] = function(card, use, self)
    local payable = 0
    for _, c in sgs.qlist(self.player:getCards("he")) do
        if self.player:canDiscard(self.player, c:getEffectiveId()) and self:getKeepValue(c) < 4 then payable = payable + 1 end
    end
    for _, friend in ipairs(self.friends_noself or {}) do
        for _, enemy in ipairs(self.enemies or {}) do
            local difference = enemy:getHandcardNum() - friend:getHandcardNum()
            if difference > 0 and difference <= payable then
                use.card = card; use.to:append(friend); use.to:append(enemy); return
            end
        end
    end
end
sgs.ai_use_priority.hlxg_dimengCard = 2
sgs.ai_skill_discard.hlxg_dimeng = function(self, discard_num)
    local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValue(cards)
    local ids = {}
    for _, c in ipairs(cards) do
        if #ids < discard_num and self.player:canDiscard(self.player, c:getEffectiveId()) then table.insert(ids, c:getEffectiveId()) end
    end
    return ids
end
end

-- ==================== c216_09
do
sgs.ai_skill_playerchosen.hljx_haoshi = function(self, targets)
    local friends = {}
    for _, p in sgs.qlist(targets) do
        if self:isFriend(p) then table.insert(friends, p) end
    end
    self:sort(friends, "handcard")
    return friends[1]
end
sgs.ai_skill_discard.hljx_haoshi = function(self, max_num, min_num)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    local ids = {}
    for i = 1, math.min(min_num, #cards) do table.insert(ids, cards[i]:getEffectiveId()) end
    return ids
end
sgs.ai_skill_cardask["@hljx_haoshi-aid"] = function(self, data, pattern, target)
    if not target or not self:isFriend(target) then return "." end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if not card:isKindOf("Peach") and not card:isKindOf("Jink") then return "$" .. card:getEffectiveId() end
    end
    return "."
end
sgs.ai_fill_skill.hljx_dimeng = function(self)
    if self.player:getMark("&hljx_dimeng") == 0 then return sgs.Card_Parse("#hljx_dimengCard:.:") end
end
sgs.ai_skill_use_func["#hljx_dimengCard"] = function(card, use, self)
    local friends, enemies = {}, {}
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if self:isFriend(p) then table.insert(friends, p)
        elseif self:isEnemy(p) then table.insert(enemies, p) end
    end
    self:sort(friends, "handcard")
    self:sort(enemies, "handcard", true)
    local a, b = friends[1], enemies[1]
    if a and b and b:getHandcardNum() > a:getHandcardNum() then
        use.card = card
        if use.to then use.to:append(a); use.to:append(b) end
    end
end
sgs.ai_use_priority.hljx_dimengCard = 4
sgs.ai_skill_discard.hljx_dimeng = function(self, discard_num, min_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    local ids = {}
    for _, card in ipairs(cards) do
        if #ids >= discard_num then break end
        if self.player:canDiscard(self.player, card:getEffectiveId())
            and self:getKeepValue(card) < 3 and not card:isKindOf("Peach") then
            table.insert(ids, card:getEffectiveId())
        end
    end
    return ids
end
-- 伏骑 and 骄恣 are passive compulsory skills.
end

-- ==================== c217_01
do
sgs.ai_skill_invoke.hljx_jizhi = true
sgs.ai_skill_playerchosen.hljx_jizhi = function(self, targets)
    for _, p in sgs.qlist(targets) do
        if self:isFriend(p) and p:getEquips():isEmpty() then return p end
    end
    return nil
end
end

-- ==================== c217_02
do
sgs.ai_skill_invoke.hlxg_jizhi_huangyueying = true
sgs.ai_skill_invoke.hlxg_jiqiao = true
sgs.ai_skill_discard.hlxg_jiqiao = function(self, discard_num, min_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    local ids = {}
    for _, card in ipairs(cards) do
        if #ids >= discard_num then break end
        if not card:isKindOf("TrickCard") and self.player:canDiscard(self.player, card:getEffectiveId())
            and self:getKeepValue(card) < 3 and not card:isKindOf("Peach") then
            table.insert(ids, card:getEffectiveId())
        end
    end
    return ids
end
sgs.ai_skill_invoke.hlxg_kurou_huanggai = function(self)
    return self.player:getHp() > 2 or (self.player:getHp() > 1 and self:getCardsNum("Peach") > 0)
end
end

-- ==================== c217_03
do
for _, name in ipairs({"hljx_kurou", "hlxg_kurou_huanggai2"}) do
    sgs.ai_fill_skill[name] = function(self)
        if self.player:getHp() > 2 then return sgs.Card_Parse("#" .. name .. "Card:.:") end
    end
    sgs.ai_skill_use_func["#" .. name .. "Card"] = function(card, use, self)
        if self.player:getHp() > 2 then use.card = card end
    end
    sgs.ai_use_priority[name .. "Card"] = 6.8
end
sgs.ai_skill_invoke.hlxg_xiaojuan = function(self, data)
    local use = data:toCardUse()
    return use.to:length() == 1 and self:isEnemy(use.to:first())
end
sgs.ai_view_as.hlxg_jinggong = function(card, player, place)
    if card:isKindOf("EquipCard") and place ~= sgs.Player_PlaceSpecial then
        return ("slash:hlxg_jinggong[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId())
    end
end
sgs.ai_fill_skill.hlxg_jinggong = function(self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if card:isKindOf("EquipCard") then
            return sgs.Card_Parse(("slash:hlxg_jinggong[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId()))
        end
    end
end
end
