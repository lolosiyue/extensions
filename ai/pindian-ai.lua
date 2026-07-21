--[[====================================================================
	拼點點數統一判斷 API
	--------------------------------------------------------------------
	目的：取代散落各處嘅 "if hasSkill("tianbian") then point = 13" 式
	硬編碼，用註冊表集中管理所有會影響拼點點數嘅技能效果。

	核心函數：
		sgs.getPindianNumber(card, player, ctx)
			計算 player 以 card 拼點時嘅有效點數（已 clamp 喺 [1,13]）。
			ctx 為可選 table，字段：
				opponent  拼點對手（ServerPlayer，可 nil）
				ai        調用嘅 SmartAI（用嚟攞 room、判斷敵我，可 nil）
				mode      nil = 只計自動生效效果；
						  "max" = 連可選效果嘅最佳潛力（保守估算敵人/估算自己上限）
						  "min" = 連可選效果嘅最差潛力（估算自己/隊友故意輸嘅下限）
				reason    拼點原因（技能名，部分技能按 reason 生效）
				is_from   player 係咪拼點發起方（from）；nil 當有可能
				cards     （只畀 SmartAI:getPindianCard 用）自定牌池

	SmartAI 封装：
		SmartAI:getPindianCard(player, mode, ctx)     -> card, point
		SmartAI:getPindianMaxCard(player, ctx)        -> card, point
		SmartAI:getPindianMinCard(player, ctx)        -> card, point
		SmartAI:getPindianPoint(player, mode, ctx)    -> point
		SmartAI:getPindianMaxPoint(player, ctx)       -> point
		SmartAI:getPindianMinPoint(player, ctx)       -> point

	涵蓋技能（改點類）：
		自動覆寫：tianbian(紅心K) sfofl_zhiyang(紅K) s4_2_mingmen(K)
				  mobilemoujinjiu(對手有技能時酒當1)
		自動加點：mobilexinmingfa tenyearjici zijue gsgushe theace
				  ov_danlie ov_qinghan ov_jianwei ov_chuanshu ov_lvren xin2chuhai
		可選加減：yingyang s4_zhiba sfofl_kannan ov_niju fuzuo jibian
				  jici(OL) sxjici

	明確唔涵蓋（唔屬於「點數判斷」範疇）：
		換牌改點類：PlusGuicai PlusGuidao kexiantianbian kejiexiantianbian
					SixGuicai(任選1-13) sfofl_dimeng(互換) —— 呢啲係替換拼點牌，
					屬於「結果能否被改寫」嘅估算，唔係單張牌嘅點數。
		預設拼點牌類：tianbian/sfofl_quanyi(牌堆頂) thshenduan(牌堆最大)
					yhbuque olhanzhan/eqiangbian(對手隨機) manchanyu(對手最小)
					qiantun/xingqiantun —— 改變用邊張牌，唔改變牌面點數。
	====================================================================]]

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
	if type(card) ~= "userdata" or type(player) ~= "userdata" then return 0 end
	ctx = ctx or {}
	local number = card:getNumber()
	for _, e in ipairs(sgs.ai_pindian_effects) do
		local ok, n = pcall(e.callback, number, card, player, ctx)
		if ok and type(n) == "number" then number = n end
	end
	return math.max(1, math.min(13, number))
end

local function pindianRoom(ctx)
	if ctx.ai and ctx.ai.room then return ctx.ai.room end
	return global_room
end

--====================================================================
-- 自動·覆寫類
--====================================================================

-- 天辯：紅心拼點牌視為K
sgs.addPindianEffect("tianbian", function(number, card, player, ctx)
	if player:hasSkill("tianbian") and card:getSuit() == sgs.Card_Heart then return 13 end
end, 2)

-- sfofl_zhiyang 峙陽：紅色拼點牌視為K
sgs.addPindianEffect("sfofl_zhiyang", function(number, card, player, ctx)
	if player:hasSkill("sfofl_zhiyang") and card:isRed() then return 13 end
end, 2)

-- s4_2_mingmen 名門：鎖定技，拼點牌視為最大
sgs.addPindianEffect("s4_2_mingmen", function(number, card, player, ctx)
	if player:hasSkill("s4_2_mingmen") then return 13 end
end, 2)

-- mobilemoujinjiu 謀禁酒：對手有此技能時，以酒拼點點數視為1（強制）
-- 壓過一切覆寫，保守估算（寧低估自己張酒，唔好高估）
sgs.addPindianEffect("mobilemoujinjiu", function(number, card, player, ctx)
	local opponent = ctx.opponent
	if opponent and opponent:hasSkill("mobilemoujinjiu") and card:isKindOf("Analeptic") then return 1 end
end, 3)

--====================================================================
-- 自動·加點類
--====================================================================

-- mobilexinmingfa 新命法：拼點點數+2
sgs.addPindianEffect("mobilexinmingfa", function(number, card, player, ctx)
	if player:hasSkill("mobilexinmingfa") then return number + 2 end
end)

-- tenyearjici 激詞（十週年）：點數唔大於饒舌標記數時，強制+標記數
sgs.addPindianEffect("tenyearjici", function(number, card, player, ctx)
	if not player:hasSkill("tenyearjici") then return end
	local n = player:getMark("&raoshe")
	if n > 0 and number <= n then return number + n end
end)

-- zijue 姿爵：+&zijue+#num 標記數
-- 引擎實現裏 to 方加嘅係 from 方嘅標記數（疑似引擎 bug，呢度如實模擬）
sgs.addPindianEffect("zijue", function(number, card, player, ctx)
	if player:getMark("&zijue+#num") < 1 then return end
	if ctx.is_from == false and ctx.opponent and ctx.opponent:getMark("&zijue+#num") > 0 then
		return number + ctx.opponent:getMark("&zijue+#num")
	end
	return number + player:getMark("&zijue+#num")
end)

-- gsgushe 鼓舌：+2×&gsgushe 標記數（僅當點數<13）
sgs.addPindianEffect("gsgushe", function(number, card, player, ctx)
	if not player:hasSkill("gsgushe") or number >= 13 then return end
	local n = player:getMark("&gsgushe")
	if n > 0 then return number + 2 * n end
end)

-- theace：僅 from 方，+2×@wannawin
-- is_from 未知（nil）時當有可能（最常見嘅估算場景係玩家自己發起拼點）
sgs.addPindianEffect("theace", function(number, card, player, ctx)
	if ctx.is_from == false then return end
	if not player:hasSkill("theace") then return end
	local n = player:getMark("@wannawin")
	if n > 0 then return number + 2 * n end
end)

-- ov_danlie 膽烈：+已損失體力
sgs.addPindianEffect("ov_danlie", function(number, card, player, ctx)
	if not player:hasSkill("ov_danlie") then return end
	local n = player:getLostHp()
	if n > 0 then return number + n end
end)

-- ov_qinghan 擎漢：+2×裝備數
sgs.addPindianEffect("ov_qinghan", function(number, card, player, ctx)
	if not player:hasSkill("ov_qinghan") then return end
	local n = player:getEquips():length() * 2
	if n > 0 then return number + n end
end)

-- ov_jianwei 劍衛：有武器時 +攻擊範圍
sgs.addPindianEffect("ov_jianwei", function(number, card, player, ctx)
	if not player:hasSkill("ov_jianwei") or not player:getWeapon() then return end
	local n = player:getAttackRange()
	if n > 0 then return number + n end
end)

-- ov_chuanshu 傳授：帶 "&ov_chuanshu+#擁有者" 標記嘅參與者 +3（每名擁有者獨立計）
sgs.addPindianEffect("ov_chuanshu", function(number, card, player, ctx)
	local room = pindianRoom(ctx)
	if not room then return end
	local bonus = 0
	for _, owner in sgs.qlist(room:findPlayersBySkillName("ov_chuanshu")) do
		if player:getMark("&ov_chuanshu+#" .. owner:objectName()) > 0 then bonus = bonus + 3 end
	end
	if bonus > 0 then return number + bonus end
end)

-- ov_lvren 旅人：+2×拼點目標數（唔少於+2）
sgs.addPindianEffect("ov_lvren", function(number, card, player, ctx)
	if not player:hasSkill("ov_lvren") then return end
	local n = 2
	if ctx.reason then
		local tag = player:getTag("targetsPindian_" .. ctx.reason):toString()
		if tag and tag ~= "" then n = #(tag:split("+")) * 2 end
	end
	return number + n
end)

-- xin2chuhai 出海（使命技）：使命未完成、reason 為 xin2chuhai、from 方，+max(0,4-裝備數)
sgs.addPindianEffect("xin2chuhai", function(number, card, player, ctx)
	if not player:hasSkill("xin2chuhai") then return end
	if ctx.reason ~= "xin2chuhai" or ctx.is_from == false then return end
	if player:getMark("successxin2chuhai") > 0 or player:getMark("failxin2chuhai") > 0 then return end
	local n = math.max(0, 4 - player:getEquips():length())
	if n > 0 then return number + n end
end)

--====================================================================
-- 可選·加減類（只喺 mode 為 "max"/"min" 時計入潛力）
--====================================================================

-- yingyang 陰陽：可令自己點數+3或-3
sgs.addPindianEffect("yingyang", function(number, card, player, ctx)
	if not player:hasSkill("yingyang") then return end
	if ctx.mode == "max" then return number + 3 end
	if ctx.mode == "min" then return number - 3 end
end)

-- s4_zhiba 制霸（主公技）：可令自己點數±3
sgs.addPindianEffect("s4_zhiba", function(number, card, player, ctx)
	if not player:hasLordSkill("s4_zhiba") then return end
	if ctx.mode == "max" then return number + 3 end
	if ctx.mode == "min" then return number - 3 end
end)

-- sfofl_kannan 困難：可令自己點數±場上勢力數
sgs.addPindianEffect("sfofl_kannan", function(number, card, player, ctx)
	if not player:hasSkill("sfofl_kannan") then return end
	local n = getKingdoms(player)
	if ctx.mode == "max" then return number + n end
	if ctx.mode == "min" then return number - n end
end)

-- ov_niju 逆舉（主公技）：可令任一參與者點數±群勢力角色數
-- 玩家自己係主公直接計；否則保守估算同陣營嘅逆舉主公會幫手/打壓
sgs.addPindianEffect("ov_niju", function(number, card, player, ctx)
	local room = pindianRoom(ctx)
	if not room then return end
	local qun = 0
	if player:hasLordSkill("ov_niju") then
		qun = room:getLieges("qun", player):length()
	elseif ctx.ai then
		local lord = room:findPlayerBySkillName("ov_niju")
		if lord and lord:isAlive() and ctx.ai:isFriend(lord) == ctx.ai:isFriend(player) then
			qun = room:getLieges("qun", lord):length()
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
	local room = pindianRoom(ctx)
	if not room then return end
	local owner = room:findPlayerBySkillName("fuzuo")
	if not owner or owner:isDead() or owner:isKongcheng() then return end
	if ctx.ai:isFriend(owner) == ctx.ai:isFriend(player) then return number + 3 end
end)

-- jibian 機變：可摸1~3張牌令自己點數-n（最差潛力-3）
sgs.addPindianEffect("jibian", function(number, card, player, ctx)
	if not player:hasSkill("jibian") then return end
	if ctx.mode == "min" then return number - 3 end
end)

-- jici 激詞（OL）：reason 為 gushe、點數細過饒舌標記數時可+標記數
sgs.addPindianEffect("jici", function(number, card, player, ctx)
	if not player:hasSkill("jici") then return end
	if ctx.reason ~= "gushe" or ctx.mode ~= "max" then return end
	local n = player:getMark("&raoshe")
	if n > 0 and number < n then return number + n end
end)

-- sxjici 激詞：可失去1點體力令自己點數視為K（體力>1先會用）
sgs.addPindianEffect("sxjici", function(number, card, player, ctx)
	if not player:hasSkill("sxjici") then return end
	if ctx.mode == "max" and player:getHp() > 1 then return 13 end
end, 2)

--====================================================================
-- SmartAI 封装
--====================================================================

-- 以有效點數揀出最大/最細嘅牌。mode: "max"（預設）或 "min"
-- 可見性規則同 getMaxCard 一致：其他人只計已知嘅牌；自己跳過貴重牌（冇就用fallback）
function SmartAI:getPindianCard(player, mode, ctx)
	if type(player) ~= "userdata" then return nil end
	mode = mode or "max"
	ctx = ctx or {}
	ctx.ai = ctx.ai or self
	ctx.mode = mode
	local cards = ctx.cards or player:getHandcards()
	cards = sgs.QList2Table(cards)
	if #cards < 1 then return nil end
	local best_card, best_point
	local function scan(skip_valuable)
		for _, card in ipairs(cards) do
			if not (skip_valuable and player == self.player and self:isValuableCard(card))
			and (player == self.player or self.player:canSeeHandcard(player)
				or card:hasFlag("visible")
				or card:hasFlag("visible_" .. self.player:objectName() .. "_" .. player:objectName())) then
				local point = sgs.getPindianNumber(card, player, ctx)
				if not best_point or (mode == "max" and point > best_point) or (mode == "min" and point < best_point) then
					best_card, best_point = card, point
				end
			end
		end
	end
	scan(true)
	if player == self.player and not best_card then scan(false) end
	return best_card, best_point
end

function SmartAI:getPindianMaxCard(player, ctx)
	return self:getPindianCard(player, "max", ctx)
end

function SmartAI:getPindianMinCard(player, ctx)
	return self:getPindianCard(player, "min", ctx)
end

function SmartAI:getPindianPoint(player, mode, ctx)
	local _, point = self:getPindianCard(player, mode, ctx)
	return point
end

function SmartAI:getPindianMaxPoint(player, ctx)
	return self:getPindianPoint(player, "max", ctx)
end

function SmartAI:getPindianMinPoint(player, ctx)
	return self:getPindianPoint(player, "min", ctx)
end
