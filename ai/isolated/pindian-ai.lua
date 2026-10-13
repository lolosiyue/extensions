-- Fixed pindian-ai.lua complete effect registry and six SmartAI wrappers.
-- No hand identities beyond the current viewer's snapshot enter the evaluator.
local function pq(object, method, ...)
    if AIValue.isPlayer(object) and method == "getMark" then method = "getStrategyMark" end
    if not object or type(object[method]) ~= "function" then ai_unsupported("Pindian helper is unavailable", method) end
    local value = object[method](object, ...)
    if AIUnsupported.is(value) then error(value, 0) end
    -- The following methods have legitimate nil/no-player/no-weapon results.
    if value == nil and method ~= "findPlayerBySkillName" and method ~= "getWeapon" then
        ai_unsupported("Pindian input is unknown", method)
    end
    return value
end
local function pindianKingdoms(player)
    local room = pq(player, "getRoom")
    local kingdoms, count = {[pq(player, "getKingdom")]=true}, 1
    -- addFunction.lua:179 includes the player even if not in the alive roster.
    for _, p in ipairs(pq(room, "getAlivePlayers")) do
        local name = pq(p, "getKingdom")
        if not kingdoms[name] then kingdoms[name] = true; count = count + 1 end
    end
    return count
end
local function pindianTargetTag(player, ctx)
    local room = pq(player, "getRoom")
    local ai = ctx.ai or room._ai
    if not ai or player:objectName() ~= ai.player:objectName() then
        ai_unsupported("Foreign Pindian target tag is private", "ov_lvren.targets")
    end
    local value = player:getTag(ctx.reason)
    if value == nil then return "" end
    if type(value) ~= "string" then ai_unsupported("Owner Pindian target tag is not projected", "ov_lvren.targets") end
    return value
end
sgs.ai_pindian_effects = sgs.ai_pindian_effects or {}

-- 註冊拼點效果。callback(number, card, player, ctx) -> number|nil（nil = 無影響）
-- priority：1=加減類（先應用） 2=覆寫為高點 3=覆寫為低點（最後應用，保守起見壓過一切）
function sgs.addPindianEffect(name, callback, priority)
	if type(name) ~= "string" or type(callback) ~= "function" then return end
	for _, e in ipairs(sgs.ai_pindian_effects) do
		if e.name == name then
			e.callback = callback
			e.priority = priority or 1
			table.sort(sgs.ai_pindian_effects, function(a, b) return a.priority < b.priority end)
			return
		end
	end
	table.insert(sgs.ai_pindian_effects, { name = name, callback = callback, priority = priority or 1 })
	table.sort(sgs.ai_pindian_effects, function(a, b) return a.priority < b.priority end)
end

-- 統一求值器
function sgs.getPindianNumber(card, player, ctx)
	if not AIValue.isCard(card) or not AIValue.isPlayer(player) then return 0 end
	ctx = ctx or {}
	local number = pq(card, "getNumber")
	for _, e in ipairs(sgs.ai_pindian_effects) do
		local ok, n = pcall(e.callback, number, card, player, ctx)
		if not ok and AIUnsupported.is(n) then error(n, 0) end
		if ok and type(n) == "number" then number = n end
	end
	return math.max(1, math.min(13, number))
end

local function pindianRoom(ctx, player)
	if ctx.ai and ctx.ai.room then return ctx.ai.room end
	return pq(player, "getRoom")
end

--====================================================================
-- 自動·覆寫類
--====================================================================

-- 天辯：紅心拼點牌視為K
sgs.addPindianEffect("tianbian", function(number, card, player, ctx)
	if pq(player, "hasSkill", "tianbian") and pq(card, "getSuit") == sgs.Card_Heart then return 13 end
end, 2)

-- sfofl_zhiyang 峙陽：紅色拼點牌視為K
sgs.addPindianEffect("sfofl_zhiyang", function(number, card, player, ctx)
	if pq(player, "hasSkill", "sfofl_zhiyang") and pq(card, "isRed") then return 13 end
end, 2)

-- s4_2_mingmen 名門：鎖定技，拼點牌視為最大
sgs.addPindianEffect("s4_2_mingmen", function(number, card, player, ctx)
	if pq(player, "hasSkill", "s4_2_mingmen") then return 13 end
end, 2)

-- mobilemoujinjiu 謀禁酒：對手有此技能時，以酒拼點點數視為1（強制）
-- 壓過一切覆寫，保守估算（寧低估自己張酒，唔好高估）
sgs.addPindianEffect("mobilemoujinjiu", function(number, card, player, ctx)
	local opponent = ctx.opponent
	if opponent and pq(opponent, "hasSkill", "mobilemoujinjiu") and pq(card, "isKindOf", "Analeptic") then return 1 end
end, 3)

--====================================================================
-- 自動·加點類
--====================================================================

-- mobilexinmingfa 新命法：拼點點數+2
sgs.addPindianEffect("mobilexinmingfa", function(number, card, player, ctx)
	if pq(player, "hasSkill", "mobilexinmingfa") then return number + 2 end
end)

-- tenyearjici 激詞（十週年）：點數唔大於饒舌標記數時，強制+標記數
sgs.addPindianEffect("tenyearjici", function(number, card, player, ctx)
	if not pq(player, "hasSkill", "tenyearjici") then return end
	local n = pq(player, "getMark", "&raoshe")
	if n > 0 and number <= n then return number + n end
end)

-- zijue 姿爵：+&zijue+#num 標記數
-- 引擎實現裏 to 方加嘅係 from 方嘅標記數（疑似引擎 bug，呢度如實模擬）
sgs.addPindianEffect("zijue", function(number, card, player, ctx)
	if pq(player, "getMark", "&zijue+#num") < 1 then return end
	if ctx.is_from == false and ctx.opponent and pq(ctx.opponent, "getMark", "&zijue+#num") > 0 then
		return number + pq(ctx.opponent, "getMark", "&zijue+#num")
	end
	return number + pq(player, "getMark", "&zijue+#num")
end)

-- gsgushe 鼓舌：+2×&gsgushe 標記數（僅當點數<13）
sgs.addPindianEffect("gsgushe", function(number, card, player, ctx)
	if not pq(player, "hasSkill", "gsgushe") or number >= 13 then return end
	local n = pq(player, "getMark", "&gsgushe")
	if n > 0 then return number + 2 * n end
end)

-- theace：僅 from 方，+2×@wannawin
-- is_from 未知（nil）時當有可能（最常見嘅估算場景係玩家自己發起拼點）
sgs.addPindianEffect("theace", function(number, card, player, ctx)
	if ctx.is_from == false then return end
	if not pq(player, "hasSkill", "theace") then return end
	local n = pq(player, "getMark", "@wannawin")
	if n > 0 then return number + 2 * n end
end)

-- ov_danlie 膽烈：+已損失體力
sgs.addPindianEffect("ov_danlie", function(number, card, player, ctx)
	if not pq(player, "hasSkill", "ov_danlie") then return end
	local n = pq(player, "getLostHp")
	if n > 0 then return number + n end
end)

-- ov_qinghan 擎漢：+2×裝備數
sgs.addPindianEffect("ov_qinghan", function(number, card, player, ctx)
	if not pq(player, "hasSkill", "ov_qinghan") then return end
	local n = pq(player, "getEquips"):length() * 2
	if n > 0 then return number + n end
end)

-- ov_jianwei 劍衛：有武器時 +攻擊範圍
sgs.addPindianEffect("ov_jianwei", function(number, card, player, ctx)
	if not pq(player, "hasSkill", "ov_jianwei") or not pq(player, "getWeapon") then return end
	local n = pq(player, "getAttackRange")
	if n > 0 then return number + n end
end)

-- ov_chuanshu 傳授：帶 "&ov_chuanshu+#擁有者" 標記嘅參與者 +3（每名擁有者獨立計）
sgs.addPindianEffect("ov_chuanshu", function(number, card, player, ctx)
	local room = pindianRoom(ctx, player)
	if not room then return end
	local bonus = 0
	for _, owner in sgs.qlist(pq(room, "findPlayersBySkillName", "ov_chuanshu")) do
		if pq(player, "getMark", "&ov_chuanshu+#" .. pq(owner, "objectName")) > 0 then bonus = bonus + 3 end
	end
	if bonus > 0 then return number + bonus end
end)

-- ov_lvren 旅人：+2×拼點目標數（唔少於+2）
sgs.addPindianEffect("ov_lvren", function(number, card, player, ctx)
	if not pq(player, "hasSkill", "ov_lvren") then return end
	local n = 2
	if ctx.reason then
		local tag = pindianTargetTag(player, ctx)
		if tag and tag ~= "" then n = #(tag:split("+")) * 2 end
	end
	return number + n
end)

-- xin2chuhai 出海（使命技）：使命未完成、reason 為 xin2chuhai、from 方，+max(0,4-裝備數)
sgs.addPindianEffect("xin2chuhai", function(number, card, player, ctx)
	if not pq(player, "hasSkill", "xin2chuhai") then return end
	if ctx.reason ~= "xin2chuhai" or ctx.is_from == false then return end
	if pq(player, "getMark", "successxin2chuhai") > 0 or pq(player, "getMark", "failxin2chuhai") > 0 then return end
	local n = math.max(0, 4 - pq(player, "getEquips"):length())
	if n > 0 then return number + n end
end)

--====================================================================
-- 可選·加減類（只喺 mode 為 "max"/"min" 時計入潛力）
--====================================================================

-- yingyang 陰陽：可令自己點數+3或-3
sgs.addPindianEffect("yingyang", function(number, card, player, ctx)
	if not pq(player, "hasSkill", "yingyang") then return end
	if ctx.mode == "max" then return number + 3 end
	if ctx.mode == "min" then return number - 3 end
end)

-- s4_zhiba 制霸（主公技）：可令自己點數±3
sgs.addPindianEffect("s4_zhiba", function(number, card, player, ctx)
	if not pq(player, "hasLordSkill", "s4_zhiba") then return end
	if ctx.mode == "max" then return number + 3 end
	if ctx.mode == "min" then return number - 3 end
end)

-- sfofl_kannan 困難：可令自己點數±場上勢力數
sgs.addPindianEffect("sfofl_kannan", function(number, card, player, ctx)
	if not pq(player, "hasSkill", "sfofl_kannan") then return end
	local n = pindianKingdoms(player)
	if ctx.mode == "max" then return number + n end
	if ctx.mode == "min" then return number - n end
end)

-- ov_niju 逆舉（主公技）：可令任一參與者點數±群勢力角色數
-- 玩家自己係主公直接計；否則保守估算同陣營嘅逆舉主公會幫手/打壓
sgs.addPindianEffect("ov_niju", function(number, card, player, ctx)
	local room = pindianRoom(ctx, player)
	if not room then return end
	local qun = 0
	if pq(player, "hasLordSkill", "ov_niju") then
		qun = pq(room, "getLieges", "qun", player):length()
	elseif ctx.ai then
		local lord = pq(room, "findPlayerBySkillName", "ov_niju")
		if lord and pq(lord, "isAlive") and pq(ctx.ai, "isFriend", lord) == pq(ctx.ai, "isFriend", player) then
			qun = pq(room, "getLieges", "qun", lord):length()
		end
	end
	if qun < 1 then return end
	if ctx.mode == "max" then return number + qun end
	if ctx.mode == "min" then return number - qun end
end)

-- fuzuo 輔佐：擁有者可棄一張1~7點手牌令任一參與者+（牌點/2)，最多+3
-- 只影響 "max" 潛力；同陣營（由 ctx.ai 判斷）先會幫手
sgs.addPindianEffect("fuzuo", function(number, card, player, ctx)
	if ctx.mode ~= "max" or not ctx.ai then return end
	local room = pindianRoom(ctx, player)
	if not room then return end
	local owner = pq(room, "findPlayerBySkillName", "fuzuo")
	if not owner or pq(owner, "isDead") or pq(owner, "isKongcheng") then return end
	if pq(ctx.ai, "isFriend", owner) == pq(ctx.ai, "isFriend", player) then return number + 3 end
end)

-- jibian 機變：可摸1~3張牌令自己點數-n（最差潛力-3）
sgs.addPindianEffect("jibian", function(number, card, player, ctx)
	if not pq(player, "hasSkill", "jibian") then return end
	if ctx.mode == "min" then return number - 3 end
end)

-- jici 激詞（OL）：reason 為 gushe、點數細過饒舌標記數時可+標記數
sgs.addPindianEffect("jici", function(number, card, player, ctx)
	if not pq(player, "hasSkill", "jici") then return end
	if ctx.reason ~= "gushe" or ctx.mode ~= "max" then return end
	local n = pq(player, "getMark", "&raoshe")
	if n > 0 and number < n then return number + n end
end)

-- sxjici 激詞：可失去1點體力令自己點數視為K（體力>1先會用）
sgs.addPindianEffect("sxjici", function(number, card, player, ctx)
	if not pq(player, "hasSkill", "sxjici") then return end
	if ctx.mode == "max" and pq(player, "getHp") > 1 then return 13 end
end, 2)

--====================================================================
-- SmartAI 封装
--====================================================================

-- 以有效點數揀出最大/最細嘅牌。mode: "max"（預設）或 "min"
-- 可見性規則同 getMaxCard 一致：其他人只計已知嘅牌；自己跳過貴重牌（冇就用fallback）
function SmartAIView:getPindianCard(player, mode, ctx)
    if not AIValue.isPlayer(player) then return nil end
    mode = mode or "max"
    ctx = ctx or {}
    ctx.ai = ctx.ai or self
    ctx.mode = mode
    local own = AIValue.sameLegacyIdentity(player, self.player)
    local cards = ctx.cards or (own and pq(player,"getHandcards") or pq(player,"getKnownCards"))
    cards = sgs.QList2Table(cards)
    if #cards < 1 then return nil end
    local known = {}
    if not own then
        for _, card in ipairs(pq(player,"getKnownCards")) do known[pq(card,"getEffectiveId")] = true end
    end
    local best_card, best_point
    local function scan(skip_valuable)
        for _, card in ipairs(cards) do
            if not (skip_valuable and own and pq(self,"isValuableCard",card)) then
                local visible = own
                if not visible and known[pq(card,"getEffectiveId")] then
                    visible = pq(player,"isHandVisible") or pq(card,"hasFlag","visible")
                        or pq(card,"hasFlag","visible_"..self.player:objectName().."_"..player:objectName())
                end
                if visible then
                    local point = sgs.getPindianNumber(card, player, ctx)
                    if not best_point or (mode == "max" and point > best_point) or (mode == "min" and point < best_point) then
                        best_card, best_point = card, point
                    end
                end
            end
        end
    end
    scan(true)
    if own and not best_card then scan(false) end
    return best_card, best_point
end

function SmartAIView:getPindianMaxCard(player, ctx)
	return self:getPindianCard(player, "max", ctx)
end

function SmartAIView:getPindianMinCard(player, ctx)
	return self:getPindianCard(player, "min", ctx)
end

function SmartAIView:getPindianPoint(player, mode, ctx)
	local _, point = self:getPindianCard(player, mode, ctx)
	return point
end

function SmartAIView:getPindianMaxPoint(player, ctx)
	return self:getPindianPoint(player, "max", ctx)
end

function SmartAIView:getPindianMinPoint(player, ctx)
	return self:getPindianPoint(player, "min", ctx)
end
